# Payload installation lane

This note describes the role of the existing Diretta runtime in Path C.

## Status

- optional post-install payload
- personal-use only unless licensing changes
- suitable for lab, partner integration, or explicit user-side installation flows
- compatible with a user-supplied or pre-deployed SDK model

## Pre-deployed SDK + user authorization flow

A valid operating model is:

1. the software platform is installed or flashed,
2. the SDK is already present on the target system as a pre-deployed dependency,
3. the install/onboarding flow explicitly tells the user that actual use depends on the official Diretta terms,
4. the user chooses and completes the applicable official authorization path (for example free/personal-use or any other official path made available by Diretta),
5. the payload install path then wires the runtime into the platform.

This project should not claim to grant authorization itself; it can only surface the step and require user acknowledgement.

## Existing reusable hooks

- `install.sh`
- `systemd/install-systemd.sh`
- `systemd/uninstall-systemd.sh`
- `scripts/make-minimal-tarball.sh`
