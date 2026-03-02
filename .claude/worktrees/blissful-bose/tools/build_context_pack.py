#!/usr/bin/env python3
"""
build_context_pack.py - Creates minimal deterministic context pack for a ticket.

Ticket formats supported:
    New (YAML frontmatter): fields ticket, title, allowlist, notes
    Legacy (## headings):   ## ID, ## Allowed Files, ## New Files, ## Goal

Usage:
    python tools/build_context_pack.py agents/tickets/TICKET-0001.md

Output:
    tools/context_packs/TICKET-0001/
        - project_summary.md
        - invariants.md
        - conventions.md
        - allowed_files/[repo-relative paths]
        - vault_notes/[Studio_OS-relative paths]   (notes: field only)
        - manifest.json  (integrity manifest)

Exit codes:
    0 - Success
    1 - Missing/invalid ticket
    2 - Allowlist violation (path traversal, glob, vault path)
    3 - Allowlist limit exceeded (max 10 files per vault rule)
    4 - No allowed files resolved (empty pack is forbidden)
"""

import sys
import os
import re
import json
import hashlib
import shutil
from pathlib import Path

MAX_ALLOWED_FILES = 10
# Patterns forbidden in the code allowlist (notes use a different validator)
FORBIDDEN_PATH_PATTERNS = [
    '..',           # path traversal
    'Studio_OS',   # vault directory — never ingest via allowlist
    '*',           # glob wildcards
    '?',           # glob wildcards
]


def _try_yaml_import():
    """Return the yaml module if available, else None."""
    try:
        import yaml  # type: ignore
        return yaml
    except ImportError:
        return None


def parse_ticket(ticket_path: str) -> dict:
    """Parse ticket file for metadata.

    Tries YAML frontmatter (new format) first.
    Falls back to ## heading format (legacy).

    Returned dict keys:
        id, title, allowed_files, new_files, goal, notes
    """
    ticket = {
        'id': '',
        'title': '',
        'allowed_files': [],
        'new_files': [],
        'goal': '',
        'notes': [],        # vault-relative paths (relative to Studio_OS/)
    }

    with open(ticket_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # ── YAML frontmatter path ──────────────────────────────────────────────
    if content.startswith('---'):
        yaml = _try_yaml_import()
        if yaml is None:
            print("FATAL: PyYAML required for frontmatter tickets. Run: pip install pyyaml")
            sys.exit(1)

        parts = content.split('---', 2)
        if len(parts) >= 3:
            fm_text = parts[1].strip()
            if fm_text:
                try:
                    fm = yaml.safe_load(fm_text)
                except yaml.YAMLError as e:
                    print(f"FATAL: Invalid YAML frontmatter in ticket: {e}")
                    sys.exit(1)

                if isinstance(fm, dict):
                    ticket['id'] = str(fm.get('ticket', '')).strip()
                    ticket['title'] = str(fm.get('title', '')).strip()

                    raw_allowlist = fm.get('allowlist', [])
                    if isinstance(raw_allowlist, list):
                        ticket['allowed_files'] = [
                            str(p).strip() for p in raw_allowlist if p
                        ]

                    raw_notes = fm.get('notes', [])
                    if isinstance(raw_notes, list):
                        ticket['notes'] = [
                            str(p).strip() for p in raw_notes if p
                        ]

                    ticket['goal'] = str(fm.get('goal', '')).strip()
                    return ticket

    # ── Legacy ## heading format ───────────────────────────────────────────
    id_match = re.search(r'## ID\s*\n([A-Z0-9][-A-Z0-9_]+)', content)
    if id_match:
        ticket['id'] = id_match.group(1).strip()

    title_match = re.search(r'## Title\s*\n(.+?)\n', content)
    if title_match:
        ticket['title'] = title_match.group(1).strip()

    allowed_section = re.search(
        r'## Allowed Files.*?\n(.*?)(?=##|\Z)',
        content,
        re.DOTALL
    )
    if allowed_section:
        for line in allowed_section.group(1).split('\n'):
            line = line.strip()
            if line.startswith('- '):
                filepath = line[2:].strip()
                if filepath and not filepath.startswith('#'):
                    ticket['allowed_files'].append(filepath)

    new_section = re.search(
        r'## New Files.*?\n(.*?)(?=##|\Z)',
        content,
        re.DOTALL
    )
    if new_section:
        for line in new_section.group(1).split('\n'):
            line = line.strip()
            if line.startswith('- '):
                filepath = line[2:].strip()
                if filepath and not filepath.startswith('#'):
                    ticket['new_files'].append(filepath)

    goal_match = re.search(r'## Goal\s*\n(.+?)\n', content)
    if goal_match:
        ticket['goal'] = goal_match.group(1).strip()

    return ticket


def validate_allowlist(allowed_files: list, repo_root: Path) -> list:
    """Validate allowlist entries. Returns list of error strings."""
    errors = []

    # Enforce max file count (vault rule: max 10)
    if len(allowed_files) > MAX_ALLOWED_FILES:
        errors.append(
            f"Allowlist exceeds max of {MAX_ALLOWED_FILES} files "
            f"(got {len(allowed_files)})"
        )

    for filepath in allowed_files:
        # Check forbidden patterns
        for pattern in FORBIDDEN_PATH_PATTERNS:
            if pattern in filepath:
                errors.append(
                    f"Forbidden pattern '{pattern}' in allowlist entry: {filepath}"
                )

        # Resolve and confirm file stays within repo
        try:
            resolved = (repo_root / filepath).resolve()
            if not str(resolved).startswith(str(repo_root.resolve())):
                errors.append(f"Path escapes repository root: {filepath}")
        except (OSError, ValueError) as e:
            errors.append(f"Invalid path '{filepath}': {e}")

    return errors


def validate_notes(notes: list, vault_root: Path) -> list:
    """Validate vault note paths. Notes are vault-relative (relative to Studio_OS/).

    Rules (inverted from allowlist):
      - Must not contain '..' or glob characters
      - Must end with .md
      - Must resolve within the vault root
    """
    errors = []
    for note in notes:
        if '..' in note:
            errors.append(f"Path traversal in note: {note}")
            continue
        if '*' in note or '?' in note:
            errors.append(f"Glob not allowed in note path: {note}")
            continue
        if not note.endswith('.md'):
            errors.append(f"Note must be a .md file: {note}")
            continue
        try:
            resolved = (vault_root / note).resolve()
            if not str(resolved).startswith(str(vault_root.resolve())):
                errors.append(f"Note path escapes vault root: {note}")
        except (OSError, ValueError) as e:
            errors.append(f"Invalid note path '{note}': {e}")
    return errors


def sha256_file(path: Path) -> str:
    """Compute SHA-256 hash of a file. Returns 'sha256:<64hex>'."""
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return f"sha256:{h.hexdigest()}"


def build_context_pack(ticket_path: str) -> str:
    """Build context pack for ticket. Returns pack directory path."""

    # Parse ticket
    ticket = parse_ticket(ticket_path)
    if not ticket['id']:
        print("FATAL: Could not parse ticket ID from: " + ticket_path)
        sys.exit(1)

    if not ticket['allowed_files']:
        print("FATAL: Ticket has no allowlist — empty packs are forbidden")
        sys.exit(4)

    repo_root = Path(__file__).parent.parent
    vault_root = repo_root / 'Studio_OS'

    # Validate code allowlist
    allowlist_errors = validate_allowlist(ticket['allowed_files'], repo_root)
    if allowlist_errors:
        print("FATAL: Allowlist validation failed:")
        for err in allowlist_errors:
            print(f"  - {err}")
        if any("exceeds max" in e for e in allowlist_errors):
            sys.exit(3)
        sys.exit(2)

    # Validate vault notes (separate path, separate rules)
    if ticket['notes']:
        note_errors = validate_notes(ticket['notes'], vault_root)
        if note_errors:
            print("FATAL: Notes validation failed:")
            for err in note_errors:
                print(f"  - {err}")
            sys.exit(2)

    # Create pack directory
    pack_dir = repo_root / 'tools' / 'context_packs' / ticket['id']
    pack_dir.mkdir(parents=True, exist_ok=True)

    # Clear existing pack
    for item in pack_dir.iterdir():
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)

    manifest_entries = {}

    # Copy standard context files
    context_src = repo_root / 'agents' / 'context'
    for ctx_file in ['project_summary.md', 'invariants.md', 'conventions.md']:
        src = context_src / ctx_file
        if src.exists():
            shutil.copy2(src, pack_dir / ctx_file)
            manifest_entries[ctx_file] = sha256_file(src)

    # Copy ticket itself
    shutil.copy2(ticket_path, pack_dir / 'ticket.md')
    manifest_entries['ticket.md'] = sha256_file(Path(ticket_path))

    # Copy allowlisted code files
    copied_count = 0
    missing = []
    for filepath in ticket['allowed_files']:
        src = repo_root / filepath
        if src.exists():
            dst = pack_dir / 'allowed_files' / Path(filepath)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            manifest_entries[f"allowed_files/{filepath}"] = sha256_file(src)
            copied_count += 1
            print(f"  Copied: {filepath}")
        else:
            missing.append(filepath)

    if missing:
        print(f"WARNING: {len(missing)} allowlisted file(s) not found:")
        for m in missing:
            print(f"  - {m}")

    if copied_count == 0:
        print("FATAL: Zero allowed files resolved — refusing to create empty pack")
        shutil.rmtree(pack_dir, ignore_errors=True)
        sys.exit(4)

    # Copy vault notes (controlled ingestion — vault-relative paths under Studio_OS/)
    notes_copied = 0
    notes_missing = []
    for note_path in ticket['notes']:
        src = vault_root / note_path
        if src.exists():
            dst = pack_dir / 'vault_notes' / note_path
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            manifest_entries[f"vault_notes/{note_path}"] = sha256_file(src)
            notes_copied += 1
            print(f"  Note:   {note_path}")
        else:
            notes_missing.append(note_path)

    if notes_missing:
        print(f"WARNING: {len(notes_missing)} note(s) not found in Studio_OS/:")
        for n in notes_missing:
            print(f"  - {n}")

    # Create new_files directory (empty placeholder)
    new_files_dir = pack_dir / 'new_files'
    new_files_dir.mkdir(exist_ok=True)
    for filepath in ticket['new_files']:
        (new_files_dir / filepath).parent.mkdir(parents=True, exist_ok=True)

    # Write manifest
    manifest = {
        'ticket_id': ticket['id'],
        'allowed_file_count': copied_count,
        'vault_note_count': notes_copied,
        'max_allowed': MAX_ALLOWED_FILES,
        'hash_algorithm': 'sha256',
        'files': manifest_entries,
    }
    manifest_path = pack_dir / 'manifest.json'
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    # Write human-readable metadata
    metadata_path = pack_dir / 'pack_metadata.txt'
    with open(metadata_path, 'w') as f:
        f.write(f"Ticket: {ticket['id']}\n")
        f.write(f"Title: {ticket['title']}\n")
        f.write(f"Goal: {ticket['goal']}\n")
        f.write(f"\nAllowed files ({copied_count}/{len(ticket['allowed_files'])}):\n")
        for fpath in ticket['allowed_files']:
            f.write(f"  - {fpath}\n")
        f.write(f"\nVault notes ({notes_copied}/{len(ticket['notes'])}):\n")
        for note in ticket['notes']:
            f.write(f"  - Studio_OS/{note}\n")
        f.write(f"\nNew files ({len(ticket['new_files'])}):\n")
        for fpath in ticket['new_files']:
            f.write(f"  - {fpath}\n")

    print(f"\nContext pack created: {pack_dir}")
    print(f"  Code files:  {copied_count}/{len(ticket['allowed_files'])}")
    print(f"  Vault notes: {notes_copied}/{len(ticket['notes'])}")
    print(f"  Manifest:    {manifest_path}")
    return str(pack_dir)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python tools/build_context_pack.py <ticket_file>")
        print("Exit codes: 0=ok, 1=bad ticket, 2=path violation, 3=count exceeded, 4=empty pack")
        sys.exit(1)

    ticket_path = sys.argv[1]
    if not os.path.exists(ticket_path):
        print(f"FATAL: Ticket file not found: {ticket_path}")
        sys.exit(1)

    build_context_pack(ticket_path)
