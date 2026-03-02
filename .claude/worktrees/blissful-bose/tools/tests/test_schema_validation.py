#!/usr/bin/env python3
"""
test_schema_validation.py - Unit tests for manifest schema, config validation,
and hash format consistency.

Run:
    python -m pytest tools/tests/test_schema_validation.py -v
    # or without pytest:
    python tools/tests/test_schema_validation.py
"""

import sys
import os
import json
import unittest

# Allow imports from tools/
TOOLS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.path.insert(0, TOOLS_DIR)

from verify_manifest import validate_manifest_schema
from validate_configs import validate_risk_config, validate_budget_config


class TestManifestSchema(unittest.TestCase):
    """Tests for manifest.json schema validation."""

    def _valid_manifest(self):
        return {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": 2,
            "vault_note_count": 1,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {
                "ticket.md": "sha256:a" * 7 + "0" * 57,  # needs valid format
            },
        }

    def test_valid_manifest_passes(self):
        m = {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": 2,
            "vault_note_count": 1,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {
                "ticket.md": "sha256:" + "a" * 64,
            },
        }
        errors = validate_manifest_schema(m)
        self.assertEqual(errors, [], f"Expected no errors, got: {errors}")

    def test_missing_ticket_id(self):
        m = {
            "allowed_file_count": 2,
            "vault_note_count": 1,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {"a.md": "sha256:" + "b" * 64},
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with missing ticket_id")

    def test_invalid_ticket_id_pattern(self):
        m = {
            "ticket_id": "bad-id",
            "allowed_file_count": 2,
            "vault_note_count": 1,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {"a.md": "sha256:" + "c" * 64},
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with invalid ticket_id")

    def test_empty_files_rejected(self):
        m = {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": 0,
            "vault_note_count": 0,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {},
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with empty files dict")

    def test_hash_without_prefix_rejected(self):
        m = {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": 1,
            "vault_note_count": 0,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {"a.md": "d" * 64},  # missing sha256: prefix
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with unprefixed hash")

    def test_wrong_hash_algorithm_rejected(self):
        m = {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": 1,
            "vault_note_count": 0,
            "max_allowed": 10,
            "hash_algorithm": "sha3_256",
            "files": {"a.md": "sha256:" + "e" * 64},
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with wrong algorithm")

    def test_negative_file_count_rejected(self):
        m = {
            "ticket_id": "TICKET-0001",
            "allowed_file_count": -1,
            "vault_note_count": 0,
            "max_allowed": 10,
            "hash_algorithm": "sha256",
            "files": {"a.md": "sha256:" + "f" * 64},
        }
        errors = validate_manifest_schema(m)
        self.assertTrue(len(errors) > 0, "Should fail with negative count")


class TestRiskConfig(unittest.TestCase):
    """Tests for risk config validation."""

    def test_valid_config(self):
        config = {"thresholds": {"low": 25, "medium": 50, "high": 75, "critical": 100}}
        errors = validate_risk_config(config)
        self.assertEqual(errors, [])

    def test_monotonic_violation(self):
        config = {"thresholds": {"low": 50, "medium": 25, "high": 75, "critical": 100}}
        errors = validate_risk_config(config)
        self.assertTrue(any("monotonic" in e.lower() for e in errors))

    def test_missing_level(self):
        config = {"thresholds": {"low": 25, "medium": 50, "high": 75}}
        errors = validate_risk_config(config)
        self.assertTrue(any("missing" in e.lower() for e in errors))

    def test_out_of_range(self):
        config = {"thresholds": {"low": -1, "medium": 50, "high": 75, "critical": 100}}
        errors = validate_risk_config(config)
        self.assertTrue(any("range" in e.lower() for e in errors))

    def test_equal_thresholds_valid(self):
        config = {"thresholds": {"low": 50, "medium": 50, "high": 50, "critical": 50}}
        errors = validate_risk_config(config)
        self.assertEqual(errors, [], "Equal thresholds should be valid (non-decreasing)")


class TestBudgetConfig(unittest.TestCase):
    """Tests for budget config validation."""

    def test_valid_config(self):
        config = {"allocations": {"local": 0.6, "claude": 0.25, "codex": 0.1, "manual": 0.05}}
        errors = validate_budget_config(config)
        self.assertEqual(errors, [])

    def test_sum_too_high(self):
        config = {"allocations": {"local": 0.6, "claude": 0.3, "codex": 0.2}}
        errors = validate_budget_config(config)
        self.assertTrue(any("sum" in e.lower() for e in errors))

    def test_sum_too_low(self):
        config = {"allocations": {"local": 0.5}}
        errors = validate_budget_config(config)
        self.assertTrue(any("sum" in e.lower() for e in errors))

    def test_negative_allocation(self):
        config = {"allocations": {"local": -0.1, "claude": 1.1}}
        errors = validate_budget_config(config)
        self.assertTrue(any("range" in e.lower() for e in errors))

    def test_tolerance_accepted(self):
        # 0.6 + 0.25 + 0.1 + 0.0499 = 0.9999 which is within 0.001
        config = {"allocations": {"local": 0.6, "claude": 0.25, "codex": 0.1, "manual": 0.0499}}
        errors = validate_budget_config(config)
        self.assertEqual(errors, [], "Should pass within tolerance")


class TestHashFormat(unittest.TestCase):
    """Tests for hash format consistency."""

    def test_sha256_file_returns_prefixed(self):
        """sha256_file must return sha256:<64hex> format."""
        import tempfile
        from verify_manifest import sha256_file

        with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
            f.write("test content for hashing")
            f.flush()
            result = sha256_file(f.name)

        os.unlink(f.name)

        self.assertTrue(result.startswith("sha256:"), f"Hash must start with 'sha256:', got: {result}")
        hex_part = result[7:]
        self.assertEqual(len(hex_part), 64, f"Hex part must be 64 chars, got {len(hex_part)}")
        self.assertTrue(all(c in "0123456789abcdef" for c in hex_part))


if __name__ == "__main__":
    unittest.main()
