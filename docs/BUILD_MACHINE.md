# Build Machine Guide

本仓库的 Linux 构建应在 self-hosted runner 上进行。

## 目标环境

- Linux x86_64
- GitHub self-hosted runner
- 已放置或可解压 `third_party/archives/DirettaHostSDK_149_6.tar.zst`

## 关键路径

- runner 脚本：`scripts/setup-runner.sh`
- workflow：`.github/workflows/build-self-hosted.yml`
- SDK 默认安装路径：`$HOME/audio/DirettaHostSDK_149`

## 说明

runner 脚本会：
- 安装基础依赖与 `zstd`
- 检查 SDK 目录
- 如果仓库内已有 `third_party/archives/DirettaHostSDK_149_6.tar.zst`，可直接解压到 `$HOME/audio/`
- 配置 `DIRETTA_SDK_PATH`
