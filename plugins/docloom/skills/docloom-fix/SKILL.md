---
name: docloom-fix
description: Use when fixing documents via feedback generation and brainstorm-assisted refinement in docloom.
metadata:
  version: "6.0"
---

# docloom-fix

## 目标

用户手动修复入口——接收 doc_path + context，调 reviewer 生成 feedback_note → brainstorm 逐条确认方案 → 修改文档 + 回填 → commit [LOOM-FIX]。修复后扫描 severity，含严重级违规则询问是否调 entropy 回补 spec。

## 非目的

不修 entry 中未描述的问题——禁止扩大修复范围。不跳过 reviewer——entry 格式化与 spec 规则匹配必须一致。entropy 不可用时仅告警跳过，不阻断。

## 参数

- **`doc_path`** — string，必填。目标文档相对路径。
- **`context`** — string，必填。用户描述的问题，作为 issues[] 传入 reviewer。

## 收集参数

frontmatter type（从 doc_path 读取，读不到时询问用户确认——仅此 1 次）、brainstorm 返回的自然语言摘要（从中提取修复决策→entry 映射）。

## 流程

确认 doc_path + context 齐备（缺一 → 告知缺失项，等待补齐）
→ 读 doc_path frontmatter 获取 type
    - 读不到 → 询问用户确认 → 重新读取——仅此 1 次，防止死循环
    - 仍无 type → 报错终止
→ 根据 type 查 [config.yaml][docloom-config]，获取 spec 路径和 feedback_dir
    - type 不在 document_types 中 → 报错列出有效类型——修复仅支持已注册类型
→ 调 docloom-reviewer（doc-path, source=fix, issues=[context]）→ 返回 note_path
——reviewer 是唯一知晓 entry-schema 的组件，fix 只传自然语言，不耦合 entry 格式
    - 失败 → 告知用户原因，终止
→ 读 feedback_note，提取 entry 摘要（每条：title、severity、问题简述、违反的 spec 规则）
→ 调 docloom-brainstorm，传入场景描述：
    "用户报告了 {doc_path} 的问题：{context}。经 reviewer 审查，发现以下违规（按严重度排列）：{entry 摘要列表}。请与用户协作确认修复方案——优先处理严重级，低严重度项如用户无异议可批量确认。"
→ docloom-brainstorm 返回自然语言摘要——从「用户确认方案」中提取修复决策，映射到对应 entry
→ 按映射关系修改文档 + 回填 entry status
——只修 entry 中明确描述的问题，禁止扩大范围
→ commit `[LOOM-FIX]`
→ 逐条 entry 检查 severity：
    - **含严重级** → 询问用户是否调 docloom-entropy（doc-type, note-path）
        ——一条严重就足以触发建议；频率统计等深度分析是 entropy 的职责
        - 用户确认 → 执行 entropy 并走其审批流程
        - 用户拒绝 → 正常结束
    - **无严重级** → 正常结束
    - **解析失败** → 告警结束

## 验证

```bash
grep -q "## 目标" SKILL.md && grep -q "## 非目的" SKILL.md && grep -q "## 参数" SKILL.md && grep -q "## 流程" SKILL.md && grep -q "docloom-reviewer" SKILL.md && grep -q "severity" SKILL.md && grep -q "LOOM-FIX" SKILL.md && grep -q "场景描述" SKILL.md && grep -q "entry 摘要" SKILL.md
```

- [ ] type 从 frontmatter 读取
- [ ] docloom-reviewer 为独立步骤，不可跳过
- [ ] 文档内容变更与 entry 描述一致
- [ ] feedback_note 中被处理的 entry status 已更新
- [ ] commit message 含 `[LOOM-FIX]` 前缀
- [ ] 用户确认后才调 docloom-entropy

## 示例

> **正例：**
>
> doc_path=docs/api-docs/endpoints.md, context="第 3 节缺少请求示例"
> → frontmatter type=api-doc → config 查询 ✅
> → reviewer(source=fix, issues=[context]) → note_path（1 条 entry，severity=重要）
> → 提取 entry 摘要 → brainstorm（传入场景描述：用户问题 + entry 摘要）
>   → 用户确认："添加 curl 示例 + 成功/401 响应 JSON"
> → 从摘要提取修复决策 → 修改文档 + 回填 → commit [LOOM-FIX]
> → severity 扫描 → 无严重级 → 正常结束。

> **反例：**
>
> doc_path=docs/notes/scratch.md, context="日志格式不一致"
> → frontmatter type=scratch-note → config 中 scratch-note 未注册
> → 报错列出有效类型，终止。
>
> 修复仅支持已注册类型——未注册类型没有 spec 和 feedback_dir，reviewer 无法定位双层规范。注册新类型需走 docloom-register。

[docloom-config]: docs/loom/config.yaml
