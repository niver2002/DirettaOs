# Appliance architecture notes

This repository now contains the initial scaffold for a commercial-capable appliance platform under `image/`.

## Delivery mode: Path C

The repository is currently aligned to **Path C**:

- a **commercial-capable base appliance platform** that is valid on its own, and
- a **Diretta personal-use payload** treated as optional post-install or lab/integration functionality.

This split exists because the repository documents the Diretta Host SDK as personal-use-only.

## SDK supply model

The intended integration model is now:

- this project ships the software platform and optional payload integration path,
- the SDK may be either pre-deployed with the target environment or supplied separately from the official Diretta channel,
- the install/onboarding flow must explicitly tell the user that actual use depends on the official Diretta terms,
- the user must choose and complete the applicable official authorization path before real use.

That keeps the software platform and the official SDK authorization flow separate, while still allowing a pre-deployed SDK operational model.

## Key design choices

1. **Commercial license gate first**
   - The Diretta Host SDK is documented as personal-use-only.
   - The appliance platform can advance independently, but a Diretta commercial SKU requires separate legal clearance.

2. **Board-pack delivery model**
   - Delivery should target named, qualified board packs rather than broad SoC-family claims.

3. **Single supported tuning path**
   - The supported tuning contract should converge on:
     - `/etc/default/diretta-renderer`
     - `systemd/start-renderer.sh`
     - product-aware UI profiles
   - Standalone tuner scripts remain engineering references, not end-user defaults.

4. **Image-first product model**
   - Appliance image is the flagship delivery artifact.
   - Minimal tarball/runtime payload remains useful for downstream integrators and lab use.

5. **Onboarding as state machine**
   - First boot should be distinct from the existing runtime config editor.

## Initial scaffold

- `image/README.md`
- `image/common/`
- `image/boards/`
- `image/onboarding/`
- `image/recovery/`
- `image/updates/`
- `image/manifests/`

This is a structural starting point, not yet a complete image implementation.
