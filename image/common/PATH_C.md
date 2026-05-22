# Path C delivery split

Path C means the repository advances along two deliberately separated tracks:

## Track 1 — Commercial appliance platform

This is the shippable, supportable base image program.
It is responsible for:

- board-qualified images,
- onboarding and recovery,
- signed updates,
- channel policy,
- supportability and product safety,
- image/release metadata.

This track must not assume Diretta bundling rights.

## Track 2 — Diretta personal-use payload

This is the existing renderer/runtime path based on the Diretta Host SDK.
Until licensing changes, it should be treated as:

- personal-use only,
- optional,
- post-install or lab/integration payload,
- compatible with a pre-deployed SDK model or a user-supplied SDK model,
- not a default commercial image promise.

## Practical rule

If an image is intended for commercial shipment, its default manifests, onboarding copy, and release metadata should all be valid without bundling the Diretta payload.
