# Onboarding state contract

This file documents the intended first-boot state flow for the appliance image.

## States

- `factory-new` — image has never been provisioned.
- `onboarding-required` — management endpoint is available, user setup pending.
- `network-setup` — onboarding is collecting or validating network settings.
- `target-validation` — runtime prerequisites and target reachability are being checked.
- `preset-selection` — safe/performance/lab preset selection.
- `operational` — onboarding complete; normal management UI is primary.
- `degraded` — renderer unavailable but recovery/management still available.
- `recovery` — explicit recovery/reset workflow in progress.

## Persistence

The first implementation should persist a simple state marker under `/etc/diretta-appliance/` and keep renderer runtime config separate in `/etc/default/diretta-renderer`.
