# Agent Workflow Implementation Summary

## What Was Created

### Directory Structure
```
ironcore-work/
├── agents/
│   ├── TICKET_TEMPLATE.md          # Template for new tickets
│   ├── context/
│   │   ├── invariants.md           # Architectural constraints
│   │   ├── project_summary.md      # Project overview
│   │   └── conventions.md          # Code style guide
│   ├── prompts/                    # (empty, for future prompt templates)
│   └── tickets/                    # Ticket definitions
│       ├── TICKET-001.md           # Headless match runner
│       ├── TICKET-002.md           # UI smoke test
│       ├── TICKET-003.md           # Gate scripts
│       ├── TICKET-004.md           # Context pack builder
│       └── TICKET-005.md           # Output normalizer
├── tools/
│   ├── build_context_pack.py       # Creates context packs from tickets
│   ├── normalize_agent_output.py   # Validates agent deliverables
│   ├── dev_gate.ps1                # Windows gate script
│   ├── dev_gate.sh                 # Mac/Linux gate script
│   ├── run_headless_matches.gd     # Godot: Automated battle testing
│   └── run_ui_smoke.gd             # Godot: UI navigation testing
├── reports/                        # (created at runtime)
├── agent_runs/                     # (for agent outputs)
└── .gitignore                      # Updated to exclude runtime dirs

```

## How to Use

### 1. Create a New Ticket

Copy `agents/TICKET_TEMPLATE.md` to `agents/tickets/TICKET-XXX.md` and fill in:
- **Title**: Clear, actionable description
- **Goal**: What "done" looks like
- **Allowed Files**: Explicit list of files agent can edit
- **New Files**: Files the agent will create
- **Acceptance Criteria**: Testable conditions

### 2. Build Context Pack

```bash
python tools/build_context_pack.py agents/tickets/TICKET-001.md
```

This creates:
```
tools/context_packs/TICKET-001/
├── project_summary.md
├── invariants.md
├── conventions.md
├── ticket.md
├── pack_metadata.txt
└── allowed_files/          # Copied from allowlist
```

### 3. Agent Implements

Feed the context pack to your agent. Agent produces output in:
```
agent_runs/TICKET-001/
├── NEW_FILES/              # Complete new files
├── MODIFICATIONS/          # Diffs or before/after
├── TESTS/                  # Test files
├── INTEGRATION_GUIDE.md    # Step-by-step integration
└── CHANGELOG.md            # What changed
```

### 4. Normalize Output

```bash
python tools/normalize_agent_output.py TICKET-001
```

Validates:
- Required files exist
- No TODO/FIXME stubs
- No edits outside allowlist
- Generates validation report in `reports/`

### 5. Apply and Test

1. Copy NEW_FILES to project
2. Apply MODIFICATIONS per INTEGRATION_GUIDE.md
3. Run gate:

```bash
# Windows
.\tools\dev_gate.ps1

# Mac/Linux
./tools/dev_gate.sh
```

### 6. Iterate If Gate Fails

Gate will tell you exactly what failed:
- Match crashes → Fix simulation code
- UI transition fails → Fix scene/node references
- Both pass → Ticket complete

## Gate Stages

### Stage 1: Headless Match Tests
- Runs 10 AI vs AI battles
- Checks for crashes, timeouts
- Verifies battle completion
- Reports win rates and durations

### Stage 2: UI Smoke Tests  
- Navigates: Main → Builder → Campaign → Battle → Results → Campaign
- Verifies all scenes load
- Checks button clicks work
- Detects missing nodes/signals

## Key Constraints (Enforced)

1. **One ticket at a time** — Complete and gate-pass before next
2. **File allowlist** — Agent can only touch allowed files
3. **No stubs** — Complete implementations only
4. **Gate required** — Every ticket ends with gate run
5. **Determinism preserved** — 60Hz sim, seeded RNG

## Ticket Priority Order

Already created and ready:
1. **TICKET-001**: Headless match runner ✓
2. **TICKET-002**: UI smoke test ✓
3. **TICKET-003**: Gate scripts ✓
4. **TICKET-004**: Context pack builder ✓
5. **TICKET-005**: Output normalizer ✓

Next tickets to create (when needed):
- TICKET-006: AI pathfinding system
- TICKET-007: Simulation unit tests
- TICKET-008: Asset pipeline
- TICKET-009: Balance validation tool

## Workflow in Practice

```
You: "Add damage over time weapon effect"

1. Create TICKET-006.md with:
   - Allowed: autoload/SimulationManager.gd, src/entities/bot.gd
   - New: src/components/dot_effect.gd
   - AC: Can apply DOT, ticks each second, expires correctly

2. Build context pack:
   python tools/build_context_pack.py agents/tickets/TICKET-006.md

3. Agent implements with context pack

4. Normalize output:
   python tools/normalize_agent_output.py TICKET-006

5. Apply changes:
   - Copy agent_runs/TICKET-006/NEW_FILES/ → project/
   - Apply MODIFICATIONS/ per INTEGRATION_GUIDE.md

6. Run gate:
   ./tools/dev_gate.sh

7. Gate passes → Commit, next ticket
   Gate fails → Fix, re-run gate
```

## Benefits

- **Small diffs** — Easy to review, low conflict risk
- **Playable builds** — Gate ensures game always runs
- **Deterministic** — Same inputs = same outputs
- **Cost efficient** — Minimal context, targeted work
- **No thrash** — Invariants prevent cascading refactors

## Notes

- Godot 4.x required in PATH
- Reports go to `user://reports/` (Godot user directory)
- Windows: `%APPDATA%/Godot/app_userdata/ironcore-arena/reports/`
- Linux: `~/.local/share/godot/app_userdata/ironcore-arena/reports/`
- Mac: `~/Library/Application Support/Godot/app_userdata/ironcore-arena/reports/`
