#!/usr/bin/env python3
"""
require_context_pack.py - Blocks execution if no context pack exists for a ticket.

This is the ingestion enforcement gate. It must run BEFORE any agent or
tool touches code on behalf of a ticket.

Usage:
    python tools/require_context_pack.py TICKET-001

Checks:
    1. Context pack directory exists for the given ticket ID.
    2. manifest.json exists inside the pack.
    3. manifest.json is valid JSON with required fields.
    4. At least one allowed file is listed in the manifest.

Exit codes:
    0 - Context pack exists and is valid
    1 - Usage error
    2 - No context pack found for ticket
    3 - Context pack is missing manifest or manifest is invalid
"""

import sys
import os
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
PACKS_DIR = os.path.join(SCRIPT_DIR, "context_packs")

REQUIRED_MANIFEST_FIELDS = ["ticket_id", "allowed_file_count", "files"]


def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/require_context_pack.py <TICKET-ID>")
        print("Exit codes: 0=ok, 1=usage, 2=no pack, 3=invalid manifest")
        sys.exit(1)

    ticket_id = sys.argv[1].strip()
    if not ticket_id:
        print("FATAL: Empty ticket ID")
        sys.exit(1)

    pack_dir = os.path.join(PACKS_DIR, ticket_id)

    # Check 1: pack directory exists
    if not os.path.isdir(pack_dir):
        print(f"BLOCKED: No context pack found for {ticket_id}")
        print(f"  Expected: {pack_dir}")
        print(f"  Run: python tools/build_context_pack.py agents/tickets/{ticket_id}.md")
        sys.exit(2)

    # Check 2: manifest.json exists
    manifest_path = os.path.join(pack_dir, "manifest.json")
    if not os.path.isfile(manifest_path):
        print(f"BLOCKED: Context pack for {ticket_id} has no manifest.json")
        print(f"  Pack dir exists but is missing integrity manifest")
        print(f"  Rebuild: python tools/build_context_pack.py agents/tickets/{ticket_id}.md")
        sys.exit(3)

    # Check 3: manifest is valid JSON with required fields
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"BLOCKED: manifest.json is corrupt for {ticket_id}: {e}")
        sys.exit(3)

    missing = [k for k in REQUIRED_MANIFEST_FIELDS if k not in manifest]
    if missing:
        print(f"BLOCKED: manifest.json missing required fields: {', '.join(missing)}")
        sys.exit(3)

    # Check 4: at least one allowed file
    file_count = manifest.get("allowed_file_count", 0)
    if file_count == 0:
        print(f"BLOCKED: Context pack for {ticket_id} has zero allowed files")
        sys.exit(3)

    # Check 5: ticket_id in manifest matches requested ticket
    manifest_id = manifest.get("ticket_id", "")
    if manifest_id != ticket_id:
        print(f"BLOCKED: Manifest ticket_id mismatch: expected {ticket_id}, got {manifest_id}")
        sys.exit(3)

    # All checks passed
    print(f"PASS: Context pack verified for {ticket_id}")
    print(f"  Allowed files: {file_count}")
    print(f"  Manifest entries: {len(manifest.get('files', {}))}")
    sys.exit(0)


if __name__ == "__main__":
    main()
