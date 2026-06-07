---
name: docloom-author
description: Use when generating structured document drafts with automated review and fix pipeline in docloom.
metadata:
  version: "4.0"
---

# docloom-author

## 目标

docloom 编排层——接收 `doc_type`（必填）、`context`（可选）。先加载 spec + `../docloom/references/base.spec.md` 获取章节清单。`context` 缺失则调 `docloom-brainstorm` 逐章收集内容，存在则直接生成。落盘后依次调 `reviewer` → `feedback` → `review-auto-fix`，产出审查+修复后的文档。commit。

## 适用判断

需要在 docloom 流水线中生成文档草稿时使用。

## 前置条件

- `docs/loom/config.yaml` 存在且含目标 `doc_type`
- `../docloom/references/base.spec.md` 可访问
- `docloom-brainstorm` 可用（context 缺失时）
- `docloom-reviewer`、`docloom-review-auto-fix` 可用

## 执行步骤

### 声明参数

- **`doc_type`** — string，必填。文档类型键名，对应 config.yaml 中 `document_types`
- **`context`** — string，可选。文档内容上下文

### 流程

1. 接收 `doc_type`（必填）、`context`（可选）
2. 根据 `doc_type` 查询 `docs/loom/config.yaml`，获取 `spec` 路径和 `output_dir`
   - `doc_type` 不存在 → 报错列出有效类型
3. 根据 `spec` 路径加载 `<type>.spec.md` + `../docloom/references/base.spec.md`，获取章节清单
4. 根据 `context` 状态决定生成方式
   - `context` 缺失 → 调用 `docloom-brainstorm`，传入 `topic=author`、`context=章节清单`，返回逐章确认后的内容
   - `context` 存在 → 按 context 逐章生成文档
5. 写入 frontmatter（`type: <doc_type>`）→ 落盘到 `output_dir/<doc_type>-<timestamp>.md`
6. 调用 `reviewer`，传入 `doc_path=<刚生成的文档路径>`，返回 `issues[]`
7. 调用 `feedback`，传入 `doc_path`、`issues[]`、`source=author`，返回 `note_path`
8. 调用 `review-auto-fix`，传入 `note_path`，返回修复结果
9. commit

### 约束

- **落盘后强制调 reviewer → feedback → review-auto-fix**——确保文档输出即达标
- `doc_type` 必填——没有 doc_type 无法确定用哪份 spec
- 任一子 skill 报错 → 终止，不 commit

## 示例

### 场景 A：全自动生成（正常）

参数：doc_type=design, context="系统架构：前后端分离，React + TS 前端，Go + PostgreSQL 后端"

1. 查 config → spec + output_dir ✅
2. 加载 spec → 直接按 context 逐章生成
3. 落盘 → reviewer 审查 → 3 issues → feedback 生成 note → review-auto-fix 自动修复 → commit

### 场景 B：交互收集（缺 context）

参数：doc_type=prd

1. 查 config → spec ✅
2. context 缺失 → docloom-brainstorm(topic=author) → 逐章一问一答 → 用户确认内容
3. 落盘 → 审查链路 → commit

### 场景 C：doc_type 不存在（异常）

参数：doc_type=unknown

- 报错："unknown 不存在于 config.yaml。可用类型：api-doc, design, plan, ..."

## 验证

- 生成后验证文档存在于 `output_dir`，frontmatter 含正确的 `type`
- 验证 `reviewer` 已调用（issues[] 非空或为空均有返回）
- 验证 `feedback_note` 文件存在于 `feedback_dir`
- 验证 commit 已执行

## FAQ

**Q: 为什么 author 调 reviewer 但不调 fix？**

A: author → reviewer → review-auto-fix 是自动化闭环——生成、审查、修复一次性完成。fix 是用户手动入口（交互式），与 author 的自动化定位不同。用户读 feedback_note 后如需手动干预，自行调 fix。
