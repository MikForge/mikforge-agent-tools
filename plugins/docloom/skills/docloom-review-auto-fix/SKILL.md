---
name: docloom-review-auto-fix
description: Use when automatically fixing documents from feedback_note entries without user interaction in the docloom pipeline.
user-invocable: false
metadata:
  version: "1.0"
---

# docloom-review-auto-fix

## 目标

Agent-to-agent 自动修复器——接收 `note_path`，读取 feedback_note 获取被审文档路径 + entry 列表，加载 spec + `../docloom/references/base.spec.md` 获取约束，逐 entry 按 location 定位自动修复。修不了标记阻塞。不调 brainstorm、不交互。commit `[LOOM-FIX]`。

## 适用判断

被 `docloom-author` 内部调用——author 完成审查后自动调本 skill 执行修复。用户不直接触发。

## 前置条件

- `docs/loom/config.yaml` 存在且含 `document_types` 定义
- `../docloom/references/base.spec.md` 可访问
- `note_path` 指向的 feedback_note 文件存在且可读

## 执行步骤

### 声明参数

- **`note_path`** — string，必填。feedback_note 文件相对路径

### 流程

1. 接收 `note_path`
2. 根据 `note_path` 读取 feedback_note，获取 Header `被审文档` 字段值 + 全部 entry
3. 根据 `被审文档` 路径读取文档 frontmatter，获取 `doc_type`
4. 根据 `doc_type` 查询 `docs/loom/config.yaml`，获取 `spec` 路径
5. 根据 `spec` 路径加载 `<type>.spec.md` + `../docloom/references/base.spec.md`，获取约束定义
6. 过滤 `status="未处理"` 的 entry
7. 逐 entry 根据 `location` 定位文档位置，按 spec 约束 + `description` 自动修复
   - 修复成功 → `status=已修复` + `fix_summary`
   - 无法修复 → `status=阻塞` + `block_reason`
8. 被审文档 + 回填后 feedback_note 落盘
9. commit `[LOOM-FIX]`

### 约束

- **不调 brainstorm**——不确定就标记阻塞，不交互
- **只修复 entry 中明确描述的问题**——禁止扩大范围
- `block_reason` 必须写明原因（如"无法定位"、"约束不明确"、"修复涉及多文件"）

## 示例

### 场景 A：全部修复（正常）

参数：note_path=docs/loom/feedback/design/design-20260607T000000-feedback-note.md

1. 读 feedback_note → 被审文档=docs/design-docs/feature.md，3 条 entry（全部未处理）
2. 加载 design.spec.md + base.spec.md
3. 逐条修复：3 条全部修复成功 → 全部 status=已修复
4. 回填 + 文档落盘 + commit

### 场景 B：部分阻塞（边界）

同一 feedback_note，3 条 entry：
- entry 1：location 明确 → 修复成功
- entry 2：location 明确 → 修复成功
- entry 3：约束不明确 → status=阻塞，block_reason="无法确定最佳方案，需人工判断"

结果：2 已修复、1 阻塞，反馈给 author。

### 场景 C：全部已修复（边界）

feedback_note 全部 entry status ≠ "未处理"

- 无待修复项 → "所有 entry 已处理" → 正常退出

## 验证

- 修复后验证文档内容与 entry 描述一致
- 验证 feedback_note 中被处理的 entry status 已更新
- commit 含 `[LOOM-FIX]` 前缀
- 阻塞 entry 的 `block_reason` 非空

## FAQ

**Q: 为什么修不了就阻塞而不调 brainstorm 交互？**

A: review-auto-fix 是 agent-to-agent 链路——author 自动化流水线的一环。插入交互会中断自动化流程。阻塞的 entry 标记后，用户可手动调 fix 处理。

**Q: 和 fix 的区别？**

A: review-auto-fix 是自动的（author 内调，不交互），fix 是手动的（用户调，brainstorm 交互确认）。两者互补——能自动修的自动修，修不了的标记阻塞等人工介入。
