# docloom 插件迁移设计

将 `docloom-plugin` 从独立仓库迁移到 `mikforge-agent-tools` 仓库内，通过 `./plugins/docloom` 相对路径引用，实现单仓库维护。

## 当前状态

```
独立仓库: MikForge/docloom-plugin          (插件本体)
         MikForge/mikforge-agent-tools     (marketplace 目录)
```

两个 marketplace 文件都指向外部源：

| marketplace 文件 | 当前 source | 类型 |
|---|---|---|
| `.claude-plugin/marketplace.json` | `{"source":"github", "repo":"MikForge/docloom-plugin"}` | GitHub 远程 |
| `.agents/plugins/marketplace.json` | `{"source":"url", "url":"https://github.com/MikForge/docloom-plugin.git", "ref":"main"}` | Git URL 远程 |

## 目标状态

```
mikforge-agent-tools/
├── .claude-plugin/
│   └── marketplace.json          ← source: "./plugins/docloom"
├── .agents/
│   └── plugins/
│       └── marketplace.json      ← source: { "source": "local", "path": "./plugins/docloom" }
├── plugins/
│   └── docloom/                  ← 插件本体（新位置）
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── .codex-plugin/
│       │   └── plugin.json
│       ├── hooks/
│       │   └── hooks.json
│       ├── skills/
│       │   ├── docloom/
│       │   ├── docloom-author/
│       │   ├── docloom-brainstorm/
│       │   ├── docloom-build-spec/
│       │   ├── docloom-entropy/
│       │   ├── docloom-feedback/
│       │   ├── docloom-fix/
│       │   ├── docloom-init/
│       │   ├── docloom-register/
│       │   ├── docloom-review-auto-fix/
│       │   └── docloom-reviewer/
│       ├── assets/
│       │   └── .gitkeep
│       ├── .mcp.json
│       ├── integrity.json
│       └── README.md
```

所有 marketplace source 都指向本地 `./plugins/docloom`，只需维护 `mikforge-agent-tools` 一个仓库。

## 变更清单

### 1. marketplace 文件变更

#### 1.1 `.claude-plugin/marketplace.json`

```diff
{
  "name": "mikforge",
  "description": "MikForge Tools",
  "owner": { "name": "MikForge" },
  "plugins": [
    {
      "name": "docloom",
-     "source": {
-       "source": "github",
-       "repo": "MikForge/docloom-plugin"
-     },
+     "source": "./plugins/docloom",
      "description": "...",
      "author": { "name": "MikForge" },
      "category": "development"
    }
  ]
}
```

**说明**：Claude Code 的相对路径 source 直接写字符串 `"./plugins/docloom"`（不是对象）。路径从 marketplace root（repo 根目录）解析。

#### 1.2 `.agents/plugins/marketplace.json`

```diff
{
  "name": "mikforge",
  "interface": { "displayName": "MikForge Tools" },
  "plugins": [
    {
      "name": "docloom",
      "source": {
-       "source": "url",
-       "url": "https://github.com/MikForge/docloom-plugin.git",
-       "ref": "main"
+       "source": "local",
+       "path": "./plugins/docloom"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Development & Workflow"
    }
  ]
}
```

**说明**：Codex 的相对路径 source 是对象 `{"source": "local", "path": "./plugins/docloom"}`。路径同样从 marketplace root 解析。

### 2. plugin.json manifest 更新

#### 2.1 `.claude-plugin/plugin.json`

```diff
{
  "name": "docloom",
- "version": "1.0.7",
  "description": "...",
  "author": { "name": "MikForge", "url": "https://github.com/MikForge" },
- "homepage": "https://github.com/MikForge/docloom-plugin",
- "repository": "https://github.com/MikForge/docloom-plugin",
+ "homepage": "https://github.com/MikForge/mikforge-agent-tools",
+ "repository": "https://github.com/MikForge/mikforge-agent-tools",
  "license": "MIT",
  "keywords": ["documentation", "review", "spec", "pipeline"],
  "skills": "./skills/"
}
```

变更：

- **移除 `version` 字段** → 改用 git commit SHA 自动版本（见第 4 节）
- **更新 `homepage` / `repository`** → 指向 monorepo

#### 2.2 `.codex-plugin/plugin.json`

```diff
{
  "name": "docloom",
- "version": "1.0.7",
  "description": "...",
  "author": { "name": "MikForge" },
  "skills": "./skills/",
  "interface": {
    "displayName": "Docloom",
    ...
-   "websiteURL": "https://github.com/MikForge/docloom-plugin",
+   "websiteURL": "https://github.com/MikForge/mikforge-agent-tools",
    ...
  }
}
```

变更同上：移除 `version`，更新 `interface.websiteURL`。

### 3. 排除的文件（不迁移）

| 文件 | 原因 |
|---|---|
| `.git/` | docloom-plugin 的 git 历史独立，不需要合并 |
| `sync.yaml` | 本地开发配置，包含绝对路径 `/Users/michael/...`，迁移后技能直接在 `skills/` 下，不再需要外部同步 |
| `sync.yaml.bak` | sync.yaml 的备份 |
| `sync-skills.sh` | 同步脚本，迁移后技能直接存在于 `skills/`，不再需要 |
| `sync-and-version.sh` | sync + version 组合调用，均不再需要 |
| `version.sh` | 本地工具，迁移后改用 git commit SHA 做版本（见第 4 节） |
| `skills/docloom/references/references` | **递归软链接**（指向自身），rsync/cp 会导致无限循环 |

### 4. 版本管理：改用 git commit SHA

不再使用 `version.sh`（MD5 checksum → 自增 patch → 写 manifest）。

迁移后策略：

- 两个 `plugin.json` 中的 **`version` 字段移除**（不显式声明版本号）
- Claude Code 和 Codex 在没有 `version` 字段时，**自动以 git commit SHA 作为版本**
- 每次 commit 自动成为新版本，用户 `/plugin update` 时拉取最新的 commit
- `integrity.json` 保留作为目录完整性快照（只读参考，不再驱动版本变更）
- 如果需要 release channel（stable/latest），通过 git tag + marketplace `ref` 字段区分

### 5. 递归软链接处理

`skills/docloom/references/references` 是一个指向 `/Users/michael/Desktop/gitfiles/ai_tools_in_work/.agents/skills/docloom/references` 的软链接，该目标路径又包含同名的 `references` 软链接，形成递归。

处理方式：`rsync --exclude 'skills/docloom/references/references'` 排除此链接。其他 reference 文件（`.md`、`.yaml`）正常迁移。

### 6. 旧仓库处理

迁移完成后：

- `MikForge/docloom-plugin` 仓库在 GitHub 上 Archive
- README 添加迁移提示指向 `MikForge/mikforge-agent-tools`
- 已安装 docloom 的用户通过 `/plugin marketplace update` 拉取新的 marketplace.json，下次安装/更新会从 monorepo 内获取

## 迁移步骤

### Step 1: 复制插件内容

```bash
cd /Users/michael/Desktop/gitfiles/mikforge-agent-tools

# 创建目标目录
mkdir -p plugins/docloom

# 用 rsync 复制，排除不需要的文件
rsync -av \
  --exclude '.git' \
  --exclude '*.sh' \
  --exclude 'sync.yaml' \
  --exclude 'sync.yaml.bak' \
  --exclude 'skills/docloom/references/references' \
  /Users/michael/Desktop/gitfiles/docloom-plugin/ \
  plugins/docloom/
```

### Step 2: 更新 plugin.json manifest

编辑 `plugins/docloom/.claude-plugin/plugin.json`：
- 移除 `version` 字段
- `homepage` → `"https://github.com/MikForge/mikforge-agent-tools"`
- `repository` → `"https://github.com/MikForge/mikforge-agent-tools"`

编辑 `plugins/docloom/.codex-plugin/plugin.json`：
- 移除 `version` 字段
- `interface.websiteURL` → `"https://github.com/MikForge/mikforge-agent-tools"`

### Step 3: 更新 marketplace 文件

编辑 `.claude-plugin/marketplace.json`：
- `source` → `"./plugins/docloom"`

编辑 `.agents/plugins/marketplace.json`：
- `source` → `{"source": "local", "path": "./plugins/docloom"}`

### Step 4: 验证

```bash
# 校验 marketplace JSON 语法
claude plugin validate .

# 校验插件结构
claude plugin validate plugins/docloom

# 本地安装测试
claude plugin marketplace add .
claude plugin install docloom@mikforge
```

### Step 5: 提交

```bash
git add plugins/docloom/ .claude-plugin/marketplace.json .agents/plugins/marketplace.json
git commit -m "migrate: move docloom plugin into monorepo, use local relative paths"
git push
```

### Step 6: 归档旧仓库

在 `MikForge/docloom-plugin` 仓库：
- README 顶部添加：`> ⚠️ This plugin has moved to [MikForge/mikforge-agent-tools](https://github.com/MikForge/mikforge-agent-tools).`
- 在 GitHub Settings → Archive repository

## 两个平台的 source 格式速查

| 平台 | marketplace 位置 | 相对路径格式 |
|---|---|---|
| Claude Code | `.claude-plugin/marketplace.json` | `"source": "./plugins/docloom"` (字符串) |
| Codex | `.agents/plugins/marketplace.json` | `"source": {"source": "local", "path": "./plugins/docloom"}` (对象) |

两个平台的路径解析规则一致：**从 marketplace root（即 repo 根目录）解析，而非从 `.claude-plugin/` 或 `.agents/plugins/` 目录解析**。

`./plugins/docloom` 在两个平台都解析为 `<repo-root>/plugins/docloom`。

## 注意事项

1. **相对路径只对 Git-based marketplace 生效**。如果用户通过原始 URL 添加 marketplace.json（而非 `owner/repo`），相对路径会失效。当前 marketplace 以 `MikForge/mikforge-agent-tools` GitHub 仓库形式分发，不存在此问题。
2. **路径不能包含 `..`**。两个平台都禁止 `../` 引用 marketplace root 之外的路径。
3. **用户已安装的插件不受影响**。已缓存的插件继续使用旧版本，直到用户执行 `/plugin update` 或重新安装才会拉取新 marketplace 配置。
4. **`version` 移除后版本以 git commit SHA 为准**。如果后续需要显式版本号（如发布到官方 marketplace），可以在 `plugin.json` 中添加回 `version` 字段。
