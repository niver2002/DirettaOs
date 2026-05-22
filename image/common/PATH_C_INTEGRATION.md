# Path C integration note

The current installer and service assets are still oriented around the Diretta runtime.
Under Path C, they should be interpreted as the optional payload-install lane, not the definition of the base commercial image.

## Meaning

- `install.sh` remains useful for payload installation and migration.
- `systemd/install-systemd.sh` remains useful for personal-use or lab deployment.
- The future base image should be valid before these payload steps run.

## Practical consequence

Board packs, onboarding, update flows, and recovery policy should not assume that `diretta-renderer.service` is always present on a commercial base image.
