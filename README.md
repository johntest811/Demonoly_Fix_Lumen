# Demonologist MX Settings Helper

An unofficial, reversible Windows settings helper for trying to run
**Demonologist** on older NVIDIA MX-series laptop graphics cards.

This is an experimental configuration workaround. It cannot add missing GPU
features, guarantee playable performance, or replace lighting data that the game
does not provide. Demonologist currently lists a GTX 1060 6 GB as its minimum
graphics card.

## MX130 2 GB: dark rooms after applying profiles

### v1.3: test misplaced or disappearing lighting overrides

Option **8** is a focused configuration test for files where `Engine.ini` lacks
lighting overrides but they have been placed under `[SystemSettings]` in
`GameUserSettings.ini`. It backs up both files, removes the matching misplaced
entries, and writes supported Lumen requests under `[SystemSettings]` in
`Engine.ini`. It requests Lumen GI, software tracing, High GI scalability,
disabled Lumen reflections, 70% render scale and a 30 FPS cap. Resolution and
other quality groups are preserved. This can cost more GPU time than Lumen off.

It also adds `[SectionsToSave] bCanSaveAllSections=True` to both files to test
Unreal's section-saving behavior. Whether this works in the game's particular
shipping build must be checked after launch and exit. It does not lock files,
change permissions, disable Steam Cloud or prove that Steam caused a rewrite.

Close the game, choose **8**, then **6** before launching. After playing and
exiting, choose **7** and **5**. Option **3** undoes the most recent application.
Persistence and lighting are separate checks: a retained setting can still be
ignored or unsupported. A helper success message confirms file writes only.
Do not use option 2 to repair dark rooms.

The code is tested for correct file placement, preservation, repeat application
and exact restoration. Actual lighting and persistence in Demonologist on MX130
remain unverified.

References: [Epic config-file API](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Core/FConfigFile)
and [Epic support discussion of saved config sections](https://forums.unrealengine.com/t/best-way-to-handle-different-plugin-that-handle-swapchain/2668193).

### Hardware and recovery

There is **no verified permanent lighting fix for the MX130** in this project.
Do not use Lumen off as a repair for dark rooms. It can remove the indirect
lighting those rooms need. The current Epic documentation lists a GTX 1070 or
higher for software Lumen; the MX130 is below that supported target. This alone
does not prove the cause of a particular rendering problem.

Download the updated ZIP, close the game, and choose **4 — Recover EARLIEST
backup**. This restores settings from before the first available helper backup,
even if you applied both profiles repeatedly. It cannot recover backups that
were deleted and does not guarantee those original settings had working lighting.
Current settings are preserved separately in `MX-Recovery-Snapshots` first.

Record then remove custom Steam launch options for a test with the game's
default renderer. Launch and check the same room with a flashlight. If it stays
dark, use **5 — Diagnostic report** and share the resulting text file along with
the game version and previous launch options. The report is saved locally in the
config folder; nothing is uploaded. It lists installed adapters, selected INI
values and available renderer lines from the latest game log. Adapter detection
alone does not identify the GPU actually used by the game.

If the game cannot provide correct lighting on this hardware, a lasting solution
requires a developer-supported lighting fallback or a computer that meets the
game's requirements. An INI file cannot create missing baked lighting or upgrade
the GPU.

## Download and use

### Suspected settings deletion or reset (v1.2)

The helper edits `Engine.ini` and `GameUserSettings.ini`; it does not install a
separate game profile. To check what happens to these files:

1. Close the game and choose **6** to record the current files.
2. Launch through Steam normally. With the game still open, run the helper again
   and choose **7**.
3. Exit the game and choose **7** again. Do not choose 6 between checks.
4. Share both comparison reports and the option 5 diagnostic report.

The reports distinguish missing files, changed contents and unchanged contents.
They cannot identify the process responsible or prove that the game loaded the
settings. Normal saves can change file contents too. Option 6 replaces the
comparison baseline only; neither option edits game settings. If testing an
applied profile, record the baseline after applying it and before launching.

Unreal can save user settings automatically; Steam Cloud can sync files selected
by the developer. We have not established which, if either, is responsible in
this game. Keeping an INI file on disk does not establish working Lumen support.

### Running a profile

1. Download [`Demonologist-MX.zip`](./Demonologist-MX.zip).
2. Extract the entire ZIP to a normal folder.
3. Launch Demonologist once, then close it completely.
4. Double-click `Run.cmd`.
5. For MX130 darkness after previous tweaks, choose **4**. Otherwise option
   **1 — Software Lumen** is an experimental performance/lighting tradeoff.
6. Launch the game normally through Steam and test the same map and room.

If performance remains poor, try 1280 × 720 in the game's display settings.
Do not run the helper while the game is open.

## Modes

- **Software Lumen:** requests indirect lighting, disables Lumen hardware tracing and
  Lumen reflections, lowers other graphics settings, requests 70% render scale,
  and caps the game at 30 FPS.
- **Lumen off:** disables Lumen global illumination too. This can improve
  performance, but rooms may become too dark or incorrectly lit.
- **Restore:** restores both configuration files from the backup made before the
  most recent application.
- **Recover earliest backup:** restores both files from the earliest available
  helper backup, undoing successive profiles.
- **Diagnostic report:** records configuration and available GPU/renderer details
  without changing settings.

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
