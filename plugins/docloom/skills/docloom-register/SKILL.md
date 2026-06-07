---
name: docloom-register
description: Use when registering, adding, or removing document types in the docloom pipeline config.yaml.
metadata:
  version: "2.0"
---

# docloom-register

## 目标

docloom 流水线文档类型注册入口——管理 `docs/loom/config.yaml`（运行时实例），支持 init 初始化、add 新增、remove 移除三种模式。不生成 spec 或 review 文件。

## 适用判断

需要管理 docloom 流水线的文档类型配置时使用本 skill：
- 项目首次接入 docloom → `mode=init`
- 新增文档类型 → `mode=add`
- 移除文档类型 → `mode=remove`

如果不属于以上场景，跳过本 skill。

## 前置条件

- `docs/loom/config.yaml` 运行时配置文件（init 时自动创建，add/remove 时需已存在）
- `references/config-template.yaml` 模板文件（随 skill 分发，仅 init 时读取）

## 执行步骤

### 声明参数

- **`mode`** — string，必填。`init` / `add` / `remove`
- **`doc_type`** — string，条件。`add`/`remove` 时必填。文档类型键名（小写、连字符，如 `api-doc`）
- **`name`** — string，条件。`add` 时必填。中文显示名称
- **`output_dir`** — string，条件。`add` 时必填。文档输出目录（相对项目根目录，不以 `/` 结尾时自动追加）
- **`upstream_type`** — string，可选。上游文档类型键名（必须在 `document_types` 中存在）

### mode=init — 首次初始化

1. 检查 `docs/loom/config.yaml` 是否存在
2. **存在则幂等跳过**——输出"config.yaml 已存在，无需重复初始化"。禁止覆盖已有配置——即使模板更新也不覆盖，因为运行时 config 可能已被用户修改，覆盖会丢失数据
3. 不存在则：
   - 复制 `references/config-template.yaml` → `docs/loom/config.yaml`
   - 创建目录骨架：
     ```bash
     mkdir -p docs/loom/{base,specs,review,feedback,entropy/{analysis,checkpoints,drafts}}
     ```
4. commit: `chore(docloom): init docs/loom/ config and directory skeleton`

### mode=add — 注册新文档类型

1. 加载 `docs/loom/config.yaml`——如不存在提示先执行 `mode=init`
2. 验证 `doc_type` 在 `document_types` 中**不存在**——已存在则报错退出，列出冲突类型名
3. 验证 `upstream_type` 在 `document_types` 中存在（若提供）——不存在则报错列出可用类型
4. **按约定生成路径**（不读任何文件，纯命名约定）：
   - `spec`: `docs/loom/specs/<doc_type>.spec.md`
   - `review`: `docs/loom/review/<doc_type>.review.md`
   - `feedback_dir`: `docs/loom/feedback/<doc_type>/`
5. 按字母序在 `document_types` 中定位插入位置
6. 使用 **Edit 工具**插入新条目——保留注释、2-space 缩进，**禁止使用任何 YAML 库**（Python yaml/Ruby YAML 等）读写 config.yaml，因为 YAML 库会丢弃注释
7. 插入后 YAML 语法验证：
   ```bash
   ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"
   ```
   验证失败不 commit
8. commit: `docs(docloom): add <doc_type> document type`

### mode=remove — 移除文档类型

1. 加载 `docs/loom/config.yaml`
2. 验证 `doc_type` 在 `document_types` 中**存在**——不存在则报错列出可用类型
3. 使用 **Edit 工具**删除对应条目（保留其余条目和注释）
4. **不删除已生成的 spec/review/feedback 文件**——这些是用户数据，register 不负责删除
5. 删除后 YAML 语法验证：
   ```bash
   ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"
   ```
   验证失败不 commit
6. commit: `docs(docloom): remove <doc_type> document type`

### 通用约束

1. **config.yaml 所有编辑操作必须使用 Edit 工具**——精确字符串替换，保留所有注释和格式
2. **禁止使用任何 YAML 库**（Python yaml、Ruby YAML、ruamel.yaml 等）读写 config.yaml——YAML 库会无条件丢弃注释
3. **每次 config.yaml 编辑后必须执行 YAML 语法验证**——即使改动只有几行、即使肉眼确认无误。`ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')"` 是唯一接受的验证方式
4. **验证失败不 commit**——先修正 YAML 格式，验证通过后再 commit

## 示例

### 场景 A：首次初始化（正常，mode=init）

```bash
$ ls docs/loom/config.yaml
# 文件不存在
```

执行 init：
- 检测 config.yaml 不存在
- 复制 `references/config-template.yaml` → `docs/loom/config.yaml`
- 创建 `docs/loom/{base,specs,review,feedback,entropy/}` 目录
- commit

```bash
$ ls docs/loom/config.yaml
docs/loom/config.yaml  # 10 种文档类型
```

### 场景 B：重复初始化（边界，mode=init）

```bash
$ ls docs/loom/config.yaml
docs/loom/config.yaml  # 已存在，含用户修改
```

执行 init：
- 检测 config.yaml 已存在 → 跳过（幂等）
- 输出"config.yaml 已存在，无需重复初始化"
- 不覆盖、不 diff、不修改

### 场景 C：注册新类型（正常，mode=add）

参数：doc_type=game-prd, name="游戏PRD", output_dir="docs/00-project-knowledge-base/03-assets-layer/01-prd-docs/game/"

1. 加载 config.yaml → game-prd 不存在 ✅
2. 生成路径：spec=docs/loom/specs/game-prd.spec.md, review=docs/loom/review/game-prd.review.md, feedback_dir=docs/loom/feedback/game-prd/
3. 按字母序在 `game-` 位置 Edit 插入
4. `ruby -ryaml` 验证 → PASS
5. commit

### 场景 D：移除类型（正常，mode=remove）

参数：doc_type=manual

1. 加载 config.yaml → manual 存在 ✅
2. Edit 删除 `manual:` 条目块（保留其余类型）
3. `ruby -ryaml` 验证 → PASS
4. commit
5. `docs/loom/specs/manual.spec.md` 等文件**未被删除**——原样保留

### 场景 E：注册已存在类型（边界，mode=add）

参数：doc_type=design

- 加载 config.yaml → design **已存在**
- 报错："design 已存在于 config.yaml，不可重复注册"

## 验证

- init：验证 `docs/loom/config.yaml` 存在且 YAML 语法合法——`ls docs/loom/config.yaml && ruby -ryaml -e "YAML.load_file('docs/loom/config.yaml')" && echo 'init OK'`
- add：验证新 `doc_type` 出现在 config.yaml 的 `document_types` 中且 YAML 语法合法
- remove：验证 `doc_type` 已从 config.yaml 的 `document_types` 中移除且 YAML 语法合法

## FAQ

**Q: 为什么不能用 Python yaml.dump 编辑 config.yaml？**

A: Python yaml 库的 safe_load 不保留注释，dump 会丢弃所有 `# 注释`。config.yaml 中的注释（字段说明、使用提示）是配置文档的一部分，丢失后会增加后续维护成本。Edit 工具做精确字符串替换，注释不丢失。

**Q: init 时模板更新了怎么办？**

A: init 只在 config.yaml 不存在时复制模板。模板更新后，已初始化的项目需要手动更新——避免自动覆盖导致用户修改丢失。可在 release notes 中说明模板变更。

**Q: remove 后 spec/review 文件还在怎么办？**

A: 这是预期行为。register 只管理 config.yaml 注册表，不管理数据文件。如需清理文件，请在 remove 后手动删除对应的 spec/review/feedback 文件。
