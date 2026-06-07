# Entry Schema — 数据结构声明

定义 entry 的 9 字段结构、组装规则和校验清单，供 [docloom-reviewer][reviewer]（生成 entry）、[docloom-fix][fix]（解析 entry）、[docloom-entropy][entropy]（分析 entry）共用。

---

## 目的

确保 entry 结构在所有生产者和消费者之间一致，下游可精确解析。Entry 通过 `specid` 关联具体 spec 规则，违规性质由对应规则定义；`spec_source` + `specid` 提供精确定位。

## 非目的

不定义 feedback_note 的 Header 格式、文件命名规则和整体结构（由 [feedback-note.spec.md][fb-spec] 定义）。

---

## 字段定义

每条 entry 描述一个审查发现的问题，包含 9 个字段：

### 核心描述字段

| 字段 | 说明 | 取值范围 |
|------|------|----------|
| `title` | 问题标题 | 一句话概括，不可为空 |
| `severity` | 严重度 | `严重`（阻断性，必须修复）/ `重要`（明显缺陷，修复后可通过）/ `轻微`（不影响通过，记录备改） |
| `location` | 问题定位 | `<章节>:<行号范围>`，如 `问题陈述:3-5` |
| `description` | 具体问题及影响 | 必须可验证，不可模糊 |

### 违规分类字段

| 字段 | 说明 | 取值范围 |
|------|------|----------|
| `spec_source` | 触发域 | `base`、`design`、`plan`、`prd`、`third-party-lib`、`api-doc`、`api-reference-entry`；匹配不到时填 `uncategorized` |
| `specid` | 触发规则编号 | spec 文档内部规则 ID（如 `DSG-001`、`BSG-003`、`PSG-012`）；无法精确匹配到单条规则时填 `uncategorized` |

### 状态追踪字段

| 字段 | 说明 | 取值范围 |
|------|------|------|
| `status` | 处理状态 | `未处理` / `已修复` / `阻塞` |
| `fix_summary` | 修复简述 | 已修复时填写，否则留空 |
| `block_reason` | 阻塞原因 | 阻塞时填写，否则留空 |

## 组装规则

- 每条 entry 只描述一个问题，独立完整
- 新生成 entry 初始状态为"未处理"，`fix_summary` 和 `block_reason` 留空
- `specid` 必填，reviewer 从违规表现反查对应 spec 规则编号填写；无法精确匹配到单条规则时填 `uncategorized`
- 审查后未发现任何问题时 entry 列表为空
- 旧 entry 缺少 `specid` 字段时，消费方填 `uncategorized` 处理，不阻塞解析

---

## 合格示例

```markdown
## Entry 列表

### 描述过于简略
- **severity:** 重要
- **spec_source:** api-reference-entry
- **specid:** ASG-003
- **location:** 描述:12
- **description:** 描述仅一句"Canvas 是核心渲染组件"，缺少功能说明和使用场景。类条目描述需 ≥3 句，覆盖用途、使用场景、关键行为。
- **status:** 未处理
- **fix_summary:** 
- **block_reason:** 

### 缺少导入语句
- **severity:** 严重
- **spec_source:** api-reference-entry
- **specid:** ASG-002
- **location:** 签名/定义:45
- **description:** 「签名/定义」章节缺少 `- **导入**：...` 字段，导入语句为必填项。
- **status:** 未处理
- **fix_summary:** 
- **block_reason:** 
```

## 不合格示例

```markdown
### 文档有问题
- **severity:** 中等
- **location:** 开头
```

问题：`severity` 不在枚举范围；缺少 `spec_source`、`specid`；`location` 无行号范围；缺少 `description`、`status` 等必填字段；描述模糊不可验证。

---

## 审查列表

输出前逐项确认：

- [ ] 🟡 [warning] 每条 entry 含全部 9 个字段
- [ ] 🟢 [info] `severity` 值在严重/重要/轻微 范围内
- [ ] 🟢 [info] `specid` 值非空，匹配不到具体规则时填 `uncategorized`
- [ ] 🟢 [info] `status` 值在未处理/已修复/阻塞 范围内
- [ ] 🟢 [info] 新生成 entry 状态为"未处理"，`fix_summary` 和 `block_reason` 为空
- [ ] 🟢 [info] 每条 entry 只描述一个问题，独立完整

[reviewer]: ../../docloom-reviewer/SKILL.md
[fix]: ../../docloom-fix/SKILL.md
[entropy]: ../../docloom-entropy/SKILL.md
[fb-spec]: feedback-note.spec.md
