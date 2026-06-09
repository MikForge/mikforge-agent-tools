---
name: docloom-author
description: Use when generating structured document drafts with layered spec validation in docloom.
metadata:
  version: "5.0"
---

# docloom-author

## 目标

docloom 编排层——接收 doc_type，按 [base.spec.md][docloom-base-spec] + `<type>.spec.md` 双层规范生成文档，落盘后强制执行审查 → feedback → 修复 → commit。

## 非目的

不跳过审查链——审查和修复是强制执行步骤，不可省略。不支持跨类型 spec 生成——每种 doc_type 使用自身对应的 spec。

## 参数

- **`doc_type`** — string，必填。目标文档类型，必须在 [config.yaml][docloom-config] 中已注册。
- **`context`** — string，可选。用户提供的上下文，作为 brainstorm 候选方案参考。

## 收集参数

brainstorm 返回的自然语言摘要——从中提取各章决策，按 spec 章节结构组装文档正文和 frontmatter。

## 流程

确认 doc_type 齐备（缺失 → 报错终止——没有 doc_type 无法确定 spec 和 output_dir）
→ 查 [config.yaml][docloom-config]，获取 spec 路径和 output_dir
    - doc_type 不存在 → 报错列出有效类型
→ 检查 spec 文件存在性：
    - [base.spec.md][docloom-base-spec] 不存在 → 收集缺失项
    - `<type>.spec.md` 不存在 → 收集缺失项
    - 存在任何缺失 → 一次性报错列出所有缺失路径，终止——并行检查，一次报全
    - 全部存在 → 加载两层 spec，合并规则
——base.spec.md 定义通用写作约束，<type>.spec.md 定义类型专属章节结构，两层同等生效
→ 调 docloom-brainstorm，传入场景描述：
    "用户需要撰写一份 {doc_type} 文档。规范要求：{spec 章节结构摘要}。base 通用约束：{base 约束摘要}。用户提供的上下文：{context 或 '无'}。请与用户协作确认文档的整体方案和各章节内容。"
→ docloom-brainstorm 返回自然语言摘要——从「用户确认方案」中提取各章决策，组装文档正文
——spec 定义了必须覆盖的章节，brainstorm 负责确认每章写什么、怎么写
→ 写入 frontmatter（`type: <doc_type>`）→ 落盘到 `output_dir/<doc_type>-<timestamp>.md`
→ 审查与修复：
    - 调 reviewer（source=author）→ 收集 issues[]
    - 生成 feedback_note → 按 review-auto-fix 步骤修复
    - 任一阶段报错 → 终止，不 commit——未经审查的文档禁止进入仓库
→ commit

## 验证

```bash
grep -q "## 目标" SKILL.md && grep -q "## 非目的" SKILL.md && grep -q "## 参数" SKILL.md && grep -q "## 流程" SKILL.md && grep -q "base.spec.md" SKILL.md && grep -q "docloom-brainstorm" SKILL.md && grep -q "场景描述" SKILL.md && grep -q "自然语言摘要" SKILL.md
```

- [ ] 生成后验证文档存在于 output_dir，frontmatter 含正确的 type
- [ ] 验证 reviewer 已调用（issues[] 非空或为空均有返回）
- [ ] 验证 feedback_note 文件存在于 feedback_dir
- [ ] 验证 commit 已执行

## 示例

> **正例：**
>
> doc_type=design, context="系统架构：前后端分离，React + TS 前端，Go + PostgreSQL 后端"
> → 查 config → spec ✅ → 加载 base.spec.md + design.spec.md ✅
> → brainstorm（传入场景描述：文档类型 + 规范要求 + 用户上下文）
>   → 用户确认：背景用痛点驱动、目标从性能瓶颈反推、架构用分层图
> → 从摘要提取各章决策 → 组装文档 + frontmatter → 落盘
> → reviewer 审查 → 3 issues → feedback 生成 note → 自动修复 → commit。

> **反例：**
>
> doc_type=design → 审查发现 3 issues → 跳过修复直接 commit。
>
> 审查 → feedback → 修复链强制执行，任何环节不可跳过。跳过审查意味着未经 spec 验证的文档进入了仓库——后续所有消费者（reviewer、entropy）都将基于不合规文档工作。

[docloom-config]: ../../docs/loom/config.yaml
[docloom-base-spec]: ../docloom/references/base.spec.md
