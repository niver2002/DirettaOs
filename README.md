# audio-linux-os

面向高音质播放链路的 Linux / appliance 平台仓库。

这个仓库现在按 **平台优先、参考源码分层** 的方式组织：

- `image/`：appliance / board-pack / onboarding / recovery / updates 主线
- `scripts/`：构建机和 runner 脚本
- `docs/`：平台文档、SDK 资产说明、路线图
- `references/DirettaRendererUPnP/`：作为参考源码收纳的 DirettaRendererUPnP 工程
- `third_party/archives/`：用户提供的 Diretta 相关官方归档文件

## 设计原则

1. **顶层是 OS / 平台项目**，不是单一播放器项目。
2. **DirettaRendererUPnP 作为参考源码目录存在**，用于实现、迁移和音质优化参考。
3. **外部 SDK 与官方包按资产管理**，不与主平台结构混淆。
4. **Linux 构建在 self-hosted runner 上完成**。

## 目录结构

```text
audio-linux-os/
├── .github/workflows/                # self-hosted 构建工作流
├── docs/                             # 平台文档、SDK 说明、路线图
├── image/                            # appliance / board-pack / onboarding / recovery
├── references/
│   └── DirettaRendererUPnP/          # 参考源码目录
├── scripts/                          # runner / 构建辅助脚本
└── third_party/archives/             # 官方归档资产
```

## Self-hosted runner 快速开始

1. 在 Linux x86_64 构建机上 clone 本仓库
2. 运行：

```bash
chmod +x scripts/setup-runner.sh
./scripts/setup-runner.sh
```

脚本会：
- 安装 runner 和构建依赖
- 检查/解压 `third_party/archives/DirettaHostSDK_149_6.tar.zst`
- 配置 `DIRETTA_SDK_PATH=$HOME/audio/DirettaHostSDK_149`
- 注册 self-hosted runner 到本仓库

## 当前重点

- Raspberry Pi 5 `k16` 作为主 board-pack 验证线
- Path C：平台可交付，Diretta payload 按官方条款启用
- 将现有 CPU/IRQ/SMT/MTU/RT/buffer 能力整理成 presets
- 后续推进 raw PCM fast path 与更深层 host tuning 实验
