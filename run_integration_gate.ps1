param(
    [string]$Godot = "C:\Users\yoimiya\Documents\Codex\2026-09-17\ban\work\engine\Godot_v4.7.2-stable_win64.exe",
    [switch]$SkipRender,
    [switch]$SkipExport
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$project = $PSScriptRoot

if (-not (Test-Path -LiteralPath $Godot)) {
    throw "Godot executable not found: $Godot"
}

function Invoke-GateStep {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    $argumentLine = ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + $_.Replace('"', '\"') + '"'
        } else {
            $_
        }
    }) -join " "
    $exitCode = -1
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $process = Start-Process `
            -FilePath $Godot `
            -ArgumentList $argumentLine `
            -WorkingDirectory $project `
            -Wait `
            -PassThru `
            -NoNewWindow
        $exitCode = $process.ExitCode
        if ($exitCode -ne -1) {
            break
        }
        Write-Warning "$Name returned process code -1; retrying once"
        Start-Sleep -Seconds 2
    }
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode"
    }
}

Invoke-GateStep "Godot script parse" @(
    "--headless",
    "--editor",
    "--quit",
    "--path", $project
)

Invoke-GateStep "Five-part contract check" @(
    "--headless",
    "--path", $project,
    "--script", "res://integration_check.gd"
)

Invoke-GateStep "Driving regression" @(
    "--headless",
    "--path", $project,
    "--script", "res://driving_audit.gd"
)

Invoke-GateStep "AI race audit" @(
    "--headless",
    "--path", $project,
    "--script", "res://ai_race_audit.gd"
)

$aiReport = Join-Path $project "AI_RACE_TEST_RESULTS.md"
if (-not (Test-Path -LiteralPath $aiReport)) {
    throw "AI race report was not generated"
}
if (Select-String -LiteralPath $aiReport -Pattern "All five AI finished: NO" -Quiet) {
    throw "AI race audit contains an unfinished race"
}

if (-not $SkipRender) {
    Invoke-GateStep "Quality budget audit" @(
        "--path", $project,
        "--script", "res://quality_audit.gd",
        "--resolution", "1280x800"
    )
    $qualityReport = Join-Path $project "qa\quality_report.txt"
    if (-not (Test-Path -LiteralPath $qualityReport)) {
        throw "Quality report was not generated"
    }
    $qualityLines = @(Get-Content -LiteralPath $qualityReport | Where-Object { $_ })
    if ($qualityLines.Count -lt 4) {
        throw "Quality report must contain a header and three tracks"
    }
    $qualityHeaders = $qualityLines[0] -split "`t"
    $trackColumn = [Array]::IndexOf($qualityHeaders, "track")
    $lightColumn = [Array]::IndexOf($qualityHeaders, "lights")
    $budgetColumn = [Array]::IndexOf($qualityHeaders, "light_budget")
    $violationColumn = [Array]::IndexOf($qualityHeaders, "violations")
    if ($trackColumn -lt 0 -or $lightColumn -lt 0 -or $budgetColumn -lt 0 -or $violationColumn -lt 0) {
        throw "Quality report header is missing required columns"
    }
    $qualityRows = @($qualityLines | Select-Object -Skip 1)
    if ($qualityRows.Count -ne 3) {
        throw "Quality report must contain three tracks"
    }
    foreach ($row in $qualityRows) {
        $columns = $row -split "`t"
        if ($columns.Count -le $violationColumn) {
            throw "Malformed quality report row: $row"
        }
        if ([int]$columns[$violationColumn] -ne 0) {
            throw "Track $($columns[$trackColumn]) has quality clearance violations"
        }
        if ([int]$columns[$lightColumn] -gt [int]$columns[$budgetColumn]) {
            throw "Track $($columns[$trackColumn]) exceeds its light budget"
        }
    }

    Invoke-GateStep "Race UI and audio audit" @(
        "--path", $project,
        "--script", "res://qa/race_ui_audit.gd",
        "--resolution", "1280x800"
    )
    $uiReport = Join-Path $project "qa\audio_test.txt"
    if (-not (Test-Path -LiteralPath $uiReport)) {
        throw "Race UI/audio report was not generated"
    }
    if (Select-String -LiteralPath $uiReport -Pattern "overflow=[1-9]|overlap=True" -Quiet) {
        throw "Race UI audit found overflow or overlap"
    }

    Invoke-GateStep "Visual render audit" @(
        "--path", $project,
        "--script", "res://art_audit.gd",
        "--resolution", "1280x800"
    )
}

Invoke-GateStep "Main scene smoke test" @(
    "--headless",
    "--path", $project,
    "--quit-after", "5"
)

if (-not $SkipExport) {
    Invoke-GateStep "Windows release export" @(
        "--headless",
        "--path", $project,
        "--export-release", "Windows Desktop"
    )
    $exe = Join-Path $project "Q版氮气竞速.exe"
    if (-not (Test-Path -LiteralPath $exe)) {
        throw "Exported executable was not generated"
    }
    $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
    if ($version -ne "2.8.0") {
        throw "Exported product version mismatch: $version"
    }
}

Write-Host ""
Write-Host "INTEGRATION GATE PASSED" -ForegroundColor Green
