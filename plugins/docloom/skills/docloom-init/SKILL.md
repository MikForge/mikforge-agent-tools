---
name: docloom-init
description: Use when initializing the docloom project environment for the first time.
metadata:
  version: "2.0"
---

# docloom-init

## 目标

docloom 项目一次性初始化——创建 `docs/loom/config.yaml` 和目录骨架（specs/、feedback/、entropy/ 子目录）。元定义文件统一从 `../docloom/references/` 读取，不复制到项目目录。幂等，已存在则跳过。repair 模式检测已有文件完整性。

## 适用判断

首次设置 docloom 流水线环境或检测已有配置完整性时使用。

## 前置条件

- 无——初始化工具本身，所有依赖在初始化后可用
- `../docloom/references/` 共享目录存在（随 skill 安装）

## 执行步骤

### 声明参数

- **`mode`** — string，可选。默认 `init`。`init` 创建缺失项，`repair` 检测已有文件完整性

### 流程

1. 接收 `mode`（可选，默认 init）
2. 根据 `mode` 判定
   - `init`：创建缺失项
   - `repair`：检测已有文件完整性，输出检查报告
3. 创建 `docs/loom/config.yaml`（若不存在）
4. 创建目录骨架：
   - `docs/loom/specs/`
   - `docs/loom/feedback/`
   - `docs/loom/entropy/checkpoints/`
   - `docs/loom/entropy/drafts/`
   - `docs/loom/entropy/analysis/`
5. 幂等——已存在则跳过

### 约束

- 元定义文件（base.spec.md 等）不复制到项目目录——所有 skill 从 `../docloom/references/` 直接读取
- 幂等：多次 init 无副作用

## 示例

### 场景 A：首次初始化（正常）

调用 docloom-init（默认 mode=init）

1. 检测 config.yaml 不存在 → 创建
2. 创建目录骨架：specs/、feedback/、entropy/ 全部子目录
3. 幂等——后续调用无变化

### 场景 B：repair 模式（边界）

调用 docloom-init mode=repair

1. 检测 config.yaml 存在 ✅
2. 检测子目录：specs/ ✅、feedback/ ✅、entropy/checkpoints/ ✅、entropy/drafts/ ✅、entropy/analysis/ ✅
3. 输出完整性报告：所有文件/目录正常

### 场景 C：重复 init（幂等）

再次调用 docloom-init

1. config.yaml 已存在 → 跳过
2. 所有子目录已存在 → 跳过
3. 无任何副作用

## 验证

- init 后验证 `docs/loom/config.yaml` 存在
- init 后验证所有子目录存在
- repair 后验证输出完整性报告

## FAQ

**Q: 元定义文件为什么不复制到项目中？**

A: 避免多项目同步问题。元定义文件跟随 skill 安装目录，single source of truth。更新 skill 即更新规范，不需逐项目复制。
