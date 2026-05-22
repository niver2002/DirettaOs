# SDK archive selection note

From the user-provided archives in the project root, the assets break down as follows:

## Directly useful for this repository

- `DirettaHostSDK_149_6.tar.zst`
  - This is the correct Host SDK family for `DirettaRendererUPnP`.
  - It provides the `Host/` headers and `libDirettaHost_*` / `libACQUA_*` static libraries expected by the current `Makefile`.

## Reference-only / not directly integrated

- `DirettaAlsaHost_149_7.tar.xz`
  - Separate ALSA-host product path with its own kernel-module/service workflow.
- `MemoryPlayHostLinux_148_14.tar.zst`
  - Separate MemoryPlay host application.
- `MemoryPlayControllerSDK_148_13.tar.zst`
  - Separate controller SDK.
- `diretta_RaspberryPi5_149_16_includeRoonBridge.zip`
  - Prebuilt Raspberry Pi 5 image; useful as a reference artifact only.

## Integration choice made

The project has been updated so local SDK auto-detection now searches `vendor/diretta/` first, allowing the unpacked `DirettaHostSDK_149/` to be used without forcing users to copy it elsewhere.
