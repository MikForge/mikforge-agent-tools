---
name: docloom-reviewer
description: Use when reviewing documents and generating structured feedback_note files in the docloom pipeline.
user-invocable: false
metadata:
  version: "2.0"
---

# docloom-reviewer

## 目标

审查 + feedback-note 生成合并入口——接收 doc-path + source + 可选的 issues[]，加载双层 spec 审查文档，按 [entry-schema.md][docloom-entry-schema] 格式化发现并落盘 feedback_note。

## 非目的

只审不修——不修改被审文档、不调其他 skill、不执行修复动作。entry-schema 和 feedback-note.spec 的读取对调用方透明。

## 参数

- **`doc-path`** — string，必填。被审文档路径。
- **`source`** — `fix | author`，必填。`author`=纯审查模式（issues[] 为空），`fix`=用户手动修复（issues[] 必填）。
- **`issues[]`** — string[]，source=fix 时必填。自然语言描述的问题列表。

## 收集参数

无——所有信息从参数和 spec 文件获取。

## 流程

验证 doc-path 存在、source 为 fix 或 author
    - doc-path 不存在 → 报错终止
    - source 不是 fix 或 author → 报错终止
    - source=fix 且 issues[] 为空 → 报错终止
→ 读 doc-path frontmatter 获取 type
    - type 缺失 → 报错终止——无法定位 spec
→ 加载 base.spec.md（硬编码 `.agents/skills/docloom/references/base.spec.md`）+ `docs/loom/specs/<type>.spec.md`
    - 任一不存在 → 一次性列出缺失路径，报错终止
    - spec 中无有效规则 → 报错终止
→ 逐检查项对照文档内容审查，收集不通过项
→ issues[] 非空时逐条解析自然语言匹配 spec 规则——无法匹配 → specid=uncategorized，不阻断
→ 按 [entry-schema.md][docloom-entry-schema] 格式化所有发现为 Entry——初始 status 统一为"未处理"
→ 按 [feedback-note.spec.md][docloom-feedback-note-spec] 组装 Header
→ 命名 `<type>-<timestamp>-feedback-note.md` 落盘到 `docs/loom/feedback/<type>/`
    - 目录不存在 → 自动创建（失败则报错）
→ 返回 note_path
——审查全通过 + issues[] 为空时仍生成文件，Header 标注"审查结论：通过"，Entry 列表为空

## 验证

```bash
grep -q "## 目标" SKILL.md && grep -q "## 非目的" SKILL.md && grep -q "## 参数" SKILL.md && grep -q "## 流程" SKILL.md && grep -q "source" SKILL.md && grep -q "entry-schema" SKILL.md
```

- [ ] 生成后验证 feedback_note 文件存在且命名符合 `<type>-<timestamp>-feedback-note.md`
- [ ] 验证 Entry 的 status 字段为 "未处理"
- [ ] 零 issues 时验证 Header 含 "审查结论：通过"

## 示例

> **正例：**
>
> doc-path=docs/design-docs/feature.md, source=author
> → 验证通过 → type=design → 加载 base.spec.md + design.spec.md ✅
> → 15 项审查清单 → 3 项不通过 → 格式化 3 条 Entry → 落盘 → 返回 note_path。

> **反例：**
>
> doc-path=docs/api-docs/endpoints.md, source=fix（issues[] 为空）
> → 步骤 1：source=fix 但 issues[] 为空 → 报错「fix 模式下 issues[] 必须非空」。
>
> fix 模式必须有自然语言描述的问题，否者 reviewer 无法区分哪些 Entry 来自审查发现、哪些来自用户报告。

[docloom-entry-schema]: ../docloom/references/entry-schema.md
[docloom-feedback-note-spec]: ../docloom/references/feedback-note.spec.md
