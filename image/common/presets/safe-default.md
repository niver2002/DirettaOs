# Safe default preset

This preset represents the intended commercial shipping baseline.

## Goals

- predictable startup,
- stable networking,
- conservative CPU/IRQ placement,
- supportable logging and recovery behavior,
- no irreversible or opaque system mutation.

## Expected tuning envelope

- runtime config through `/etc/default/diretta-renderer`,
- wrapper-managed priority and optional MTU overrides,
- no standalone tuner-script dependency,
- no lab-only kernel isolation assumptions.
