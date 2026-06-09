---
name: docloom-entropy
description: Use when analyzing feedback_note files to identify document-quality patterns and generate data-driven spec improvement drafts.
metadata:
  version: "4.0"
---

# docloom-entropy

## 目标

扫描 feedback_note 文件，按多维度分析违规模式，产出数据驱动的 spec 改进建议草稿供用户审批。

## 非目的

不修复文档——只分析、不改动。不得依赖预聚合数据替代逐条解析——每条 feedback-note 逐个 Entry 读。不得抽样——未处理 = 全量。

## 参数

- **`doc-type`** — string，必填。目标文档类型，必须在 [config.yaml][docloom-config] 中已注册。
- **`context`** — string，可选。额外上下文。
- **`note-path`** — string，可选。指定单个 feedback_note 路径——触发单条分析模式。

## 收集参数

全量模式下 git/file 扫描得到的未处理 note 列表、checkpoint（commit hash 或文件列表）。

## 流程

确认 doc-type 齐备
→ 加载 [config.yaml][docloom-config] → 验证 doc-type 存在
→ 模式判定：
    - **传了 note-path** → 单条分析模式：
        → 解析指定 feedback_note（不存在 → 报错退出）
        → 覆盖率自检（该文件内 entry 覆盖率 = 100%）
        → 5 维分析（违规频率/修复模式/类型分布/阻塞项/优化优先级）
        ——跳过全量模式专属的趋势分析、跨文档对比、规范变更追踪
        ——不读写 checkpoint
    - **未传 note-path** → 全量批量模式：
        → 判定环境：git 可用 → git 模式扫描 `git log --grep=[LOOM-FIX]`，checkpoint 用 commit hash
          git 不可用 → file 模式扫描 feedback_dir 下 `*-feedback-note.md`，checkpoint 用文件列表
        → 差集为空 → "无新数据，分析跳过" 正常退出
        → 逐条读取未处理 note 的所有 Entry → 8 维分析
        → 覆盖率自检 → 100%（否则标记"分析不完整"）
→ 生成改进建议草稿 → 落盘 `docs/loom/entropy/drafts/<type>/<timestamp>-entropy-analysis.草稿.md`
→ 全量模式回填 checkpoint（单条模式跳过）
→ 呈现草稿给用户审批：
    - **批准** → 移至 `docs/loom/entropy/analysis/<type>/`，去掉 `.草稿` 后缀
    - **修改要求** → 修改草稿后重新审批
→ 审批通过后询问是否应用到 spec：
    - **是** → 调 docloom-spec-writer（mode=edit, idea=改进建议, doc_type, spec_path）
    - **否** → 结束

## 验证

```bash
grep -q "## 目标" SKILL.md && grep -q "## 非目的" SKILL.md && grep -q "## 参数" SKILL.md && grep -q "## 流程" SKILL.md && grep -q "note-path" SKILL.md && grep -q "模式判定" SKILL.md
```

- [ ] 验证草稿文件存在于 `drafts/<type>/`
- [ ] 验证覆盖率 = 100%（输出的覆盖率摘要）
- [ ] 审批后验证文件从 `drafts/` 移至 `analysis/`
- [ ] 单条模式：验证维度输出仅含 5 个精简维度

## 示例

> **正例：**
>
> doc-type=api-doc（git 可用，无 checkpoint）
> → git 模式扫描 [LOOM-FIX] commit → 12 个 commit → 15 个 feedback_note
> → 逐条解析 87 条 entry → 8 维分析 → 覆盖率 100%
> → 生成草稿 → 回填 commit hash → 呈现审批。

> **反例：**
>
> doc-type=design → 扫描 feedback_dir → 15 个 feedback_note
> → 按数据分布抽样：取最近 5 个分析，其余跳过。
>
> 抽样掩盖低频但高严重度的违规模式——一条 block 级规则被触发 1 次在抽样中可能遗漏，但它对规范改进价值很高。全量解析 + 覆盖率 100% 确保无遗漏。

[docloom-config]: ../../docs/loom/config.yaml
