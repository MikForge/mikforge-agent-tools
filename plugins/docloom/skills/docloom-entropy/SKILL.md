---
name: docloom-entropy
description: Use when analyzing feedback_note files to identify document-quality patterns and generate data-driven spec improvement drafts.
metadata:
  version: "3.0"
---

# docloom-entropy

## 目标

扫描 `feedback_dir` 下 feedback_note 文件，按多维度分析违规模式，产出数据驱动的 spec 改进建议草稿供用户审批。

## 适用判断

需要从历史修复数据中发现文档质量模式并改进 spec 时使用本 skill：
- 分析某文档类型的常见违规 → `doc-type=<type>`
- 生成 spec 改进建议 → 审批后调 `docloom-build-spec`

如果不属于以上场景，跳过本 skill。

## 前置条件

- `docs/loom/config.yaml` 含目标 `doc-type`
- `../docloom/references/entry-schema.md` 可访问（Entry 字段定义）
- 目标类型在 `docs/loom/feedback/<type>/` 下有历史 feedback_note 文件
- `../docloom/references/analysis-dimensions.md` 可访问（维度定义）

## 执行步骤

### 声明参数

- **`doc-type`** — string，必填。文档类型，必须在 config.yaml `document_types` 中存在
- **`context`** — string，可选。分析时间范围或关注的特定维度

### 阶段一：配置加载与输入验证

1. 加载 `docs/loom/config.yaml` → 验证 doc-type 存在
2. 读取 `document_types.<doc-type>.feedback_dir`
3. 验证 `../docloom/references/entry-schema.md` 可访问

### 阶段二：数据采集

**首先判定环境：** 执行 `git rev-parse --git-dir 2>/dev/null`

#### git 模式（git 可用）

- 同旧版逻辑——扫描 `git log --grep=[LOOM-FIX]`，checkpoint 用 commit hash（40 字符）
- 已处理 commit 列表从 `docs/loom/entropy/checkpoints/<type>/checkpoint.md` 读取
- 差集 = 未处理 commit → 逐 commit 提取 feedback_note 路径 → 进入阶段三

#### file 模式（git 不可用）

**checkpoint.md 格式：**
- 每行一个 feedback_note 文件名（如 `api-doc-20260607T000000-feedback-note.md`）
- 首行 `# <type> checkpoint` 注释标明类型
- 写入方式：`echo "<filename>" >> docs/loom/entropy/checkpoints/<type>/checkpoint.md`

1. 扫描 `feedback_dir` 下所有 `*-feedback-note.md` 文件 → 按文件名排序
2. 读取 checkpoint（如存在）→ 获取已分析文件名列表
3. 差集得到未分析文件列表
4. 列表为空 → "无新数据，分析跳过" 正常退出
5. 分析完成后回填 checkpoint：追加已分析文件名

### 阶段三：Entry 解析与维度分析

1. 逐条读取每个未处理 feedback-note 的所有 Entry（字段以 entry-schema 为准）
2. 按 8 个维度分析（详见 `../docloom/references/analysis-dimensions.md`）：
   - 违规频率统计 / 修复模式 / 修复类型分布 / 跨文档对比 / 趋势 / 阻塞项 / 规范变更追踪 / 优化优先级
3. 覆盖率自检 → entry 覆盖率 = 100%（否则标记"分析不完整"）

### 阶段四：产出生成与审批

1. 生成改进建议草稿 → 落盘 `docs/loom/entropy/drafts/<type>/<timestamp>-entropy-analysis.草稿.md`
2. 回填 checkpoint（记录已处理 commit hash）
3. 呈现草稿给用户审批
4. 批准 → 移至 `docs/loom/entropy/analysis/<type>/`，去掉 `.草稿` 后缀
5. 修改要求 → 修改草稿后重新审批

### 审批后：衔接 build-spec

草稿审批通过后，询问用户是否将改进应用到 spec：

> "是否将改进建议应用到 spec？"

是 → 调 `docloom-build-spec`（mode=edit, doc_type=<type>, context=<改进建议>）
否 → 结束

### 硬约束

- 不得依赖预聚合数据替代逐条解析——每条 feedback-note 逐个 Entry 读
- 不得按数据分布选择性抽样——未处理 = 全量
- feedback-note 不存在或解析失败 → 记录警告（文件路径 + 失败原因），不静默跳过
- 覆盖率 < 100% → 输出中显式标记"分析不完整"
- 执行开始时读取 entry-schema，覆盖率报告中声明解析字段来源

## 示例

### 场景 A：首次分析 — git 模式

参数：doc-type=api-doc（git 可用）

1. config.yaml → api-doc 存在 ✅
2. `git rev-parse --git-dir` → git 模式
3. 无 checkpoint → 扫描所有 `[LOOM-FIX]` commit → 12 个 commit → 15 个 feedback_note
4. 逐条解析 87 条 entry → 8 维度分析
5. 覆盖率 100% → 生成草稿 → 回填 commit hash → 呈现

### 场景 B：file 模式首次分析

参数：doc-type=design（git 不可用）

1. `git rev-parse --git-dir` 失败 → file 模式
2. 扫描 feedback_dir → 15 个 feedback_note 文件
3. 无 checkpoint → 全量未分析
4. 逐条解析 → 8 维度分析 → 生成草稿 → 回填文件名

### 场景 C：增量分析（有 checkpoint）

参数：doc-type=plan

1. checkpoint 已处理 20 条
2. 新发现 5 个 → 仅分析增量
3. 生成增量草稿

### 场景 D：无新数据（边界）

1. checkpoint 覆盖全部 → 未处理 0 个
2. "无新数据，分析跳过" → 正常退出

## 验证

- 验证草稿文件存在于 `drafts/<type>/`
- 验证覆盖率 = 100%（输出的覆盖率摘要）
- 审批后验证文件从 `drafts/` 移至 `analysis/`

## FAQ

**Q: 为什么必须逐条解析不能抽样？**

A: 抽样会掩盖低频但高严重度的违规模式。一条 block 级规则被触发 1 次和 20 次——在抽样中可能被遗漏，但它对规范改进的价值很高。全量解析 + 覆盖率 100% 确保无遗漏。

**Q: 草稿审批后怎么应用？**

A: 询问用户是否调 docloom-build-spec 将改进落地到 spec。如果用户同意，build-spec 会按改进建议编辑 spec（edit 模式）。
