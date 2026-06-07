# Docloom 插件迁移到 Monorepo — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 docloom 插件从独立仓库 `MikForge/docloom-plugin` 迁移到 `MikForge/mikforge-agent-tools/plugins/docloom/`，并将两个 marketplace 的 source 从外部 GitHub 引用改为本地相对路径。

**Architecture:** 纯文件迁移 + 4 个配置文件编辑。不涉及任何代码逻辑变更。技能文件、manifest、assets 原样复制；source 引用从远程改为 `./plugins/docloom`。

**Tech Stack:** bash (rsync, git), JSON 编辑, `claude plugin validate`

---

### Task 1: 复制插件内容到 monorepo

**Files:**
- Create: `plugins/docloom/` (整个目录树，排除 `.git/`, `*.sh`, `sync.yaml*`, 递归软链接)

- [ ] **Step 1: 创建目标目录并执行 rsync**

```bash
cd /Users/michael/Desktop/gitfiles/mikforge-agent-tools
mkdir -p plugins

rsync -av \
  --exclude '.git' \
  --exclude '*.sh' \
  --exclude 'sync.yaml' \
  --exclude 'sync.yaml.bak' \
  --exclude 'skills/docloom/references/references' \
  /Users/michael/Desktop/gitfiles/docloom-plugin/ \
  plugins/docloom/
```

Expected: 输出文件列表，无 error。应在 `plugins/docloom/` 下看到 `.claude-plugin/`、`.codex-plugin/`、`skills/`、`hooks/`、`assets/`、`.mcp.json`、`integrity.json`、`README.md`。

- [ ] **Step 2: 验证关键文件已就位**

```bash
ls plugins/docloom/.claude-plugin/plugin.json \
   plugins/docloom/.codex-plugin/plugin.json \
   plugins/docloom/skills/ \
   plugins/docloom/hooks/hooks.json \
   plugins/docloom/.mcp.json \
   plugins/docloom/integrity.json \
   plugins/docloom/README.md
```

Expected: 7 个路径全部存在。

- [ ] **Step 3: 确认排除了不应存在的文件**

```bash
test ! -f plugins/docloom/sync.yaml && echo "OK: sync.yaml excluded"
test ! -f plugins/docloom/sync-skills.sh && echo "OK: sync-skills.sh excluded"
test ! -f plugins/docloom/version.sh && echo "OK: version.sh excluded"
test ! -f plugins/docloom/sync-and-version.sh && echo "OK: sync-and-version.sh excluded"
test ! -L plugins/docloom/skills/docloom/references/references && echo "OK: recursive symlink excluded"
```

Expected: 5 行 `OK: ... excluded`。

- [ ] **Step 4: 确认技能数量正确（11 个目录）**

```bash
ls -d plugins/docloom/skills/*/ | wc -l
```

Expected: `11`

- [ ] **Step 5: 提交 Task 1**

```bash
git add plugins/docloom/
git commit -m "migrate(plugins): copy docloom plugin content from MikForge/docloom-plugin"
```

---

### Task 2: 更新 Claude Code plugin manifest

**Files:**
- Modify: `plugins/docloom/.claude-plugin/plugin.json`

- [ ] **Step 1: 用 Edit 工具更新 `plugins/docloom/.claude-plugin/plugin.json`**

先读取当前内容：
```bash
cat plugins/docloom/.claude-plugin/plugin.json
```

然后用 Edit 工具做两处变更：

**变更 A** — 移除 `version` 字段：
```diff
-  "version": "1.0.7",
```

**变更 B** — 更新 `homepage`：
```diff
-  "homepage": "https://github.com/MikForge/docloom-plugin",
+  "homepage": "https://github.com/MikForge/mikforge-agent-tools",
```

**变更 C** — 更新 `repository`：
```diff
-  "repository": "https://github.com/MikForge/docloom-plugin",
+  "repository": "https://github.com/MikForge/mikforge-agent-tools",
```

- [ ] **Step 2: 验证 JSON 语法有效**

```bash
python3 -m json.tool plugins/docloom/.claude-plugin/plugin.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 3: 验证 version 已移除、URL 已更新**

```bash
cat plugins/docloom/.claude-plugin/plugin.json
```

Expected: 不包含 `"version"` 字段；`homepage` 和 `repository` 指向 `mikforge-agent-tools`。

- [ ] **Step 4: 提交 Task 2**

```bash
git add plugins/docloom/.claude-plugin/plugin.json
git commit -m "migrate(docloom): remove version, update URLs to mikforge-agent-tools in claude manifest"
```

---

### Task 3: 更新 Codex plugin manifest

**Files:**
- Modify: `plugins/docloom/.codex-plugin/plugin.json`

- [ ] **Step 1: 用 Edit 工具更新 `plugins/docloom/.codex-plugin/plugin.json`**

先读取当前内容：
```bash
cat plugins/docloom/.codex-plugin/plugin.json
```

做两处变更：

**变更 A** — 移除 `version` 字段：
```diff
-  "version": "1.0.7",
```

**变更 B** — 更新 `websiteURL`：
```diff
-    "websiteURL": "https://github.com/MikForge/docloom-plugin",
+    "websiteURL": "https://github.com/MikForge/mikforge-agent-tools",
```

- [ ] **Step 2: 验证 JSON 语法有效**

```bash
python3 -m json.tool plugins/docloom/.codex-plugin/plugin.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 3: 验证变更**

```bash
cat plugins/docloom/.codex-plugin/plugin.json
```

Expected: 不包含 `"version"` 字段；`websiteURL` 指向 `mikforge-agent-tools`。

- [ ] **Step 4: 提交 Task 3**

```bash
git add plugins/docloom/.codex-plugin/plugin.json
git commit -m "migrate(docloom): remove version, update websiteURL to mikforge-agent-tools in codex manifest"
```

---

### Task 4: 更新 Claude Code marketplace source 为相对路径

**Files:**
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: 用 Edit 工具更新 `.claude-plugin/marketplace.json`**

当前内容：
```json
      "source": {
        "source": "github",
        "repo": "MikForge/docloom-plugin"
      },
```

替换为：
```json
      "source": "./plugins/docloom",
```

注意：这是**字符串**，不是对象。Claude Code 相对路径 source 直接写 `"./plugins/docloom"`。

- [ ] **Step 2: 验证 JSON 语法有效**

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 3: 确认 source 字段正确**

```bash
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f:
    d = json.load(f)
src = d['plugins'][0]['source']
assert isinstance(src, str), f'source should be a string, got {type(src).__name__}'
assert src == './plugins/docloom', f'source should be ./plugins/docloom, got {src}'
print(f'OK: source = \"{src}\" (type: {type(src).__name__})')
"
```

Expected: `OK: source = "./plugins/docloom" (type: str)`

- [ ] **Step 4: 提交 Task 4**

```bash
git add .claude-plugin/marketplace.json
git commit -m "migrate(marketplace): point claude source to ./plugins/docloom (relative path)"
```

---

### Task 5: 更新 Codex marketplace source 为本地路径

**Files:**
- Modify: `.agents/plugins/marketplace.json`

- [ ] **Step 1: 用 Edit 工具更新 `.agents/plugins/marketplace.json`**

当前内容：
```json
      "source": {
        "source": "url",
        "url": "https://github.com/MikForge/docloom-plugin.git",
        "ref": "main"
      },
```

替换为：
```json
      "source": {
        "source": "local",
        "path": "./plugins/docloom"
      },
```

注意：Codex 是**对象**格式 `{"source": "local", "path": "./plugins/docloom"}`。

- [ ] **Step 2: 验证 JSON 语法有效**

```bash
python3 -m json.tool .agents/plugins/marketplace.json > /dev/null && echo "JSON valid"
```

Expected: `JSON valid`

- [ ] **Step 3: 确认 source 字段正确**

```bash
python3 -c "
import json
with open('.agents/plugins/marketplace.json') as f:
    d = json.load(f)
src = d['plugins'][0]['source']
assert isinstance(src, dict), f'source should be dict, got {type(src).__name__}'
assert src['source'] == 'local', f'source.source should be local, got {src[\"source\"]}'
assert src['path'] == './plugins/docloom', f'source.path should be ./plugins/docloom, got {src[\"path\"]}'
print('OK: source = {\"source\": \"local\", \"path\": \"./plugins/docloom\"}')
"
```

Expected: `OK: source = {"source": "local", "path": "./plugins/docloom"}`

- [ ] **Step 4: 提交 Task 5**

```bash
git add .agents/plugins/marketplace.json
git commit -m "migrate(marketplace): point codex source to local ./plugins/docloom"
```

---

### Task 6: 最终验证

- [ ] **Step 1: Claude Code 插件结构校验**

```bash
cd /Users/michael/Desktop/gitfiles/mikforge-agent-tools
claude plugin validate plugins/docloom
```

Expected: 没有 error。可能有 warning（如 YAML frontmatter 建议），不阻塞。

- [ ] **Step 2: 确认两个 marketplace.json 语法正确**

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "claude OK"
python3 -m json.tool .agents/plugins/marketplace.json > /dev/null && echo "codex OK"
```

Expected:
```
claude OK
codex OK
```

- [ ] **Step 3: 最终目录结构完整性检查**

```bash
cd /Users/michael/Desktop/gitfiles/mikforge-agent-tools

echo "=== Required files ==="
for f in \
  .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json \
  plugins/docloom/.claude-plugin/plugin.json \
  plugins/docloom/.codex-plugin/plugin.json \
  plugins/docloom/skills/docloom/SKILL.md \
  plugins/docloom/skills/docloom-author/SKILL.md \
  plugins/docloom/skills/docloom-brainstorm/SKILL.md \
  plugins/docloom/skills/docloom-build-spec/SKILL.md \
  plugins/docloom/skills/docloom-entropy/SKILL.md \
  plugins/docloom/skills/docloom-feedback/SKILL.md \
  plugins/docloom/skills/docloom-fix/SKILL.md \
  plugins/docloom/skills/docloom-init/SKILL.md \
  plugins/docloom/skills/docloom-register/SKILL.md \
  plugins/docloom/skills/docloom-review-auto-fix/SKILL.md \
  plugins/docloom/skills/docloom-reviewer/SKILL.md \
  plugins/docloom/hooks/hooks.json \
  plugins/docloom/.mcp.json \
  plugins/docloom/integrity.json \
  plugins/docloom/README.md; do
  test -f "$f" && echo "  ✓ $f" || echo "  ✗ MISSING: $f"
done

echo ""
echo "=== Excluded files (should NOT exist) ==="
for f in \
  plugins/docloom/sync.yaml \
  plugins/docloom/sync-skills.sh \
  plugins/docloom/version.sh \
  plugins/docloom/sync-and-version.sh; do
  test ! -f "$f" && echo "  ✓ $f excluded" || echo "  ✗ SHOULD NOT EXIST: $f"
done
test ! -L plugins/docloom/skills/docloom/references/references && echo "  ✓ recursive symlink excluded" || echo "  ✗ RECURSIVE SYMLINK EXISTS"
```

Expected: 19 个 `✓` required files，5 个 `✓ ... excluded`。

- [ ] **Step 4: 最终提交（如前面有未提交变更）**

```bash
git status
```

如果 clean，跳到 Step 5。如果有未提交变更：

```bash
git add -A
git commit -m "migrate: complete docloom monorepo migration — verify structure"
```

- [ ] **Step 5: 推送**

```bash
git push
```

---

## Completion Checklist

迁移完成后确认：
- [ ] `MikForge/mikforge-agent-tools` 仓库包含 `plugins/docloom/` 且结构完整
- [ ] `.claude-plugin/marketplace.json` 的 source 为 `"./plugins/docloom"`（字符串）
- [ ] `.agents/plugins/marketplace.json` 的 source 为 `{"source": "local", "path": "./plugins/docloom"}`（对象）
- [ ] 两个 plugin.json 已移除 `version` 字段
- [ ] URL 字段指向 `MikForge/mikforge-agent-tools`
- [ ] `MikForge/docloom-plugin` 仓库已 Archive（手动在 GitHub 操作）
