# 基础规范（Base Spec）

所有文档类型共享的写作约束，author 写入时遵守，reviewer 审查时逐项核对。

---

## 目的

确保所有文档类型在引用链接、措辞精确度、frontmatter 格式上保持一致，下游工具可稳定解析。

## 非目的

不定义类型专属的章节结构或内容规则。

## 必要章节

无（base spec 本身不定义文档章节，各 type spec 自行声明）。

---

### Frontmatter

每份文档头部必须包含 YAML frontmatter，格式为 `---\ntype: <doc_type>\n---`。`type` 为单值字符串，值为合法的文档类型名（如 design、prd、plan）。`---` 分隔线后紧跟正文第一行，中间无空行。

#### Frontmatter 合格示例

```yaml
---
type: design
---
# 设计文档标题
```

#### 不合格示例

```yaml
---
type: [design, prd]
---
```

问题：`type` 为数组而非单值；分隔线后有空行，正文开头不应有空行。

---

### 引用式链接

全文统一使用 `[显示文字][引用ID]` 引用式链接，所有路径定义集中在文末。禁止行内链接、裸 URL、绝对路径、反引号包裹路径、路径定义散落正文各处。文件引用必须使用相对路径。

#### 引用式链接合格示例

```markdown
启动时加载 [config.yaml][docloom-config]，验证配置存在。

[docloom-config]: ../docloom/config.yaml
```

#### 引用式链接不合格示例

```markdown
启动时加载 [config.yaml](https://github.com/xxx/blob/main/config.yaml)。
```

问题：行内链接、绝对路径、路径定义未集中在文末。

---

### 禁止措辞

禁止使用：

- 占位符：TBD / TODO / "后续补充" 等，必须改写为可验证、可执行的具体描述
- 模糊描述："适当处理" / "按需优化" / "灵活配置" 等，必须改写为具体可验证的描述
- 形容词替代指标："高性能" / "高可用" / "易于扩展" 等，必须给出量化标准或判断条件
- 隐含上下文依赖："类似上一任务" / "同上" 等，每条规则必须自包含

#### 禁止措辞合格示例

```markdown
输出格式必须包含 6 个部分：背景、目标、约束、执行规则、验收标准、示例。
```

#### 禁止措辞不合格示例

```markdown
输出时应适当优化格式，尽量简洁。
```

问题："适当"、"尽量" 为模糊措辞，缺少可判定的具体标准。

---

### 声明参数

文档规范中描述输入参数时，使用逐行格式。每个参数独立一行，格式为 `- **`name`** — type，必填/可选。说明。`。无默认值时省略"默认："段。禁止纯自然语言段落式罗列参数。参数条目按逻辑分组排列，同组参数连续排列。

#### 声明参数合格示例

```markdown
- **`type`** — string，必填。文档类型，必须在 config.yaml 的 document_types 中存在。
- **`context`** — string，可选。用户提供的结构化上下文，包含各章节所需信息。
- **`auto_review`** — boolean，可选，默认：true。落盘后是否自动调 reviewer 审查。
```

#### 声明参数不合格示例

```markdown
必传参数有 type（文档类型），可选参数有 context（用户提供的上下文信息）和 auto_review（默认 true）。
```

问题：纯自然语言段落式罗列，每个参数未独立成行，缺少 type 和必填/可选标识。

---

### 正反例

规范文档中的每条规则必须提供合格示例和不合格示例成对出现。每个示例聚焦一个问题点，不合格示例必须标注问题所在。

#### 正反例合格示例

规则：函数命名使用 camelCase。

```javascript
function getUserById(id) { return db.users.find(id); }
```

#### 正反例不合格示例

```javascript
function get_user_by_id(id) { return db.users.find(id); }
```

问题：使用 snake_case 而非 camelCase。

---

### 审查列表

输出前逐项确认。每条按可自动修复性标注严重程度（🔴 error 无法自动修复 / 🟡 warning 可修复但需确认 / 🟢 info 纯机械修复）：

- [ ] 🟡 [warning] 文档含 YAML frontmatter，`type` 字段为非空单值
- [ ] 🟢 [info] `---` 分隔线后紧跟正文，无空行
- [ ] 🟢 [info] 全文使用 `[text][id]` 引用式链接，定义集中在文末
- [ ] 🟢 [info] 无行内链接、裸 URL、绝对路径
- [ ] 🔴 [error] 无 TBD / TODO / "后续补充" 占位符
- [ ] 🟡 [warning] 无模糊措辞和形容词替代指标
- [ ] 🟡 [warning] 无隐含上下文依赖表述
- [ ] 🟢 [info] 参数声明使用逐行格式（`- **`name`** — type，必填/可选。说明。`），无纯自然语言段落式罗列
- [ ] 🟡 [warning] 每条规则有成对的正例/反例
