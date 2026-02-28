## Gate Scripts

Creates: tools/dev_gate.ps1 + tools/dev_gate.sh

Requirements:
1. Run headless matches (res://tools/run_headless_matches.gd)
2. Run UI smoke (res://tools/run_ui_smoke.gd)
3. Fail fast on nonzero exit
4. Print brief summary of where it failed

PowerShell script structure:
- Check Godot executable exists
- Run headless matches with --headless --script flags
- Check $LASTEXITCODE
- Run UI smoke
- Check $LASTEXITCODE
- Print summary

Bash script structure:
- Similar logic for Linux/Mac
- Use godot --headless --script
- Check $?
- Print summary

Both scripts should:
- Set working directory to repo root
- Create reports/ directory if missing
- Output clear pass/fail messages
