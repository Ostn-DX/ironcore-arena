import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
VAULT_DIR_NAME = "Studio_OS"
VAULT_ROOT = REPO_ROOT / VAULT_DIR_NAME

# Minimal schema to satisfy validation and keep links intact
DEFAULT_FM = {
    "title": None,          # will be filled from filename if missing
    "type": "note",
    "layer": "unknown",
    "status": "draft",
    "tags": [],
    "depends_on": [],
    "used_by": [],
}

FM_START = "---\n"
FM_END = "---\n"

def slug_title_from_filename(path: Path) -> str:
    return path.stem.replace("_", " ").strip()

def extract_frontmatter(text: str):
    if not text.startswith("---"):
        return None, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None, text
    fm_raw = parts[1]
    body = parts[2].lstrip("\n")
    return fm_raw, body

def parse_simple_kv_lines(fm_raw: str):
    """
    Robust parser for "YAML-ish" frontmatter.
    Accepts:
      key: value
      key: [a, b]
      key:
        - item
    Any unparseable lines are preserved in _raw_frontmatter.
    """
    lines = fm_raw.splitlines()
    data = {}
    raw_unparsed = []

    i = 0
    while i < len(lines):
        line = lines[i].rstrip("\r")
        if not line.strip():
            i += 1
            continue

        # tabs break YAML frequently; normalize
        line = line.replace("\t", "  ")

        # list item without a current key -> unparsed
        if re.match(r"^\s*-\s+", line):
            raw_unparsed.append(line)
            i += 1
            continue

        m = re.match(r"^([A-Za-z0-9_\-]+)\s*:\s*(.*)$", line)
        if not m:
            raw_unparsed.append(line)
            i += 1
            continue

        key, val = m.group(1), m.group(2).strip()

        # Multiline list form:
        if val == "":
            # gather indented list items
            items = []
            j = i + 1
            while j < len(lines):
                nxt = lines[j].replace("\t", "  ").rstrip("\r")
                if re.match(r"^\s*-\s+", nxt):
                    items.append(re.sub(r"^\s*-\s+", "", nxt).strip())
                    j += 1
                elif nxt.strip() == "":
                    j += 1
                else:
                    break
            # if we collected items, store list; else store empty list
            data[key] = items if items else []
            i = j
            continue

        # Inline list: [a, b]
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            if inner == "":
                data[key] = []
            else:
                data[key] = [x.strip().strip('"').strip("'") for x in inner.split(",")]
            i += 1
            continue

        # scalar
        data[key] = val.strip().strip('"').strip("'")
        i += 1

    if raw_unparsed:
        data["_raw_frontmatter"] = raw_unparsed

    return data

def to_yaml_block(d: dict) -> str:
    """
    Emit conservative YAML that never breaks:
    - strings quoted only when needed
    - lists as block lists
    """
    def yaml_scalar(v):
        if v is None:
            return '""'
        if isinstance(v, bool):
            return "true" if v else "false"
        if isinstance(v, (int, float)):
            return str(v)
        s = str(v)
        # Quote if it contains colon, hash, brackets, or leading/trailing spaces
        if any(ch in s for ch in [":", "#", "[", "]", "{", "}", ","]) or s != s.strip():
            return '"' + s.replace('"', '\\"') + '"'
        return s

    out = []
    for k in ["title", "type", "layer", "status", "tags", "depends_on", "used_by"]:
        v = d.get(k)
        if isinstance(v, list):
            out.append(f"{k}:")
            for item in v:
                out.append(f"  - {yaml_scalar(item)}")
            if not v:
                out[-1] = f"{k}: []"
        else:
            out.append(f"{k}: {yaml_scalar(v)}")

    # Preserve any unparsed junk so you can recover later (optional)
    raw = d.get("_raw_frontmatter")
    if raw:
        out.append("_raw_frontmatter:")
        for line in raw:
            out.append(f'  - "{line.replace(chr(34), r"\"")}"')

    return "\n".join(out) + "\n"

def repair_file(path: Path):
    text = path.read_text(encoding="utf-8", errors="replace")
    fm_raw, body = extract_frontmatter(text)

    # If missing frontmatter, add defaults
    if fm_raw is None:
        d = dict(DEFAULT_FM)
        d["title"] = slug_title_from_filename(path)
        new_text = FM_START + to_yaml_block(d) + FM_END + "\n" + text.lstrip("\n")
        path.write_text(new_text, encoding="utf-8")
        return "added"

    # Parse YAML-ish
    parsed = parse_simple_kv_lines(fm_raw)
    d = dict(DEFAULT_FM)

    # Fill from parsed if present
    for k in d.keys():
        if k in parsed and parsed[k] not in [None, ""]:
            d[k] = parsed[k]

    # Ensure title
    if not d["title"]:
        d["title"] = slug_title_from_filename(path)

    # Normalize list fields if someone wrote strings
    for lk in ["tags", "depends_on", "used_by"]:
        if isinstance(d[lk], str):
            d[lk] = [d[lk]]
        elif d[lk] is None:
            d[lk] = []

    # Preserve raw garbage
    if "_raw_frontmatter" in parsed:
        d["_raw_frontmatter"] = parsed["_raw_frontmatter"]

    new_text = FM_START + to_yaml_block(d) + FM_END + "\n" + body
    path.write_text(new_text, encoding="utf-8")
    return "repaired"

def main():
    if not VAULT_ROOT.is_dir():
        print(f"Vault not found: {VAULT_ROOT}")
        sys.exit(1)

    md_files = list(VAULT_ROOT.rglob("*.md"))
    changed = {"added": 0, "repaired": 0}

    for f in md_files:
        result = repair_file(f)
        changed[result] += 1

    print(f"Frontmatter fix complete. added={changed['added']} repaired={changed['repaired']} total={len(md_files)}")

if __name__ == "__main__":
    main()