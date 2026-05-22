# SDK Policy

## 基本原则

- Diretta Host SDK 仍受官方条款约束。
- 本仓库保留 SDK 相关归档与参考，但实际使用前应由最终用户按官方要求完成对应授权路径选择。
- 平台主线与参考源码应分层管理，不把 SDK 资产与主平台结构混淆。

## 当前落地方式

- `third_party/archives/` 保存官方归档文件
- Linux runner 从该目录中提取 `DirettaHostSDK_149_6.tar.zst`
- 参考源码位于 `references/DirettaRendererUPnP/`
