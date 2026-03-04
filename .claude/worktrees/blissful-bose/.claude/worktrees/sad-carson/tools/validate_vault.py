#!/usr/bin/env python3
"""
validate_vault.py - Validates all markdown files in the Studio_OS vault.

Checks:
    - Every .md file has valid YAML frontmatter
    - Required fields: title, type, layer, status
    - No file read errors (encoding, permissions)

Exit codes:
    0 - All files valid
    1 - Vault path not found or empty
    2 - One or more validation errors
"""

import os
import sys

try:
    import yaml
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

VAULT_DIR_NAME = "Studio_OS"
VAULT_ROOT = os.path.join(REPO_ROOT, VAULT_DIR_NAME)

REQUIRED_FRONTMATTER_FIELDS = ["title", "type", "layer", "status"]


def find_markdown_files(root: str):
    md_files = []
    for dirpath, _, filenames in os.walk(root):
        for f in filenames:
            if f.endswith(".md"):
                md_files.append(os.path.join(dirpath, f))
    return sorted(md_files)


def extract_frontmatter(content: str):
    if not content.startswith("---"):
        return None
    parts = content.split("---", 2)
    if len(parts) < 3:
        return None
    raw = parts[1].strip()
    if not raw:
        return None  # empty frontmatter block (---\n---)
    return parts[1]


def validate_frontmatter(filepath: str):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except UnicodeDecodeError as e:
        return False, f"Encoding error (not valid UTF-8): {e}"
    except OSError as e:
        return False, f"Read error: {e}"

    fm_text = extract_frontmatter(content)
    if fm_text is None:
        return False, "Missing or malformed YAML frontmatter"

    try:
        data = yaml.safe_load(fm_text)
    except yaml.YAMLError as e:
        return False, f"Invalid YAML frontmatter: {e}"

    if not isinstance(data, dict):
        return False, f"Frontmatter is not a mapping (got {type(data).__name__})"

    missing = [f for f in REQUIRED_FRONTMATTER_FIELDS if f not in data]
    if missing:
        return False, f"Missing required field(s): {', '.join(missing)}"

    # Ensure required fields are non-empty
    for field in REQUIRED_FRONTMATTER_FIELDS:
        val = data[field]
        if val is None or (isinstance(val, str) and not val.strip()):
            return False, f"Required field '{field}' is empty"

    return True, None


def main():
    if not os.path.isdir(VAULT_ROOT):
        print(f"FATAL: Vault path not found: {VAULT_DIR_NAME} (expected at {VAULT_ROOT})")
        sys.exit(1)

    files = find_markdown_files(VAULT_ROOT)
    if not files:
        print("FATAL: No markdown files found in vault.")
        sys.exit(1)

    errors = []
    checked = 0
    for fpath in files:
        checked += 1
        ok, err = validate_frontmatter(fpath)
        if not ok:
            rel = os.path.relpath(fpath, REPO_ROOT)
            errors.append(f"{rel}: {err}")

    print(f"Checked {checked} file(s) in {VAULT_DIR_NAME}/")

    if errors:
        print(f"\nVAULT VALIDATION FAILED — {len(errors)} error(s):")
        for e in errors[:200]:
            print(f"  ✗ {e}")
        if len(errors) > 200:
            print(f"  ... and {len(errors) - 200} more")
        sys.exit(2)

    print("VAULT VALIDATION PASSED")
    sys.exit(0)


if __name__ == "__main__":
    main()