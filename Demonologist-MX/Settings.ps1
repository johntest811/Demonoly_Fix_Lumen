param(
    [ValidateSet('Menu','SoftwareLumen','LumenOff','Restore','RestoreOriginal','Diagnose','Snapshot','Compare','LightingTest')][string]$Action = 'Menu',
    [string]$ConfigPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Set-IniValues([string]$Text, [string]$Section, $Values) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $remaining = @{}
    foreach ($key in $Values.Keys) { $remaining[$key] = $Values[$key] }
    $inside = $false
    $found = $false
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            if ($inside) {
                foreach ($key in @($remaining.Keys | Sort-Object)) { $lines.Add("$key=$($remaining[$key])") }
                $remaining.Clear()
            }
            $inside = $Matches[1] -ieq $Section
            if ($inside) { $found = $true }
        }
        if ($inside -and $line -match '^\s*([^;#=]+?)\s*=') {
            $key = $Matches[1].Trim()
            if ($Values.Contains($key)) {
                if ($remaining.ContainsKey($key)) {
                    $lines.Add("$key=$($remaining[$key])")
                    $remaining.Remove($key)
                }
                continue
            }
        }
        $lines.Add($line)
    }
    if (-not $found) { $lines.Add("[$Section]") }
    foreach ($key in @($remaining.Keys | Sort-Object)) { $lines.Add("$key=$($remaining[$key])") }
    return ($lines -join "`r`n")
}

function Read-Ini([string]$Path) {
    if (Test-Path -LiteralPath $Path) { return [IO.File]::ReadAllText($Path) }
    return ''
}

function Remove-IniKeys([string]$Text, [string]$Section, [string[]]$Keys) {
    $inside = $false
    $lines = foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*\[([^\]]+)\]\s*$') { $inside = $Matches[1] -ieq $Section }
        if ($inside -and $line -match '^\s*([^;#=]+?)\s*=' -and $Matches[1].Trim() -in $Keys) { continue }
        $line
    }
    return ($lines -join "`r`n")
}

try {
    Write-Host 'Demonologist MX settings helper v1.3 - experimental, reversible' -ForegroundColor Cyan
    Write-Host 'Close the game before applying or restoring. No administrator rights needed.'
    Write-Host 'MX130 2 GB: no verified lighting fix. For dark rooms after tweaks, use 4 first.' -ForegroundColor Yellow

    if (-not $ConfigPath) {
        $candidates = @(
            foreach ($game in @('Demonologist','Shivers')) {
                foreach ($platform in @('Windows','WindowsNoEditor')) {
                    $p = Join-Path $env:LOCALAPPDATA "$game\Saved\Config\$platform"
                    if ((Test-Path -LiteralPath (Join-Path $p 'GameUserSettings.ini')) -or
                        (Test-Path -LiteralPath (Join-Path $p 'MX-ConfigBaseline.json'))) { $p }
                }
            }
        )
        if ($candidates.Count -eq 1) { $ConfigPath = $candidates[0] }
        else {
            Write-Host 'Automatic detection was inconclusive. Existing candidates:'
            $candidates | ForEach-Object { Write-Host "  $_" }
            $ConfigPath = (Read-Host 'Paste the game config folder containing GameUserSettings.ini (blank cancels)').Trim('"')
            if (-not $ConfigPath) { exit 0 }
        }
    }
    $ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
    $userFile = Join-Path $ConfigPath 'GameUserSettings.ini'
    $engineFile = Join-Path $ConfigPath 'Engine.ini'
    $baselineFile = Join-Path $ConfigPath 'MX-ConfigBaseline.json'
    Write-Host "Settings folder: $ConfigPath"
    if ($Action -eq 'Menu') {
        Write-Host '1 - Try software Lumen: preserve indirect lighting, lower other costs'
        Write-Host '2 - Experimental Lumen OFF: may make rooms dark or incorrectly lit'
        Write-Host '3 - Restore settings from before the most recent application'
        Write-Host '4 - Recover EARLIEST backup (undo successive helper profiles)'
        Write-Host '5 - Save a local diagnostic report (no settings changes)'
        Write-Host '6 - Record current files BEFORE launching the game'
        Write-Host '7 - Check whether files changed AFTER launching the game'
        Write-Host '8 - Test corrected Lumen settings + config-section saving (experimental)'
        Write-Host 'Q - Exit'
        switch (Read-Host 'Choose') {
            '1' { $Action = 'SoftwareLumen' }
            '2' { $Action = 'LumenOff' }
            '3' { $Action = 'Restore' }
            '4' { $Action = 'RestoreOriginal' }
            '5' { $Action = 'Diagnose' }
            '6' { $Action = 'Snapshot' }
            '7' { $Action = 'Compare' }
            '8' { $Action = 'LightingTest' }
            default { exit 0 }
        }
    }
    if ($Action -in @('Snapshot','Compare')) {
        $state = @(
            foreach ($file in @($userFile,$engineFile)) {
                $exists = Test-Path -LiteralPath $file -PathType Leaf
                [pscustomobject]@{
                    Name = [IO.Path]::GetFileName($file)
                    Exists = $exists
                    Hash = if ($exists) { (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash } else { '' }
                }
            }
        )
        if ($Action -eq 'Snapshot') {
            if (@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessName -match '^(Demonologist|Shivers)(-|$)'
            }).Count -gt 0) { throw 'Close the game before recording the before-launch files.' }
            [IO.File]::WriteAllText($baselineFile, (ConvertTo-Json -InputObject $state))
            Write-Host 'Baseline recorded. Launch normally, then choose 7 while the game is open.' -ForegroundColor Green
            Write-Host 'Choose 7 again after exiting. Do not choose 6 again between comparisons.'
            exit 0
        }
        if (-not (Test-Path -LiteralPath $baselineFile -PathType Leaf)) {
            throw 'No baseline found. With the game closed, choose 6 before the next test launch.'
        }
        $before = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($baselineFile))
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add('Configuration comparison v1.2 - ' + (Get-Date -Format s))
        foreach ($item in $state) {
            $old = @($before | Where-Object { $_.Name -eq $item.Name })
            if ($old.Count -ne 1) { throw 'Invalid baseline. Record a new baseline with option 6.' }
            $status = if ($old[0].Exists -and -not $item.Exists) { 'MISSING now (present at baseline)' }
                elseif (-not $old[0].Exists -and $item.Exists) { 'CREATED since baseline' }
                elseif (-not $item.Exists) { 'ABSENT both times' }
                elseif ($old[0].Hash -eq $item.Hash) { 'UNCHANGED contents' }
                else { 'CHANGED contents (may include normal settings saves)' }
            $lines.Add($item.Name + ': ' + $status)
        }
        $lines.Add('This compares two points in time; it cannot identify the process responsible,')
        $lines.Add('detect temporary deletion followed by identical recreation, or prove settings were loaded.')
        $resultFile = Join-Path $ConfigPath ('MX-Comparison-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.txt')
        [IO.File]::WriteAllLines($resultFile, $lines)
        $lines | ForEach-Object { Write-Host $_ }
        Write-Host "Report saved: $resultFile"
        exit 0
    }
    if ($Action -eq 'Diagnose') {
        $report = [System.Collections.Generic.List[string]]::new()
        $report.Add('Demonologist helper v1.3 diagnostics - ' + (Get-Date -Format s))
        $report.Add('This report cannot confirm working Lumen or diagnose darkness from hardware alone.')
        $report.Add('Detected display adapters (presence does not prove the game uses this adapter):')
        try {
            foreach ($gpu in @(Get-CimInstance Win32_VideoController)) {
                $report.Add("  $($gpu.Name); driver $($gpu.DriverVersion)")
            }
        } catch { $report.Add('  Adapter query unavailable.') }
        foreach ($file in @($userFile,$engineFile)) {
            $report.Add([IO.Path]::GetFileName($file) + ':')
            if (Test-Path -LiteralPath $file) {
                $report.Add('  Modified: ' + (Get-Item -LiteralPath $file).LastWriteTime.ToString('s'))
                foreach ($line in ((Read-Ini $file) -split '\r?\n')) {
                    if ($line -match '^\s*\[(SystemSettings|ScalabilityGroups|SectionsToSave|/Script/Engine.GameUserSettings|/Script/Engine.RendererSettings)\]\s*$' -or
                        $line -match '^\s*(bCanSaveAllSections|sg\.[\w.]+|r\.(Lumen[\w.]*|DynamicGlobalIlluminationMethod|RayTracing[\w.]*|ScreenPercentage)|t\.MaxFPS|ResolutionSize[XY]|FullscreenMode)\s*=\s*[-\w.]+\s*$') {
                        $report.Add('  ' + $line.Trim())
                    }
                }
            } else { $report.Add('  Absent') }
        }
        $logDir = Join-Path (Split-Path (Split-Path $ConfigPath -Parent) -Parent) 'Logs'
        $logs = @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        $report.Add('Latest log: selected renderer/adapter lines (may describe a previous launch):')
        if ($logs.Count -gt 0) {
            $report.Add('  Log modified: ' + $logs[0].LastWriteTime.ToString('s'))
            $matches = @(Get-Content -LiteralPath $logs[0].FullName -Tail 20000 -ErrorAction SilentlyContinue |
                Where-Object { $_ -match 'Log(RHI|D3D11RHI|D3D12RHI):.*(Chosen D3D|Using.*(RHI|Adapter)|RHI Selected|Adapter Name|Feature Level|Shader Model)' } |
                Select-Object -Last 25)
            foreach ($line in $matches) { $report.Add($line.Replace($env:USERPROFILE, '<USERPROFILE>')) }
            if ($matches.Count -eq 0) { $report.Add('  No matching renderer lines. Shipping builds may omit them.') }
        } else { $report.Add('  No game logs found.') }
        $report.Add('Record separately: Steam launch options, game version, map, and whether flashlight lights nearby walls.')
        $reportFile = Join-Path $ConfigPath ('MX-Diagnostics-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.txt')
        [IO.File]::WriteAllLines($reportFile, $report)
        Write-Host "Report saved locally: $reportFile" -ForegroundColor Green
        Write-Host 'Review it before sharing. Nothing was uploaded; no game settings were changed.'
        exit 0
    }
    if (@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^(Demonologist|Shivers)(-|$)'
    }).Count -gt 0) { throw 'The game appears to be running. Close it and try again.' }
    if ($Action -in @('SoftwareLumen','LumenOff','LightingTest') -and -not (Test-Path -LiteralPath $userFile -PathType Leaf)) {
        throw 'GameUserSettings.ini was not found. Launch the game once, exit, and try again.'
    }
    foreach ($file in @($userFile,$engineFile)) {
        if ((Test-Path -LiteralPath $file) -and (Get-Item -LiteralPath $file).IsReadOnly) {
            throw "File is read-only: $file. Remove the read-only attribute before trying again."
        }
    }
    $backupRoot = Join-Path $ConfigPath 'MX-Settings-Backups'
    if ($Action -in @('Restore','RestoreOriginal')) {
        $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'complete.txt') } |
            Sort-Object Name -Descending)
        if ($backups.Count -eq 0) { throw 'No completed backup found.' }
        $backup = $backups[0].FullName
        if ($Action -eq 'RestoreOriginal') { $backup = $backups[-1].FullName }
        # Validate both sources before changing either destination.
        foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
            if (-not (Test-Path -LiteralPath (Join-Path $backup $name) -PathType Leaf) -and
                -not (Test-Path -LiteralPath (Join-Path $backup "$name.absent") -PathType Leaf)) {
                throw "Incomplete backup: $name"
            }
        }
        # Keep current settings separately so recovery does not alter the original backup order.
        $recovery = Join-Path $ConfigPath ('MX-Recovery-Snapshots\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
        New-Item -ItemType Directory -Path $recovery -Force | Out-Null
        foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
            $current = Join-Path $ConfigPath $name
            if (Test-Path -LiteralPath $current) { Copy-Item -LiteralPath $current -Destination (Join-Path $recovery $name) }
            else { [IO.File]::WriteAllText((Join-Path $recovery "$name.absent"), '') }
        }
        foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
            $source = Join-Path $backup $name
            $target = Join-Path $ConfigPath $name
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $target -Force }
            elseif (Test-Path -LiteralPath (Join-Path $backup "$name.absent")) {
                if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
            } else { throw "Incomplete backup: $name" }
        }
        Write-Host "Restored from: $backup" -ForegroundColor Green
        Write-Host "Pre-restore settings saved in: $recovery"
        if ($Action -eq 'RestoreOriginal') {
            Write-Host 'Recovered the earliest AVAILABLE backup. This may not be factory defaults.'
            Write-Host 'Record then remove custom Steam launch options to test the default renderer.'
            Write-Host 'If still dark, choose 5 after a test launch and share the report for diagnosis.'
        }
        Write-Host 'This restores both INI files, including any in-game settings changed since that backup.'
        exit 0
    }

    $userText = Read-Ini $userFile
    $engineText = Read-Ini $engineFile
    if ($Action -eq 'LightingTest') {
        # These engine CVars are not normally read from GameUserSettings.ini.
        # Remove only the matching keys there; preserve other sections/settings.
        $lighting = [ordered]@{
            'r.DynamicGlobalIlluminationMethod'='1'
            'r.Lumen.HardwareRayTracing'='0'
            'r.Lumen.DiffuseIndirect.Allow'='1'
            'r.Lumen.Reflections.Allow'='0'
            'sg.GlobalIlluminationQuality'='2'
            'r.ScreenPercentage'='70'
            't.MaxFPS'='30'
        }
        $oldKeys = @($lighting.Keys) + @('r.Lumen.Reflections.HardwareRayTracing',
            'r.Lumen.Radiosity.HardwareRayTracing','r.Lumen.SoftwareRayTracingMode')
        $userText = Remove-IniKeys $userText 'SystemSettings' $oldKeys
        $userText = Set-IniValues $userText 'ScalabilityGroups' ([ordered]@{
            'sg.GlobalIlluminationQuality'='2'; 'sg.ReflectionQuality'='0'
        })
        $engineText = Set-IniValues $engineText 'SystemSettings' $lighting
        # Engine versions differ in section saving. This is a persistence test,
        # not proof that this shipping build will retain or honor the overrides.
        $engineText = Set-IniValues $engineText 'SectionsToSave' ([ordered]@{'bCanSaveAllSections'='True'})
        $userText = Set-IniValues $userText 'SectionsToSave' ([ordered]@{'bCanSaveAllSections'='True'})
    } else {
    $gi = if ($Action -eq 'SoftwareLumen') { '2' } else { '0' }
    $allowGI = if ($Action -eq 'SoftwareLumen') { '1' } else { '0' }
    $scalability = [ordered]@{
        'sg.ResolutionQuality'='70'; 'sg.ViewDistanceQuality'='0'; 'sg.AntiAliasingQuality'='1'
        'sg.ShadowQuality'='0'; 'sg.GlobalIlluminationQuality'=$gi; 'sg.ReflectionQuality'='0'
        'sg.PostProcessQuality'='0'; 'sg.TextureQuality'='0'; 'sg.EffectsQuality'='0'
        'sg.FoliageQuality'='0'; 'sg.ShadingQuality'='0'
    }
    $userText = Set-IniValues $userText 'ScalabilityGroups' $scalability
    $engineText = Set-IniValues $engineText 'SystemSettings' ([ordered]@{
        'r.Lumen.HardwareRayTracing'='0'; 'r.Lumen.DiffuseIndirect.Allow'=$allowGI
        'r.Lumen.Reflections.Allow'='0'; 'r.ScreenPercentage'='70'; 't.MaxFPS'='30'
    })
    }

    $backup = Join-Path $backupRoot ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
        $source = Join-Path $ConfigPath $name
        if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $backup $name) }
        else { [IO.File]::WriteAllText((Join-Path $backup "$name.absent"), '') }
    }
    [IO.File]::WriteAllText((Join-Path $backup 'complete.txt'), $Action)
    try {
        $utf8 = [Text.UTF8Encoding]::new($false)
        [IO.File]::WriteAllText($userFile, $userText, $utf8)
        [IO.File]::WriteAllText($engineFile, $engineText, $utf8)
    } catch {
        foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
            $target = Join-Path $ConfigPath $name
            $source = Join-Path $backup $name
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $target -Force }
            elseif (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
        }
        throw
    }
    Write-Host "Applied $Action. Backup: $backup" -ForegroundColor Green
    if ($Action -eq 'LightingTest') {
        Write-Host 'Corrected settings written. This does NOT confirm working lighting on MX130.'
        Write-Host 'Choose 6 before launch, then 7 after launch and exit to check persistence.'
        Write-Host 'No file locks were set. Your resolution and other quality groups were preserved.'
    }
    Write-Host 'Launch through Steam normally. Test the same room before and after.'
    Write-Host 'Try 1280 x 720 in the game menu if performance remains poor.'
    Write-Host 'Software Lumen needs game-provided distance fields and compatible hardware.'
    Write-Host 'Settings may be ignored or reset by the game. No FPS or lighting fix is guaranteed.'
    Write-Host 'If lighting worsens or the game crashes, run this again and choose 3.'
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
