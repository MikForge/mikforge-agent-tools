# docloom-review-auto-fix

## 目标

Agent-to-agent 自动修复器——接收 note_path，读取 feedback_note 获取被审文档路径 + entry 列表，逐条未处理 entry 思考 2-3 个修复方案，选最优解执行修复并回填。无法确定的标记阻塞。

## 非目的

不调 brainstorm、不交互——不确定就标记阻塞，不由用户决策。只修复 entry 中明确描述的问题——禁止扩大范围。

## 参数

- **`note_path`** — string，必填。feedback_note 文件相对路径。

## 收集参数

无——被审文档路径和 entry 列表从 feedback_note 读取。

## 流程

确认 note_path 存在且可读（缺失 → 报错终止）
→ 读 feedback_note → 获取被审文档路径 + 全部 entry
→ 过滤 status="未处理" 的 entry
    - 无未处理 entry → "所有 entry 已处理" → 正常退出
→ 逐 entry 修复：
    - 思考 2-3 个修复方案，选最优解
    - 可确定 → 执行修复 → status=已修复 + fix_summary 回填
    - 无法确定 → status=阻塞 + block_reason 回填
    ——block_reason 必须写明原因（如"无法定位"、"约束不明确"、"修复涉及多文件"）
→ 落盘（被审文档 + 回填后的 feedback_note）

## 验证

```bash
grep -q "## 目标" review-auto-fix.md && grep -q "## 非目的" review-auto-fix.md && grep -q "## 参数" review-auto-fix.md && grep -q "## 流程" review-auto-fix.md
```

- [ ] 修复后验证文档内容与 entry 描述一致
- [ ] 验证 feedback_note 中被处理的 entry status 已更新
- [ ] 阻塞 entry 的 block_reason 非空

## 示例

> **正例：**
>
> note_path=docs/loom/feedback/design/design-20260607T000000-feedback-note.md
> → 读 feedback_note → 被审文档 feature.md，3 条 entry（全部未处理）
> → entry 1：2 方案（补充章节 / 合并到相邻章节）→ 选 A → 修复 + status=已修复
> → entry 2：2 方案（添加示例 / 引用外部文档）→ 选 A → 修复 + status=已修复
> → entry 3：2 方案均不确定 → status=阻塞，block_reason="无法确定最佳方案，需人工判断"
> → 落盘。结果：2 已修复、1 阻塞。

> **反例：**
>
> note_path=docs/loom/feedback/design/design-20260607T000000-feedback-note.md
> → 读 feedback_note → 3 条未处理 entry
> → entry 1 修复后顺手改了相邻章节的措辞和段落结构。
>
> 只修复 entry 中明确描述的问题——禁止扩大范围。entry 未提到的内容不应修改，否则引入未预期的副作用，后续 reviewer 也无法追溯到对应的 feedback entry。
