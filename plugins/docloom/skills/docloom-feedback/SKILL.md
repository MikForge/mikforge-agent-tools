---
name: docloom-feedback
description: Use when generating structured feedback_note files from issues and entry-schema in the docloom pipeline.
user-invocable: false
metadata:
  version: "3.0"
---

# docloom-feedback

## 目标

纯函数 feedback_note 文件生成器——接收 `doc_path`、`issues[]`、`source`，读取 frontmatter 获取 doc_type 查 config 获取 feedback_dir，从 `../docloom/references/entry-schema.md` 组装 Entry，从 `../docloom/references/feedback-note.spec.md` 组装 Header，落盘并返回 `note_path`。不审查、不修复、不调其他 skill。

## 适用判断

被 `docloom-author` 或 `docloom-fix` 调用——需要生成结构化的审查反馈文件时使用。用户不直接触发。

## 前置条件

- `docs/loom/config.yaml` 存在且含 `document_types` 定义
- `../docloom/references/entry-schema.md` 可访问
- `../docloom/references/feedback-note.spec.md` 可访问
- 调用方提供 `doc_path`、`issues[]`、`source` 三个参数

## 执行步骤

### 声明参数

- **`doc_path`** — string，必填。被审文档相对路径
- **`issues[]`** — array，必填。审查发现的问题列表，每条含：
  - `title` — 问题标题
  - `severity` — 严重度（严重 / 重要 / 轻微）
  - `location` — 问题定位
  - `description` — 具体问题描述
  - `spec_source` — 触发域
  - `specid` — 触发规则编号
- **`source`** — string，必填。调用来源（author / fix）

### 流程

1. 接收 `doc_path`、`issues[]`、`source`
2. 根据 `doc_path` 读取文档 frontmatter，获取 `doc_type`
3. 根据 `doc_type` 查询 `docs/loom/config.yaml`，获取 `feedback_dir`
   - 缺失或为空 → 报错退出
   - `feedback_dir` 目录不存在 → 自动创建
4. 根据 `../docloom/references/entry-schema.md` 组装 Entry（9 字段齐全）：
   - `status` 初始 = "未处理"
   - `fix_summary`、`block_reason` 初始留空
5. 根据 `../docloom/references/feedback-note.spec.md` 组装 Header
6. 命名 `<doc_type>-<timestamp>-feedback-note.md`
7. 落盘到 `feedback_dir/`
8. 返回 `note_path`

### 零 issues 处理

`issues[]` 为空时仍然生成文件——Header 标注"审查结论：通过"，Entry 列表为空。禁止跳过生成。

### 约束

- **只生成文件**——不审查文档内容、不修改被审文档、不执行修复
- **不调其他 skill**——纯函数，无副作用
- Entry 初始 `status` 统一为 "未处理"

## 示例

### 场景 A：正常生成

参数：doc_path=docs/design-docs/feature.md, issues=[{title:"缺少前置条件", severity:"严重", location:"§前置条件:L12", ...}], source=author

1. 读 frontmatter → doc_type=design
2. 查 config → feedback_dir=docs/loom/feedback/design/
3. 组装 1 条 entry → status="未处理"
4. 生成 note → docs/loom/feedback/design/design-20260607T000000-feedback-note.md
5. 返回路径

### 场景 B：零 issues

参数：issues=[]

1. issues 为空
2. 仍生成文件——Header 标注"审查结论：通过"，Entry 列表为空
3. 返回路径

## 验证

- 生成后验证文件存在且命名符合 `<doc_type>-<timestamp>-feedback-note.md`
- 验证 Entry 的 `status` 字段为 "未处理"
- 零 issues 时验证 Header 含"审查结论：通过"

## FAQ

**Q: 为什么零 issues 也要生成文件？**

A: 调用方依赖文件存在来判断审查已完成。零 issues 不生成文件，调用方无法区分"审查通过"和"审查未执行"。生成"通过"标记的空反馈文件让上游明确知道已完成。

**Q: entry 路径为什么用相对路径？**

A: `../docloom/references/` 从 skill 目录往上一级即到共享目录。所有 docloom skill 使用统一的相对路径约定。
