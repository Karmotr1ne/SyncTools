## What the tool does

**Two-way copy** with `robocopy`: copies **newer files only** in both directions (A→B, B→A), **never deletes**, and skips common junk files; logs to `logs/`.

# Simple Two-Way Sync — Setup & Usage

This is a **minimal two-way sync** (copy newer files both directions, never delete) using three files:

- `RunSync.bat` — main entry (you can edit A/B paths or pass them as arguments)
    
- `Sync.ps1` — core logic
    
- `LaunchIfExists.bat` — **stable launcher kept on C drive** that calls `RunSync.bat` (which can live anywhere)

## Placement Model

- Keep **`LaunchIfExists.bat` at a stable C path**, e.g.  
    `C:\Users\Administrator\Scripts\LaunchIfExists.bat`
    
- Keep the **actual sync tool** anywhere else (e.g. a portable/workspace drive):  
    `E:\Work Space\Code Project\SyncTools\RunSync.bat`  
    `E:\Work Space\Code Project\SyncTools\Sync.ps1`
    
## Create the Scheduled Task

Open **CMD** and run:

-``schtasks /create /tn AutoSync_Startup /tr "C:\Users\Administrator\Scripts\LaunchIfExists.bat" /sc onlogon /rl highest /f``

-``schtasks /create /tn AutoSync_Every30Min /tr "C:\Users\Administrator\Scripts\LaunchIfExists.bat" /sc minute /mo 30 /rl highest /f``

-``schtasks /run /tn AutoSync_Every30Min``

