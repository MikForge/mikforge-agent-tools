---
name: docloom-init
description: Use when initializing the docloom project environment for the first time.
metadata:
  version: "3.0"
---

# docloom-init

## 目标

一次性创建 docloom 项目骨架——config.yaml + 目录结构。幂等，已存在则跳过。repair 模式检测已有文件完整性。

## 非目的

不注册文档类型、不生成 spec 文件、不触发审查链。

## 参数

- **`mode`** — string，可选，默认：init。`init` 创建缺失项，`repair` 检测已有文件完整性。

## 收集参数

无。

## 流程

接收 mode（可选，默认 init）
→ mode 判定：
    - **init** → 创建 [config.yaml][docloom-config]（若不存在）
        → 创建目录骨架：`docs/loom/specs/`、`docs/loom/feedback/`、`docs/loom/entropy/checkpoints/`、`docs/loom/entropy/drafts/`、`docs/loom/entropy/analysis/`
        → 已存在则跳过，幂等无副作用
    - **repair** → 检测 config.yaml + 全部子目录存在性 → 输出完整性报告
——元定义文件从 `../docloom/references/` 直接读取，不复制到项目目录

## 验证

```bash
grep -q "## 目标" SKILL.md && grep -q "## 非目的" SKILL.md && grep -q "## 参数" SKILL.md && grep -q "## 流程" SKILL.md && grep -q "## 验证" SKILL.md && grep -q "## 示例" SKILL.md
```

- [ ] init 后验证 `docs/loom/config.yaml` 存在
- [ ] init 后验证所有子目录存在
- [ ] repair 后验证输出完整性报告

## 示例

> **正例：**
>
> 调用 docloom-init（默认 mode=init）
> → config.yaml 不存在 → 创建 → 创建目录骨架 → 完成。再次调用 → 全部已存在 → 跳过，无副作用。

> **反例：**
>
> init 时复制 `base.spec.md` 到项目目录下。
>
> 元定义文件跟随 skill 安装目录，复制到项目会导致多项目同步问题。所有 skill 从 `../docloom/references/` 直接读取。

[docloom-config]: docs/loom/config.yaml
