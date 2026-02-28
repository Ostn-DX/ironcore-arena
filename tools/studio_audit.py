#!/usr/bin/env python3
"""
studio_audit.py - Phase 5: self-maintaining studio OS.

Audits the enforcement pipeline by:
  1. Running vault validation (validate_vault.py)
  2. Running dev gate in SkipGodot mode
  3. Scanning the last N run reports for failures and file churn
  4. Verifying context pack integrity for each scanned run
  5. Computing drift indicators against configurable thresholds
  6. Generating a remediation ticket if drift is detected

Outputs:
    agents/audits/<YYYY-MM-DD>/AUDIT_REPORT.md
    agents/audits/<YYYY-MM-DD>/METRICS.json
    agents/tickets/AUDIT-XXXX.md  (only if drift detected and auto_ticket.enabled)

    Simulated drift uses:
    agents/audits/<YYYY-MM-DD>-simulated/   (separate dir to preserve real audit)

Usage:
    python tools/studio_audit.py
    python tools/studio_audit.py --simulate-drift
    python tools/studio_audit.py --config path/to/custom_config.json

Exit codes:
    0 - Clean (no violations)
    1 - Usage / config error
    2 - Drift detected (violations found; ticket generated if enabled)
    3 - Infrastructure failure (vault validation or dev gate failed critically)
"""

import sys
import os
import json
import re
import argparse
import subprocess
import platform
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

try:
    import yaml  # type: ignore
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
TOOLS_DIR = REPO_ROOT / "tools"
RUNS_DIR = REPO_ROOT / "agents" / "runs"
TICKETS_DIR = REPO_ROOT / "agents" / "tickets"
AUDITS_DIR = REPO_ROOT / "agents" / "audits"
PACKS_DIR = TOOLS_DIR / "context_packs"
DEFAULT_CONFIG_PATH = TOOLS_DIR / "studio_audit_config.json"

DEFAULT_CONFIG = {
    "runs_to_scan": 10,
    "thresholds": {
        "gate_failure_rate": 0.3,
        "repeated_file_modifications": 5,
        "vault_validation_failures": 1,
        "missing_manifest_count": 1,
        "tampered_pack_count": 1,
    },
    "auto_ticket": {
        "enabled": True,
        "prefix": "AUDIT",
    },
}


# ── data types ─────────────────────────────────────────────────────────────────

@dataclass
class StepInfo:
    name: str
    passed: bool
    exit_code: int


@dataclass
class RunSummary:
    ticket_id: str
    run_dir: Path
    status: str              # PASSED / FAILED / WAITING_FOR_EXTERNAL_EXECUTOR
    executor: str
    steps: List[StepInfo]
    allowed_files: List[str] # repo-relative paths (allowed_files/ prefix stripped)
    report_mtime: float
    has_manifest: bool
    manifest_tampered: bool


@dataclass
class DriftMetrics:
    scanned_runs: int
    gate_failures: int
    gate_failure_rate: float
    repeated_files: Dict[str, int]   # repo-relative path -> count of distinct runs
    vault_passed: bool
    dev_gate_passed: bool
    missing_manifests: int
    tampered_packs: int
    vault_output: str
    dev_gate_output: str


@dataclass
class DriftViolation:
    indicator: str
    actual: float
    threshold: float
    severity: str            # "warning" or "critical"
    remediation: str


# ── config loading ─────────────────────────────────────────────────────────────

def load_config(config_path: Path) -> dict:
    if not config_path.exists():
        print(f"Config not found at {config_path}, using defaults.")
        return DEFAULT_CONFIG
    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        print(f"FATAL: Cannot read config {config_path}: {e}")
        sys.exit(1)
    # Shallow-merge each subsection with defaults
    merged = dict(DEFAULT_CONFIG)
    merged.update({k: v for k, v in data.items() if not k.startswith("_comment")})
    merged["thresholds"] = {
        **DEFAULT_CONFIG["thresholds"],
        **{k: v for k, v in data.get("thresholds", {}).items() if not k.startswith("_")},
    }
    merged["auto_ticket"] = {
        **DEFAULT_CONFIG["auto_ticket"],
        **{k: v for k, v in data.get("auto_ticket", {}).items() if not k.startswith("_")},
    }
    return merged


# ── subprocess helper ──────────────────────────────────────────────────────────

def run_cmd(cmd: List[str]) -> Tuple[int, str]:
    """Run a command, return (exit_code, combined stdout+stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            cwd=str(REPO_ROOT),
        )
        out = (result.stdout or "") + (result.stderr or "")
        return result.returncode, out.strip()
    except (FileNotFoundError, OSError) as e:
        return 127, f"Command error: {e}"


# ── run discovery and REPORT.md parsing ───────────────────────────────────────

_STATUS_RE = re.compile(r'\|\s*Status\s*\|\s*\*\*([^*\n]+)\*\*', re.IGNORECASE)
_EXECUTOR_RE = re.compile(r'\|\s*Executor\s*\|\s*`([^`\n]+)`', re.IGNORECASE)
_STEP_RE = re.compile(
    r'###\s+\d+\.\s+(\S+)\s+--\s+\[([^\]]+)\][^\n]*\(exit\s+(\d+)\)',
    re.IGNORECASE,
)


def parse_report(report_path: Path) -> Tuple[str, str, List[StepInfo]]:
    """Extract (status, executor, steps) from a REPORT.md."""
    try:
        text = report_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return "UNKNOWN", "unknown", []

    status_m = _STATUS_RE.search(text)
    status = status_m.group(1).strip() if status_m else "UNKNOWN"

    exec_m = _EXECUTOR_RE.search(text)
    executor = exec_m.group(1).strip() if exec_m else "unknown"

    steps = [
        StepInfo(
            name=m.group(1),
            passed=(m.group(2).upper() == "OK"),
            exit_code=int(m.group(3)),
        )
        for m in _STEP_RE.finditer(text)
    ]
    return status, executor, steps


def load_manifest_files(ticket_id: str) -> Tuple[bool, bool, List[str]]:
    """
    Return (has_manifest, tampered, repo_relative_allowed_files).
    Runs verify_manifest.py for integrity; extracts allowed_files/ entries.
    """
    manifest_path = PACKS_DIR / ticket_id / "manifest.json"
    if not manifest_path.exists():
        return False, False, []

    # Integrity check
    code, _ = run_cmd([sys.executable, str(TOOLS_DIR / "verify_manifest.py"), ticket_id])
    tampered = (code == 3)

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return True, True, []

    prefix = "allowed_files/"
    allowed = [
        k[len(prefix):]
        for k in manifest.get("files", {})
        if k.startswith(prefix)
    ]
    return True, tampered, allowed


def discover_runs(n: int) -> List[RunSummary]:
    """Return the most recently completed N runs from agents/runs/."""
    if not RUNS_DIR.exists():
        return []

    candidates: List[Tuple[float, Path]] = []
    for run_dir in RUNS_DIR.iterdir():
        if not run_dir.is_dir():
            continue
        report_path = run_dir / "REPORT.md"
        if not report_path.exists():
            continue
        candidates.append((report_path.stat().st_mtime, run_dir))

    candidates.sort(key=lambda x: x[0], reverse=True)
    candidates = candidates[:n]

    summaries = []
    for mtime, run_dir in candidates:
        ticket_id = run_dir.name
        status, executor, steps = parse_report(run_dir / "REPORT.md")
        has_manifest, tampered, allowed_files = load_manifest_files(ticket_id)
        summaries.append(RunSummary(
            ticket_id=ticket_id,
            run_dir=run_dir,
            status=status,
            executor=executor,
            steps=steps,
            allowed_files=allowed_files,
            report_mtime=mtime,
            has_manifest=has_manifest,
            manifest_tampered=tampered,
        ))
    return summaries


# ── gate checks ────────────────────────────────────────────────────────────────

def run_vault_validation() -> Tuple[bool, str]:
    code, out = run_cmd([sys.executable, str(TOOLS_DIR / "validate_vault.py")])
    return code == 0, out


def run_dev_gate() -> Tuple[bool, str]:
    if platform.system() == "Windows":
        cmd = [
            "powershell.exe", "-NoProfile", "-NonInteractive",
            "-File", str(TOOLS_DIR / "dev_gate.ps1"), "-SkipGodot",
        ]
    else:
        cmd = ["bash", str(TOOLS_DIR / "dev_gate.sh"), "--skip-godot"]
    code, out = run_cmd(cmd)
    return code == 0, out


# ── metrics ────────────────────────────────────────────────────────────────────

def compute_metrics(
    runs: List[RunSummary],
    vault_passed: bool,
    dev_gate_passed: bool,
    vault_output: str,
    dev_gate_output: str,
) -> DriftMetrics:
    total = len(runs)
    failures = sum(1 for r in runs if r.status == "FAILED")
    rate = (failures / total) if total > 0 else 0.0

    file_counts: Dict[str, int] = {}
    for run in runs:
        for f in run.allowed_files:
            file_counts[f] = file_counts.get(f, 0) + 1

    return DriftMetrics(
        scanned_runs=total,
        gate_failures=failures,
        gate_failure_rate=rate,
        repeated_files=file_counts,
        vault_passed=vault_passed,
        dev_gate_passed=dev_gate_passed,
        missing_manifests=sum(1 for r in runs if not r.has_manifest),
        tampered_packs=sum(1 for r in runs if r.manifest_tampered),
        vault_output=vault_output,
        dev_gate_output=dev_gate_output,
    )


def check_thresholds(metrics: DriftMetrics, thresholds: dict) -> List[DriftViolation]:
    violations: List[DriftViolation] = []

    if metrics.gate_failure_rate >= thresholds["gate_failure_rate"]:
        pct = metrics.gate_failure_rate * 100
        tpct = thresholds["gate_failure_rate"] * 100
        violations.append(DriftViolation(
            indicator="gate_failure_rate",
            actual=round(pct, 1),
            threshold=round(tpct, 1),
            severity="critical",
            remediation=(
                f"Gate failure rate {pct:.1f}% >= {tpct:.0f}% threshold. "
                "Open each failing REPORT.md, identify the first failing step, "
                "and re-run `python tools/run_ticket.py` after fixing root causes."
            ),
        ))

    max_repeats = max(metrics.repeated_files.values(), default=0)
    if max_repeats >= thresholds["repeated_file_modifications"]:
        top = sorted(metrics.repeated_files.items(), key=lambda x: -x[1])[:3]
        top_str = ", ".join(f"`{f}` ({c}x)" for f, c in top)
        violations.append(DriftViolation(
            indicator="repeated_file_modifications",
            actual=float(max_repeats),
            threshold=float(thresholds["repeated_file_modifications"]),
            severity="warning",
            remediation=(
                f"File(s) modified in {max_repeats}+ distinct runs: {top_str}. "
                "This may indicate churn — create a focused stabilisation ticket "
                "to converge these files to a final state."
            ),
        ))

    if not metrics.vault_passed:
        violations.append(DriftViolation(
            indicator="vault_validation_failures",
            actual=1.0,
            threshold=float(thresholds["vault_validation_failures"]),
            severity="critical",
            remediation=(
                "Vault validation failed. Run `python tools/validate_vault.py` "
                "to list all frontmatter errors in Studio_OS/. Fix each file before "
                "any further pipeline runs."
            ),
        ))

    if metrics.missing_manifests >= thresholds["missing_manifest_count"]:
        violations.append(DriftViolation(
            indicator="missing_manifest_count",
            actual=float(metrics.missing_manifests),
            threshold=float(thresholds["missing_manifest_count"]),
            severity="critical",
            remediation=(
                f"{metrics.missing_manifests} run(s) have no context pack manifest — "
                "the enforcement pipeline was bypassed. Identify which tickets are "
                "affected and re-run them: `python tools/run_ticket.py --ticket <path>`."
            ),
        ))

    if metrics.tampered_packs >= thresholds["tampered_pack_count"]:
        violations.append(DriftViolation(
            indicator="tampered_pack_count",
            actual=float(metrics.tampered_packs),
            threshold=float(thresholds["tampered_pack_count"]),
            severity="critical",
            remediation=(
                f"{metrics.tampered_packs} context pack(s) failed SHA-256 integrity check. "
                "Files were modified outside the enforcement pipeline. Rebuild affected "
                "packs: `python tools/build_context_pack.py <ticket.md>`."
            ),
        ))

    return violations


# ── simulated drift ────────────────────────────────────────────────────────────

def simulate_drift_metrics() -> DriftMetrics:
    """Return synthetic metrics that exceed every default threshold."""
    return DriftMetrics(
        scanned_runs=10,
        gate_failures=5,
        gate_failure_rate=0.50,
        repeated_files={
            "agents/context/conventions.md": 7,
            "agents/context/invariants.md": 6,
            "agents/context/project_summary.md": 5,
        },
        vault_passed=False,
        dev_gate_passed=False,
        missing_manifests=2,
        tampered_packs=1,
        vault_output="[SIMULATED] FAIL: 3 files with invalid frontmatter in Studio_OS/",
        dev_gate_output="[SIMULATED] FAIL: vault stage failed, aborting dev gate",
    )


# ── ticket ID allocation ───────────────────────────────────────────────────────

def next_audit_ticket_id(prefix: str) -> str:
    pattern = re.compile(rf'^{re.escape(prefix)}-(\d+)\.md$', re.IGNORECASE)
    max_num = 0
    if TICKETS_DIR.exists():
        for p in TICKETS_DIR.iterdir():
            m = pattern.match(p.name)
            if m:
                max_num = max(max_num, int(m.group(1)))
    return f"{prefix}-{max_num + 1:04d}"


# ── ticket generation ──────────────────────────────────────────────────────────

def generate_ticket_markdown(
    ticket_id: str,
    violations: List[DriftViolation],
    metrics: DriftMetrics,
    audit_date: str,
) -> str:
    has_critical = any(v.severity == "critical" for v in violations)
    risk = "high" if has_critical else "low"
    scope = "large" if len(violations) >= 3 else "small"

    # Allowlist: context files are always relevant; vault fixes are read-only
    allowlist_lines = [
        "  - agents/context/conventions.md",
        "  - agents/context/invariants.md",
    ]

    # Acceptance criteria — one per violation
    ac_lines = [
        f"- [ ] AC{i}: Resolve `{v.indicator}` "
        f"(current: {v.actual}, threshold: {v.threshold})"
        for i, v in enumerate(violations, 1)
    ]

    # Remediation detail — one section per violation
    remediation_sections = [
        f"### {i}. {v.indicator} [{v.severity.upper()}]\n\n{v.remediation}"
        for i, v in enumerate(violations, 1)
    ]

    metrics_lines = [
        f"- Runs scanned:      {metrics.scanned_runs}",
        f"- Gate failures:     {metrics.gate_failures} ({metrics.gate_failure_rate*100:.1f}%)",
        f"- Vault validation:  {'PASS' if metrics.vault_passed else 'FAIL'}",
        f"- Dev gate:          {'PASS' if metrics.dev_gate_passed else 'FAIL'}",
        f"- Missing manifests: {metrics.missing_manifests}",
        f"- Tampered packs:    {metrics.tampered_packs}",
    ]
    if metrics.repeated_files:
        top = sorted(metrics.repeated_files.items(), key=lambda x: -x[1])[:5]
        metrics_lines.append("- Repeated files:")
        for f, c in top:
            metrics_lines.append(f"  - `{f}` ({c} runs)")

    parts = [
        "---",
        f"ticket: {ticket_id}",
        f'title: "Remediation: studio drift detected {audit_date}"',
        f"scope: {scope}",
        f"risk: {risk}",
        "allowlist:",
        *allowlist_lines,
        "---",
        "",
        "## Goal",
        "",
        f"Remediate all drift indicators flagged by `studio_audit.py` on {audit_date}.",
        "This ticket was auto-generated — do not modify the frontmatter manually.",
        "",
        "## Drift Summary",
        "",
        *metrics_lines,
        "",
        "## Acceptance Criteria",
        "",
        *ac_lines,
        "",
        "## Remediation Steps",
        "",
        *remediation_sections,
        "",
        "## Notes",
        "",
        f"- Auto-generated by `tools/studio_audit.py` on {audit_date}",
        "- Resolve every violation listed above, then re-run the audit to verify",
        "- Re-run: `python tools/studio_audit.py`",
        "",
        "## Definition of Done",
        "",
        "`python tools/studio_audit.py` exits 0 (status: CLEAN).",
        "",
    ]
    return "\n".join(parts)


# ── report writers ─────────────────────────────────────────────────────────────

def _ok(passed: bool) -> str:
    return "PASS" if passed else "FAIL"


def write_audit_report(
    audit_dir: Path,
    audit_date: str,
    metrics: DriftMetrics,
    violations: List[DriftViolation],
    runs: List[RunSummary],
    thresholds: dict,
    ticket_generated: Optional[str],
    simulated: bool,
) -> Path:
    overall = "CLEAN" if not violations else "DRIFT-DETECTED"
    if simulated:
        overall += " [SIMULATED]"

    fired = {v.indicator for v in violations}

    lines = [
        f"# Studio Audit Report: {audit_date}",
        "",
        f"| Field               | Value |",
        f"|---------------------|-------|",
        f"| Date                | `{audit_date}` |",
        f"| Status              | **{overall}** |",
        f"| Simulated           | `{'yes' if simulated else 'no'}` |",
        f"| Runs scanned        | `{metrics.scanned_runs}` |",
        f"| Gate failures       | `{metrics.gate_failures}` ({metrics.gate_failure_rate*100:.1f}%) |",
        f"| Vault validation    | `{_ok(metrics.vault_passed)}` |",
        f"| Dev gate            | `{_ok(metrics.dev_gate_passed)}` |",
        f"| Missing manifests   | `{metrics.missing_manifests}` |",
        f"| Tampered packs      | `{metrics.tampered_packs}` |",
        f"| Drift violations    | `{len(violations)}` |",
        f"| Ticket generated    | `{ticket_generated or 'none'}` |",
        "",
        "## Drift Indicators",
        "",
        "| Indicator | Actual | Threshold | Status |",
        "|-----------|--------|-----------|--------|",
    ]

    max_repeats = max(metrics.repeated_files.values(), default=0)
    indicator_rows = [
        ("gate_failure_rate",
         f"{metrics.gate_failure_rate*100:.1f}%",
         f"{thresholds['gate_failure_rate']*100:.0f}%"),
        ("repeated_file_modifications",
         str(max_repeats),
         str(thresholds["repeated_file_modifications"])),
        ("vault_validation_failures",
         "1" if not metrics.vault_passed else "0",
         str(thresholds["vault_validation_failures"])),
        ("missing_manifest_count",
         str(metrics.missing_manifests),
         str(thresholds["missing_manifest_count"])),
        ("tampered_pack_count",
         str(metrics.tampered_packs),
         str(thresholds["tampered_pack_count"])),
    ]
    for name, actual, threshold in indicator_rows:
        status = "**FAIL**" if name in fired else "OK"
        lines.append(f"| `{name}` | {actual} | {threshold} | {status} |")
    lines.append("")

    if violations:
        lines += ["## Violations", ""]
        for i, v in enumerate(violations, 1):
            lines += [
                f"### {i}. `{v.indicator}` [{v.severity.upper()}]",
                "",
                f"- **Actual:** {v.actual}",
                f"- **Threshold:** {v.threshold}",
                f"- **Remediation:** {v.remediation}",
                "",
            ]

    if runs:
        lines += [
            "## Scanned Runs",
            "",
            "| Run | Executor | Status | Files | Manifest |",
            "|-----|----------|--------|-------|----------|",
        ]
        for r in sorted(runs, key=lambda x: -x.report_mtime):
            manifest_note = "OK" if r.has_manifest and not r.manifest_tampered else (
                "TAMPERED" if r.manifest_tampered else "MISSING"
            )
            lines.append(
                f"| `{r.ticket_id}` | `{r.executor}` | `{r.status}` "
                f"| {len(r.allowed_files)} | {manifest_note} |"
            )
        lines.append("")

    if metrics.repeated_files:
        repeat_threshold = thresholds["repeated_file_modifications"]
        lines += [
            "## File Modification Frequency",
            "",
            "| File | Run count | Status |",
            "|------|-----------|--------|",
        ]
        for f, c in sorted(metrics.repeated_files.items(), key=lambda x: -x[1]):
            flag = "**EXCEEDS THRESHOLD**" if c >= repeat_threshold else "OK"
            lines.append(f"| `{f}` | {c} | {flag} |")
        lines.append("")

    if ticket_generated:
        lines += [
            "## Auto-generated Ticket",
            "",
            f"Drift violations triggered ticket generation.",
            f"Written to: `agents/tickets/{ticket_generated}.md`",
            "",
        ]

    if simulated:
        lines += [
            "> **NOTE:** This report used `--simulate-drift`. "
            "Metrics above are synthetic and do not reflect the actual repo state.",
            "",
        ]

    lines += [
        "---",
        f"_Generated by `tools/studio_audit.py` at "
        f"{datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}_",
    ]

    report_path = audit_dir / "AUDIT_REPORT.md"
    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


def write_metrics_json(
    audit_dir: Path,
    audit_date: str,
    metrics: DriftMetrics,
    violations: List[DriftViolation],
    ticket_generated: Optional[str],
    simulated: bool,
) -> Path:
    data = {
        "audit_date": audit_date,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "simulated": simulated,
        "overall_status": "CLEAN" if not violations else "DRIFT_DETECTED",
        "vault_validation": "PASS" if metrics.vault_passed else "FAIL",
        "dev_gate": "PASS" if metrics.dev_gate_passed else "FAIL",
        "runs_scanned": metrics.scanned_runs,
        "gate_failures": metrics.gate_failures,
        "gate_failure_rate": round(metrics.gate_failure_rate, 4),
        "missing_manifests": metrics.missing_manifests,
        "tampered_packs": metrics.tampered_packs,
        "repeated_files": metrics.repeated_files,
        "drift_violations": [
            {
                "indicator": v.indicator,
                "actual": v.actual,
                "threshold": v.threshold,
                "severity": v.severity,
                "remediation": v.remediation,
            }
            for v in violations
        ],
        "auto_ticket_generated": ticket_generated,
    }
    metrics_path = audit_dir / "METRICS.json"
    metrics_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    return metrics_path


# ── main ───────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="studio_audit.py -- Phase 5 self-maintaining studio OS",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exit codes:\n"
            "  0   clean (no violations)\n"
            "  1   usage / config error\n"
            "  2   drift detected\n"
            "  3   infrastructure failure (vault or dev gate critical)\n"
        ),
    )
    p.add_argument(
        "--simulate-drift", action="store_true",
        help="Inject synthetic drift metrics to demonstrate auto-ticket generation",
    )
    p.add_argument(
        "--config", default=str(DEFAULT_CONFIG_PATH), metavar="PATH",
        help=f"Path to config JSON (default: {DEFAULT_CONFIG_PATH})",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()
    config = load_config(Path(args.config))
    thresholds = config["thresholds"]
    auto_ticket_cfg = config["auto_ticket"]
    runs_to_scan = int(config.get("runs_to_scan", 10))

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    audit_dir_name = f"{today}-simulated" if args.simulate_drift else today
    audit_dir = AUDITS_DIR / audit_dir_name
    audit_dir.mkdir(parents=True, exist_ok=True)

    print("")
    print("=========================================")
    print(f"  studio_audit.py {'[SIMULATE-DRIFT]' if args.simulate_drift else ''}")
    print("=========================================")
    print(f"  Date:    {today}")
    print(f"  Config:  {args.config}")
    print(f"  Output:  {audit_dir}")
    print("")

    # ── Real or simulated metrics ──────────────────────────────────────────────
    if args.simulate_drift:
        print("  [SIM] Injecting synthetic drift metrics...")
        metrics = simulate_drift_metrics()
        runs: List[RunSummary] = []
        print("  [SIM] Vault:    FAIL (simulated)")
        print("  [SIM] Dev gate: FAIL (simulated)")
        print(f"  [SIM] Runs:     {metrics.scanned_runs} (synthetic)")
    else:
        # Step 1: vault validation
        print("  [1] vault validation...")
        vault_passed, vault_out = run_vault_validation()
        print(f"       [{_ok(vault_passed)}] vault validation")

        # Step 2: dev gate
        print("  [2] dev gate (SkipGodot)...")
        dev_gate_passed, dev_gate_out = run_dev_gate()
        print(f"       [{_ok(dev_gate_passed)}] dev gate")

        # Step 3: scan recent runs
        print(f"  [3] scanning last {runs_to_scan} run(s)...")
        runs = discover_runs(runs_to_scan)
        print(f"       found {len(runs)} run(s)")
        for r in runs:
            manifest_note = "" if r.has_manifest else " (no manifest)"
            tamper_note = " (TAMPERED)" if r.manifest_tampered else ""
            print(f"       - {r.ticket_id}: {r.status}{manifest_note}{tamper_note}")

        # Step 4: compute metrics
        metrics = compute_metrics(
            runs, vault_passed, dev_gate_passed, vault_out, dev_gate_out
        )

    # ── Check thresholds ───────────────────────────────────────────────────────
    print("")
    violations = check_thresholds(metrics, thresholds)
    if violations:
        print(f"  Drift violations: {len(violations)}")
        for v in violations:
            print(f"    [{v.severity.upper()}] {v.indicator}: {v.actual} >= {v.threshold}")
    else:
        print("  No drift violations detected.")

    # ── Auto-ticket generation ─────────────────────────────────────────────────
    ticket_generated: Optional[str] = None
    if violations and auto_ticket_cfg.get("enabled", True):
        ticket_id = next_audit_ticket_id(auto_ticket_cfg.get("prefix", "AUDIT"))
        ticket_md = generate_ticket_markdown(ticket_id, violations, metrics, today)
        ticket_path = TICKETS_DIR / f"{ticket_id}.md"
        TICKETS_DIR.mkdir(parents=True, exist_ok=True)
        ticket_path.write_text(ticket_md, encoding="utf-8")
        ticket_generated = ticket_id
        print(f"  Auto-ticket: {ticket_path}")

    # ── Write outputs ──────────────────────────────────────────────────────────
    report_path = write_audit_report(
        audit_dir=audit_dir,
        audit_date=today,
        metrics=metrics,
        violations=violations,
        runs=runs,
        thresholds=thresholds,
        ticket_generated=ticket_generated,
        simulated=args.simulate_drift,
    )
    metrics_path = write_metrics_json(
        audit_dir=audit_dir,
        audit_date=today,
        metrics=metrics,
        violations=violations,
        ticket_generated=ticket_generated,
        simulated=args.simulate_drift,
    )

    print("")
    print(f"  Report:  {report_path}")
    print(f"  Metrics: {metrics_path}")

    # ── Final status ───────────────────────────────────────────────────────────
    if not args.simulate_drift:
        infra_failed = not metrics.vault_passed or not metrics.dev_gate_passed
    else:
        infra_failed = False  # simulation never counts as infra failure

    print("")
    if not violations:
        print("  =======================================")
        print("  CLEAN: No drift detected.")
        print("  =======================================")
        sys.exit(0)
    else:
        print("  =======================================")
        print(f"  DRIFT DETECTED: {len(violations)} violation(s)")
        if ticket_generated:
            print(f"  Ticket: agents/tickets/{ticket_generated}.md")
        print("  =======================================")
        if infra_failed:
            sys.exit(3)
        sys.exit(2)


if __name__ == "__main__":
    main()
