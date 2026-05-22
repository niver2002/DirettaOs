# Shared appliance assets

This directory is for components reused across all board packs:

- image build helpers,
- runtime payload integration,
- service policy,
- tuning presets,
- signing/update metadata templates,
- shared recovery hooks.

## Design rule

The supported runtime-tuning contract should converge on:

- `/etc/default/diretta-renderer` for persisted mutable policy,
- `systemd/start-renderer.sh` for host-side orchestration,
- profile-driven web UI surfaces for safe and performance presets.

Standalone tuner scripts remain useful as engineering references, but the appliance product path should not require end users to run them directly.
