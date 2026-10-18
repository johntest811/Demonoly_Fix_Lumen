# Demonologist MX Settings Helper

An unofficial, reversible Windows settings helper for trying to run
**Demonologist** on older NVIDIA MX-series laptop graphics cards.

This is an experimental configuration workaround. It cannot add missing GPU
features, guarantee playable performance, or replace lighting data that the game
does not provide. Demonologist currently lists a GTX 1060 6 GB as its minimum
graphics card.

## Download and use

1. Download [`Demonologist-MX.zip`](./Demonologist-MX.zip).
2. Extract the entire ZIP to a normal folder.
3. Launch Demonologist once, then close it completely.
4. Double-click `Run.cmd`.
5. Start with option **1 — Software Lumen**.
6. Launch the game normally through Steam and test the same map and room.

If performance remains poor, try 1280 × 720 in the game's display settings.
Do not run the helper while the game is open.

## Modes

- **Software Lumen:** keeps indirect lighting, disables hardware ray tracing and
  Lumen reflections, lowers other graphics settings, requests 70% render scale,
  and caps the game at 30 FPS.
- **Lumen off:** disables Lumen global illumination too. This can improve
  performance, but rooms may become too dark or incorrectly lit.
- **Restore:** restores both configuration files from the backup made before the
  most recent application.

The helper edits only `Engine.ini` and `GameUserSettings.ini` in the game's local
configuration folder. It preserves unrelated settings and creates a backup
before every application. It does not change drivers, the Windows registry,
game binaries, save files, or Steam launch settings.

## Important limitations

- Results depend on the exact MX model, VRAM, driver, and game version.
- Software Lumen still requires compatible hardware and distance-field data
  included by the developer.
- Disabling Lumen can break the intended appearance of maps that have no
  suitable fallback lighting.
- Game updates or graphics-menu changes may overwrite these settings.
- If lighting worsens, the game crashes, or performance drops, run the helper
  again and choose **Restore**.
- Remove manually added `-dx11` or `-d3d11` Steam launch options before testing
  Software Lumen with the game's default renderer. Restore previous settings if
  the default renderer will not launch.

## Source files

The readable source is in [`Demonologist-MX`](./Demonologist-MX):

- `Run.cmd` starts the helper with Windows PowerShell.
- `Settings.ps1` detects the game configuration, backs it up, applies a selected
  profile, and provides restoration.
- `README.txt` is the offline documentation included in the ZIP.

The configuration and restoration behavior was tested with isolated temporary
INI files. Actual performance and rendering have not been tested on the target
MX laptop.

## References

- [Demonologist system requirements on Steam](https://store.steampowered.com/app/1929610/Demonologist/)
- [Unreal Engine Lumen Performance Guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-performance-guide-for-unreal-engine)
- [Unreal Engine Lumen Technical Details](https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-technical-details-in-unreal-engine)

This project is not affiliated with Clock Wizard Games, Epic Games, NVIDIA, or
Valve.
