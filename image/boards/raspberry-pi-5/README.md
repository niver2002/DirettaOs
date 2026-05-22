# Raspberry Pi 5 board pack

Status: draft scaffold

## Intended role

Primary flagship board pack candidate for the appliance image program.

## Known repo-aligned constraints

- ARM64 is supported.
- The project documentation and helper scripts distinguish between standard and `k16` SDK variants.
- Newer ARM64 kernels are associated with the `aarch64-linux-15k16` recommendation.

## Board-pack responsibilities

This pack should eventually define:

- exact storage/boot assumptions,
- kernel and page-size expectations,
- network interface defaults,
- validated safe/performance presets,
- onboarding defaults,
- recovery and update support status.
