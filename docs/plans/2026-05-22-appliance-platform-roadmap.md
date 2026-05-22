# 2026-05-22 Appliance Platform and Audio Ceiling Roadmap

This document snapshots the current implementation plan that combines:

- the appliance/image platform scaffold,
- the Path C delivery split,
- vendored Diretta SDK integration,
- and the next wave of audio-quality / performance-ceiling work.

## Core direction

1. Keep the `image/` tree as the commercial-capable appliance base.
2. Treat the Diretta renderer as an optional payload path governed by official terms.
3. Use the vendored `DirettaHostSDK_149` path as the primary SDK validation target.
4. Productize existing mature tuning controls into presets before adding too many new low-level knobs.
5. Prioritize Raspberry Pi 5 `k16` as the main board-pack validation line.

## Highest-priority implementation items

- Verify real builds with `DirettaHostSDK_149`
- Turn current CPU/IRQ/SMT/MTU/RT/buffer controls into explicit presets
- Implement raw PCM fast path as the top hot-path optimization candidate
- Tighten Pi 5 board-pack, onboarding, and payload authorization flow
- Expand deeper host-level tuning only after lab qualification

## References

- `docs/IMAGE_PLATFORM.md`
- `docs/DIRETTA_VENDOR_ASSETS.md`
- `image/common/presets/`
- `image/boards/raspberry-pi-5/`
- `C:/Users/Administrator/.claude/plans/pi4-5-cm-os-buzzing-fox.md` (authoring source)
