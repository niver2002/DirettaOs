# Verification and recovery gates

This document defines the minimum product gates for appliance delivery.

## Legal gate

- confirm whether the Diretta payload may be commercially bundled,
- confirm redistribution rights,
- confirm support/warranty channel constraints.

## Board qualification gate

Per board pack:
- cold boot and warm reboot reliability,
- storage and recovery behavior,
- NIC discovery,
- Wi-Fi/Bluetooth onboarding path,
- thermal stability during long playback.

## Audio ceiling gate

Per validated preset:
- PCM ceiling,
- DSD ceiling,
- lossless/lossy stream regression,
- gapless,
- MTU and NIC variants,
- IRQ/CPU/SMT preset side effects.

## Product safety gate

- onboarding interruption recovery,
- degraded-mode management access,
- factory reset correctness,
- failed update rollback,
- bad config recovery.

## Upgrade compatibility gate

- renderer config migration,
- board-pack mismatch detection,
- 4K/16K mismatch handling,
- obsolete-key handling.
