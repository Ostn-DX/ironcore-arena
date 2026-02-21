extends Node
class_name WinLossManager
## WinLossManager — tracks battle statistics and determines victory conditions.
## Works with BattleManager to provide detailed end-of-battle analysis.

enum EndCondition {
    ALL_ENEMIES_DESTROYED,    # Normal victory
    ALL_PLAYER_BOTS_DESTROYED, # Normal defeat  
    PLAYER_SURRENDER,          # Manual retreat
    TIMEOUT_VICTORY,           # Timeout with player advantage
    TIMEOUT_DEFEAT,            # Timeout with enemy advantage
    STALEMATE                  # Timeout with equal standing
}

# Battle statistics tracking
class BattleStats:
    var start_tick: int = 0
    var end_tick: int = 0
    
    # Bot stats
    var player_bots_spawned: int = 0
    var enemy_bots_spawned: int = 0
    var player_bots_destroyed: int = 0
    var enemy_bots_destroyed: int = 0
    
    # Damage stats
    var total_damage_dealt: int = 0
    var total_damage_taken: int = 0
    var total_damage_to_enemies: int = 0
    
    # Shot stats
    var shots_fired: int = 0
    var shots_hit: int = 0
    
    # Command stats
    var commands_issued: int = 0
    var commands_by_type: Dictionary = {"move": 0, "follow": 0, "focus": 0}
    
    # Timing
    var first_blood_tick: int = -1
    var last_kill_tick: int = -1
    
    func get_duration_ticks() -> int:
        return end_tick - start_tick
    
    func get_duration_seconds() -> float:
        return get_duration_ticks() / 60.0
    
    func get_accuracy() -> float:
        if shots_fired == 0:
            return 0.0
        return float(shots_hit) / float(shots_fired)
    
    func get_kill_death_ratio() -> float:
        if player_bots_destroyed == 0:
            return float(enemy_bots_destroyed)
        return float(enemy_bots_destroyed) / float(player_bots_destroyed)
    
    func to_dictionary() -> Dictionary:
        return {
            "duration_seconds": get_duration_seconds(),
            "player_bots_spawned": player_bots_spawned,
            "enemy_bots_spawned": enemy_bots_spawned,
            "player_bots_destroyed": player_bots_destroyed,
            "enemy_bots_destroyed": enemy_bots_destroyed,
            "damage_dealt": total_damage_to_enemies,
            "damage_taken": total_damage_taken,
            "shots_fired": shots_fired,
            "shots_hit": shots_hit,
            "accuracy": get_accuracy(),
            "kd_ratio": get_kill_death_ratio(),
            "commands_issued": commands_issued,
            "first_blood_seconds": first_blood_tick / 60.0 if first_blood_tick > 0 else -1
        }

# Current battle tracking
var current_stats: BattleStats = null
var is_tracking: bool = false

# Event log for replay/debug
var event_log: Array[Dictionary] = []
var max_log_events: int = 1000

# Callbacks for UI updates
var on_stat_update: Callable = Callable()


func _ready() -> void:
    _connect_signals()


func _connect_signals() -> void:
    ## Connect to SimulationManager signals
    if SimulationManager:
        SimulationManager.entity_destroyed.connect(_on_entity_destroyed)
        SimulationManager.entity_damaged.connect(_on_entity_damaged)
        SimulationManager.projectile_spawned.connect(_on_projectile_spawned)
        SimulationManager.command_issued.connect(_on_command_issued)


# ============================================================================
# TRACKING CONTROL
# ============================================================================

func start_tracking(start_tick: int, player_bot_count: int, enemy_bot_count: int) -> void:
    ## Start tracking a new battle
    current_stats = BattleStats.new()
    current_stats.start_tick = start_tick
    current_stats.player_bots_spawned = player_bot_count
    current_stats.enemy_bots_spawned = enemy_bot_count
    
    event_log.clear()
    is_tracking = true
    
    _log_event("battle_start", {"player_bots": player_bot_count, "enemy_bots": enemy_bot_count})
    print("WinLossManager: Started tracking battle")


func stop_tracking(end_tick: int) -> void:
    ## Stop tracking current battle
    if current_stats:
        current_stats.end_tick = end_tick
    is_tracking = false
    
    _log_event("battle_end", {"final_stats": current_stats.to_dictionary() if current_stats else {}})


func reset() -> void:
    ## Reset all tracking data
    current_stats = null
    event_log.clear()
    is_tracking = false


# ============================================================================
# VICTORY CONDITION CHECKS
# ============================================================================

func check_victory_condition() -> Dictionary:
    ## Check current victory condition
    ## Returns: {"ended": bool, "victory": bool, "condition": EndCondition, "reason": String}
    
    if not SimulationManager or not SimulationManager.is_running:
        return {"ended": false, "victory": false, "condition": -1, "reason": "Not running"}
    
    var player_alive: int = 0
    var enemy_alive: int = 0
    var player_hp_total: int = 0
    var enemy_hp_total: int = 0
    var player_max_hp: int = 0
    var enemy_max_hp: int = 0
    
    for bot_id in SimulationManager.bots:
        var bot = SimulationManager.bots[bot_id]
        if bot.team == 0:
            player_max_hp += bot.max_hp
            if bot.is_alive:
                player_alive += 1
                player_hp_total += bot.hp
        else:
            enemy_max_hp += bot.max_hp
            if bot.is_alive:
                enemy_alive += 1
                enemy_hp_total += bot.hp
    
    # Check all destroyed conditions
    if enemy_alive == 0 and player_alive == 0:
        # Mutual destruction - check who dealt more damage
        if current_stats and current_stats.total_damage_to_enemies > current_stats.total_damage_taken:
            return {"ended": true, "victory": true, "condition": EndCondition.ALL_ENEMIES_DESTROYED, "reason": "Mutual destruction (damage advantage)"}
        else:
            return {"ended": true, "victory": false, "condition": EndCondition.ALL_PLAYER_BOTS_DESTROYED, "reason": "Mutual destruction"}
    
    if enemy_alive == 0:
        return {"ended": true, "victory": true, "condition": EndCondition.ALL_ENEMIES_DESTROYED, "reason": "All enemies destroyed"}
    
    if player_alive == 0:
        return {"ended": true, "victory": false, "condition": EndCondition.ALL_PLAYER_BOTS_DESTROYED, "reason": "All player bots destroyed"}
    
    return {"ended": false, "victory": false, "condition": -1, "reason": "Battle ongoing"}


func resolve_timeout() -> Dictionary:
    ## Resolve battle when time runs out
    ## Returns: {"victory": bool, "condition": EndCondition, "reason": String}
    
    var player_alive: int = 0
    var enemy_alive: int = 0
    var player_hp_pct: float = 0.0
    var enemy_hp_pct: float = 0.0
    var player_count: int = 0
    var enemy_count: int = 0
    
    for bot_id in SimulationManager.bots:
        var bot = SimulationManager.bots[bot_id]
        var hp_pct: float = float(bot.hp) / float(bot.max_hp)
        
        if bot.team == 0:
            player_count += 1
            if bot.is_alive:
                player_alive += 1
                player_hp_pct += hp_pct
        else:
            enemy_count += 1
            if bot.is_alive:
                enemy_alive += 1
                enemy_hp_pct += hp_pct
    
    if player_count > 0:
        player_hp_pct /= player_count
    if enemy_count > 0:
        enemy_hp_pct /= enemy_count
    
    # Determine winner by HP percentage
    if player_hp_pct > enemy_hp_pct:
        return {"victory": true, "condition": EndCondition.TIMEOUT_VICTORY, "reason": "Time limit - HP advantage"}
    elif enemy_hp_pct > player_hp_pct:
        return {"victory": false, "condition": EndCondition.TIMEOUT_DEFEAT, "reason": "Time limit - HP disadvantage"}
    else:
        # Exact tie - check kills, then damage
        if current_stats:
            if current_stats.enemy_bots_destroyed > current_stats.player_bots_destroyed:
                return {"victory": true, "condition": EndCondition.TIMEOUT_VICTORY, "reason": "Time limit - kill advantage"}
            elif current_stats.total_damage_to_enemies > current_stats.total_damage_taken:
                return {"victory": true, "condition": EndCondition.TIMEOUT_VICTORY, "reason": "Time limit - damage advantage"}
        
        return {"victory": false, "condition": EndCondition.STALEMATE, "reason": "Stalemate - equal standing"}


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_entity_destroyed(bot_id: int, team: int) -> void:
    if not is_tracking or not current_stats:
        return
    
    var tick: int = SimulationManager.current_tick if SimulationManager else 0
    
    if team == 0:
        current_stats.player_bots_destroyed += 1
    else:
        current_stats.enemy_bots_destroyed += 1
    
    # Track first blood
    if current_stats.first_blood_tick == -1:
        current_stats.first_blood_tick = tick
    
    current_stats.last_kill_tick = tick
    
    _log_event("destroy", {"bot_id": bot_id, "team": team, "tick": tick})
    _notify_update()


func _on_entity_damaged(bot_id: int, hp: int, max_hp: int) -> void:
    if not is_tracking or not current_stats:
        return
    
    # Note: This tracks current HP, not damage dealt
    # Actual damage tracking would need delta calculation
    pass


func _on_projectile_spawned(proj_id: int, position: Vector2, direction: Vector2) -> void:
    if not is_tracking or not current_stats:
        return
    
    current_stats.shots_fired += 1
    _notify_update()


func _on_command_issued(bot_id: int, command_type: String, target: Variant) -> void:
    if not is_tracking or not current_stats:
        return
    
    current_stats.commands_issued += 1
    
    if current_stats.commands_by_type.has(command_type):
        current_stats.commands_by_type[command_type] += 1
    
    _log_event("command", {"bot_id": bot_id, "type": command_type, "target": str(target)})
    _notify_update()


# ============================================================================
# DAMAGE TRACKING (manual)
# ============================================================================

func track_damage_dealt(amount: int, to_enemy: bool = true) -> void:
    ## Track damage dealt (call this from damage application)
    if not is_tracking or not current_stats:
        return
    
    current_stats.total_damage_dealt += amount
    if to_enemy:
        current_stats.total_damage_to_enemies += amount
    else:
        current_stats.total_damage_taken += amount
    
    _notify_update()


func track_shot_hit() -> void:
    ## Track successful shot hit
    if not is_tracking or not current_stats:
        return
    
    current_stats.shots_hit += 1
    _notify_update()


# ============================================================================
# LOGGING
# ============================================================================

func _log_event(event_type: String, data: Dictionary) -> void:
    ## Add event to battle log
    if event_log.size() >= max_log_events:
        event_log.pop_front()  # Remove oldest
    
    event_log.append({
        "tick": SimulationManager.current_tick if SimulationManager else 0,
        "type": event_type,
        "data": data
    })


func get_event_log() -> Array[Dictionary]:
    return event_log.duplicate()


func get_recent_events(count: int = 10) -> Array[Dictionary]:
    var start: int = maxi(0, event_log.size() - count)
    return event_log.slice(start)


# ============================================================================
# STATS ACCESS
# ============================================================================

func get_current_stats() -> BattleStats:
    return current_stats


func get_stats_dictionary() -> Dictionary:
    if current_stats:
        return current_stats.to_dictionary()
    return {}


# ============================================================================
# UI CALLBACKS
# ============================================================================

func _notify_update() -> void:
    ## Notify UI of stat update
    if on_stat_update.is_valid():
        on_stat_update.call(current_stats)


func set_stat_update_callback(callback: Callable) -> void:
    on_stat_update = callback


# ============================================================================
# UTILITY
# ============================================================================

func format_condition_string(condition: EndCondition) -> String:
    match condition:
        EndCondition.ALL_ENEMIES_DESTROYED: return "Victory - Enemies Eliminated"
        EndCondition.ALL_PLAYER_BOTS_DESTROYED: return "Defeat - Squad Lost"
        EndCondition.PLAYER_SURRENDER: return "Retreat"
        EndCondition.TIMEOUT_VICTORY: return "Victory - Time Limit"
        EndCondition.TIMEOUT_DEFEAT: return "Defeat - Time Limit"
        EndCondition.STALEMATE: return "Stalemate"
        _: return "Unknown"
