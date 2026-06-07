---
name: docloom-reviewer
description: Use when reviewing a document against spec-derived checklist returning issues array.
user-invocable: false
metadata:
  version: "5.0"
---

# docloom-reviewer

## 目标

纯函数文档审查器——接收 `doc_path`，从 `<type>.spec.md` 规则 1:1 提取检查+严重度构造审查清单，从 `../docloom/references/base.spec.md` 追加通用检查项，逐项对照文档审查，返回 `issues[]`。只审不修，不调任何其他 skill。

## 适用判断

被 `docloom-author` 内部调用——author 生成文档后自动调本 skill 执行审查。用户不直接触发。

## 前置条件

- `doc_path` 指向的 `.md` 文件存在且可读
- `docs/loom/config.yaml` 存在且含 `document_types` 定义
- `../docloom/references/base.spec.md` 可访问

## 执行步骤

### 声明参数

- **`doc_path`** — string，必填。待审文档的相对路径。

⚠️ `doc_path` 未提供 → 报错终止。

### 审查流程

1. 接收 `doc_path`
2. 根据 `doc_path` 读取文档 frontmatter，获取 `type` 字段
   - 无 `type` 字段 → 报错："文档缺少 type 字段，无法确定审查规范"
3. 根据 `type` 查询 `docs/loom/config.yaml`，获取 `spec` 路径
   - `type` 不存在 → 报错列出所有有效类型
4. 根据 `spec` 路径加载 `<type>.spec.md`，解析 `### XXX-NNN` 规则
5. 逐规则提取 `**检查：**` + `**严重度：**` 字段，构造审查清单（1:1）
   - ⚠️ 规则缺少 `**检查：**` 字段 → 跳过该规则，记录 warn
   - spec 无任何规则 → 报错
6. 根据 `../docloom/references/base.spec.md` 追加通用规范检查项
7. 逐检查项对照文档内容审查，收集不通过项
8. 返回 `issues[]`，每条含：
   - `title` — 问题标题
   - `severity` — 严重度（严重 / 重要 / 轻微）
   - `location` — 问题定位（章节:行号）
   - `description` — 具体问题描述
   - `spec_source` — 触发域（base / `<type>`）
   - `specid` — 触发规则编号（XXX-NNN）

### 约束

- **只审不修**——不修改被审文档
- **不调其他 skill**——不调 feedback、不调 fix、不调 brainstorm
- **纯函数**——仅从输入参数推导结果，无副作用
- 任一必需文件缺失 → 报错给出路径，不静默跳过

## 示例

### 场景 A：正常审查

参数：doc_path=docs/00-project-knowledge-base/02-technology-layer/04-api-docs/auth-api.md

1. 读 frontmatter → type=api-doc ✅
2. 查 config → spec=docs/loom/specs/api-doc.spec.md
3. 加载 spec → 解析 15 条规则 → 构造 15 项审查清单
4. 追加 base.spec.md 通用检查项（+3 项）→ 共 18 项
5. 逐项审查 → 发现 3 项不通过
6. 返回 issues[3]

### 场景 B：文档缺少 type

参数：doc_path=docs/some-doc.md

- frontmatter 无 `type` 字段 → 报错

### 场景 C：type 不在 config 中

参数：doc_path=docs/loom/some-unknown.md

- frontmatter type=unknown-type
- config.yaml 无 unknown-type → 报错列出有效类型

## 验证

- 调用后验证返回值为数组，每条含 title / severity / location / description / spec_source / specid
- 验证未修改被审文档（文件内容不变）
- 验证检查项数 = spec 规则数 + base 检查项数（扣除缺检查字段的规则）

## FAQ

**Q: 为什么不调 feedback 生成 feedback_note？**

A: reviewer 是纯函数——只审查不记录。feedback_note 生成由 author 编排层负责。职责分离让 author 可以灵活决定审查结果的处理方式。

**Q: base.spec.md 路径为什么用相对路径？**

A: `../docloom/references/base.spec.md` 从 skill 目录（`.agents/skills/docloom-reviewer/`）往上一级即可定位到共享目录。所有 docloom skill 使用统一的相对路径约定。
