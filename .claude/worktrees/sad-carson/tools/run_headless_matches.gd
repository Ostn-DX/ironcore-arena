##
## Headless Match Runner - Automated battle testing tool
## Runs AI vs AI matches without UI to validate simulation stability
##
## Usage: godot --headless --script res://tools/run_headless_matches.gd
## Output: reports/match_report.json
##

class_name HeadlessMatchRunner
extends SceneTree

const MATCH_COUNT: int = 10
const SEEDS: Array[int] = [12345, 67890, 11111, 22222, 33333, 44444, 55555, 66666, 77777, 88888]

var _simulation: SimulationManager
var _data_loader: DataLoader
var _current_match: int = 0
var _results: Array[Dictionary] = []
var _current_arena: Dictionary = {}
var _start_time: int = 0
var _crashes: int = 0
var _timeouts: int = 0

func _initialize() -> void:
    ## Initialize autoloads manually in headless mode
    _data_loader = load("res://autoload/DataLoader.gd").new()
    root.add_child(_data_loader)
    _data_loader._ready()
    
    _simulation = load("res://autoload/SimulationManager.gd").new()
    root.add_child(_simulation)
    _simulation._ready()
    
    # Connect to battle events
    _simulation.battle_ended.connect(_on_battle_ended)
    
    # Create reports directory
    var dir := DirAccess.open("user://")
    if dir:
        dir.make_dir_recursive("reports")
    
    # Start first match
    _run_next_match()

func _run_next_match() -> void:
    if _current_match >= MATCH_COUNT:
        _generate_report()
        quit(0 if _crashes == 0 else 1)
        return
    
    var seed_val: int = SEEDS[_current_match]
    _start_time = Time.get_ticks_msec()
    
    # Get first arena config
    _current_arena = _data_loader.get_arena("roxtan_park")
    if _current_arena.is_empty():
        _log_error("Failed to load arena: roxtan_park")
        _crashes += 1
        _current_match += 1
        _run_next_match()
        return
    
    # Create simple bot loadouts
    var player_loadout: Dictionary = _create_test_loadout("player")
    var enemy_loadout: Dictionary = _create_test_loadout("enemy")
    
    # Start battle
    _simulation.start_battle(
        _current_arena,
        [player_loadout],
        [enemy_loadout],
        true  # headless
    )

func _create_test_loadout(team: String) -> Dictionary:
    return {
        "id": "test_" + team,
        "chassis": "akaumin_dl2_100",
        "weapons": ["raptor_dt_01"],
        "armor": ["santrin_auro"],
        "mobility": "mob_wheels_t1",
        "sensors": "sen_basic_t1",
        "ai_profile": "ai_balanced" if team == "player" else "ai_aggressive"
    }

func _on_battle_ended(result: String, tick_count: int) -> void:
    var duration_ms: int = Time.get_ticks_msec() - _start_time
    var duration_sec: float = duration_ms / 1000.0
    
    # Check for timeout
    if tick_count >= _simulation.MAX_TICKS - 10:
        _timeouts += 1
    
    var match_result: Dictionary = {
        "match_id": _current_match,
        "seed": SEEDS[_current_match],
        "result": result,
        "winner": 0 if result == "victory" else 1,
        "ticks": tick_count,
        "duration_seconds": duration_sec,
        "crashed": false
    }
    
    _results.append(match_result)
    
    print("Match %d/%d: %s (%d ticks, %.2fs)" % [_current_match + 1, MATCH_COUNT, result, tick_count, duration_sec])
    
    _current_match += 1
    _run_next_match()

func _generate_report() -> void:
    var total_duration: float = 0.0
    var wins: Dictionary = {0: 0, 1: 0}
    
    for r in _results:
        total_duration += r["duration_seconds"]
        wins[r["winner"]] += 1
    
    var report: Dictionary = {
        "version": "0.1.0",
        "timestamp": Time.get_datetime_string_from_system(),
        "total_matches": MATCH_COUNT,
        "seeds": SEEDS,
        "crashes": _crashes,
        "timeouts": _timeouts,
        "timeout_rate": float(_timeouts) / float(MATCH_COUNT),
        "average_duration_seconds": total_duration / float(MATCH_COUNT),
        "win_rates": {
            "player_team": float(wins[0]) / float(MATCH_COUNT),
            "enemy_team": float(wins[1]) / float(MATCH_COUNT)
        },
        "results": _results,
        "errors": _get_error_log()
    }
    
    var json_string: String = JSON.stringify(report, "  ")
    var file := FileAccess.open("user://reports/match_report.json", FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
        print("\nReport saved: user://reports/match_report.json")
    else:
        push_error("Failed to write report file")
    
    # Print summary
    print("\n=== HEADLESS MATCH SUMMARY ===")
    print("Total matches: %d" % MATCH_COUNT)
    print("Crashes: %d" % _crashes)
    print("Timeouts: %d (%.1f%%)" % [_timeouts, float(_timeouts) / float(MATCH_COUNT) * 100])
    print("Avg duration: %.2fs" % (total_duration / float(MATCH_COUNT)))
    print("Player win rate: %.1f%%" % (float(wins[0]) / float(MATCH_COUNT) * 100))
    print("==============================")

func _log_error(message: String) -> void:
    push_error(message)
    print("ERROR: " + message)

func _get_error_log() -> Array[String]:
    # Collect recent errors
    var errors: Array[String] = []
    # Godot doesn't have easy error log access, so we track manually
    return errors

# Entry point for --script execution
func _init():
    print("=== Ironcore Arena Headless Match Runner ===")
    print("Running %d matches...\n" % MATCH_COUNT)
    
    # Delay initialization to ensure SceneTree is ready
    create_timer(0.1).timeout.connect(_initialize)
