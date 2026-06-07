---
name: docloom-build-spec
description: Use when creating or editing spec files in the docloom pipeline with single-file spec output.
metadata:
  version: "4.0"
---

# docloom-build-spec

## 目标

docloom 流水线 spec 单文件生成器——按 `spec-doc.spec.md` 作为唯一权威模版，生成 `docs/loom/specs/<type>.spec.md`（规范），落盘前强制 5 项合规自检。create 模式下自动注册新文档类型到 config.yaml。

## 适用判断

需要在 docloom 流水线中创建或编辑文档类型的规范文件时使用本 skill：
- 新建文档类型规范 → `mode=create`
- 编辑已有规范 → `mode=edit`

如果不属于以上场景，跳过本 skill。

## 前置条件

- `docs/loom/config.yaml` 可访问（create 模式下 doc_type 不存在时自动注册）
- `../docloom/references/spec-doc.spec.md` 可访问
- `docloom-brainstorm` 可用（始终走交互收集元数据）
- edit 模式下目标 spec 文件已存在

## 执行步骤

### 声明参数

- **`mode`** — string，必填。`create` 新建 / `edit` 编辑已有
- **`doc_type`** — string，必填。文档类型标识（小写、连字符）
- **`context`** — string，可选。章节描述、约束说明等上下文

参数缺失时，调用 `docloom-brainstorm`，传入 `topic=collect-params`、`context=<参数定义 + 已有值>`。brainstorm 逐一收集缺失参数（一次一个，已有值不重复问），返回完整参数集合。

### 单文件输出

| 文件 | 路径 | 内容 |
|------|------|------|
| spec | `docs/loom/specs/<doc_type>.spec.md` | 规范文档——规则编号（`### XXX-NNN`）、严重度/约束/检查三段式、`>` blockquote 正反例 |

spec 文件自包含完整规则定义和自检清单，无独立 review 文件。

### mode=create — 新建

1. **注册类型**——加载 `docs/loom/config.yaml`
   - `doc_type` 已存在 → 跳过注册，继续步骤 2
   - `doc_type` 不存在 → 按约定自动生成路径并注册：
     - `spec: docs/loom/specs/<doc_type>.spec.md`
     - `output_dir: docs/docloom/<doc_type>/`
     - `feedback_dir: docs/loom/feedback/<doc_type>/`
     - 收集 `upstream_type`（可选）——上游文档类型，AI 列出 config 中已有类型供参考，用户选择或跳过
     - 按字母序在 `document_types` 中定位插入位置，使用 **Edit 工具**精确插入新条目（保留注释和格式）
     - ⚠️ 禁止使用任何 YAML 库读写 config.yaml（库会丢弃注释）
     - 插入后 YAML 语法验证：`ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"`——验证失败不继续
2. 加载 `../docloom/references/spec-doc.spec.md`，提取 5 章节模板（目的/非目的/输入参数声明/产出文件命名/必要章节）及每章说明
3. 调 `docloom-brainstorm`，传入 `topic=build-spec`、`context=<5章节模板 + doc_type>`，返回结构化 YAML（含 purpose/non_purpose/params/output_naming/required_chapters）
4. 按 brainstorm 返回的元数据 + spec-doc 规则格式，生成 spec 草稿（5 个 `##` 章节 + 按 required_chapters 推导 `### XXX-NNN` 规则 + 三段式 + 正反例）
5. **合规自检（5 项）→ 全部通过后单文件落盘**

### mode=edit — 编辑

1. 验证 `doc_type` 在 `document_types` 中存在
2. 验证 spec 文件存在——不存在则报错，提示使用 `mode=create`
3. 加载现有 spec 文件
4. 按 context 修改 spec 指定部分
5. **合规自检（5 项）→ 全部通过后落盘**

### 合规自检（落盘前强制，5 项）

1. spec 含 5 个 `##` 章节（目的/非目的/参数声明/输出声明/必要章节），彼此同级
2. 任一章节缺失或层级不一致 → 不落盘，补齐后重检
3. 新 spec 常见错误发现次数初始化为 0——禁止编造数据
4. spec 每条规则含完整三段式（严重度/约束/检查）——缺段不落盘
5. spec-doc.spec.md 最新版本已加载——禁止凭记忆或旁例生成

**自检失败 → 不落盘，修正后重新自检。**

### 通用约束

- **spec-doc.spec.md 是唯一权威**——已有 spec 文件可能不合规，不可盲从旁例
- **create 遇已有 spec 报错**——提示使用 `mode=edit`
- **edit 遇不存在 spec 报错**——提示使用 `mode=create`
- **config.yaml 编辑用 Edit 工具**——禁止 YAML 库，编辑后 `ruby -ryaml` 验证

## 示例

### 场景 A：新建 spec（正常，mode=create）

参数：doc_type=game-prd

1. config.yaml → game-prd 不存在 → upstream_type（跳过）→ 自动生成路径（spec/output_dir/feedback_dir）→ 注册（Edit 插入 + ruby 验证）✅
2. 加载 spec-doc.spec.md → 提取 5 章节模板
3. brainstorm(topic=build-spec) → 返回结构化 YAML（5 章元数据）
4. 按元数据生成 spec.md（5 个 `##` 章节 + 从必要章节推导 GAME-001~GAME-012 规则 + 正反例）
5. 自检 5 项 → 全部通过 → 落盘
6. commit

### 场景 B：编辑已有 spec（正常，mode=edit）

参数：doc_type=api-doc, context="新增 API-001 规则：API 端点描述必须含请求方法+路径+响应码"

1. 加载 api-doc.spec.md
2. 在 spec 常见错误章节新增 API-001 规则
3. 自检 5 项 → 通过 → 落盘
4. commit

### 场景 C：create 遇已有 spec（边界）

参数：doc_type=design（spec 已存在）

- 报错："design spec 已存在于 docs/loom/specs/design.spec.md，请使用 mode=edit 或先 remove 后重新 create"

### 场景 D：自检失败（边界）

spec 含 4 个 `##` 章节（缺少必要章节）

- 自检第 1 项失败 → 不落盘
- 补齐必要章节 → 重新自检 → 通过 → 落盘

## 验证

- create：验证 brainstorm 已调用（返回结构化 YAML 含 5 章元数据）；验证 `docs/loom/specs/<doc_type>.spec.md` 存在且内容非空
- edit：验证 spec 文件修改时间戳更新
- 自检：验证生成前 5 项全部勾选通过

## FAQ

**Q: 为什么已有 spec 不能当作权威参考？**

A: 已有 spec 可能是在旧版 spec-doc 下生成的，格式可能已过时。spec-doc.spec.md 是持续更新的唯一权威——以它为准，不以旁例为准。
