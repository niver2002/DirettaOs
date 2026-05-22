# Generic appliance runtime contract

This file describes the runtime assumptions for a commercial-capable base image that does not require the Diretta payload to be bundled.

## Base image responsibilities

- boot into a validated board pack,
- expose onboarding and management entrypoints,
- persist platform state and recovery state,
- expose update and channel metadata,
- remain recoverable even when optional payloads are absent.

## Optional payload examples

- Diretta personal-use renderer payload,
- downstream partner payloads,
- lab-only integration packages.

## Rule

The base image must be coherent and supportable even when no optional audio payload is installed.
