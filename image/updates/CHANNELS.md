# Update channel model

This document is a scaffold for appliance update policy.

## Required channels

- `stable`
- `beta`
- `lab`

## Intended behavior

- stable: only qualified board packs and validated presets
- beta: pre-release board-pack and update candidates
- lab: experimental tuning and platform work not suitable for default deployment

## Future metadata

Each release should eventually declare:

- channel,
- board-pack compatibility,
- required migration level,
- rollback compatibility,
- signing status.
