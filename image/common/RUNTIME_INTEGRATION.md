# Runtime payload integration

This note defines how the existing renderer runtime should plug into the appliance image.

## Existing reusable assets

- Binary/service installation flow: `systemd/install-systemd.sh`
- Runtime wrapper and host-side policy: `systemd/start-renderer.sh`
- Mutable runtime config: `systemd/diretta-renderer.conf`
- Upgrade-aware config migration: `install.sh`
- Management UI service and profile model: `webui/`
- Partner/distributor packaging path: `scripts/make-minimal-tarball.sh`

## Product direction

The appliance path should treat the current runtime as a payload that is:

- installed into a known immutable app location,
- configured through `/etc/default/diretta-renderer`,
- managed by systemd,
- surfaced through product-aware web UI profiles,
- wrapped by image-specific onboarding, update, and recovery layers.

## Non-goals

The appliance image should not require end users to run `install.sh` interactively after flashing.
