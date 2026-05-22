# Context

DirettaRendererUPnP 现在已经不仅是一个播放器工程，而是同时具备三层基础：

1. **音频热路径与调优基础已经很强**
   - 应用走 `DIRETTA::Sync` 直连模式，不经过本地 ALSA 播放栈：`src/DirettaSync.h`, `src/DirettaSync.cpp`
   - 已有低延迟缓冲、重缓冲、PCM bypass、DSD 优化、CPU affinity、RT priority、IRQ affinity、SMT、MTU/jumbo、FFmpeg LTO 等成熟能力：`src/DirettaSync.h:196-255`, `src/main.cpp:200-338`, `systemd/start-renderer.sh:7-240`, `systemd/diretta-renderer.conf:36-333`, `install.sh:199-269`
   - README/配置文档/优化报告已经清楚表明：这个项目追求的是**时序稳定性和抖动控制**，不是单纯“跑得更快”：`docs/2026-01-17-1407-TIMING_VARIANCE_OPTIMIZATION_REPORT.md`, `README.md:194-245`

2. **平台/appliance 骨架已经开始落盘**
   - 已新增 `image/`、`docs/IMAGE_PLATFORM.md`、board-pack、onboarding、recovery、updates、manifest scaffold
   - 已新增 Path C 方向文档：平台本身可商业交付，Diretta payload 作为可选路径
   - 已新增 onboarding service/profile/state scaffold，并把它接回了 `install.sh` 与 `systemd/install-systemd.sh`

3. **用户已提供官方 Diretta 相关资产，且其中一部分已被实际接入本项目推进路径**
   - `DirettaHostSDK_149_6.tar.zst` 已解包并可被本项目自动发现：`vendor/diretta/DirettaHostSDK_149/`
   - `Makefile` 与 `install.sh` 已调整为优先在 `vendor/diretta/` 查找 SDK
   - 其他资产（`DirettaAlsaHost_149`, `MemoryPlayHostLinux_148`, `MemoryPlayControllerSDK_148`, `diretta_RaspberryPi5_149_16_includeRoonBridge.img`）不适合直接并入主构建链，但对**调优策略、板卡预设、授权提示、appliance 交付形态**有重要参考价值：`docs/DIRETTA_VENDOR_ASSETS.md`

本次要把 plan 升级成一版更激进、但仍然可执行的路线：**凡是对项目推进有帮助、对音质提升有帮助、且和当前仓库状态能闭环的功能，都纳入计划；但要明确哪些是直接实现项、哪些是参考项、哪些是实验项。**

# Recommended approach

## 1. 总方向：继续走 Path C，但把“音质上限推进”和“平台化落地”同时推进

推荐继续坚持 **Path C**：

- **Layer A：commercial-capable appliance platform**
  - `image/`、board-pack、onboarding、recovery、update、manifest、release metadata
- **Layer B：Diretta payload**
  - 现有 `DirettaRendererUPnP` + vendored `DirettaHostSDK_149`
  - 可预部署 SDK，也可单独提供
  - 安装/首启时明确要求用户按官方流程选择适用授权路径（free/personal-use 或其他官方路径）

但和上一版 plan 不同的是，新的重点不只是平台骨架，而是把**所有对音质和项目推进有帮助的功能**按优先级落盘：

### A. 直接实现并整合（必须进入主计划）
- vendored `DirettaHostSDK_149` 的编译链和兼容验证
- 现有 CPU/IRQ/SMT/MTU/RT/buffer knobs 的 preset 化
- onboarding 与 payload 安装的权限/授权提示整合
- Pi 5 `k16` 作为主平台的 board-pack 细化
- 非交互安装/预部署路径

### B. 参考吸收（进入计划，但不直接抄代码）
- `DirettaAlsaHost_149` 的 thread-mode / cycle / CPU / singleMode / LatencyBuffer 概念
- `MemoryPlayControllerSDK_148` 的控制/发现/状态视图思路
- `diretta_RaspberryPi5_149_16_includeRoonBridge.img` 的 appliance packaging 方向

### C. 实验项（明确为 lab，不承诺立即默认启用）
- 更激进的 SDK thread-mode preset
- raw PCM fast path
- topology-aware pinning（CCD/NUMA/housekeeping）
- 更深的 host tuning（C-state、network queue/offload、tmpfs/log layout）

## 2. SDK 与外部资产的使用策略

### 2.1 直接用于本项目推进的资产

#### `DirettaHostSDK_149_6.tar.zst`
这是本项目唯一直接可用、且已经开始接入的外部资产。

要做的不是“只是解包”，而是让它真正进入主线：

1. **让本地构建默认可发现 `vendor/diretta/DirettaHostSDK_149/`**
   - 这个已经开始做了，需要纳入正式执行计划
2. **增加 149 的编译与兼容验证步骤**
   - 确认当前 `DIRETTA::Sync`、`diretta_stream`、`FormatID`、库文件命名仍与仓库代码匹配
3. **必要时补 149 兼容修正**
   - 尤其关注 `Sync.hpp` 中 thread mode / API 细节
4. **保留 148 文档参考，但主验证切到 149**

### 2.2 参考吸收但不直接并入的资产

#### `DirettaAlsaHost_149_7.tar.xz`
不能当代码 donor，但它对本项目有三类价值：

- 它暴露了更多官方 host tuning 术语：
  - `CycleTime`
  - `CycleMinTime`
  - `LatencyBuffer`
  - `CpuSend`
  - `CpuOther`
  - `ScanOnlineStop`
  - `singleMode`
- 这些可以直接反哺本项目：
  - 现有 config preset 设计
  - appliance preset 命名
  - 单目标模式 / 播放时暂停扫描 等策略
- 但不要把 `alsa_bridge` 内核模块、`syncAlsa_*` 二进制、其 service 工作流直接并入本项目

#### `MemoryPlayControllerSDK_148_13.tar.zst`
直接代码复用价值低，但对**控制平面**有参考价值：
- host list / target list / connect / status 的 CLI 语义可反哺 onboarding 和 diagnostics UI
- 适合用于 future tooling / support bundle / diagnostics plan

#### `MemoryPlayHostLinux_148_14.tar.zst`
直接实现价值低，但可用来参考：
- 一体化 host 产品如何组织
- service 和 appliance 交付体验

#### `diretta_RaspberryPi5_149_16_includeRoonBridge.img`
不能当源码用，但对计划有很大帮助：
- 证明 Pi 5 `k16` 是非常现实的目标板
- 可作为 board-pack / artifact 参考样本
- 可用来反推：我们自己的 Pi 5 image 至少需要哪些交付物和用户体验

## 3. 音质提升主线：把已有成熟 knobs 产品化，而不是先加一堆新旋钮

当前仓库对音质最有帮助的成熟功能，已经不算少。升级 plan 时，应该优先把它们组织成**可验证的 preset / mode**，而不是先无限扩张新参数。

### 3.1 直接纳入 preset 的成熟功能

#### Runtime / app-level
- `CPU_AUDIO`
- `CPU_DECODE`
- `CPU_OTHER`
- `RT_PRIORITY`
- `THREAD_MODE`
- `TRANSFER_MODE`
- `CYCLE_TIME`
- `CYCLE_MIN_TIME`
- `TARGET_PROFILE_LIMIT`
- `MINIMAL_UPNP`
- `PCM/DSD/remote/high-rate buffer & prefill`

来源：
- `src/main.cpp:200-338`
- `src/DirettaSync.h:196-255`
- `systemd/start-renderer.sh:164-228`
- `systemd/diretta-renderer.conf:155-333`

#### Host / service-level
- `IRQ_INTERFACE`
- `IRQ_CPUS`
- `SMT`
- `TARGET_INTERFACE`
- `TARGET_SPEED`
- `TARGET_DUPLEX`
- `MTU`
- `NICE_LEVEL`
- `IO_SCHED_CLASS`
- `IO_SCHED_PRIORITY`

来源：
- `systemd/start-renderer.sh:45-124`
- `systemd/diretta-renderer.conf:100-153`
- `systemd/diretta-renderer.conf:247-333`

### 3.2 计划中必须新增的 preset 体系

计划里应正式定义这几套 preset，并在 image/onboarding/profile 中落地：

1. **safe-default**
   - 兼容优先
   - 不启用危险 host-level 行为
   - 保证可恢复、可升级、可支持

2. **performance**
   - 基于已验证板卡
   - 启用 CPU pinning / IRQ affinity / MTU preset / minimal UPnP（视控制点兼容）
   - 为 Pi 5 `k16` 准备主线 preset

3. **streaming-resilient**
   - 面向 remote PCM / CDN / radio
   - 更高 remote buffer / prefill
   - 尽量避免高码率互联网源抖动

4. **single-target-appliance**
   - 借鉴 ALSA Host 的 `singleMode` / `ScanOnlineStop` 思路
   - 减少播放中不必要的 target 扫描与控制面扰动

5. **lab-extreme**
   - 仅限实验
   - 用于验证 `NOSHORTSLEEP` / `NOSLEEPFORCE` / 更激进 CPU 隔离等

## 4. 最高价值的新实现项

基于现有代码与优化文档，升级后的 plan 应明确把这些列为高优先级新实现：

### 4.1 raw PCM fast path

这是当前最明显、最直接可能提升热路径稳定性的下一个优化点。

证据：
- `docs/plans/2026-01-17-Optimisation_Opportunities.md` 已明确把“真正绕开 FFmpeg decode 的 raw PCM path”列为下一步机会
- 当前已实现 PCM bypass，但还没有完全跳过 `avcodec_send_packet()` / `avcodec_receive_frame()` 的 raw packet fast path

计划要求：
- 针对 WAV / 原始 PCM 容器建立更直接的数据通路
- 避免不必要的 FFmpeg decode 调度与状态机抖动
- 和现有 PCM bypass 逻辑兼容，而不是重写一套体系

### 4.2 topology-aware pinning

当前已有 CPU affinity，但 هنوز缺少**更智能的拓扑感知**：
- Pi 4 / Pi 5 按核心拓扑推荐 pinning
- Ryzen / CCD-aware pinning
- housekeeping/audio/decode lane 的自动建议

来源：
- `ROADMAP.md` 中对 CCD / NUMA / host tuning 的提示
- `docs/2026-01-17-1407-TIMING_VARIANCE_OPTIMIZATION_REPORT.md` 对 timing variance 的强调

计划要求：
- 先从**board-pack preset recommendation** 做起，不强求一上来就自动调优
- 允许将来演进成自动建议/自动布局

### 4.3 host-level network buffer / queue tuning

当前 installer 只做了 `net.core.rmem_max` / `wmem_max` 的基本提升。计划里应把以下内容列为明确候选：
- NIC offload / coalescing / queue settings 调查与验证
- UDP/rmem/wmem 的 image preset 化
- 单网口/双网口/3-tier 拓扑下的差异验证

注意：这必须先进入 **lab / qualification**，不能直接默认打开。

### 4.4 official thread-mode presets

SDK 149 `Sync.hpp` 暴露了官方的 `THRED_MODE` 位集合：
- `CRITICAL`
- `NOSHORTSLEEP`
- `OCCUPIED`
- `NOFASTFEEDBACK`
- `IDLEONE`
- `IDLEALL`
- `NOSLEEPFORCE`
- `LIMITRESEND`
- `NOJUMBOFRAME`
- `NOFIREWALL`
- `NORAWSOCKET`

计划要求：
- 不让用户直接面对一串难懂 bitmask
- 用 profile/preset 封装成：
  - low-jitter stable
  - remote-stream resilient
  - busy-loop max performance
  - compatibility / no-jumbo

## 5. 平台/appliance 路线的下一步收口

### 5.1 继续做 image scaffold，但要和“可运行”更接近

当前 `image/` 已有骨架，接下来应把 plan 升级为：

#### 必须完成
- board-pack manifest schema 完整化
- onboarding state persistence 与 renderer config 分离
- update/recovery metadata 占位变成明确 contract
- 文档与安装脚本对齐 Path C + SDK 预置/授权提示模型

#### 代表性路径
- `image/boards/raspberry-pi-5/`
- `image/common/presets/`
- `image/onboarding/`
- `image/recovery/`
- `image/updates/`
- `image/manifests/`

### 5.2 强化 Pi 5 主线

现在最现实、最值得押注的 board-pack 是：
- **Raspberry Pi 5 + `aarch64-linux-15k16`**

理由：
- 当前项目 `Makefile` 已自动识别 Pi 5 / 16KB page：`Makefile:70-80`
- 用户提供的官方镜像也是 Pi 5：`diretta_RaspberryPi5_149_16_includeRoonBridge.img`
- 已经有 `image/boards/raspberry-pi-5/QUALIFICATION.md`

计划升级要求：
- 把 Pi 5 定义成音质上限主线验证板
- Pi 4 保留兼容线，不抢主线资源
- CM5 仅在 carrier 固定时推进

## 6. 非交互安装与 SDK 预部署/授权提示模型

你已经明确方向：
- SDK 可以预部署
- 安装或首启时提示用户按官方路径选择授权（free / 其他官方路径）

所以升级版计划不再把“让用户自己找 SDK”当主线，而是：

### 主模型
1. 系统平台预部署
2. SDK 可预置于 target 环境
3. 安装/首启流程提示用户确认官方授权路径
4. payload install lane 将 renderer 真正接入平台

### 实现要求
- `install.sh` 保留 interactive / semi-interactive lane
- image/onboarding 中明确加入授权确认文案与 state
- `docs/IMAGE_PLATFORM.md`、`image/common/PAYLOAD_INSTALL.md`、payload manifest 与 README 同步这一模型

## 7. Critical files to modify

### 核心实现文件
- `Makefile`
- `install.sh`
- `src/AudioEngine.cpp`
- `src/DirettaSync.h`
- `src/DirettaSync.cpp`
- `src/main.cpp`
- `systemd/start-renderer.sh`
- `systemd/diretta-renderer.conf`
- `systemd/install-systemd.sh`
- `systemd/uninstall-systemd.sh`

### 平台与 preset
- `image/common/presets/*`
- `image/boards/raspberry-pi-5/*`
- `image/onboarding/*`
- `image/manifests/*`
- `image/updates/*`
- `image/recovery/*`

### 文档与参考
- `README.md`
- `docs/IMAGE_PLATFORM.md`
- `docs/DIRETTA_VENDOR_ASSETS.md`
- `docs/CONFIGURATION.md`
- `docs/SDK_148_MIGRATION_JOURNAL.md`
- `docs/plans/2026-01-17-Optimisation_Opportunities.md`
- `docs/2026-01-17-1407-TIMING_VARIANCE_OPTIMIZATION_REPORT.md`

### vendored reference-only sources
- `vendor/diretta/DirettaHostSDK_149/Host/Sync.hpp`
- `vendor/diretta/DirettaHostSDK_149/Host/Format.hpp`
- `vendor/diretta/DirettaHostSDK_149/memo_host.txt`
- `vendor/diretta/DirettaAlsaHost/readme.txt`
- `vendor/diretta/DirettaAlsaHost/rewrite.sh`
- `vendor/diretta/MemoryPlayControllerSDK/memo.txt`

## 8. Risks

### A. 149 SDK 兼容风险
- 当前虽然已接入自动发现，但还没有完成一次真实 149 编译与运行验证
- 149 可能引入和 148 不同的 ABI/行为差异

### B. 文档/默认值漂移风险
- 现有 docs 中对 remote buffer 等默认值已经有和代码不完全一致的地方
- 如果不统一 preset 与文档，会造成“用户以为自己在用某个模式，实际上不是”

### C. 把参考资产误当可复用代码的风险
- ALSA Host / MemoryPlay / Pi 5 预制镜像都不能直接生搬硬套
- 只能吸收概念与交付经验

### D. 调优冲突风险
- native affinity、wrapper tuning、tuner scripts 仍可能互相冲突
- 必须坚持单一路径：`start-renderer.sh` + config + preset

### E. 音质与可支持性冲突
- 任何更激进 host-level 调优（busy loop、offload、GRUB、journald/tmpfs）都必须先进入 lab/qualification
- 不能一上来就默认给最终用户

## 9. Verification

### Gate 1 — SDK / build
- 使用 `vendor/diretta/DirettaHostSDK_149/` 完成一次真实构建
- 验证 `x64-linux-15v3`、`aarch64-linux-15`、`aarch64-linux-15k16` 变体选择正确
- 验证 `DIRETTA_SDK_PATH` 覆盖行为仍然可用

### Gate 2 — preset / config
- safe-default / performance / streaming-resilient / single-target-appliance / lab-extreme 五套 preset 的 config 映射正确
- UI / onboarding / config file / wrapper 参数保持一致

### Gate 3 — audio ceiling
- PCM 44.1/16、192/24、384/24
- DSD64/128/256
- lossy radio on 24-bit DACs
- remote PCM / local PCM
- MINIMAL_UPNP on/off
- single NIC / dual NIC / 3-tier

### Gate 4 — Pi 5 主线
- `aarch64-linux-15k16` 主线验证
- MTU 1500 / 9000 / 16128
- IRQ affinity / SMT / CPU affinity preset 差异对比
- thermal / soak / reboot / recovery

### Gate 5 — experimental / lab
- raw PCM fast path 正确性与收益
- advanced thread-mode presets 对 jitter / CPU / stability 的影响
- host-level network buffer / queue tuning 的副作用
- topology-aware pinning 建议是否可信

# What to do first

如果开始执行升级版计划，建议顺序改成：

1. **先让 vendored `DirettaHostSDK_149` 真正参与一次构建验证**
2. **然后把现有成熟 knobs 收敛成正式 preset 体系**
3. **再实现 raw PCM fast path 这一项最高价值新优化**
4. **并行完善 Pi 5 board-pack + onboarding + payload authorization flow**
5. **最后再推进更深的 host-level / lab-only 音质调优**

这样做的好处是：
- 先把最直接能推动项目进展的外部资产真正用起来
- 再把已经存在的音质能力“产品化”
- 然后才扩展到新的音质实验项
- 同时保持平台/appliance 路线不脱节