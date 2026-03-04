# Agent Swarm Task Queue - Ready for Assignment

## Current Status
- Infrastructure: ✅ Implemented (gate scripts, context packer, normalizer)
- Complex Tasks: ✅ 4 tickets ready for agent swarm

## The 4 Agent Swarm Tasks

### AGENT-001: Advanced AI Combat System
**Complexity: HIGH** | **Est. Time: 2-3 days**

**Problem:** Current AI walks directly at player and shoots. No tactics.

**Deliverable:**
- A* pathfinding with obstacle avoidance
- Tactical positioning (cover, flanking, range management)
- Squad coordination (focus fire, role assignment)
- 4 AI role profiles: Tank, Assault, Sniper, Scout

**Key Challenge:** Maintaining determinism (seeded RNG only) while having "intelligent" behavior. Pathfinding must complete in <1ms.

**Success Criteria:**
- Snipers maintain 70%+ of max weapon range
- Tanks position closer to enemies than allies
- 3+ bots can focus-fire same target within 2 seconds
- AI retreats when HP < 25% and no allies nearby

**Context Files Needed:**
- autoload/SimulationManager.gd
- src/entities/bot.gd
- data/campaign.json (for obstacle definitions)

---

### AGENT-002: Comprehensive Simulation Test Suite
**Complexity: HIGH** | **Est. Time: 2 days**

**Problem:** Zero tests. Simulation correctness is unverified.

**Deliverable:**
- 30+ test cases across 6 categories
- GUT-based test framework integration
- Determinism validation (replayability)
- Edge case detection (divide by zero, null refs)
- Headless test runner with JSON output

**Key Challenge:** Testing deterministic floating-point simulation across platforms. Property-based testing (fuzzing) for edge cases.

**Success Criteria:**
- All existing mechanics have at least one test
- Determinism: same seed = identical battle log
- Edge case tests catch 3+ potential crashes
- Tests run in < 30 seconds total

**Context Files Needed:**
- Full read-only access to all source files
- components.json for test data
- GUT addon documentation

---

### AGENT-003: Asset Pipeline and Animation System
**Complexity: MEDIUM-HIGH** | **Est. Time: 2 days**

**Problem:** Procedural sprites only. When art arrives, integration will be painful.

**Deliverable:**
- SpriteAtlas Resource class (texture atlas support)
- AnimationStateMachine with transitions
- SpriteComponent and AnimationComponent (drop-in replacements)
- Atlas builder tool (packs sprites into atlases)
- Animation preview tool (editor)
- Migration guide for existing entities

**Key Challenge:** Building parallel system that doesn't break existing procedural sprites. Designing for artist workflow, not programmer convenience.

**Success Criteria:**
- Hot-reload works in editor (change art, see update immediately)
- One draw call per atlas (batching)
- State machine transitions: idle → move → attack
- Sample assets demonstrate full pipeline

**Context Files Needed:**
- autoload/VFXManager.gd (for integration points)
- scenes/ structure (for migration planning)

---

### AGENT-004: Balance Validation Framework
**Complexity: MEDIUM-HIGH** | **Est. Time: 1.5 days**

**Problem:** Balance is guesswork. No data on whether progression feels good.

**Deliverable:**
- Headless balance validator tool
- Component analysis (1v1 matchups, win rates)
- Arena difficulty analysis (first-attempt clear rates)
- Economy progression simulation
- Automated recommendations with specific tuning values

**Key Challenge:** Simulating "player behavior" (upgrading after losses) to get realistic progression curves. Statistical significance with limited simulations.

**Success Criteria:**
- Runs 1000+ battles in < 60 seconds
- Identifies 3+ potential imbalances
- Recommendations include specific values ("reduce HP from 180 to 160")
- Compares against baseline targets (50% first-attempt clear rate)

**Context Files Needed:**
- data/components.json
- data/campaign.json
- autoload/GameState.gd (for economy tracking)

---

## How to Assign to Agent Swarm

### Step 1: Build Context Pack
```bash
python tools/build_context_pack.py agents/tickets/AGENT-001.md
```

Output: `tools/context_packs/AGENT-001/` with:
- invariants.md, project_summary.md, conventions.md
- All allowlisted files copied
- pack_metadata.txt with ticket details

### Step 2: Feed to Agent
Provide context pack files + ticket.md to your agent swarm.

### Step 3: Agent Produces Output
Agent creates deliverables in `agent_runs/AGENT-001/`:
```
NEW_FILES/           # Complete implementation files
MODIFICATIONS/       # Diffs for existing files
TESTS/               # Test files
INTEGRATION_GUIDE.md # Step-by-step integration
CHANGELOG.md         # Summary of changes
```

### Step 4: Normalize
```bash
python tools/normalize_agent_output.py AGENT-001
```
Validates:
- No TODO/FIXME stubs
- No edits outside allowlist
- Required files present

### Step 5: Apply and Gate
```bash
# Copy NEW_FILES to project/
# Apply MODIFICATIONS per INTEGRATION_GUIDE.md

# Run gate
./tools/dev_gate.sh
```

Gate must pass before considering complete.

---

## Recommended Assignment Order

1. **AGENT-002 (Test Suite)** - First, because:
   - Tests validate other agents' work
   - Catches regressions early
   - Non-breaking (parallel addition)

2. **AGENT-004 (Balance Framework)** - Second, because:
   - Baseline metrics needed before AI changes
   - Validates current state before modifications

3. **AGENT-001 (Tactical AI)** - Third, because:
   - Builds on test suite (can verify determinism)
   - Uses balance framework (tune AI difficulty)
   - Most complex, needs solid foundation

4. **AGENT-003 (Asset Pipeline)** - Fourth/Later, because:
   - Parallel to gameplay work
   - Can be done anytime before art arrives
   - Lower priority than core mechanics

---

## Agent Swarm Efficiency Tips

**For Complex Algorithms (AGENT-001, AGENT-002):**
- Ask for pseudocode first, then implementation
- Request algorithm explanation before code
- Verify approach before full implementation

**For Tools (AGENT-003, AGENT-004):**
- Start with CLI/tool interface design
- Implement core loop, then add features
- Test with sample data early

**For All Tickets:**
- If agent gets stuck, narrow scope further
- Request incremental delivery (skeleton → fill in)
- Validate against invariants frequently

---

## Parallel Execution Possibility

AGENT-002 and AGENT-004 can run **in parallel** — they don't conflict:
- Both are analysis/tools (no gameplay changes)
- Both read-only access to game code
- No overlapping file modifications

AGENT-001 must wait for AGENT-002 (tests validate AI determinism).

AGENT-003 can run anytime (parallel implementation, no conflicts).

---

## Success Metrics

After all 4 agents complete:
- Gate passes 100% of the time
- AI exhibits tactical behavior (cover, flanking)
- 30+ automated tests run on every build
- Balance report generated automatically
- Asset pipeline ready for artist handoff

---

## File Locations Summary

| File | Path |
|------|------|
| Ticket specs | `agents/tickets/AGENT-00{1-4}.md` |
| Context packs | `tools/context_packs/AGENT-00{1-4}/` |
| Agent outputs | `agent_runs/AGENT-00{1-4}/` |
| Validation reports | `reports/AGENT-00{1-4}_validation.txt` |
| Gate script | `tools/dev_gate.sh` |
| Context builder | `tools/build_context_pack.py` |
| Output normalizer | `tools/normalize_agent_output.py` |

Ready to assign to your agent swarm.
