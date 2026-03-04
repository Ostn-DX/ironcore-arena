#!/bin/bash
# studio_run.sh - One-command pipeline: ticket -> route -> pack -> verify -> execute -> gate -> audit
#
# Usage:
#   ./tools/studio_run.sh agents/tickets/TICKET-0001.md
#
# Exit codes:
#   0 - Full pipeline passed
#   1 - Usage error
#   2+ - Propagated from first failing step

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass()  { echo -e "${GREEN}[OK]${NC}   $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
info()  { echo -e "${YELLOW}->  ${NC} $1"; }
header(){ echo -e "${CYAN}=== $1 ===${NC}"; }

# ── Args ──────────────────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo "Usage: ./tools/studio_run.sh <ticket.md>"
    echo ""
    echo "Runs the full enforcement pipeline:"
    echo "  1. validate_vault.py"
    echo "  2. route_ticket.py"
    echo "  3. build_context_pack.py"
    echo "  4. require_context_pack.py"
    echo "  5. verify_manifest.py"
    echo "  6. run_ticket.py"
    echo "  7. dev_gate.sh --skip-godot"
    echo "  8. studio_audit.py"
    exit 1
fi

TICKET_PATH="$1"

if [ ! -f "$TICKET_PATH" ]; then
    fail "Ticket file not found: $TICKET_PATH"
    exit 1
fi

# ── Locate tools ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Find Python
PYTHON=""
for pycmd in python3 python py; do
    if command -v "$pycmd" &> /dev/null; then
        if "$pycmd" --version &> /dev/null 2>&1; then
            PYTHON="$pycmd"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    fail "Python not found in PATH"
    exit 1
fi

echo ""
header "studio_run.sh"
info "Ticket: $TICKET_PATH"
info "Python: $PYTHON"
info "Repo:   $REPO_ROOT"
echo ""

# ── Helper: run step with exit code propagation ──────────────────────────────
STEP=0
run_step() {
    local name="$1"
    shift
    STEP=$((STEP + 1))
    info "[$STEP] $name"
    if "$@"; then
        pass "$name"
        echo ""
    else
        local rc=$?
        fail "$name (exit $rc)"
        echo ""
        fail "Pipeline stopped at step $STEP: $name"
        exit $rc
    fi
}

# ── Pipeline steps ────────────────────────────────────────────────────────────

# Extract ticket ID for steps that need it
TICKET_ID=$($PYTHON -c "
import sys, re
with open('$TICKET_PATH', 'r') as f:
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
")

if [ -z "$TICKET_ID" ]; then
    fail "Could not extract ticket ID from: $TICKET_PATH"
    exit 1
fi
info "Ticket ID: $TICKET_ID"
echo ""

run_step "validate_vault" \
    $PYTHON "$SCRIPT_DIR/validate_vault.py"

run_step "validate_configs" \
    $PYTHON "$SCRIPT_DIR/validate_configs.py"

run_step "route_ticket" \
    $PYTHON "$SCRIPT_DIR/route_ticket.py" --ticket "$TICKET_PATH"

run_step "build_context_pack" \
    $PYTHON "$SCRIPT_DIR/build_context_pack.py" "$TICKET_PATH"

run_step "require_context_pack" \
    $PYTHON "$SCRIPT_DIR/require_context_pack.py" "$TICKET_ID"

run_step "verify_manifest" \
    $PYTHON "$SCRIPT_DIR/verify_manifest.py" "$TICKET_ID"

run_step "run_ticket" \
    $PYTHON "$SCRIPT_DIR/run_ticket.py" --ticket "$TICKET_PATH"

run_step "dev_gate" \
    bash "$SCRIPT_DIR/dev_gate.sh" --skip-godot

run_step "studio_audit" \
    $PYTHON "$SCRIPT_DIR/studio_audit.py"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
header "PIPELINE COMPLETE"
pass "All $STEP steps passed for $TICKET_ID"
echo ""
exit 0
