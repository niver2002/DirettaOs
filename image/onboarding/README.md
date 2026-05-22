# Onboarding platform

This directory is for first-boot setup and ongoing product-management entrypoints.

## Required states

The appliance onboarding flow should evolve into a state machine with states such as:

- `factory-new`
- `onboarding-required`
- `network-setup`
- `target-validation`
- `preset-selection`
- `operational`
- `degraded`
- `recovery`

## Scope

Onboarding is distinct from the existing renderer configuration UI.
The current web UI edits runtime config and restarts services; this layer should instead own:

- first-boot detection,
- guided setup,
- validation,
- state persistence,
- handoff to the ongoing management UI.
