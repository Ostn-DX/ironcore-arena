#!/usr/bin/env python3
"""
test_vault_validation.py - Tests that validate_vault.py correctly rejects bad files.

Creates temporary malformed markdown files, runs validation, and confirms
the validator fails with the correct exit code.

Usage:
    python tools/test_vault_validation.py

Exit codes:
    0 - All test cases passed (validator correctly rejects bad input)
    1 - Test failure (validator did NOT reject bad input)
"""

import sys
import os
import subprocess
import tempfile
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
VALIDATOR = os.path.join(SCRIPT_DIR, "validate_vault.py")

# Find Python executable
PYTHON = sys.executable or "python3"

# Test cases: (name, file_content, should_fail)
TEST_CASES = [
    (
        "missing_frontmatter",
        "# Just a heading\n\nNo frontmatter at all.\n",
        True,
    ),
    (
        "empty_frontmatter",
        "---\n---\n\nEmpty frontmatter block.\n",
        True,
    ),
    (
        "missing_required_field_type",
        "---\ntitle: Test\nlayer: design\nstatus: active\n---\n\nMissing type field.\n",
        True,
    ),
    (
        "missing_required_field_status",
        "---\ntitle: Test\ntype: rule\nlayer: design\n---\n\nMissing status field.\n",
        True,
    ),
    (
        "invalid_yaml",
        "---\ntitle: Test\ntype: [unclosed bracket\nlayer: design\nstatus: active\n---\n\nBad YAML.\n",
        True,
    ),
    (
        "empty_required_field",
        "---\ntitle:\ntype: rule\nlayer: design\nstatus: active\n---\n\nEmpty title.\n",
        True,
    ),
    (
        "frontmatter_not_mapping",
        "---\n- item1\n- item2\n---\n\nFrontmatter is a list.\n",
        True,
    ),
    (
        "valid_file",
        "---\ntitle: Valid_Test\ntype: rule\nlayer: design\nstatus: active\n---\n\nThis is valid.\n",
        False,
    ),
]


def run_test(test_name: str, content: str, should_fail: bool) -> bool:
    """Run a single test case. Returns True if test passed."""
    # Create a temporary vault directory with one file
    tmp_dir = tempfile.mkdtemp(prefix=f"vault_test_{test_name}_")
    test_file = os.path.join(tmp_dir, f"{test_name}.md")

    try:
        with open(test_file, "w", encoding="utf-8") as f:
            f.write(content)

        # We need to override VAULT_ROOT in the validator.
        # Simplest: run it with an env var override via a wrapper.
        env = os.environ.copy()
        env["VAULT_TEST_OVERRIDE"] = tmp_dir

        # Run the validator as a subprocess with the override
        result = subprocess.run(
            [PYTHON, "-c", f"""
import sys, os
# Patch vault root before importing
sys.path.insert(0, {repr(SCRIPT_DIR)})
import validate_vault
validate_vault.VAULT_ROOT = {repr(tmp_dir)}
validate_vault.main()
"""],
            capture_output=True,
            text=True,
            timeout=10,
        )

        actual_failed = result.returncode != 0

        if actual_failed == should_fail:
            label = "REJECTED" if should_fail else "ACCEPTED"
            print(f"  PASS: {test_name} — correctly {label} (exit={result.returncode})")
            return True
        else:
            expected = "fail" if should_fail else "pass"
            print(f"  FAIL: {test_name} — expected {expected}, got exit={result.returncode}")
            if result.stdout.strip():
                print(f"        stdout: {result.stdout.strip()[:200]}")
            if result.stderr.strip():
                print(f"        stderr: {result.stderr.strip()[:200]}")
            return False

    except subprocess.TimeoutExpired:
        print(f"  FAIL: {test_name} — timed out")
        return False
    except Exception as e:
        print(f"  FAIL: {test_name} — exception: {e}")
        return False
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def main():
    print(f"Running {len(TEST_CASES)} vault validation test cases...\n")

    passed = 0
    failed = 0

    for test_name, content, should_fail in TEST_CASES:
        if run_test(test_name, content, should_fail):
            passed += 1
        else:
            failed += 1

    print(f"\nResults: {passed} passed, {failed} failed out of {len(TEST_CASES)}")

    if failed > 0:
        print("\nTEST SUITE FAILED")
        sys.exit(1)

    print("\nTEST SUITE PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
