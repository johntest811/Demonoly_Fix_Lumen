DEMONOLOGIST MX SETTINGS HELPER

VERSION 1.1 - MX130 DARK-ROOM RECOVERY
There is no verified permanent lighting fix for the MX130 2 GB in this tool.
Do not use option 2 to fix dark rooms: disabling Lumen can remove needed lighting.
If previous profiles made lighting worse, close the game and choose 4.
Option 4 restores the EARLIEST available helper backup, even after repeated
profile changes. It is not necessarily factory defaults or working lighting.
Before restoring, the tool saves current files in MX-Recovery-Snapshots.
Record then remove custom Steam launch options and test the default renderer.
If still dark, choose 5 after a test launch and share the generated diagnostic
text file, game version, prior launch options, and whether a flashlight lights
nearby walls. The report is saved in the game config folder; nothing is uploaded.
It records adapters, selected graphics settings, and available renderer log lines.
Installed adapter names do not prove which GPU the game actually used.

Epic's current software Lumen documentation lists GTX 1070 or higher, and the
game lists GTX 1060 6 GB minimum. MX130 is below these supported targets.
A permanent solution may require a developer-provided lighting fallback or
a computer that meets the requirements. INI changes cannot create missing light
maps, add GPU capabilities, or guarantee that this game honors the overrides.

Extract the whole ZIP to a folder on your friend's Windows PC.
Launch Demonologist once, then fully exit it. Double-click Run.cmd.
For MX130 darkness after tweaks, choose 4 first. Launch through Steam afterward.
The helper needs no installation, internet, or administrator access.
Run.cmd uses Windows PowerShell with execution policy bypass for this process
only; it does not change the machine's execution policy.

WHAT IT DOES
1: Requests software Lumen GI (High GI scalability), disables Lumen reflections,
   lowers other scalability groups, requests 70% render resolution and a 30 FPS
   cap. The cap improves consistency only when the GPU can sustain 30 FPS.
   This can be SLOWER than existing settings if Lumen was previously disabled.
2: Also disables Lumen GI. This is an experimental performance tradeoff:
   rooms can become dark or incorrectly lit if the game lacks fallback lighting.
3: Restores both INI files from before the most recent application. Repeating
   Restore restores that same backup; it does not walk backward through history.
   Older backups remain in MX-Settings-Backups inside the config folder.
4: Restores both files from the earliest available helper backup.
5: Saves local diagnostics without changing game settings.

Only Engine.ini and GameUserSettings.ini are edited. Existing unrelated keys
are preserved. Every application backs up both originals first; missing files
are recorded so Restore can remove an Engine.ini created by this helper.
Restore also undoes any other changes to those INI files since the backup.
Savegames, binaries, drivers, registry, and Steam launch settings are untouched.
No settings have been applied to the computer where this package was created.

If detection fails, supply the actual game configuration folder containing
GameUserSettings.ini. The helper checks existing Demonologist and Shivers
folders under %LOCALAPPDATA%, with Saved\Config\Windows or WindowsNoEditor.
Do not select another game's folder. If several candidates appear, use the one
whose GameUserSettings.ini changed when you last saved this game's settings.

LIMITS / TROUBLESHOOTING
This is a settings workaround, not a permanent engine or hardware repair.
Demonologist lists a GTX 1060 6 GB minimum. An unspecified old MX laptop GPU
cannot be promised playable performance. Software Lumen still needs supported
hardware and distance-field data shipped by the developer. INI edits cannot
generate that data or restore missing baked lighting. The game can ignore
overrides or overwrite settings after graphics-menu changes or updates.

For software Lumen, remove any manually added -dx11 or -d3d11 Steam launch
option before testing the game's default renderer. This helper does not force
DX12: support depends on the exact card, driver, and game build. If default
launch fails, restore the settings and previous launch options.
Try a 1280 x 720 display resolution in-game. Test the same map and room.
Plug the laptop into power; select the NVIDIA GPU for the game in Windows
Graphics settings if it is mistakenly using integrated graphics.
If rooms become black, option 2 is not a lighting repair. Restore with option 3.
Tell the author the exact MX model, VRAM, and whether the symptom is low FPS,
dark rooms, flickering, or a crash to tailor further troubleshooting.

VALIDATION
Script behavior is tested against temporary INI fixtures, including backups,
repeat application, profile switching and restoration. Actual game rendering
and performance have NOT been tested on your friend's laptop.

REFERENCES (checked 2026-10-18)
https://store.steampowered.com/app/1929610/Demonologist/
https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-performance-guide-for-unreal-engine
https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-technical-details-in-unreal-engine
https://gpuopen.com/learn/unreal-engine-performance-guide/

Developer documentation describes engine capabilities; it does not establish
which settings this specific shipping game build honors.
