---
name: docloom-spec-writer
description: Use when creating a new document type spec from a user idea, or editing an existing spec.
metadata:
  version: "3.0"
---

# docloom-spec-writer

## 目标

用户入口 skill——接收 idea（create 模式）编排「新文档类型」全流程（brainstorm → register → spec 生成），或接收 idea（edit 模式）修改已有 spec。create 模式为一轮统一 brainstorm 覆盖注册参数 + spec 内容；edit 模式为 brainstorm 确认改进项后应用到 spec。

## 非目的

不做注册、不创建新 spec。

## 参数

- **`mode`** — `create | edit`，必填。无默认值。
- **`idea`** — string，create 必填，edit 必填（修改意见）。用户自然语言描述。
- **`doc_type`** — string，edit 必填，create 不使用。文档类型标识符。
- **`spec_path`** — string，edit 必填，create 不使用。spec 文件路径。



## 收集参数
create 模式：brainstorm 统一会话返回的自然语言摘要——从中提取两部分：注册参数（doc_type / type_desc / spec_path / output_dir / feedback_dir / upstream_type）和 spec 各章决策。

edit 模式：brainstorm 返回的自然语言摘要——从中提取确认的改进项，应用到 spec。

## 流程

确认 mode 齐备
→ 模式路由：

**mode=create：**

→ idea 缺失 → 报错「idea 为必填参数」，终止
→ 加载 [spec-doc.spec.md][spec-doc-ref] 获取 spec 结构要求 + [register SKILL.md][register-skill] 获取注册参数字段
    - 任一缺失 → 报错列出缺失文件，终止
→ 查 [config.yaml][docloom-config] 已有文档类型列表（document_types 各 key），用作碰撞检查
→ 构建待推断集合 = 注册参数 + spec 各章决策：
    - 注册参数：doc_type + type_desc + spec_path + output_dir + feedback_dir + upstream_type（可选）
    - spec 侧章节/规则：按 spec-doc 结构逐章
    - 上下文：已有类型列表、碰撞风险
→ 调 [docloom-brainstorm][brainstorm-skill]，传入统一场景描述：

"用户想注册一种新的文档类型并为其创建编写规范（spec）。原始想法：{idea}。当前已有类型：{已有类型列表}。

需要你与用户协作确认两部分内容：

**第一部分——注册参数：**
1. 文档类型标识符（doc_type）：从 idea 推断，与已有类型不重名
2. 类型定位描述（type_desc）：2-3 句，覆盖用途/目标读者/典型内容
3. 路径参数：spec 路径、产出目录（output_dir）、反馈目录（feedback_dir）。如用户无特殊偏好，使用 docloom 约定：spec=docs/loom/specs/{doc_type}.spec.md，output_dir=docs/docloom/{doc_type}/，feedback_dir=docs/loom/feedback/{doc_type}/
4. 上游关联类型（upstream_type）：可选

**第二部分——spec 内容：**
spec 自身的编写规范要求：需包含目的、非目的、输入参数、产出命名、结构声明、必要章节、规则集（含严重度和检查方法）。base 通用约束：引用式链接、禁止措辞。

请与用户协作——先确认注册参数，再逐章确认 spec 内容。两部分一次性完成。"

→ docloom-brainstorm 返回自然语言摘要
→ 从摘要提取两部分：
    - **注册参数**：doc_type + type_desc + spec_path + output_dir + feedback_dir + optional upstream_type
    - **spec 内容**：按 spec-doc 结构的各章决策
→ 碰撞检查：提取的 doc_type 在已有类型列表中 → 报错「{doc_type} 已注册」并列出已有类型，终止
→ 注册参数 → 调 [docloom-register][register-skill]（doc_type + type_desc + spec_path + output_dir + feedback_dir + optional upstream_type）
→ spec 内容 → 按 spec-doc 结构组装 spec 正文
→ spec_path 已存在（register 成功但 spec 文件已残留）→ 报错「spec 已存在，改用 mode=edit」
→ 组装 frontmatter（`type: spec-doc`）+ 正文 → 落盘 spec_path
→ commit `docs(spec): create {doc_type}.spec.md`

**mode=edit：**

→ idea 缺失 → 报错「idea 为必填参数」，终止
→ spec_path 缺失 → 报错「spec_path 为必填参数」，终止
→ doc_type 缺失 → 报错「doc_type 为必填参数」，终止
→ 确认 spec_path 存在（不存在 → 报错「spec 不存在，改用 mode=create」）
→ 加载 [spec-doc.spec.md][spec-doc-ref] + [base.spec.md][base-spec-ref] + 现有 spec_path 内容
    - 任一缺失 → 报错列出缺失文件，终止
→ 调 [docloom-brainstorm][brainstorm-skill]，传入场景描述：

"用户需要修改 {doc_type} 的文档编写规范（spec）。
 当前 spec 摘要：{章节结构和规则要点}。
 修改意见：{idea}。
 请与用户逐条确认哪些改进应落地到 spec。"

→ docloom-brainstorm 返回自然语言摘要——从「用户确认方案」中提取确认的改进项，应用到 spec
→ 应用修改 → 落盘 spec_path
→ commit `docs(spec): update {doc_type}.spec.md`

## 输出规则

所有文件和目录引用使用 IDE 可点击格式：

- 文件：`[filename](workspace相对路径)`
- 特定行：`[filename:42](workspace相对路径#L42)`
- 目录：`[dirname/](workspace相对路径)`

流程中涉及的文件引用示范：
- spec 落盘 → `[docs/loom/specs/{doc_type}.spec.md](docs/loom/specs/{doc_type}.spec.md)`
- config.yaml → `[config.yaml](docs/loom/config.yaml)`

## 验证

```bash
grep -q "^## 目标$" SKILL.md && grep -q "^## 非目的$" SKILL.md && grep -q "^## 参数$" SKILL.md && grep -q "^## 流程$" SKILL.md && grep -q "^## 验证$" SKILL.md && grep -q "^## 输出规则$" SKILL.md && grep -q "^## 示例$" SKILL.md && grep -q "mode" SKILL.md && grep -q "idea" SKILL.md && grep -q "create" SKILL.md && grep -q "edit" SKILL.md && grep -q "docloom-register" SKILL.md && grep -q "碰撞检查" SKILL.md && grep -q "修改意见" SKILL.md && grep -q "不做注册" SKILL.md && test $(grep -c "caller" SKILL.md) -le 1
```

- [ ] create 模式 idea 缺失 → 报错终止
- [ ] create 模式 config.yaml 碰撞检查覆盖已有类型
- [ ] create 模式调 register 传齐备参数
- [ ] create 模式 spec 落盘 + commit
- [ ] edit 模式 idea 缺失 → 报错终止
- [ ] edit 模式 spec_path 不存在 → 报错

## 示例

> **正例（create）：**
>
> mode=create, idea="我需要一个管理游戏设计文档的类型，包含核心机制和角色设定"
> → idea ✅ → 加载 spec-doc.spec.md + register SKILL.md ✅
> → 查 config.yaml：已有 16 个类型 → 碰撞上下文就绪
> → 构建待推断集合（注册参数 + spec 章节）→ 调 brainstorm 统一会话
>   → 用户确认：doc_type=game-design, type_desc="游戏策划与开发团队的共同设计文档...",
>     路径用约定值，spec 含 7 章 5 规则
> → 从摘要提取注册参数 → 调 register(doc_type=game-design, type_desc=..., ...)
> → register 插 config + commit ✅
> → 组装 spec → 落盘 docs/loom/specs/game-design.spec.md → commit。

> **正例（edit）：**
>
> mode=edit, idea="skill spec 当前缺少章节顺序检查规则，需要追加，严重度=严重",
> doc_type=skill, spec_path=docs/loom/specs/skill.spec.md
> → idea ✅ → spec_path 存在 ✅
> → 加载 spec-doc + base + 现有 skill.spec.md ✅
> → brainstorm → 用户确认追加章节顺序检查规则
> → 组装新规则 → 应用到 spec → 落盘 → commit。

> **反例（create idea 缺失）：**
>
> mode=create
> → idea 缺失 → 报错「idea 为必填参数」，终止。

> **反例（edit idea 缺失）：**
>
> mode=edit, doc_type=skill, spec_path=docs/loom/specs/skill.spec.md
> → idea 缺失 → 报错「idea 为必填参数」，终止。

[spec-doc-ref]: ../docloom/references/spec-doc.spec.md
[base-spec-ref]: ../docloom/references/base.spec.md
[docloom-config]: ../../docs/loom/config.yaml
[register-skill]: ../docloom-register/SKILL.md
[brainstorm-skill]: ../docloom-brainstorm/SKILL.md
