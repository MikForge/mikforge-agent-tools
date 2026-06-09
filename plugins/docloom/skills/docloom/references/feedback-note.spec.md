---
type: spec-doc
---

# Feedback-note 格式规范

定义 reviewer 产出、fix 消费的通信协议格式。

---

## 目的

确保 fix 能精确解析审查结果，定位到文档位置，逐条驱动可追溯的修复流程。

## 非目的

不约束审查逻辑、不约束修复流程。

## 输入参数声明

- **`reviewer-doc-type`** — string，必填。被审文档类型。
- **`doc_path`** — string，必填。被审文档绝对路径。
- **`entries`** — array，必填。审查发现的问题列表，每条 entry 符合 entry-schema.md 定义。

## 产出文件命名

`<reviewer-doc-type>-<YYYY-MM-DD-HH-mm>-feedback-note.md`

输出目录由 config.yaml 中对应文档类型的 `feedback_dir` 字段指定。

## 必要章节

- Header（被审文档/审查来源/审查时间/审查结论）、Entry 列表

---

### FBN-header-fields-complete：Header 字段完整

- **严重度：** 严重
- **约束：** feedback-note 头部必须包含四个字段：被审文档（绝对路径）、审查来源（fix 或 author）、审查时间（ISO 8601 格式，含时分秒）、审查结论（通过/存在问题）。反例——被审文档用相对路径导致 fix 无法定位；缺少审查来源下游 entropy 无法区分链路；审查时间缺少时分秒格式不完整；缺少审查结论。
- **检查：** Header 含被审文档绝对路径（warning）；审查来源为 fix 或 author（error）；审查时间为 ISO 8601 格式（info）；审查结论为通过/存在问题（warning）；Header 区域以 `## Header` 标题开头（info）

> **正例：**
>
> ## Header
>
> - **被审文档：** /Users/michael/Desktop/gitfiles/ai_tools_in_work/docs/design/api-design.md
> - **审查来源：** author
> - **审查时间：** 2026-05-29T01:54:00
> - **审查结论：** 存在问题
>
> **反例：**
>
> - **被审文档：** docs/design/api-design.md
> - **审查时间：** 2026-05-29
> （缺少 ## Header 标题；被审文档为相对路径；缺少审查来源；审查时间格式不完整；缺少审查结论）
>

### FBN-entry-list-schema-compliant：Entry 列表符合 entry-schema 字段规范

- **严重度：** 严重
- **约束：** 根据 entry-schema.md 生成 entry-list，每条 entry 独立完整。新生成 entry 初始状态为"未处理"。反例——"文档有几个问题需要修复"未逐条列出 entry，缺少必填字段，fix 无法解析具体问题和位置。
- **检查：** entry-list 符合 entry-schema.md 规范（info）；Entry 列表区域以 `## Entry 列表` 标题开头（info）；新生成 entry 初始状态为"未处理"（info）

> **正例：**
>
> ### 问题陈述缺失
>
> - **severity:** 严重
> - **spec_source:** design
> - **specid:** DSG-problem-statement
> - **location:** 问题陈述:3-5
> - **description:** 设计文档缺少问题陈述章节...
> - **status:** 未处理
> - **fix_summary:**
> - **block_reason:**
>
> **反例：**
>
> 文档有几个问题需要修复，整体质量不高。
>

### FBN-zero-issues-still-generate：零问题时仍生成文件声明通过

- **严重度：** 严重
- **约束：** 审查后未发现任何问题时 entry 列表为空，正文必须写"未发现问题，审查通过。"。禁止跳过文件输出——零问题不生成文件会导致 fix 和 entropy 无法追踪该轮审查，破坏审查链路完整性。
- **检查：** 零问题时生成文件且正文含"未发现问题，审查通过"（error）
