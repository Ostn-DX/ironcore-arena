#!/usr/bin/env python3
"""
validate_configs.py - Validates risk and budget config files.

Enforces:
  - Risk thresholds are monotonic: low <= medium <= high <= critical <= 100
  - Budget allocations sum to 1.0 +/- 0.001

Usage:
    python tools/validate_configs.py
    python tools/validate_configs.py --risk path/to/risk.json --budget path/to/budget.json

Exit codes:
    0 - All configs valid
    1 - Usage / file error
    2 - Validation failure
"""

import sys
import os
import json
import argparse
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_RISK = SCRIPT_DIR / "config" / "risk_config.default.json"
DEFAULT_BUDGET = SCRIPT_DIR / "config" / "budget_config.default.json"

RISK_LEVELS = ["low", "medium", "high", "critical"]
BUDGET_TOLERANCE = 0.001


def load_json(path: Path) -> dict:
    """Load JSON file, stripping _comment keys."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_risk_config(config: dict) -> list:
    """Validate risk config. Returns list of error strings."""
    errors = []
    thresholds = config.get("thresholds")
    if not isinstance(thresholds, dict):
        errors.append("Missing or invalid 'thresholds' object")
        return errors

    missing = [k for k in RISK_LEVELS if k not in thresholds]
    if missing:
        errors.append(f"Missing risk level(s): {', '.join(missing)}")
        return errors

    values = []
    for level in RISK_LEVELS:
        val = thresholds[level]
        if not isinstance(val, (int, float)):
            errors.append(f"thresholds.{level} must be a number, got {type(val).__name__}")
            continue
        if val < 0 or val > 100:
            errors.append(f"thresholds.{level} = {val} is out of range [0, 100]")
        values.append((level, val))

    # Check monotonic (non-decreasing)
    for i in range(1, len(values)):
        prev_level, prev_val = values[i - 1]
        curr_level, curr_val = values[i]
        if curr_val < prev_val:
            errors.append(
                f"Thresholds not monotonic: {prev_level}={prev_val} > {curr_level}={curr_val}"
            )

    return errors


def validate_budget_config(config: dict) -> list:
    """Validate budget config. Returns list of error strings."""
    errors = []
    allocations = config.get("allocations")
    if not isinstance(allocations, dict):
        errors.append("Missing or invalid 'allocations' object")
        return errors

    if not allocations:
        errors.append("allocations must have at least one entry")
        return errors

    total = 0.0
    for key, val in allocations.items():
        if not isinstance(val, (int, float)):
            errors.append(f"allocations.{key} must be a number, got {type(val).__name__}")
            continue
        if val < 0 or val > 1:
            errors.append(f"allocations.{key} = {val} is out of range [0.0, 1.0]")
        total += val

    if abs(total - 1.0) > BUDGET_TOLERANCE:
        errors.append(
            f"Budget allocations sum to {total:.4f}, must be 1.0 +/- {BUDGET_TOLERANCE}"
        )

    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate risk and budget configs")
    parser.add_argument(
        "--risk", default=str(DEFAULT_RISK), metavar="PATH",
        help=f"Risk config file (default: {DEFAULT_RISK})",
    )
    parser.add_argument(
        "--budget", default=str(DEFAULT_BUDGET), metavar="PATH",
        help=f"Budget config file (default: {DEFAULT_BUDGET})",
    )
    args = parser.parse_args()

    all_errors = []

    # Validate risk config
    risk_path = Path(args.risk)
    if risk_path.exists():
        try:
            risk_config = load_json(risk_path)
            risk_errors = validate_risk_config(risk_config)
            if risk_errors:
                all_errors.append(f"Risk config ({risk_path}):")
                all_errors.extend(f"  - {e}" for e in risk_errors)
            else:
                print(f"[OK] Risk config valid: {risk_path}")
        except (json.JSONDecodeError, OSError) as e:
            all_errors.append(f"Risk config error: {e}")
    else:
        all_errors.append(f"Risk config not found: {risk_path}")

    # Validate budget config
    budget_path = Path(args.budget)
    if budget_path.exists():
        try:
            budget_config = load_json(budget_path)
            budget_errors = validate_budget_config(budget_config)
            if budget_errors:
                all_errors.append(f"Budget config ({budget_path}):")
                all_errors.extend(f"  - {e}" for e in budget_errors)
            else:
                print(f"[OK] Budget config valid: {budget_path}")
        except (json.JSONDecodeError, OSError) as e:
            all_errors.append(f"Budget config error: {e}")
    else:
        all_errors.append(f"Budget config not found: {budget_path}")

    if all_errors:
        print("\nCONFIG VALIDATION FAILED:")
        for err in all_errors:
            print(f"  {err}")
        sys.exit(2)

    print("\nALL CONFIGS VALID")
    sys.exit(0)


if __name__ == "__main__":
    main()
