# studio_run.ps1 - One-command pipeline: ticket -> route -> pack -> verify -> execute -> gate -> audit
#
# Usage:
#   .\tools\studio_run.ps1 -Ticket agents\tickets\TICKET-0001.md
#
# Exit codes:
#   0 - Full pipeline passed
#   1 - Usage error
#   2+ - Propagated from first failing step

param(
    [Parameter(Mandatory=$true)]
    [string]$Ticket
)

$ErrorActionPreference = "Stop"

# Colors
$Red = "`e[91m"
$Green = "`e[92m"
$Yellow = "`e[93m"
$Cyan = "`e[96m"
$Reset = "`e[0m"

function Write-Pass($msg)   { Write-Host "${Green}[OK]${Reset}   $msg" }
function Write-Fail($msg)   { Write-Host "${Red}[FAIL]${Reset} $msg" }
function Write-Info($msg)   { Write-Host "${Yellow}->  ${Reset} $msg" }
function Write-Header($msg) { Write-Host "${Cyan}=== $msg ===${Reset}" }

# ── Validate ticket path ─────────────────────────────────────────────────────
if (-not (Test-Path $Ticket)) {
    Write-Fail "Ticket file not found: $Ticket"
    exit 1
}

# ── Locate tools ─────────────────────────────────────────────────────────────
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Find Python
$pythonCmd = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pythonCmd = "python"
} elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
    $pythonCmd = "python3"
}

if (-not $pythonCmd) {
    Write-Fail "Python not found in PATH"
    exit 1
}

Write-Host ""
Write-Header "studio_run.ps1"
Write-Info "Ticket: $Ticket"
Write-Info "Python: $pythonCmd"
Write-Info "Repo:   $repoRoot"
Write-Host ""

# ── Extract ticket ID ─────────────────────────────────────────────────────────
$ticketId = & $pythonCmd -c @"
import sys, re
with open(r'$Ticket', 'r', encoding='utf-8') as f:
    content = f.read()
if content.startswith('---'):
    try:
        import yaml
        parts = content.split('---', 2)
        fm = yaml.safe_load(parts[1])
        print(fm.get('ticket', ''))
    except:
        m = re.search(r'ticket:\s*(\S+)', content)
        if m: print(m.group(1))
else:
    m = re.search(r'## ID\s*\n([A-Z0-9][-A-Z0-9_]+)', content)
    if m: print(m.group(1))
"@

if ([string]::IsNullOrWhiteSpace($ticketId)) {
    Write-Fail "Could not extract ticket ID from: $Ticket"
    exit 1
}
Write-Info "Ticket ID: $ticketId"
Write-Host ""

# ── Helper: run step with exit code propagation ─────────────────────────────
$global:stepNum = 0

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    $global:stepNum++
    Write-Info "[$($global:stepNum)] $Name"

    & $Command

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$Name (exit $LASTEXITCODE)"
        Write-Host ""
        Write-Fail "Pipeline stopped at step $($global:stepNum): $Name"
        exit $LASTEXITCODE
    }
    Write-Pass "$Name"
    Write-Host ""
}

# ── Pipeline steps ────────────────────────────────────────────────────────────

Run-Step "validate_vault" {
    & $pythonCmd (Join-Path $scriptDir "validate_vault.py")
}

Run-Step "validate_configs" {
    & $pythonCmd (Join-Path $scriptDir "validate_configs.py")
}

Run-Step "route_ticket" {
    & $pythonCmd (Join-Path $scriptDir "route_ticket.py") --ticket $Ticket
}

Run-Step "build_context_pack" {
    & $pythonCmd (Join-Path $scriptDir "build_context_pack.py") $Ticket
}

Run-Step "require_context_pack" {
    & $pythonCmd (Join-Path $scriptDir "require_context_pack.py") $ticketId
}

Run-Step "verify_manifest" {
    & $pythonCmd (Join-Path $scriptDir "verify_manifest.py") $ticketId
}

Run-Step "run_ticket" {
    & $pythonCmd (Join-Path $scriptDir "run_ticket.py") --ticket $Ticket
}

Run-Step "dev_gate" {
    & (Join-Path $scriptDir "dev_gate.ps1") -SkipGodot
}

Run-Step "studio_audit" {
    & $pythonCmd (Join-Path $scriptDir "studio_audit.py")
}

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Header "PIPELINE COMPLETE"
Write-Pass "All $($global:stepNum) steps passed for $ticketId"
Write-Host ""
exit 0
