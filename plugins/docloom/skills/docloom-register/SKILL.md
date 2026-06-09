---
name: docloom-register
description: Internal utility — registers a document type entry in config.yaml. Called by docloom-spec-writer.
metadata:
  version: "3.0"
---

# docloom-register

## 目标

纯工具 skill——接收参数，按字母序在 config.yaml 中插入文档类型条目，验证 YAML 语法，提交 commit。不做交互，不调其他 skill。

## 非目的

不被用户直接触发——仅供 docloom-spec-writer 调用。不推断 doc_type、不收集用户意图、不编排流程。

## 参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `doc_type` | string，必填 | 文档类型标识符 |
| `type_desc` | string，必填 | 2-3 句定位描述，覆盖用途/目标读者/典型内容 |
| `spec_path` | string，必填 | spec 文件路径 |
| `output_dir` | string，必填 | 产出目录 |
| `feedback_dir` | string，必填 | 反馈目录 |
| `upstream_type` | string，可选 | 上游关联类型 |

## 流程

接收参数
→ 齐备校验：doc_type、type_desc、spec_path、output_dir、feedback_dir 全部非空
    - 任一缺失 → 报错列出缺失字段，终止
→ 加载 [config.yaml][docloom-config] → edit 工具按字母序在 document_types 中插入新条目：
```yaml
  {doc_type}:
    spec: {spec_path}
    output_dir: {output_dir}
    feedback_dir: {feedback_dir}
    type-desc: {type_desc}
```
    若 upstream_type 存在，追加 `upstream_type: {upstream_type}` 行（紧接 type-desc 之后）
→ 验证 YAML 语法：`ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"`
    - 验证失败 → 报错「YAML 语法错误」，不 commit，终止
→ commit `docs(loom): register {doc_type}`

## 验证

```bash
grep -q "^## 目标$" SKILL.md && grep -q "^## 非目的$" SKILL.md && grep -q "^## 参数$" SKILL.md && grep -q "^## 流程$" SKILL.md && grep -q "doc_type" SKILL.md && grep -q "type_desc" SKILL.md && grep -q "齐备校验" SKILL.md && grep -q "Internal utility" SKILL.md
```

- [ ] 参数齐备校验触发正确（缺任一必填 → 报错）
- [ ] 条目按字母序插入正确位置
- [ ] YAML 语法有效：`ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"`
- [ ] upstream_type 为可选，不传时跳过

## 示例

> **正例：**
>
> doc_type=game-design, type_desc="游戏策划与开发团队的共同设计文档，涵盖核心机制与角色设定。",
> spec_path=docs/loom/specs/game-design.spec.md, output_dir=docs/docloom/game-design/,
> feedback_dir=docs/loom/feedback/game-design/
> → 齐备校验 ✅ → 按字母序在 config.yaml document_types 插入新条目
> → ruby YAML 验证 ✅ → commit `docs(loom): register game-design`。

> **正例（含 upstream_type）：**
>
> doc_type=event-budget, type_desc="活动方案预算表。...", ..., upstream_type=event-planning
> → 齐备校验 ✅ → 插入条目含 upstream_type 行 → YAML 验证 ✅ → commit。

> **反例：**
>
> doc_type=game-design, type_desc=""（空 type_desc）
> → 齐备校验：type_desc 为空 → 报错「type_desc 缺失」，终止。

[docloom-config]: ../../docs/loom/config.yaml
