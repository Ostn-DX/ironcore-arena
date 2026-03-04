#!/usr/bin/env python3
"""
verify_manifest.py - Verifies context pack integrity against its manifest.

Ensures that the files in the context pack match the SHA-256 hashes
recorded at build time. Detects tampering, corruption, or drift.

Validation steps:
    1. Validate manifest.json against tools/schemas/manifest.schema.json
    2. Verify hash_algorithm field is "sha256"
    3. Re-hash every file listed in manifest and compare

Usage:
    python tools/verify_manifest.py TICKET-001

Exit codes:
    0 - All files match manifest
    1 - Usage error
    2 - Pack or manifest not found
    3 - Integrity check failed (hash mismatch, missing file, or schema violation)
"""

import sys
import os
import json
import hashlib
import re

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PACKS_DIR = os.path.join(SCRIPT_DIR, "context_packs")
SCHEMA_PATH = os.path.join(SCRIPT_DIR, "schemas", "manifest.schema.json")

# Required top-level keys (subset validated without jsonschema library)
REQUIRED_KEYS = ["ticket_id", "allowed_file_count", "files"]
TICKET_ID_PATTERN = re.compile(r'^[A-Z][A-Z0-9]*-[0-9]+$')
HASH_PATTERN = re.compile(r'^sha256:[a-f0-9]{64}$')


def sha256_file(path: str) -> str:
    """Compute SHA-256 hash of a file. Returns 'sha256:<64hex>'."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return f"sha256:{h.hexdigest()}"


def validate_manifest_schema(manifest: dict) -> list:
    """Validate manifest against schema rules. Returns list of error strings.

    Uses jsonschema if available, otherwise falls back to manual validation
    against the same rules encoded in manifest.schema.json.
    """
    errors = []

    # Try jsonschema library first
    try:
        import jsonschema  # type: ignore
        if os.path.isfile(SCHEMA_PATH):
            with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
                schema = json.load(f)
            try:
                jsonschema.validate(instance=manifest, schema=schema)
                return []  # all good
            except jsonschema.ValidationError as e:
                errors.append(f"Schema violation: {e.message}")
                return errors
    except ImportError:
        pass  # fall through to manual validation

    # Manual validation (mirrors manifest.schema.json rules)
    for key in REQUIRED_KEYS:
        if key not in manifest:
            errors.append(f"Missing required field: {key}")

    ticket_id = manifest.get("ticket_id", "")
    if ticket_id and not TICKET_ID_PATTERN.match(str(ticket_id)):
        errors.append(
            f"ticket_id '{ticket_id}' does not match pattern WORD-DIGITS"
        )

    afc = manifest.get("allowed_file_count")
    if afc is not None and (not isinstance(afc, int) or afc < 0):
        errors.append(f"allowed_file_count must be a non-negative integer, got {afc}")

    vnc = manifest.get("vault_note_count")
    if vnc is not None and (not isinstance(vnc, int) or vnc < 0):
        errors.append(f"vault_note_count must be a non-negative integer, got {vnc}")

    algo = manifest.get("hash_algorithm")
    if algo is not None and algo != "sha256":
        errors.append(f"hash_algorithm must be 'sha256', got '{algo}'")

    files = manifest.get("files")
    if files is not None:
        if not isinstance(files, dict):
            errors.append("files must be an object/dict")
        elif len(files) == 0:
            errors.append("files must have at least one entry")
        else:
            for path, digest in files.items():
                if not isinstance(digest, str) or not HASH_PATTERN.match(digest):
                    errors.append(
                        f"files['{path}']: hash must match sha256:<64hex>"
                    )

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/verify_manifest.py <TICKET-ID>")
        print("Exit codes: 0=ok, 1=usage, 2=not found, 3=integrity failure")
        sys.exit(1)

    ticket_id = sys.argv[1].strip()
    pack_dir = os.path.join(PACKS_DIR, ticket_id)
    manifest_path = os.path.join(pack_dir, "manifest.json")

    if not os.path.isdir(pack_dir):
        print(f"FATAL: No context pack directory: {pack_dir}")
        sys.exit(2)

    if not os.path.isfile(manifest_path):
        print(f"FATAL: No manifest.json in {pack_dir}")
        sys.exit(2)

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"FATAL: Cannot read manifest: {e}")
        sys.exit(2)

    # Step 1: Schema validation
    schema_errors = validate_manifest_schema(manifest)
    if schema_errors:
        print(f"FATAL: Manifest schema validation failed for {ticket_id}:")
        for err in schema_errors:
            print(f"  - {err}")
        sys.exit(3)

    # Step 2: Verify hash algorithm consistency
    algo = manifest.get("hash_algorithm", "sha256")
    if algo != "sha256":
        print(f"FATAL: Unsupported hash_algorithm '{algo}' (expected sha256)")
        sys.exit(3)

    # Step 3: Hash verification
    files = manifest.get("files", {})
    if not files:
        print("FATAL: Manifest has no file entries")
        sys.exit(3)

    errors = []
    verified = 0

    for rel_path, expected_hash in files.items():
        full_path = os.path.join(pack_dir, rel_path)
        if not os.path.isfile(full_path):
            errors.append(f"MISSING: {rel_path}")
            continue
        actual_hash = sha256_file(full_path)
        if actual_hash != expected_hash:
            errors.append(
                f"HASH MISMATCH: {rel_path} "
                f"(expected {expected_hash[:12]}..., got {actual_hash[:12]}...)"
            )
        else:
            verified += 1

    print(f"Manifest verification for {ticket_id}:")
    print(f"  Algorithm: {algo}")
    print(f"  Files checked: {len(files)}")
    print(f"  Verified: {verified}")

    if errors:
        print(f"  Errors: {len(errors)}")
        for err in errors:
            print(f"    - {err}")
        print("\nMANIFEST VERIFICATION FAILED")
        sys.exit(3)

    print("\nMANIFEST VERIFICATION PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()
