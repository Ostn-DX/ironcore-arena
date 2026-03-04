#!/usr/bin/env python3
"""
normalize_agent_output.py - Validates and normalizes agent deliverables.

Usage:
    python tools/normalize_agent_output.py TICKET-001

Validates:
    - Required directory structure exists
    - No TODO/stubs (unless explicitly allowed in ticket)
    - No edits outside allowlist
    - All files have complete contents

Enforces output structure:
    agent_runs/TICKET-001/
        NEW_FILES/
        MODIFICATIONS/
        TESTS/
        INTEGRATION_GUIDE.md
        CHANGELOG.md
"""

import sys
import os
import re
from pathlib import Path

class OutputNormalizer:
    def __init__(self, ticket_id: str):
        self.repo_root = Path(__file__).parent.parent
        self.ticket_id = ticket_id
        self.run_dir = self.repo_root / 'agent_runs' / ticket_id
        self.errors = []
        self.warnings = []
        
        # Load ticket to get allowlist
        self.ticket_path = self.repo_root / 'agents' / 'tickets' / f"{ticket_id}.md"
        self.allowed_files = []
        self.new_files = []
        self._load_ticket()
    
    def _load_ticket(self):
        """Parse ticket for allowlist."""
        if not self.ticket_path.exists():
            # Try alternative locations
            alt_paths = [
                self.repo_root / 'agents' / f"{self.ticket_id}.md",
                self.repo_root / f"{self.ticket_id}.md",
            ]
            for alt in alt_paths:
                if alt.exists():
                    self.ticket_path = alt
                    break
        
        if self.ticket_path.exists():
            with open(self.ticket_path, 'r') as f:
                content = f.read()
            
            # Parse allowed files
            import re
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
                            self.allowed_files.append(filepath)
            
            # Parse new files
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
                            self.new_files.append(filepath)
    
    def validate_structure(self) -> bool:
        """Check required directories and files exist."""
        if not self.run_dir.exists():
            self.errors.append(f"Run directory not found: {self.run_dir}")
            return False
        
        required = ['NEW_FILES', 'MODIFICATIONS', 'TESTS']
        for req in required:
            req_path = self.run_dir / req
            if not req_path.exists():
                self.warnings.append(f"Creating missing directory: {req}")
                req_path.mkdir(parents=True, exist_ok=True)
        
        required_files = ['INTEGRATION_GUIDE.md', 'CHANGELOG.md']
        for req in required_files:
            req_path = self.run_dir / req
            if not req_path.exists():
                self.errors.append(f"Required file missing: {req}")
        
        return len(self.errors) == 0
    
    def validate_new_files(self) -> bool:
        """Check NEW_FILES for completeness."""
        new_files_dir = self.run_dir / 'NEW_FILES'
        if not new_files_dir.exists():
            return True
        
        gd_files = list(new_files_dir.rglob('*.gd'))
        
        for gd_file in gd_files:
            with open(gd_file, 'r') as f:
                content = f.read()
            
            # Check for TODO/FIXME/XXX stubs
            stub_patterns = [
                r'TODO[:\s]',
                r'FIXME[:\s]',
                r'XXX[:\s]',
                r'pass\s*#.*implement',
                r'#.*implement.*later',
            ]
            for pattern in stub_patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    rel_path = gd_file.relative_to(new_files_dir)
                    self.errors.append(f"Stub found in {rel_path}: {pattern}")
            
            # Check for empty functions
            if re.search(r'func\s+\w+\([^)]*\)\s*->\s*\w+\s*:\s*\n\s*pass\s*$', content, re.MULTILINE):
                rel_path = gd_file.relative_to(new_files_dir)
                self.errors.append(f"Empty function found in {rel_path}")
            
            # Check for type hints (GDScript 2.0 requirement)
            func_matches = re.finditer(r'func\s+(\w+)\([^)]*\)', content)
            for match in func_matches:
                func_name = match.group(1)
                if func_name.startswith('_'):
                    continue  # Private functions can skip return type in some cases
                # Check if return type is specified
                func_start = match.end()
                next_chars = content[func_start:func_start+20]
                if '->' not in next_chars and func_name not in ['_ready', '_process', '_physics_process']:
                    rel_path = gd_file.relative_to(new_files_dir)
                    self.warnings.append(f"Missing return type in {rel_path}:{func_name}")
        
        return len(self.errors) == 0
    
    def validate_modifications(self) -> bool:
        """Check MODIFICATIONS don't touch forbidden files."""
        mods_dir = self.run_dir / 'MODIFICATIONS'
        if not mods_dir.exists():
            return True
        
        # Get list of files in modifications
        mod_files = list(mods_dir.glob('*.patch')) + list(mods_dir.glob('*.gd'))
        
        for mod_file in mod_files:
            # Extract filename from patch or direct file
            if mod_file.suffix == '.patch':
                with open(mod_file, 'r') as f:
                    content = f.read()
                # Parse patch for filenames
                file_matches = re.findall(r'^---\s+(\S+)', content, re.MULTILINE)
            else:
                file_matches = [mod_file.name]
            
            for filepath in file_matches:
                # Clean up path
                filepath = filepath.replace('a/', '').replace('b/', '')
                
                # Check if in allowlist
                if filepath not in self.allowed_files:
                    self.errors.append(f"Modification touches forbidden file: {filepath}")
        
        return len(self.errors) == 0
    
    def normalize(self) -> bool:
        """Run all validations and create normalized output."""
        print(f"Normalizing output for {self.ticket_id}")
        print("=" * 50)
        
        self.validate_structure()
        self.validate_new_files()
        self.validate_modifications()
        
        # Print results
        if self.warnings:
            print("\nWarnings:")
            for w in self.warnings:
                print(f"  ⚠ {w}")
        
        if self.errors:
            print("\nErrors:")
            for e in self.errors:
                print(f"  ✗ {e}")
            print(f"\n❌ Validation FAILED ({len(self.errors)} errors)")
            return False
        
        print("\n✓ Structure validated")
        print("✓ New files validated")
        print("✓ Modifications validated")
        print(f"\n✅ Output normalized: {self.run_dir}")
        return True
    
    def generate_report(self) -> str:
        """Generate validation report."""
        report_path = self.repo_root / 'reports' / f"{self.ticket_id}_validation.txt"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_path, 'w') as f:
            f.write(f"Validation Report: {self.ticket_id}\n")
            f.write("=" * 50 + "\n\n")
            
            f.write(f"Status: {'PASS' if not self.errors else 'FAIL'}\n\n")
            
            if self.errors:
                f.write("Errors:\n")
                for e in self.errors:
                    f.write(f"  - {e}\n")
                f.write("\n")
            
            if self.warnings:
                f.write("Warnings:\n")
                for w in self.warnings:
                    f.write(f"  - {w}\n")
                f.write("\n")
            
            f.write(f"\nOutput directory: {self.run_dir}\n")
        
        return str(report_path)

def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/normalize_agent_output.py <ticket_id>")
        print("Example: python tools/normalize_agent_output.py TICKET-001")
        sys.exit(1)
    
    ticket_id = sys.argv[1]
    normalizer = OutputNormalizer(ticket_id)
    
    success = normalizer.normalize()
    report_path = normalizer.generate_report()
    
    print(f"\nReport saved: {report_path}")
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
