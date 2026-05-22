# Commercial Appliance Platform

This directory is the root of the appliance/image delivery program for DirettaRendererUPnP-derived systems.

## Purpose

The existing repository already contains:

- an installable renderer payload,
- systemd service integration,
- a lightweight management web UI,
- configuration migration logic,
- downstream distribution artifacts,
- and advanced audio-tuning controls.

The `image/` tree is where those pieces are assembled into a board-qualified, recoverable, updatable appliance platform.

## Commercial gate

Before shipping any Diretta-enabled commercial SKU, confirm the Diretta Host SDK licensing terms. The repository README states that the SDK is licensed for personal use only and that commercial use is prohibited.

## Path C delivery split

This tree now follows Path C:

- a commercial-capable appliance base image that stands on its own,
- an optional Diretta personal-use payload path that is not assumed to be part of a commercial default image.

That means platform manifests, onboarding, and recovery flows should all remain coherent even when the Diretta payload is absent.

## Layout

- `common/` — shared image-building, packaging, runtime, and policy assets.
- `boards/` — board-pack definitions and per-board defaults.
- `onboarding/` — first-boot state machine, profiles, templates, and UI assets.
- `recovery/` — reset, support bundle, and field-recovery workflows.
- `updates/` — update metadata, channel policy, and rollback scaffolding.
- `manifests/` — board/image/release manifests for signing and qualification.

## Product model

The intended delivery model is:

1. a flagship appliance image,
2. a reusable runtime payload/integration path for partners,
3. per-board qualification instead of broad family-level support claims,
4. a single supported tuning path centered on `systemd/start-renderer.sh`.

