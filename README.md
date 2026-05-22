# DirettaOs

面向高音质播放链路的 Linux / appliance 平台仓库。

这个仓库现在按 **平台优先、参考源码分层** 的方式组织：

- `image/`：appliance / board-pack / onboarding / recovery / updates 主线
- `scripts/`：构建机和 runner 脚本
- `docs/`：平台文档、SDK 资产说明、路线图
- `references/DirettaRendererUPnP/`：作为参考源码收纳的 DirettaRendererUPnP 工程
- `third_party/`：第三方资产说明；大体积官方归档不进入 Git

## 设计原则

1. **顶层是 OS / 平台项目**，不是单一播放器项目。
2. **DirettaRendererUPnP 作为参考源码目录存在**，用于实现、迁移和音质优化参考。
3. **外部 SDK 与官方包按资产管理**，不与主平台结构混淆。
4. **Linux 构建在 self-hosted runner 上完成**。

## 目录结构

```text
DirettaOs/
├── .github/workflows/                # self-hosted 构建工作流
├── docs/                             # 平台文档、SDK 说明、路线图
├── image/                            # appliance / board-pack / onboarding / recovery
├── references/
│   └── DirettaRendererUPnP/          # 参考源码目录
├── scripts/                          # runner / 构建辅助脚本
└── third_party/                      # 第三方资产说明（归档文件走同步盘/外部存储）
```

## Self-hosted runner 快速开始

### 一键脚本

如果云电脑已经装好 `git` / `tar` / `bash`，并且同步盘里有 SDK 归档，可以直接运行：

```bash
curl -fL --progress-bar https://raw.githubusercontent.com/niver2002/DirettaOs/main/scripts/bootstrap-cloud-runner.sh -o /tmp/bootstrap-cloud-runner.sh
chmod +x /tmp/bootstrap-cloud-runner.sh
/tmp/bootstrap-cloud-runner.sh
```

默认约定：
- 仓库克隆到：`$HOME/work/DirettaOs`
- 同步盘 SDK 归档：`$HOME/syncdisk/diretta-assets/DirettaHostSDK_149_6.tar.zst`
- SDK 解压到：`$HOME/audio/DirettaHostSDK_149`
- runner 安装到：`$HOME/actions-runner-direttaos`

如需覆盖路径，可先导出环境变量：

```bash
export SYNC_ASSET_DIR=/path/to/diretta-assets
export SDK_ARCHIVE=/path/to/DirettaHostSDK_149_6.tar.zst
export REPO_DIR=$HOME/work/DirettaOs
export RUNNER_DIR=$HOME/actions-runner-direttaos
/tmp/bootstrap-cloud-runner.sh
```

### 手动方式

1. 在 Linux x86_64 构建机上 clone 本仓库
2. 准备 SDK 归档或已解压目录：
   - 默认解压目标：`$HOME/audio/DirettaHostSDK_149`
   - 默认归档路径：`$HOME/syncdisk/diretta-assets/DirettaHostSDK_149_6.tar.zst`
3. 运行：

```bash
chmod +x scripts/setup-runner.sh
GH_REPO=niver2002/DirettaOs ./scripts/setup-runner.sh
```

脚本会：
- 安装 runner 和构建依赖
- 检查/解压 `DirettaHostSDK_149_6.tar.zst`
- 配置 `DIRETTA_SDK_PATH=$HOME/audio/DirettaHostSDK_149`
- 注册 self-hosted runner 到当前仓库

## 当前重点

- Raspberry Pi 5 `k16` 作为主 board-pack 验证线
- Path C：平台可交付，Diretta payload 按官方条款启用
- 将现有 CPU/IRQ/SMT/MTU/RT/buffer 能力整理成 presets
- 后续推进 raw PCM fast path 与更深层 host tuning 实验
