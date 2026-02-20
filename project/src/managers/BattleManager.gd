extends Node
class_name BattleManager
## BattleManager — orchestrates a single battle instance.
## Coordinates between BattleScreen (visuals), SimulationManager (simulation),
## and GameState (player progress). Handles setup, combat flow, and results.

enum BattleState { SETUP, COUNTDOWN, ACTIVE, PAUSED, ENDED }

# Signals
signal battle_started(arena_id: String)
signal battle_state_changed(new_state: BattleState, old_state: BattleState)
signal countdown_tick(seconds_left: int)
signal battle_ended(result: BattleResult)
signal rewards_calculated(rewards: Dictionary)

# Battle result data
class BattleResult:
    var victory: bool = false
    var arena_id: String = ""
    var arena_name: String = ""
    var completion_time: float = 0.0
    var par_time: float = 0.0
    var player_bots_lost: int = 0
    var enemy_bots_destroyed: int = 0
    var ticks_elapsed: int = 0
    
    func is_par_met() -> bool:
        return completion_time <= par_time
    
    func get_grade() -> String:
        if not victory:
            return "F"
        var time_ratio: float = completion_time / par_time if par_time > 0 else 1.0
        if time_ratio <= 0.5:
            return "S"
        elif time_ratio <= 0.75:
            return "A"
        elif time_ratio <= 1.0:
            return "B"
        elif time_ratio <= 1.5:
            return "C"
        else:
            return "D"

# Current battle state
var current_state: BattleState = BattleState.SETUP
var current_arena_id: String = ""
var current_arena_data: Dictionary = {}
var battle_result: BattleResult = null

# Battle configuration
var player_loadouts: Array[Dictionary] = []
var enemy_loadouts: Array[Dictionary] = []
var countdown_seconds: int = 3

# Runtime
var _countdown_timer: float = 0.0
var _battle_start_tick: int = 0

# Visual scene reference (set by BattleScreen)
var battle_screen: Control = null


func _ready() -> void:
    # Connect to SimulationManager signals
    if SimulationManager:
        SimulationManager.battle_ended.connect(_on_simulation_battle_ended)
        SimulationManager.tick_processed.connect(_on_tick_processed)


func _process(delta: float) -> void:
    match current_state:
        BattleState.COUNTDOWN:
            _process_countdown(delta)
        BattleState.ACTIVE:
            _process_active()


func _process_countdown(delta: float) -> void:
    _countdown_timer -= delta
    var seconds_left: int = ceil(_countdown_timer)
    
    countdown_tick.emit(seconds_left)
    
    if _countdown_timer <= 0:
        _start_combat()


func _process_active() -> void:
    # Check for manual pause input
    if Input.is_action_just_pressed("ui_cancel"):
        toggle_pause()


# ============================================================================
# PUBLIC API
# ============================================================================

func setup_battle(arena_id: String, player_loadouts_override: Array[Dictionary] = []) -> bool:
    ## Setup a new battle with the given arena and player loadouts
    ## Returns true if setup successful, false otherwise
    
    if current_state != BattleState.SETUP:
        push_warning("BattleManager: Cannot setup battle while in state: %s" % _state_to_string(current_state))
        return false
    
    # Load arena data
    current_arena_id = arena_id
    current_arena_data = DataLoader.get_arena(arena_id)
    
    if current_arena_data.is_empty():
        push_error("BattleManager: Arena not found: %s" % arena_id)
        return false
    
    # Get player loadouts
    if player_loadouts_override.is_empty():
        player_loadouts = GameState.get_active_loadouts()
    else:
        player_loadouts = player_loadouts_override
    
    if player_loadouts.is_empty():
        push_error("BattleManager: No player loadouts available")
        return false
    
    # Generate enemy loadouts based on arena tier
    enemy_loadouts = _generate_enemy_loadouts()
    
    print("BattleManager: Setup complete for arena '%s' with %d player bots vs %d enemies" % [
        current_arena_data.get("name", arena_id),
        player_loadouts.size(),
        enemy_loadouts.size()
    ])
    
    return true


func start_battle() -> void:
    ## Start the battle countdown
    if current_state != BattleState.SETUP:
        push_warning("BattleManager: Cannot start battle from state: %s" % _state_to_string(current_state))
        return
    
    _change_state(BattleState.COUNTDOWN)
    _countdown_timer = float(countdown_seconds)
    battle_started.emit(current_arena_id)


func toggle_pause() -> void:
    ## Toggle battle pause state
    if current_state == BattleState.ACTIVE:
        _change_state(BattleState.PAUSED)
        if SimulationManager:
            SimulationManager.pause()
    elif current_state == BattleState.PAUSED:
        _change_state(BattleState.ACTIVE)
        if SimulationManager:
            SimulationManager.resume()


func end_battle_early() -> void:
    ## End battle immediately (player surrender/retreat)
    if current_state in [BattleState.ACTIVE, BattleState.PAUSED]:
        if SimulationManager:
            SimulationManager.stop_battle()
        _finalize_battle(false)


func get_battle_time() -> float:
    ## Get elapsed battle time in seconds
    if current_state == BattleState.ACTIVE and SimulationManager:
        var ticks: int = SimulationManager.current_tick - _battle_start_tick
        return ticks / 60.0  # 60 ticks per second
    return 0.0


func get_formatted_time() -> String:
    ## Get battle time as MM:SS
    var total_seconds: int = int(get_battle_time())
    var minutes: int = total_seconds / 60
    var seconds: int = total_seconds % 60
    return "%02d:%02d" % [minutes, seconds]


func get_battle_summary() -> Dictionary:
    ## Get current battle state summary for HUD
    var player_alive: int = 0
    var enemy_alive: int = 0
    var enemy_total: int = 0
    
    if SimulationManager:
        for bot_id in SimulationManager.bots:
            var bot = SimulationManager.bots[bot_id]
            if bot.is_alive:
                if bot.team == 0:
                    player_alive += 1
                else:
                    enemy_alive += 1
            if bot.team == 1:
                enemy_total += 1
    
    return {
        "state": _state_to_string(current_state),
        "time": get_formatted_time(),
        "player_alive": player_alive,
        "player_total": player_loadouts.size(),
        "enemy_alive": enemy_alive,
        "enemy_total": max(enemy_total, enemy_loadouts.size()),
        "arena_name": current_arena_data.get("name", "Unknown")
    }


# ============================================================================
# PRIVATE METHODS
# ============================================================================

func _start_combat() -> void:
    ## Actually start the simulation combat
    _change_state(BattleState.ACTIVE)
    
    # Convert arena data to SimulationManager format
    var sim_arena_data: Dictionary = _convert_arena_data(current_arena_data)
    
    # Start simulation
    if SimulationManager:
        SimulationManager.start_battle(sim_arena_data, player_loadouts, enemy_loadouts, false)
        _battle_start_tick = SimulationManager.current_tick
    
    print("BattleManager: Combat started!")


func _convert_arena_data(arena: Dictionary) -> Dictionary:
    ## Convert components.json arena format to SimulationManager format
    var dimensions: Array = arena.get("dimensions", [800, 600])
    var width: int = dimensions[0] if dimensions.size() > 0 else 800
    var height: int = dimensions[1] if dimensions.size() > 1 else 600
    
    # Generate spawn points
    var player_spawns: Array[Dictionary] = [
        {"x": width * 0.15, "y": height * 0.3},
        {"x": width * 0.15, "y": height * 0.5},
        {"x": width * 0.15, "y": height * 0.7}
    ]
    
    var enemy_spawns: Array[Dictionary] = [
        {"x": width * 0.85, "y": height * 0.3},
        {"x": width * 0.85, "y": height * 0.5},
        {"x": width * 0.85, "y": height * 0.7}
    ]
    
    return {
        "id": arena.get("id", "unknown"),
        "size": {"width": width, "height": height},
        "spawn_points_player": player_spawns,
        "spawn_points_enemy": enemy_spawns,
        "obstacles": [],  # TODO: Add obstacle support
        "seed": randi()  # Random seed for this battle
    }


func _generate_enemy_loadouts() -> Array[Dictionary]:
    ## Generate enemy bot loadouts based on arena tier
    var arena_tier: int = current_arena_data.get("tier", 1)
    var enemy_count: int = min(arena_tier + 1, 4)  # 2-4 enemies based on tier
    
    var loadouts: Array[Dictionary] = []
    
    # Get available components for this tier
    var available_chassis: Array = DataLoader.get_chassis_by_tier(arena_tier)
    if available_chassis.is_empty():
        available_chassis = DataLoader.get_all_chassis()
    
    var available_weapons: Array = DataLoader.get_weapons_by_tier(arena_tier)
    if available_weapons.is_empty():
        available_weapons = DataLoader.get_all_weapons()
    
    var available_plating: Array = DataLoader.get_all_plating()
    
    # Generate enemies
    for i in range(enemy_count):
        var chassis: Dictionary = available_chassis[i % available_chassis.size()] if not available_chassis.is_empty() else {}
        var weapon: Dictionary = available_weapons[i % available_weapons.size()] if not available_weapons.is_empty() else {}
        var plating: Dictionary = available_plating[i % available_plating.size()] if not available_plating.is_empty() else {}
        
        var loadout: Dictionary = {
            "id": "enemy_%d_%s" % [i, current_arena_id],
            "name": "Enemy %d" % (i + 1),
            "chassis": chassis.get("id", "akaumin_dl2_100"),
            "weapons": [weapon.get("id", "raptor_dt_01")],
            "armor": [plating.get("id", "santrin_auro")],
            "mobility": ["mob_wheels_t1"],
            "sensors": ["sen_basic_t1"],
            "utilities": [],
            "ai_profile": _select_ai_profile(i)
        }
        
        loadouts.append(loadout)
    
    return loadouts


func _select_ai_profile(enemy_index: int) -> String:
    ## Select AI profile based on enemy position
    match enemy_index % 4:
        0: return "ai_aggressive"
        1: return "ai_balanced"
        2: return "ai_defensive"
        _: return "ai_balanced"


func _on_tick_processed(tick: int) -> void:
    ## Called every simulation tick
    if current_state != BattleState.ACTIVE:
        return
    
    # Check for timeout
    var max_ticks: int = 10800  # 3 minutes
    if tick - _battle_start_tick >= max_ticks:
        _resolve_stalemate()


func _on_simulation_battle_ended(result: String, tick_count: int) -> void:
    ## Called when SimulationManager detects victory/defeat
    var victory: bool = (result == "PLAYER_WIN")
    _finalize_battle(victory, tick_count)


func _resolve_stalemate() -> void:
    ## Resolve battle when time runs out
    if SimulationManager:
        SimulationManager.stop_battle()
    
    # Determine winner by remaining HP
    var player_hp: float = 0.0
    var enemy_hp: float = 0.0
    
    for bot_id in SimulationManager.bots:
        var bot = SimulationManager.bots[bot_id]
        if bot.team == 0:
            player_hp += bot.hp
        else:
            enemy_hp += bot.hp
    
    _finalize_battle(player_hp > enemy_hp, SimulationManager.current_tick)


func _finalize_battle(victory: bool, final_tick: int = 0) -> void:
    ## Finalize battle and calculate results
    _change_state(BattleState.ENDED)
    
    # Create result object
    battle_result = BattleResult.new()
    battle_result.victory = victory
    battle_result.arena_id = current_arena_id
    battle_result.arena_name = current_arena_data.get("name", "Unknown")
    battle_result.ticks_elapsed = final_tick - _battle_start_tick
    battle_result.completion_time = battle_result.ticks_elapsed / 60.0
    battle_result.par_time = current_arena_data.get("par_time", 120)
    
    # Count bots
    if SimulationManager:
        for bot_id in SimulationManager.bots:
            var bot = SimulationManager.bots[bot_id]
            if bot.team == 0 and not bot.is_alive:
                battle_result.player_bots_lost += 1
            elif bot.team == 1 and not bot.is_alive:
                battle_result.enemy_bots_destroyed += 1
    
    # Calculate rewards
    var rewards: Dictionary = _calculate_rewards()
    
    # Apply rewards if victory
    if victory:
        GameState.add_credits(rewards["credits"])
        GameState.complete_arena(current_arena_id)
    
    print("BattleManager: Battle ended! Victory: %s, Grade: %s, Credits: %d" % [
        victory, battle_result.get_grade(), rewards["credits"]
    ])
    
    battle_ended.emit(battle_result)
    rewards_calculated.emit(rewards)


func _calculate_rewards() -> Dictionary:
    ## Calculate battle rewards based on performance
    if not battle_result:
        return {"credits": 0, "bonus_credits": 0, "parts": []}
    
    var base_reward: int = current_arena_data.get("base_reward", 100)
    var bonus: int = 0
    
    # Victory bonus
    if battle_result.victory:
        # Par time bonus
        if battle_result.is_par_met():
            bonus += base_reward / 2
        
        # Grade bonus
        match battle_result.get_grade():
            "S": bonus += base_reward
            "A": bonus += base_reward / 2
            "B": bonus += base_reward / 4
    else:
        # Defeat: only 10% of base reward
        base_reward = base_reward / 10
    
    return {
        "credits": base_reward + bonus,
        "base_credits": base_reward,
        "bonus_credits": bonus,
        "grade": battle_result.get_grade(),
        "parts": []  # TODO: Part rewards
    }


func _change_state(new_state: BattleState) -> void:
    ## Change battle state with signal emission
    if new_state == current_state:
        return
    
    var old_state: BattleState = current_state
    current_state = new_state
    battle_state_changed.emit(new_state, old_state)
    
    print("BattleManager: State changed %s -> %s" % [_state_to_string(old_state), _state_to_string(new_state)])


func _state_to_string(state: BattleState) -> String:
    match state:
        BattleState.SETUP: return "SETUP"
        BattleState.COUNTDOWN: return "COUNTDOWN"
        BattleState.ACTIVE: return "ACTIVE"
        BattleState.PAUSED: return "PAUSED"
        BattleState.ENDED: return "ENDED"
        _: return "UNKNOWN"


# ============================================================================
# UTILITY
# ============================================================================

func is_battle_active() -> bool:
    return current_state == BattleState.ACTIVE


func is_battle_ended() -> bool:
    return current_state == BattleState.ENDED


func can_issue_commands() -> bool:
    return current_state == BattleState.ACTIVE


func get_current_arena() -> Dictionary:
    return current_arena_data.duplicate()
