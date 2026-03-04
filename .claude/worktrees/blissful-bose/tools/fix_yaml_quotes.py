#!/usr/bin/env python3
"""Fix YAML frontmatter - wrap titles with colons in quotes."""

import os
import re
from pathlib import Path

base_path = Path("/home/node/.openclaw/workspace/ironcore-work/Studio_OS/13_Studio_OS_System")

def fix_frontmatter(filepath):
    """Fix frontmatter by quoting titles with colons."""
    content = filepath.read_text(encoding='utf-8')
    
    # Find and fix title lines with colons that aren't quoted
    # Pattern: title: D01: Something -> title: "D01: Something"
    new_content = re.sub(
        r'^title: ([^"\n][^\n]*?:[^\n]*)$',
        r'title: "\1"',
        content,
        flags=re.MULTILINE
    )
    
    if new_content != content:
        filepath.write_text(new_content, encoding='utf-8')
        print(f"✅ Fixed: {filepath.name}")
        return True
    return False

def main():
    fixed = 0
    
    # Walk through all files in the directory
    for root, dirs, files in os.walk(base_path):
        for filename in files:
            if filename.endswith('.md'):
                filepath = Path(root) / filename
                if fix_frontmatter(filepath):
                    fixed += 1
    
    print(f"\nFixed {fixed} files")

if __name__ == "__main__":
    main()
