# MikForge Agent Tools

AI agent plugin marketplace by MikForge.

[中文 →][cn-docs] · [日本語 →][ja-docs]

---

## Claude Code

### Add marketplace (once)

```bash
claude plugin marketplace add MikForge/mikforge-agent-tools
```

### Install globally

```bash
claude plugin install <name>@mikforge --scope user
```

Available in all projects.

### Install per-project (shared with team)

```bash
claude plugin install <name>@mikforge --scope project
```

Writes to `.claude/settings.json` — commit to share with your team.

### Install per-project (local only)

```bash
claude plugin install <name>@mikforge --scope local
```

Writes to `.claude/settings.local.json` (gitignore'd) — affects only you.

### Browse available plugins

```bash
# List all available plugins from this marketplace
claude plugin list --available --json | jq '.available[] | select(.marketplaceName == "mikforge")'

# List all configured marketplaces
claude plugin marketplace list
```

### Manage

```bash
claude plugin list                                 # List installed
claude plugin install <name>@mikforge             # Install
claude plugin update <name>@mikforge              # Update plugin
claude plugin uninstall <name>@mikforge           # Remove
claude plugin marketplace update mikforge          # Refresh plugin catalog
```

---

## Codex

### Add marketplace (once)

```bash
codex plugin marketplace add https://github.com/MikForge/mikforge-agent-tools.git
```

### Install globally

```bash
codex plugin install <name> --source mikforge-agent-tools
```

Codex plugins install globally by default.

### Enable/disable per-project

Via `.codex/config.yaml`:

```yaml
plugins:
  <name>: true
```

### Manage

```bash
codex plugin list                           # List installed
codex plugin update <name>                 # Update
codex plugin uninstall <name>              # Remove
```

[cn-docs]: docs/README.zh-CN.md
[ja-docs]: docs/README.ja.md
