#!/usr/bin/env python3
"""
route_ticket.py - Determines execution route for a ticket.

Reads ticket YAML frontmatter and writes ROUTE.json to the run directory.
Does NOT execute anything — pure decision function.

Usage:
    python tools/route_ticket.py --ticket agents/tickets/TICKET-0003.md

Output:
    agents/runs/<TICKET-ID>/ROUTE.json

Routing decision tree (highest priority first):
    executor: <value>         — explicit override, always respected
    manual: true              — manual  (human judgment required)
    needs_codex: true         — codex
    needs_external_llm: true  — claude
    scope in [large,
              architectural]  — claude
    risk: high                — claude
    len(allowlist) > 5        — claude  (large refactor heuristic)
    default                   — local

Cost tier mapping:
    local  / manual           — free/local
    claude, allowlist <= 2    — low
    claude, allowlist <= 5    — medium
    claude, allowlist >  5    — high
    codex,  allowlist <= 3    — medium
    codex,  allowlist >  3    — high

Exit codes:
    0 — ROUTE.json written successfully
    1 — Usage / parse error
"""

import sys
import os
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
RUNS_DIR = REPO_ROOT / "agents" / "runs"

# Scope values that trigger external routing
EXTERNAL_SCOPES = {"large", "architectural"}

# Tags that signal complex/external work
EXTERNAL_TAGS = {
    "architecture", "architectural", "refactor", "large-refactor",
    "multi-file", "multi-file-architectural", "needs-external",
}

VALID_EXECUTORS = {"local", "claude", "codex", "manual"}


# ── frontmatter parsing ────────────────────────────────────────────────────────

def load_frontmatter(ticket_path: Path) -> dict:
    content = ticket_path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        print(f"FATAL: Ticket has no YAML frontmatter: {ticket_path}")
        sys.exit(1)
    parts = content.split("---", 2)
    if len(parts) < 3 or not parts[1].strip():
        print(f"FATAL: Empty frontmatter in: {ticket_path}")
        sys.exit(1)
    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        print(f"FATAL: Invalid YAML frontmatter: {e}")
        sys.exit(1)
    if not isinstance(fm, dict):
        print(f"FATAL: Frontmatter is not a YAML mapping")
        sys.exit(1)
    return fm


# ── routing logic ──────────────────────────────────────────────────────────────

def decide_executor(fm: dict) -> tuple[str, list[str]]:
    """Return (executor, list_of_reasons)."""
    reasons = []

    # Collect routing factors from frontmatter
    explicit_executor = str(fm.get("executor", "")).strip().lower()
    is_manual = bool(fm.get("manual", False))
    needs_codex = bool(fm.get("needs_codex", False))
    needs_external = bool(fm.get("needs_external_llm", False))
    scope = str(fm.get("scope", "small")).strip().lower()
    risk = str(fm.get("risk", "low")).strip().lower()
    tags = [str(t).lower() for t in (fm.get("tags") or [])]
    allowlist = fm.get("allowlist") or []
    allowlist_count = len(allowlist) if isinstance(allowlist, list) else 0

    # Priority 1: explicit override
    if explicit_executor:
        if explicit_executor not in VALID_EXECUTORS:
            print(f"FATAL: executor: '{explicit_executor}' not valid. Must be one of {sorted(VALID_EXECUTORS)}")
            sys.exit(1)
        reasons.append(f"explicit executor override: executor={explicit_executor}")
        return explicit_executor, reasons

    # Priority 2: manual flag
    if is_manual:
        reasons.append("manual: true — requires human judgment")
        return "manual", reasons

    # Priority 3: needs_codex
    if needs_codex:
        reasons.append("needs_codex: true")
        return "codex", reasons

    # Priority 4: needs_external_llm
    if needs_external:
        reasons.append("needs_external_llm: true")
        return "claude", reasons

    # Priority 5: scope-based routing
    if scope in EXTERNAL_SCOPES:
        reasons.append(f"scope={scope} requires external LLM")
        return "claude", reasons

    # Priority 6: risk-based routing
    if risk == "high":
        reasons.append(f"risk=high warrants external LLM review")
        return "claude", reasons

    # Priority 7: tag-based routing
    matched_tags = [t for t in tags if t in EXTERNAL_TAGS]
    if matched_tags:
        reasons.append(f"tags {matched_tags} indicate complex/external work")
        return "claude", reasons

    # Priority 8: large allowlist heuristic (>5 files = refactor territory)
    if allowlist_count > 5:
        reasons.append(f"allowlist has {allowlist_count} files (> 5 threshold for large refactor)")
        return "claude", reasons

    # Default
    reasons.append("no external triggers; defaulting to local execution")
    return "local", reasons


def estimate_cost_tier(executor: str, allowlist_count: int) -> str:
    if executor in ("local", "manual"):
        return "free/local"
    if executor == "claude":
        if allowlist_count <= 2:
            return "low"
        elif allowlist_count <= 5:
            return "medium"
        return "high"
    if executor == "codex":
        return "medium" if allowlist_count <= 3 else "high"
    return "low"


def build_required_gates(executor: str, risk: str) -> list:
    base = [
        "build_context_pack",
        "require_context_pack",
        "verify_manifest",
    ]
    if executor == "local":
        base.append("dev_gate")
    else:
        base.append("build_handoff_packet")
    if risk == "high":
        base.append("human_review")
    return base


# ── main ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="route_ticket.py — determine execution route for a ticket"
    )
    p.add_argument(
        "--ticket", required=True, metavar="PATH",
        help="Path to ticket .md file",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()

    ticket_path = Path(args.ticket)
    if not ticket_path.exists():
        print(f"FATAL: Ticket not found: {ticket_path}")
        sys.exit(1)

    fm = load_frontmatter(ticket_path)

    ticket_id = str(fm.get("ticket", "")).strip()
    if not ticket_id:
        print("FATAL: Missing 'ticket:' field in frontmatter")
        sys.exit(1)

    # Collect metadata for routing
    scope = str(fm.get("scope", "small")).strip().lower()
    risk = str(fm.get("risk", "low")).strip().lower()
    tags = [str(t).lower() for t in (fm.get("tags") or [])]
    allowlist = fm.get("allowlist") or []
    allowlist_count = len(allowlist) if isinstance(allowlist, list) else 0

    executor, reasons = decide_executor(fm)
    cost_tier = estimate_cost_tier(executor, allowlist_count)
    required_gates = build_required_gates(executor, risk)

    route = {
        "ticket_id": ticket_id,
        "chosen_executor": executor,
        "reason": "; ".join(reasons),
        "estimated_cost_tier": cost_tier,
        "required_gates": required_gates,
        "routing_factors": {
            "scope": scope,
            "risk": risk,
            "tags": tags,
            "allowlist_count": allowlist_count,
            "needs_external_llm": bool(fm.get("needs_external_llm", False)),
            "needs_codex": bool(fm.get("needs_codex", False)),
            "manual": bool(fm.get("manual", False)),
            "explicit_executor": str(fm.get("executor", "")).strip() or None,
        },
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    # Write ROUTE.json to run directory
    run_dir = RUNS_DIR / ticket_id
    run_dir.mkdir(parents=True, exist_ok=True)
    route_path = run_dir / "ROUTE.json"
    route_path.write_text(json.dumps(route, indent=2), encoding="utf-8")

    print(f"Route decision for {ticket_id}:")
    print(f"  executor:   {executor}")
    print(f"  cost_tier:  {cost_tier}")
    print(f"  reason:     {route['reason']}")
    print(f"  gates:      {required_gates}")
    print(f"  ROUTE.json: {route_path}")


if __name__ == "__main__":
    main()
