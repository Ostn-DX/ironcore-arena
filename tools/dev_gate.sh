#!/bin/bash
# Ironcore Arena Development Gate
# Validates vault, context packs, and build before committing
#
# Usage: ./tools/dev_gate.sh [--skip-godot]
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

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${YELLOW}→${NC} $1"; }

# Get script directory and repo root FIRST (needed for all stages)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

info "Repository root: $REPO_ROOT"

# Parse flags
SKIP_GODOT=false
for arg in "$@"; do
    case "$arg" in
        --skip-godot) SKIP_GODOT=true ;;
    esac
done

# =============================================================================
# STAGE 0: Vault Validation (always runs — cannot be skipped)
# =============================================================================
info "STAGE 0: Running vault validation..."

# Find Python (try multiple names; verify it actually runs to skip Windows store alias)
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
    fail "Python not found — vault validation requires Python"
    exit 2
fi

$PYTHON "$SCRIPT_DIR/validate_vault.py"
VAULT_EXIT=$?

if [ $VAULT_EXIT -ne 0 ]; then
    echo ""
    fail "STAGE 0: VAULT VALIDATION FAILED (exit code $VAULT_EXIT)"
    fail "Fix frontmatter errors before proceeding"
    exit 2
fi

echo ""
pass "STAGE 0: VAULT VALIDATION PASSED"
echo ""

# =============================================================================
# Godot stages (can be skipped with --skip-godot for CI/vault-only checks)
# =============================================================================
if [ "$SKIP_GODOT" = true ]; then
    info "Godot stages skipped (--skip-godot flag)"
    echo ""
    echo "================================"
    pass "DEVELOPMENT GATE: PASSED (vault-only mode)"
    echo "================================"
    exit 0
fi

# Find Godot executable
GODOT=""
POSSIBLE_PATHS=(
    "godot"
    "godot4"
    "/usr/bin/godot"
    "/usr/local/bin/godot"
    "/opt/godot/godot"
    "$HOME/Downloads/Godot_v4.x86_64"
    "/Applications/Godot.app/Contents/MacOS/Godot"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if command -v "$path" &> /dev/null; then
        GODOT="$path"
        break
    fi
    if [ -f "$path" ] && [ -x "$path" ]; then
        GODOT="$path"
        break
    fi
done

if [ -z "$GODOT" ]; then
    fail "Godot executable not found in PATH or common locations"
    echo "Please install Godot 4.x and add it to PATH"
    echo "Or use --skip-godot for vault-only validation"
    exit 1
fi

info "Using Godot: $GODOT"

# Create reports directory
REPORTS_DIR="$REPO_ROOT/reports"
mkdir -p "$REPORTS_DIR"

# Get project path
PROJECT_PATH="$REPO_ROOT/project"
if [ ! -d "$PROJECT_PATH" ]; then
    PROJECT_PATH="$REPO_ROOT"
fi

info "Project path: $PROJECT_PATH"
echo ""

# Change to project directory
cd "$PROJECT_PATH"

# =============================================================================
# STAGE 1: Headless Match Tests
# =============================================================================
info "STAGE 1: Running headless match tests..."

MATCH_REPORT="$REPORTS_DIR/match_report.json"
rm -f "$MATCH_REPORT"

# Run headless matches
$GODOT --headless --script "res://tools/run_headless_matches.gd" 2>&1

if [ $? -ne 0 ]; then
    echo ""
    fail "Headless match tests FAILED"
    fail "Exit code: $?"
    
    if [ -f "$MATCH_REPORT" ]; then
        info "Report: $MATCH_REPORT"
    fi
    
    exit 1
fi

# Verify report was created
if [ ! -f "$MATCH_REPORT" ]; then
    echo ""
    fail "Match report not found at expected location"
    fail "Expected: $MATCH_REPORT"
    exit 1
fi

# Parse report for summary (using Python for JSON parsing)
if command -v python3 &> /dev/null; then
    PYTHON="python3"
elif command -v python &> /dev/null; then
    PYTHON="python"
else
    info "Python not found, skipping detailed report parsing"
    PYTHON=""
fi

if [ -n "$PYTHON" ]; then
    CRASHES=$($PYTHON -c "import json; print(json.load(open('$MATCH_REPORT'))['crashes'])")
    TIMEOUTS=$($PYTHON -c "import json; print(json.load(open('$MATCH_REPORT'))['timeouts'])")
    AVG_DURATION=$($PYTHON -c "import json; print(json.load(open('$MATCH_REPORT'))['average_duration_seconds'])")
    TOTAL_MATCHES=$($PYTHON -c "import json; print(json.load(open('$MATCH_REPORT'))['total_matches'])")
    
    info "Matches completed: $TOTAL_MATCHES"
    
    if [ "$CRASHES" -eq 0 ]; then
        pass "Crashes: $CRASHES"
    else
        fail "Crashes: $CRASHES"
    fi
    
    if [ "$TIMEOUTS" -eq 0 ]; then
        pass "Timeouts: $TIMEOUTS"
    else
        info "Timeouts: $TIMEOUTS"
    fi
    
    info "Avg duration: $(printf '%.2f' $AVG_DURATION)s"
    
    if [ "$CRASHES" -gt 0 ]; then
        echo ""
        fail "Headless match tests FAILED (crashes detected)"
        exit 1
    fi
fi

echo ""
pass "STAGE 1: PASSED ✓"
echo ""

# =============================================================================
# STAGE 2: UI Smoke Tests
# =============================================================================
info "STAGE 2: Running UI smoke tests..."

UI_REPORT="$REPORTS_DIR/ui_smoke.json"
rm -f "$UI_REPORT"

# Run UI smoke tests
$GODOT --headless --script "res://tools/run_ui_smoke.gd" 2>&1

if [ $? -ne 0 ]; then
    echo ""
    fail "UI smoke tests FAILED"
    fail "Exit code: $?"
    
    if [ -f "$UI_REPORT" ]; then
        info "Report: $UI_REPORT"
    fi
    
    exit 1
fi

# Verify report was created
if [ ! -f "$UI_REPORT" ]; then
    echo ""
    fail "UI smoke report not found at expected location"
    fail "Expected: $UI_REPORT"
    exit 1
fi

# Parse report for summary
if [ -n "$PYTHON" ]; then
    PASSED=$($PYTHON -c "import json; print(json.load(open('$UI_REPORT'))['passed'])")
    FAILED=$($PYTHON -c "import json; print(json.load(open('$UI_REPORT'))['failed'])")
    SUCCESS_RATE=$($PYTHON -c "import json; print(json.load(open('$UI_REPORT'))['success_rate'])")
    
    info "Transitions passed: $PASSED"
    
    if [ "$FAILED" -eq 0 ]; then
        pass "Transitions failed: $FAILED"
    else
        fail "Transitions failed: $FAILED"
    fi
    
    SUCCESS_PERCENT=$(printf '%.1f' $(echo "$SUCCESS_RATE * 100" | bc -l 2>/dev/null || echo "$SUCCESS_RATE"))
    
    if [ "$FAILED" -eq 0 ]; then
        pass "Success rate: ${SUCCESS_PERCENT}%"
    else
        info "Success rate: ${SUCCESS_PERCENT}%"
    fi
    
    if [ "$FAILED" -gt 0 ]; then
        echo ""
        fail "UI smoke tests FAILED"
        
        # Show failed transitions
        $PYTHON -c "
import json
report = json.load(open('$UI_REPORT'))
for t in report['transitions']:
    if not t['success']:
        print(f\"  {t['from']} → {t['to']}: {t['error']}\")
" 2>&1 | while read line; do fail "$line"; done
        
        exit 1
    fi
fi

echo ""
pass "STAGE 2: PASSED ✓"
echo ""

# =============================================================================
# FINAL SUMMARY
# =============================================================================
echo "================================"
pass "DEVELOPMENT GATE: PASSED ✓"
echo "================================"
echo ""
pass "Match tests: OK"
pass "UI smoke tests: OK"
echo ""
pass "Build is safe to playtest and commit"
echo ""

exit 0
