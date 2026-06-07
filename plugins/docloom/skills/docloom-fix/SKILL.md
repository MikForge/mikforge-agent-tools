---
name: docloom-fix
description: Use when fixing documents via context mode with brainstorm-assisted problem refinement in the docloom pipeline.
metadata:
  version: "3.0"
---

# docloom-fix

## 目标

用户手动修复入口——context 单模式。接收 `doc_path` + `context`，加载 spec + `../docloom/references/base.spec.md` 验证问题。存在则构造 entry → 调 `feedback` 生成 note → 调 `docloom-brainstorm` 逐条确认方案 → 修改文档 + 回填。不存在或模糊则调 `docloom-brainstorm` 细化。commit `[LOOM-FIX]`。

## 适用判断

用户需要手动修复 docloom 生态内的文档时使用本 skill——传入文档路径 + 问题描述。

## 前置条件

- `docs/loom/config.yaml` 存在且含 `document_types` 定义
- `../docloom/references/base.spec.md` 可访问
- `docloom-feedback`、`docloom-brainstorm` skill 可用

## 执行步骤

### 声明参数

- **`doc_path`** — string，必填。目标文档相对路径
- **`context`** — string，必填。用户描述的问题

### 流程

1. 接收 `doc_path`、`context`
2. 根据 `doc_path` 读取文档 frontmatter，获取 `doc_type`
3. 根据 `doc_type` 查询 `docs/loom/config.yaml`，获取 `spec` 路径和 `feedback_dir`
4. 根据 `../docloom/references/base.spec.md` + `<type>.spec.md` 验证 `context` 描述的问题
   - 问题存在 → 继续步 5
   - 不存在或模糊 → 调用 `docloom-brainstorm`，传入 `topic=fix`，返回细化后的问题描述
5. 根据 `context` 构造 entry：
   - `title` — 从 context 提取核心问题描述
   - `severity` — 默认"重要"
   - `location` — 从 context 提取位置；无明确位置填 `doc_path`
   - `description` — context 原文
   - `spec_source` — 默认 `uncategorized`
   - `specid` — 默认 `uncategorized`
6. 调用 `feedback`，传入 `doc_path`、`[entry]`、`source=fix`，返回 `note_path`
7. 调用 `docloom-brainstorm`，传入 `topic=fix`、`context=entry 列表`，返回确认后的修复方案
8. 根据修复方案修改被审文档 + 回填 entry status
9. commit `[LOOM-FIX]`

### 中断保护

修复中断时，已回填的 entry status 保留在 feedback_note 中。下次传入同一描述时可从中断点继续。

### 约束

- 只能修复 entry 中明确描述的问题——禁止扩大修复范围
- 非 docloom-brainstorm 流程中不能跳过用户确认
- 回填时保留原有字段不丢失

## 示例

### 场景 A：正常修复

参数：doc_path=docs/api-docs/endpoints.md, context="API 文档第 3 节缺少请求示例"

1. 读 frontmatter → doc_type=api-doc
2. 查 config → spec + feedback_dir
3. 加载 spec → 定位第 3 节 → 确实缺少请求示例 ✅
4. feedback 生成 note → 1 条 entry
5. docloom-brainstorm 确认方案 → 用户选"添加 curl 示例 + 响应 JSON"
6. 修改文档 + 回填 → commit

### 场景 B：问题模糊（边界）

参数：doc_path=docs/design-docs/arch.md, context="架构描述不太清楚"

1. 加载 spec → 验证 → 描述模糊，无法定位具体问题
2. docloom-brainstorm(topic=fix) → 用户细化："第 4 节缺少组件间通信协议的说明"
3. 构造 entry → feedback → docloom-brainstorm 确认 → 修复 → commit

## 验证

- 修后验证文档内容变更与 entry 描述一致
- 验证 feedback_note 中被处理的 entry status 已更新
- commit 含 `[LOOM-FIX]` 前缀

## FAQ

**Q: 问题描述不具体怎么办？**

A: 第 4 步会通过 docloom-brainstorm 帮助用户细化——不会冷冰冰退出，而是交互式引导用户把模糊诉求转成可操作描述。
