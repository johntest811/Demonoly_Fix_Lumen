param(
    [ValidateSet('Menu','SoftwareLumen','LumenOff','Restore')][string]$Action = 'Menu',
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

try {
    Write-Host 'Demonologist MX settings helper - experimental, reversible' -ForegroundColor Cyan
    Write-Host 'Close the game before applying or restoring. No administrator rights needed.'
    if (@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^(Demonologist|Shivers)(-|$)'
    }).Count -gt 0) { throw 'The game appears to be running. Close it and try again.' }

    if (-not $ConfigPath) {
        $candidates = @(
            foreach ($game in @('Demonologist','Shivers')) {
                foreach ($platform in @('Windows','WindowsNoEditor')) {
                    $p = Join-Path $env:LOCALAPPDATA "$game\Saved\Config\$platform"
                    if (Test-Path -LiteralPath (Join-Path $p 'GameUserSettings.ini')) { $p }
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
    if (-not (Test-Path -LiteralPath $userFile -PathType Leaf)) {
        throw 'GameUserSettings.ini was not found. Launch the game once, exit, and try again.'
    }
    Write-Host "Settings folder: $ConfigPath"
    if ($Action -eq 'Menu') {
        Write-Host '1 - Try software Lumen: preserve indirect lighting, lower other costs'
        Write-Host '2 - Experimental Lumen OFF: may make rooms dark or incorrectly lit'
        Write-Host '3 - Restore settings from before the most recent application'
        Write-Host 'Q - Exit'
        switch (Read-Host 'Choose') {
            '1' { $Action = 'SoftwareLumen' }
            '2' { $Action = 'LumenOff' }
            '3' { $Action = 'Restore' }
            default { exit 0 }
        }
    }
    foreach ($file in @($userFile,$engineFile)) {
        if ((Test-Path -LiteralPath $file) -and (Get-Item -LiteralPath $file).IsReadOnly) {
            throw "File is read-only: $file. Remove the read-only attribute before trying again."
        }
    }
    $backupRoot = Join-Path $ConfigPath 'MX-Settings-Backups'
    if ($Action -eq 'Restore') {
        $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'complete.txt') } |
            Sort-Object Name -Descending)
        if ($backups.Count -eq 0) { throw 'No completed backup found.' }
        $backup = $backups[0].FullName
        foreach ($name in @('GameUserSettings.ini','Engine.ini')) {
            $source = Join-Path $backup $name
            $target = Join-Path $ConfigPath $name
            if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $target -Force }
            elseif (Test-Path -LiteralPath (Join-Path $backup "$name.absent")) {
                if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
            } else { throw "Incomplete backup: $name" }
        }
        Write-Host "Restored from: $backup" -ForegroundColor Green
        Write-Host 'This restores both INI files, including any in-game settings changed since that backup.'
        exit 0
    }

    $userText = Read-Ini $userFile
    $engineText = Read-Ini $engineFile
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
    Write-Host 'Launch through Steam normally. Test the same room before and after.'
    Write-Host 'Try 1280 x 720 in the game menu if performance remains poor.'
    Write-Host 'Software Lumen needs game-provided distance fields and compatible hardware.'
    Write-Host 'Settings may be ignored or reset by the game. No FPS or lighting fix is guaranteed.'
    Write-Host 'If lighting worsens or the game crashes, run this again and choose 3.'
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
