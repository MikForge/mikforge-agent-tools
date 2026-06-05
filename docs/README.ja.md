# MikForge Agent Tools

AI エージェントプラグインマーケットプレイス by MikForge。

[English →][en-docs] · [中文 →][zh-docs]

---

## Claude Code

### マーケットプレイス追加（初回のみ）

```bash
claude plugin marketplace add mikforge github:MikForge/mikforge-agent-tools
```

### グローバルインストール

```bash
claude plugin install <name>@mikforge --scope user
```

すべてのプロジェクトで利用可能。

### プロジェクト単位（チーム共有）

```bash
claude plugin install <name>@mikforge --scope project
```

`.claude/settings.json` に書き込み — git でチームと共有可能。

### プロジェクト単位（個人のみ）

```bash
claude plugin install <name>@mikforge --scope local
```

`.claude/settings.local.json`（gitignore 対象）に書き込み。

### 管理

```bash
claude plugin list                          # 一覧表示
claude plugin update <name>@mikforge       # 更新
claude plugin uninstall <name>@mikforge    # 削除
```

---

## Codex

### マーケットプレイス追加（初回のみ）

```bash
codex plugin marketplace add https://github.com/MikForge/mikforge-agent-tools.git
```

### グローバルインストール

```bash
codex plugin install <name> --source mikforge-agent-tools
```

Codex プラグインはデフォルトでグローバルインストール。

### プロジェクト単位での有効/無効

`.codex/config.yaml` で制御：

```yaml
plugins:
  <name>: true
```

### 管理

```bash
codex plugin list                            # 一覧表示
codex plugin update <name>                  # 更新
codex plugin uninstall <name>               # 削除
```

[en-docs]: ../README.md
[zh-docs]: README.zh-CN.md
