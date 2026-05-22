# Base image composition

A Path C base image should eventually include:

- board-pack selection,
- onboarding and state persistence,
- recovery and update entrypoints,
- manifests and channel metadata,
- support bundle plumbing,
- optional payload hooks.

It should not require the Diretta runtime to be present in order to boot, onboard, or recover.
