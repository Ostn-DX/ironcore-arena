## UI Smoke Navigation Runner

Creates: res://tools/run_ui_smoke.gd

Requirements:
- Load Main Menu scene
- Trigger navigation through: Main Menu → Builder → Campaign → Battle → Results → back
- Output JSON report to /reports/ui_smoke.json
- Exit nonzero on any failure to transition or missing node/signal

Navigation path:
1. Main Menu (check buttons exist)
2. Click "Builder" → Builder screen
3. Click "Campaign" → Campaign map
4. Click first arena → Battle
5. Wait for battle end (or force end)
6. Results screen
7. Click "Continue" → back to Campaign

Report fields:
- Each transition attempt (source → target)
- Success/failure per transition
- Error messages for failures
- Total time taken

Implementation notes:
- Use SceneTree.change_scene_to_file()
- Simulate button presses via signal emission
- Check for required nodes before interaction
- Set short timeouts for battle (use SimulationManager.MAX_TICKS limit)
