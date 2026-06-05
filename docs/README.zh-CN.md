# MikForge Agent Tools

MikForge 的 AI Agent 插件商店。

[English →][en-docs] · [日本語 →][ja-docs]

---

## Claude Code

### 添加源（仅一次）

```bash
claude plugin marketplace add mikforge github:MikForge/mikforge-agent-tools
```

### 全局安装

```bash
claude plugin install <name>@mikforge --scope user
```

所有项目可用。

### 安装到当前项目（团队共享）

```bash
claude plugin install <name>@mikforge --scope project
```

写入 `.claude/settings.json`，可随 git 提交给团队成员。

### 安装到当前项目（仅自己）

```bash
claude plugin install <name>@mikforge --scope local
```

写入 `.claude/settings.local.json`（gitignore 忽略），不影响他人。

### 管理

```bash
claude plugin list                          # 查看已安装
claude plugin update <name>@mikforge       # 更新
claude plugin uninstall <name>@mikforge    # 卸载
```

---

## Codex

### 添加源（仅一次）

```bash
codex plugin marketplace add https://github.com/MikForge/mikforge-agent-tools.git
```

### 全局安装

```bash
codex plugin install <name> --source mikforge-agent-tools
```

Codex 插件默认全局安装。

### 项目级启用/禁用

通过 `.codex/config.yaml` 控制：

```yaml
plugins:
  <name>: true
```

### 管理

```bash
codex plugin list                            # 查看已安装
codex plugin update <name>                  # 更新
codex plugin uninstall <name>               # 卸载
```

[en-docs]: ../README.md
[ja-docs]: README.ja.md
