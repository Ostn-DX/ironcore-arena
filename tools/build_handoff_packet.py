#!/usr/bin/env python3
"""
build_handoff_packet.py - Creates handoff packet for external executor.

Assembles everything an external model or human needs to execute a ticket
without access to the full repo or vault.

Usage:
    python tools/build_handoff_packet.py --ticket agents/tickets/TICKET-0003.md

Prerequisites (must exist before calling this):
    agents/runs/<TICKET-ID>/ROUTE.json
    tools/context_packs/<TICKET-ID>/manifest.json

Output: agents/runs/<TICKET-ID>/handoff/
    context_pack_ref.json     — pointer to the built context pack
    ticket.md                 — verbatim copy of the ticket file
    DELIVERABLE_FORMAT.md     — goal + acceptance criteria + output expectations
    CONSTRAINTS.md            — do-not-modify list + scope boundaries
    ROUTE.json                — copy of the routing decision

Exit codes:
    0 — Handoff packet created successfully
    1 — Usage / parse error
    2 — Missing prerequisite (ROUTE.json or context pack)
"""

import sys
import argparse
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
RUNS_DIR = REPO_ROOT / "agents" / "runs"
PACKS_DIR = REPO_ROOT / "tools" / "context_packs"


# ── ticket parsing ─────────────────────────────────────────────────────────────

def load_ticket(ticket_path: Path) -> tuple[dict, str]:
    """Returns (frontmatter_dict, body_after_frontmatter)."""
    content = ticket_path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        print(f"FATAL: No YAML frontmatter in: {ticket_path}")
        sys.exit(1)
    parts = content.split("---", 2)
    if len(parts) < 3:
        print(f"FATAL: Malformed frontmatter in: {ticket_path}")
        sys.exit(1)
    try:
        fm = yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as e:
        print(f"FATAL: Invalid YAML: {e}")
        sys.exit(1)
    return fm, parts[2].strip()


def extract_section(body: str, heading: str) -> str:
    """Extract a markdown section by heading text (case-insensitive)."""
    pattern = rf"(?i)(?:^|\n)#{1,3}\s+{re.escape(heading)}\s*\n(.*?)(?=\n#{1,3}\s|\Z)"
    m = re.search(pattern, body, re.DOTALL)
    if m:
        return m.group(1).strip()
    return ""


# ── document builders ──────────────────────────────────────────────────────────

def build_deliverable_format(fm: dict, body: str, ticket_id: str) -> str:
    """Build DELIVERABLE_FORMAT.md from ticket goal and acceptance criteria."""
    title = str(fm.get("title", ticket_id))
    goal = extract_section(body, "Goal") or str(fm.get("goal", "")).strip() or "(see ticket)"
    acceptance = extract_section(body, "Acceptance Criteria")
    definition = extract_section(body, "Definition of Done")

    lines = [
        f"# Deliverable Format: {ticket_id}",
        "",
        f"**Ticket:** {ticket_id}  ",
        f"**Title:** {title}  ",
        f"**Executor:** see ROUTE.json  ",
        "",
        "---",
        "",
        "## Goal",
        "",
        goal,
        "",
    ]

    if acceptance:
        lines += [
            "## Acceptance Criteria",
            "",
            acceptance,
            "",
        ]

    lines += [
        "## Required Output",
        "",
        "The external executor MUST deliver:",
        "",
        "1. All modified files listed in `context_pack_ref.json` → `allowed_files/`",
        "2. A short summary of changes made (1-3 sentences per file)",
        "3. Exit confidence: one of `[high, medium, low]` with reason",
        "4. Any new files listed in the ticket's `New Files` section",
        "",
    ]

    if definition:
        lines += [
            "## Definition of Done",
            "",
            definition,
            "",
        ]

    lines += [
        "---",
        f"_Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}_",
    ]
    return "\n".join(lines)


def build_constraints(fm: dict, body: str, ticket_id: str) -> str:
    """Build CONSTRAINTS.md from allowlist and ticket forbidden section."""
    allowlist = fm.get("allowlist") or []
    forbidden_section = extract_section(body, "Forbidden Files")

    lines = [
        f"# Constraints: {ticket_id}",
        "",
        "The external executor MUST NOT modify any file outside the allowlist.",
        "Violations will be rejected by the enforcement pipeline.",
        "",
        "---",
        "",
        "## Allowed Files (only these may be modified)",
        "",
    ]

    if allowlist:
        for f in allowlist:
            lines.append(f"- `{f}`")
    else:
        lines.append("_(no files — read-only context ticket)_")
    lines.append("")

    lines += [
        "## Hard Boundaries",
        "",
        "- `Studio_OS/` — vault is READ-ONLY. Never write to it.",
        "- `project/`   — game engine code. NEVER touch unless explicitly in allowlist.",
        "- Any file not listed above is FORBIDDEN.",
        "",
    ]

    if forbidden_section:
        lines += [
            "## Explicitly Forbidden (from ticket)",
            "",
            forbidden_section,
            "",
        ]

    lines += [
        "## Enforcement",
        "",
        "After completion, the following gates will run:",
        "- `require_context_pack` — verifies pack integrity",
        "- `verify_manifest` — SHA-256 hash check on all pack files",
        "- `dev_gate` — vault frontmatter validation",
        "",
        "---",
        f"_Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}_",
    ]
    return "\n".join(lines)


def build_context_pack_ref(ticket_id: str, pack_dir: Path) -> dict:
    """Build the context pack reference object."""
    manifest_path = pack_dir / "manifest.json"
    manifest = {}
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass

    return {
        "ticket_id": ticket_id,
        "pack_path": str(pack_dir.relative_to(REPO_ROOT)).replace("\\", "/"),
        "manifest_path": str(manifest_path.relative_to(REPO_ROOT)).replace("\\", "/"),
        "allowed_file_count": manifest.get("allowed_file_count", 0),
        "vault_note_count": manifest.get("vault_note_count", 0),
        "files": list(manifest.get("files", {}).keys()),
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


# ── main ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="build_handoff_packet.py — assemble external executor handoff"
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

    fm, body = load_ticket(ticket_path)

    ticket_id = str(fm.get("ticket", "")).strip()
    if not ticket_id:
        print("FATAL: Missing 'ticket:' in frontmatter")
        sys.exit(1)

    run_dir = RUNS_DIR / ticket_id
    route_path = run_dir / "ROUTE.json"
    pack_dir = PACKS_DIR / ticket_id

    # Verify prerequisites
    if not route_path.exists():
        print(f"FATAL: ROUTE.json not found: {route_path}")
        print(f"  Run route_ticket.py first")
        sys.exit(2)

    if not (pack_dir / "manifest.json").exists():
        print(f"FATAL: Context pack manifest not found: {pack_dir / 'manifest.json'}")
        print(f"  Run build_context_pack.py first")
        sys.exit(2)

    # Create handoff directory (clear if exists)
    handoff_dir = run_dir / "handoff"
    if handoff_dir.exists():
        shutil.rmtree(handoff_dir)
    handoff_dir.mkdir(parents=True)

    # 1. context_pack_ref.json
    ref = build_context_pack_ref(ticket_id, pack_dir)
    (handoff_dir / "context_pack_ref.json").write_text(
        json.dumps(ref, indent=2), encoding="utf-8"
    )

    # 2. ticket.md (verbatim copy)
    shutil.copy2(ticket_path, handoff_dir / "ticket.md")

    # 3. DELIVERABLE_FORMAT.md
    deliverable_md = build_deliverable_format(fm, body, ticket_id)
    (handoff_dir / "DELIVERABLE_FORMAT.md").write_text(
        deliverable_md, encoding="utf-8"
    )

    # 4. CONSTRAINTS.md
    constraints_md = build_constraints(fm, body, ticket_id)
    (handoff_dir / "CONSTRAINTS.md").write_text(
        constraints_md, encoding="utf-8"
    )

    # 5. ROUTE.json (copy routing decision into handoff for self-containment)
    shutil.copy2(route_path, handoff_dir / "ROUTE.json")

    # Summary
    files_created = [f.name for f in sorted(handoff_dir.iterdir())]
    print(f"Handoff packet created: {handoff_dir}")
    print(f"  Files: {files_created}")
    print(f"  Pack ref: {ref['allowed_file_count']} code file(s), "
          f"{ref['vault_note_count']} vault note(s)")


if __name__ == "__main__":
    main()
