#!/usr/bin/env python3
"""
run_ticket.py - Required entrypoint for all ticket execution.

Orchestrates the full enforcement pipeline for a single ticket:

  Local path (executor=local):
    0. route_ticket          — decide executor, write ROUTE.json
    1. build_context_pack    — build pack from allowlist + vault notes
    2. require_context_pack  — assert pack exists with valid manifest
    3. verify_manifest       — SHA-256 integrity check
    4. dev_gate              — vault validation (Godot skipped)

  External path (executor=claude|codex|manual):
    0. route_ticket          — decide executor, write ROUTE.json
    1. build_context_pack    — build pack (needed for handoff)
    2. require_context_pack  — assert pack valid
    3. verify_manifest       — integrity check
    4. build_handoff_packet  — assemble handoff/ for external executor
    => REPORT.md status: WAITING_FOR_EXTERNAL_EXECUTOR, exit 0

Outputs:
    agents/runs/<TICKET-ID>/ROUTE.json
    agents/runs/<TICKET-ID>/REPORT.md
    agents/runs/<TICKET-ID>/logs/<step>.log
    agents/runs/<TICKET-ID>/handoff/      (external path only)

Usage:
    python tools/run_ticket.py --ticket agents/tickets/TICKET-0001.md

Exit codes:
    0  - All steps passed (or WAITING for external)
    1  - Usage / parse error
    2+ - Preserved exit code from the first failing step
"""

import sys
import os
import argparse
import platform
import subprocess
import json
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import List, Optional

try:
    import yaml  # type: ignore
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = REPO_ROOT / "tools"
RUNS_DIR = REPO_ROOT / "agents" / "runs"

# Executors that trigger the external/handoff path
EXTERNAL_EXECUTORS = {"claude", "codex", "manual"}

# Step sequences
LOCAL_STEPS = [
    "route_ticket",
    "build_context_pack",
    "require_context_pack",
    "verify_manifest",
    "dev_gate",
]

EXTERNAL_STEPS = [
    "route_ticket",
    "build_context_pack",
    "require_context_pack",
    "verify_manifest",
    "build_handoff_packet",
]


# ── data types ─────────────────────────────────────────────────────────────────

@dataclass
class StepResult:
    name: str
    cmd: str
    exit_code: int
    stdout: str
    stderr: str
    started: datetime
    duration_s: float
    log_path: Path

    @property
    def passed(self) -> bool:
        return self.exit_code == 0

    @property
    def status_label(self) -> str:
        return "PASSED" if self.passed else "FAILED"


# ── ticket parsing ─────────────────────────────────────────────────────────────

def parse_frontmatter(ticket_path: Path) -> dict:
    content = ticket_path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        print(f"FATAL: Ticket has no YAML frontmatter: {ticket_path}")
        sys.exit(1)
    parts = content.split("---", 2)
    if len(parts) < 3 or not parts[1].strip():
        print(f"FATAL: Empty or malformed YAML frontmatter in: {ticket_path}")
        sys.exit(1)
    try:
        fm = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        print(f"FATAL: Invalid YAML in ticket frontmatter: {e}")
        sys.exit(1)
    if not isinstance(fm, dict):
        print(f"FATAL: Frontmatter is not a YAML mapping in: {ticket_path}")
        sys.exit(1)
    return fm


def extract_ticket_id(fm: dict, ticket_path: Path) -> str:
    import re
    ticket_id = str(fm.get("ticket", "")).strip()
    if not ticket_id:
        print(f"FATAL: Missing 'ticket:' field in frontmatter of: {ticket_path}")
        sys.exit(1)
    if not re.match(r'^[A-Z][A-Z0-9]*-[0-9]+$', ticket_id):
        print(f"FATAL: ticket: '{ticket_id}' must match WORD-DIGITS (e.g. TICKET-0001)")
        sys.exit(1)
    return ticket_id


# ── step execution ─────────────────────────────────────────────────────────────

def run_step(
    name: str,
    cmd: List[str],
    logs_dir: Path,
    cwd: Optional[Path] = None,
) -> StepResult:
    started = datetime.now(timezone.utc)
    log_path = logs_dir / f"{name}.log"

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(cwd or REPO_ROOT),
        )
        exit_code = result.returncode
        stdout = result.stdout
        stderr = result.stderr
    except FileNotFoundError as e:
        exit_code = 127
        stdout = ""
        stderr = f"Command not found: {e}"
    except OSError as e:
        exit_code = 1
        stdout = ""
        stderr = f"OS error: {e}"

    duration_s = (datetime.now(timezone.utc) - started).total_seconds()

    cmd_str = " ".join(str(c) for c in cmd)
    with open(log_path, "w", encoding="utf-8") as f:
        f.write(f"step:      {name}\n")
        f.write(f"command:   {cmd_str}\n")
        f.write(f"started:   {started.strftime('%Y-%m-%dT%H:%M:%SZ')}\n")
        f.write(f"exit_code: {exit_code}\n")
        f.write(f"duration:  {duration_s:.2f}s\n\n")
        if stdout:
            f.write("--- stdout ---\n")
            f.write(stdout)
            if not stdout.endswith("\n"):
                f.write("\n")
        if stderr:
            f.write("--- stderr ---\n")
            f.write(stderr)
            if not stderr.endswith("\n"):
                f.write("\n")

    return StepResult(
        name=name, cmd=cmd_str, exit_code=exit_code,
        stdout=stdout, stderr=stderr,
        started=started, duration_s=duration_s, log_path=log_path,
    )


# ── command builders ───────────────────────────────────────────────────────────

def build_step_commands(ticket_path: Path, ticket_id: str) -> dict:
    python = sys.executable

    if platform.system() == "Windows":
        dev_gate_cmd = [
            "powershell.exe", "-NoProfile", "-NonInteractive",
            "-File", str(TOOLS_DIR / "dev_gate.ps1"), "-SkipGodot",
        ]
    else:
        dev_gate_cmd = ["bash", str(TOOLS_DIR / "dev_gate.sh"), "--skip-godot"]

    return {
        "route_ticket": [
            python, str(TOOLS_DIR / "route_ticket.py"),
            "--ticket", str(ticket_path.resolve()),
        ],
        "build_context_pack": [
            python, str(TOOLS_DIR / "build_context_pack.py"),
            str(ticket_path.resolve()),
        ],
        "require_context_pack": [
            python, str(TOOLS_DIR / "require_context_pack.py"),
            ticket_id,
        ],
        "verify_manifest": [
            python, str(TOOLS_DIR / "verify_manifest.py"),
            ticket_id,
        ],
        "dev_gate": dev_gate_cmd,
        "build_handoff_packet": [
            python, str(TOOLS_DIR / "build_handoff_packet.py"),
            "--ticket", str(ticket_path.resolve()),
        ],
    }


# ── routing decision ───────────────────────────────────────────────────────────

def read_route(run_dir: Path) -> dict:
    """Read ROUTE.json after route_ticket step. Returns {} on any failure."""
    route_path = run_dir / "ROUTE.json"
    if not route_path.exists():
        return {}
    try:
        return json.loads(route_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


# ── report generation ──────────────────────────────────────────────────────────

def _truncate(text: str, max_lines: int = 20) -> str:
    lines = text.splitlines()
    if len(lines) <= max_lines:
        return text.rstrip()
    kept = lines[-max_lines:]
    return f"... ({len(lines) - max_lines} lines omitted) ...\n" + "\n".join(kept)


def write_report(
    run_dir: Path,
    ticket_id: str,
    ticket_path: str,
    results: List[StepResult],
    overall_exit: int,
    started: datetime,
    finished: datetime,
    route: Optional[dict] = None,
    status_override: Optional[str] = None,
) -> Path:
    report_path = run_dir / "REPORT.md"
    duration_total = (finished - started).total_seconds()

    if status_override:
        overall_status = status_override
    else:
        overall_status = "PASSED" if overall_exit == 0 else "FAILED"

    executor = (route or {}).get("chosen_executor", "unknown")
    cost_tier = (route or {}).get("estimated_cost_tier", "unknown")

    lines = [
        f"# Run Report: {ticket_id}",
        "",
        f"| Field     | Value |",
        f"|-----------|-------|",
        f"| Ticket    | `{ticket_id}` |",
        f"| File      | `{ticket_path}` |",
        f"| Status    | **{overall_status}** |",
        f"| Exit      | `{overall_exit}` |",
        f"| Executor  | `{executor}` |",
        f"| Cost tier | `{cost_tier}` |",
        f"| Started   | `{started.strftime('%Y-%m-%dT%H:%M:%SZ')}` |",
        f"| Finished  | `{finished.strftime('%Y-%m-%dT%H:%M:%SZ')}` |",
        f"| Duration  | `{duration_total:.2f}s` |",
        "",
    ]

    # Routing block
    if route:
        lines += [
            "## Routing",
            "",
            f"- **Executor:** `{executor}`",
            f"- **Cost tier:** `{cost_tier}`",
            f"- **Reason:** {route.get('reason', '')}",
            f"- **Required gates:** {route.get('required_gates', [])}",
            "",
        ]

    # Waiting notice for external
    if status_override == "WAITING_FOR_EXTERNAL_EXECUTOR":
        handoff_dir = run_dir / "handoff"
        lines += [
            "## Status: WAITING_FOR_EXTERNAL_EXECUTOR",
            "",
            f"Ticket routed to **{executor}** executor.",
            f"Handoff packet assembled at: `{handoff_dir}`",
            "",
            "Next steps:",
            f"1. Provide `{handoff_dir}/` to the external executor",
            "2. External executor delivers modified files per `DELIVERABLE_FORMAT.md`",
            "3. Re-run `run_ticket.py` after delivery to complete enforcement gates",
            "",
            "---",
            "",
        ]

    lines += ["## Steps", ""]

    for i, r in enumerate(results, 1):
        icon = "[OK]" if r.passed else "[FAIL]"
        lines.append(
            f"### {i}. {r.name} -- {icon} {r.status_label} "
            f"(exit {r.exit_code}) [{r.duration_s:.2f}s]"
        )
        lines.append("")
        lines.append(f"**Command:** `{r.cmd}`  ")
        lines.append(f"**Log:** [`logs/{r.log_path.name}`](logs/{r.log_path.name})")
        lines.append("")
        output = (r.stdout or r.stderr or "").strip()
        if output:
            lines += ["```", _truncate(output, 20), "```", ""]

    lines += ["---", "", "## Summary", ""]
    for r in results:
        icon = "[OK]" if r.passed else "[FAIL]"
        lines.append(f"- {icon} `{r.name}` -- {r.status_label} (exit {r.exit_code})")

    lines += ["", f"**Overall: {overall_status}** (exit `{overall_exit}`)", ""]

    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


# ── main ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="run_ticket.py -- enforced entrypoint for ticket execution",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Example:\n"
            "  python tools/run_ticket.py --ticket agents/tickets/TICKET-0001.md\n\n"
            "Exit codes:\n"
            "  0   all steps passed (or WAITING for external executor)\n"
            "  1   usage / parse error\n"
            "  2+  exit code from first failing step\n"
        ),
    )
    p.add_argument(
        "--ticket", required=True, metavar="PATH",
        help="Path to ticket .md file (must have YAML frontmatter)",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()

    ticket_path = Path(args.ticket)
    if not ticket_path.exists():
        print(f"FATAL: Ticket file not found: {ticket_path}")
        sys.exit(1)

    fm = parse_frontmatter(ticket_path)
    ticket_id = extract_ticket_id(fm, ticket_path)

    run_dir = RUNS_DIR / ticket_id
    logs_dir = run_dir / "logs"
    run_dir.mkdir(parents=True, exist_ok=True)
    logs_dir.mkdir(exist_ok=True)

    step_commands = build_step_commands(ticket_path, ticket_id)

    print(f"")
    print(f"=========================================")
    print(f"  run_ticket.py -> {ticket_id}")
    print(f"=========================================")
    print(f"  Ticket:  {ticket_path}")
    print(f"  Run dir: {run_dir}")
    print(f"")

    run_started = datetime.now(timezone.utc)
    results: List[StepResult] = []
    overall_exit = 0
    route: dict = {}
    is_external = False
    step_sequence = []  # determined after routing

    # ── Step 0: route_ticket (always first) ────────────────────────────────────
    print(f"  [0] route_ticket...")
    route_result = run_step("route_ticket", step_commands["route_ticket"], logs_dir, REPO_ROOT)
    results.append(route_result)

    status_icon = "PASS" if route_result.passed else "FAIL"
    print(f"       [{status_icon}] exit {route_result.exit_code} ({route_result.duration_s:.2f}s)")

    if not route_result.passed:
        # Routing failure is fatal
        overall_exit = route_result.exit_code
        print(f"\n  FAILED at step: route_ticket")
        print(f"  Log: {route_result.log_path}")
        run_finished = datetime.now(timezone.utc)
        write_report(run_dir, ticket_id, str(ticket_path), results,
                     overall_exit, run_started, run_finished, route)
        sys.exit(overall_exit)

    # Read routing decision
    route = read_route(run_dir)
    executor = route.get("chosen_executor", "local")
    is_external = executor in EXTERNAL_EXECUTORS

    if is_external:
        step_sequence = [s for s in EXTERNAL_STEPS if s != "route_ticket"]
        print(f"  Executor: {executor} (external) -- will build handoff packet")
    else:
        step_sequence = [s for s in LOCAL_STEPS if s != "route_ticket"]
        print(f"  Executor: {executor} (local) -- full pipeline")
    print(f"")

    # ── Remaining steps ────────────────────────────────────────────────────────
    for step_name in step_sequence:
        step_num = len(results)
        print(f"  [{step_num}] {step_name}...")

        result = run_step(step_name, step_commands[step_name], logs_dir, REPO_ROOT)
        results.append(result)

        status_icon = "PASS" if result.passed else "FAIL"
        print(f"       [{status_icon}] exit {result.exit_code} ({result.duration_s:.2f}s)")

        if not result.passed:
            overall_exit = result.exit_code
            print(f"\n  FAILED at step: {step_name}")
            print(f"  Exit code: {result.exit_code}")
            print(f"  Log: {result.log_path}")
            tail = _truncate((result.stdout or result.stderr or "").strip(), 10)
            if tail:
                print(f"")
                for line in tail.splitlines():
                    print(f"  | {line}")
            break

    run_finished = datetime.now(timezone.utc)

    # ── Determine final status ─────────────────────────────────────────────────
    all_passed = (overall_exit == 0)

    if is_external and all_passed:
        status_override = "WAITING_FOR_EXTERNAL_EXECUTOR"
    else:
        status_override = None  # write_report will use PASSED/FAILED from exit code

    report_path = write_report(
        run_dir=run_dir,
        ticket_id=ticket_id,
        ticket_path=str(ticket_path),
        results=results,
        overall_exit=overall_exit,
        started=run_started,
        finished=run_finished,
        route=route,
        status_override=status_override,
    )

    print(f"")
    if status_override == "WAITING_FOR_EXTERNAL_EXECUTOR":
        print(f"  =======================================")
        print(f"  WAITING -- {ticket_id} -> {executor}")
        print(f"  Handoff: {run_dir / 'handoff'}")
        print(f"  =======================================")
    elif all_passed:
        print(f"  =======================================")
        print(f"  PASS: ALL STEPS PASSED -- {ticket_id}")
        print(f"  =======================================")
    else:
        print(f"  =======================================")
        print(f"  FAIL: PIPELINE FAILED  -- {ticket_id} (exit {overall_exit})")
        print(f"  =======================================")

    print(f"  Report: {report_path}")
    print(f"")

    sys.exit(overall_exit)


if __name__ == "__main__":
    main()
