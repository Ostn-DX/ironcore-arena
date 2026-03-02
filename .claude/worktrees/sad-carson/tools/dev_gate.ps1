# Ironcore Arena Development Gate
# Validates vault, context packs, and build before committing
#
# Usage: .\tools\dev_gate.ps1 [-SkipGodot]
# Returns: Exit code 0 on pass, nonzero on failure
#
# Stages:
#   0 - Vault validation (frontmatter)
#   1 - Headless match tests (Godot)
#   2 - UI smoke tests (Godot)
#
# Exit codes:
#   0 - All stages passed
#   1 - Stage failure
#   2 - Vault validation failure

param(
    [switch]$SkipGodot
)

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[91m"
$Green = "`e[92m"
$Yellow = "`e[93m"
$Reset = "`e[0m"

function Write-Status($message, $status) {
    if ($status -eq "PASS") {
        Write-Host "${Green}[OK]${Reset} $message"
    } elseif ($status -eq "FAIL") {
        Write-Host "${Red}[FAIL]${Reset} $message"
    } elseif ($status -eq "INFO") {
        Write-Host "${Yellow}->${Reset} $message"
    }
}

# Get script directory and repo root FIRST (needed for all stages)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

Write-Status "Repository root: $repoRoot" "INFO"

# =============================================================================
# STAGE 0: Vault Validation (always runs — cannot be skipped)
# =============================================================================
Write-Status "STAGE 0: Running vault validation..." "INFO"

$pythonCmd = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
}

if (-not $pythonCmd) {
    Write-Status "Python not found — vault validation requires Python" "FAIL"
    exit 2
}

& $pythonCmd (Join-Path $scriptDir "validate_vault.py")

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Status "STAGE 0: VAULT VALIDATION FAILED (exit code $LASTEXITCODE)" "FAIL"
    Write-Status "Fix frontmatter errors before proceeding" "FAIL"
    exit 2
}

Write-Host ""
Write-Status "STAGE 0: VAULT VALIDATION PASSED" "PASS"
Write-Host ""

# =============================================================================
# Godot stages (can be skipped with -SkipGodot for CI/vault-only checks)
# =============================================================================
if ($SkipGodot) {
    Write-Status "Godot stages skipped (-SkipGodot flag)" "INFO"
    Write-Host ""
    Write-Host "================================"
    Write-Status "DEVELOPMENT GATE: PASSED (vault-only mode)" "PASS"
    Write-Host "================================"
    exit 0
}

# Find Godot executable
$GODOT = $null
$possiblePaths = @(
    "godot",
    "godot4",
    "C:\Program Files\Godot\Godot_v4.exe",
    "C:\Program Files (x86)\Godot\Godot_v4.exe",
    "$env:LOCALAPPDATA\Godot\Godot_v4.exe",
    "$env:USERPROFILE\Downloads\Godot_v4.exe"
)

foreach ($path in $possiblePaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $GODOT = $path
        break
    }
    if (Test-Path $path) {
        $GODOT = $path
        break
    }
}

if (-not $GODOT) {
    Write-Status "Godot executable not found in PATH or common locations" "FAIL"
    Write-Host "Please install Godot 4.x and add it to PATH"
    Write-Host "Or use -SkipGodot for vault-only validation"
    exit 1
}

Write-Status "Using Godot: $GODOT" "INFO"

# Create reports directory
$reportsDir = Join-Path $repoRoot "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
}

# Get project path
$projectPath = Join-Path $repoRoot "project"
if (-not (Test-Path $projectPath)) {
    $projectPath = $repoRoot
}

Write-Status "Project path: $projectPath" "INFO"
Write-Host ""

# Change to project directory
Push-Location $projectPath

# =============================================================================
# STAGE 1: Headless Match Tests
# =============================================================================
Write-Status "STAGE 1: Running headless match tests..." "INFO"

$matchReportPath = Join-Path $reportsDir "match_report.json"
if (Test-Path $matchReportPath) {
    Remove-Item $matchReportPath -Force
}

# Run headless matches
& $GODOT --headless --script "res://tools/run_headless_matches.gd" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Status "Headless match tests FAILED" "FAIL"
    Write-Status "Exit code: $LASTEXITCODE" "FAIL"
    
    if (Test-Path $matchReportPath) {
        Write-Status "Report: $matchReportPath" "INFO"
    }
    
    Pop-Location
    exit 1
}

# Verify report was created
if (-not (Test-Path $matchReportPath)) {
    Write-Host ""
    Write-Status "Match report not found at expected location" "FAIL"
    Write-Status "Expected: $matchReportPath" "FAIL"
    Pop-Location
    exit 1
}

# Parse report for summary
try {
    $matchReport = Get-Content $matchReportPath | ConvertFrom-Json
    $crashCount = $matchReport.crashes
    $timeoutCount = $matchReport.timeouts
    $avgDuration = $matchReport.average_duration_seconds
    
    Write-Status "Matches completed: $($matchReport.total_matches)" "INFO"
    Write-Status "Crashes: $crashCount" $(if ($crashCount -eq 0) { "PASS" } else { "FAIL" })
    Write-Status "Timeouts: $timeoutCount" $(if ($timeoutCount -eq 0) { "PASS" } else { "INFO" })
    Write-Status "Avg duration: $([math]::Round($avgDuration, 2))s" "INFO"
    
    if ($crashCount -gt 0) {
        Write-Host ""
        Write-Status "Headless match tests FAILED (crashes detected)" "FAIL"
        Pop-Location
        exit 1
    }
} catch {
    Write-Status "Failed to parse match report: $_" "FAIL"
    Pop-Location
    exit 1
}

Write-Host ""
Write-Status "STAGE 1: PASSED [OK]" "PASS"
Write-Host ""

# =============================================================================
# STAGE 2: UI Smoke Tests
# =============================================================================
Write-Status "STAGE 2: Running UI smoke tests..." "INFO"

$uiReportPath = Join-Path $reportsDir "ui_smoke.json"
if (Test-Path $uiReportPath) {
    Remove-Item $uiReportPath -Force
}

# Run UI smoke tests
& $GODOT --headless --script "res://tools/run_ui_smoke.gd" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Status "UI smoke tests FAILED" "FAIL"
    Write-Status "Exit code: $LASTEXITCODE" "FAIL"
    
    if (Test-Path $uiReportPath) {
        Write-Status "Report: $uiReportPath" "INFO"
    }
    
    Pop-Location
    exit 1
}

# Verify report was created
if (-not (Test-Path $uiReportPath)) {
    Write-Host ""
    Write-Status "UI smoke report not found at expected location" "FAIL"
    Write-Status "Expected: $uiReportPath" "FAIL"
    Pop-Location
    exit 1
}

# Parse report for summary
try {
    $uiReport = Get-Content $uiReportPath | ConvertFrom-Json
    $passed = $uiReport.passed
    $failed = $uiReport.failed
    $successRate = $uiReport.success_rate
    
    Write-Status "Transitions passed: $passed" "INFO"
    Write-Status "Transitions failed: $failed" $(if ($failed -eq 0) { "PASS" } else { "FAIL" })
    Write-Status "Success rate: $([math]::Round($successRate * 100, 1))%" $(if ($successRate -eq 1.0) { "PASS" } else { "INFO" })
    
    if ($failed -gt 0) {
        Write-Host ""
        Write-Status "UI smoke tests FAILED" "FAIL"
        
        # Show failed transitions
        foreach ($transition in $uiReport.transitions) {
            if (-not $transition.success) {
                Write-Status "  $($transition.from) -> $($transition.to): $($transition.error)" "FAIL"
            }
        }
        
        Pop-Location
        exit 1
    }
} catch {
    Write-Status "Failed to parse UI smoke report: $_" "FAIL"
    Pop-Location
    exit 1
}

Write-Host ""
Write-Status "STAGE 2: PASSED [OK]" "PASS"
Write-Host ""

# =============================================================================
# FINAL SUMMARY
# =============================================================================
Pop-Location

Write-Host "================================"
Write-Status "DEVELOPMENT GATE: PASSED [OK]" "PASS"
Write-Host "================================"
Write-Host ""
Write-Status "Match tests: OK" "PASS"
Write-Status "UI smoke tests: OK" "PASS"
Write-Host ""
Write-Status "Build is safe to playtest and commit" "PASS"
Write-Host ""

exit 0
