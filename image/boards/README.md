# Board packs

Each subdirectory in `boards/` represents a board-qualified delivery target.

A board pack should eventually define:

- exact board/carrier identity,
- kernel/page-size expectations,
- storage and recovery assumptions,
- NIC/Wi-Fi/Bluetooth hardware assumptions,
- validated tuning presets,
- onboarding defaults,
- update eligibility,
- qualification status.

## Launch discipline

Do not treat SoC family support as sufficient.
A commercial image should only ship against named, qualified board packs.
