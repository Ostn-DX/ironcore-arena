extends Node
## EventBus - Decoupled communication between systems
## Part of Studio Architecture: Core Systems

# ============================================================================
# COMBAT EVENTS
# ============================================================================
signal enemy_died(enemy: Node, position: Vector2, experience: int)
signal player_damaged(amount: float, source: Node)
signal player_healed(amount: float)
signal bot_destroyed(bot_id: String, position: Vector2, team: int)
signal weapon_fired(weapon_id: String, attacker: Node, target_position: Vector2)
signal projectile_hit(target: Node, damage: float, hit_position: Vector2)

# ============================================================================
# ECONOMY EVENTS
# ============================================================================
signal credits_changed(new_amount: int, delta: int)
signal item_purchased(item_id: String, cost: int)
signal item_sold(item_id: String, value: int)
signal reward_claimed(reward_type: String, amount: int)

# ============================================================================
# PROGRESSION EVENTS
# ============================================================================
signal tier_unlocked(tier: int)
signal arena_unlocked(arena_id: String)
signal achievement_unlocked(achievement_id: String)
signal experience_gained(amount: int, source: String)
signal level_up(new_level: int)

# ============================================================================
# BATTLE EVENTS
# ============================================================================
signal battle_started(arena_id: String, difficulty: int)
signal battle_ended(result: String, stats: Dictionary)
signal battle_timer_update(remaining_seconds: int)
signal wave_started(wave_number: int, total_waves: int)
signal wave_cleared(wave_number: int)

# ============================================================================
# UI EVENTS
# ============================================================================
signal show_notification(text: String, duration: float)
signal show_dialogue(speaker: String, text: String)
signal update_hud(health: float, max_health: float, shield: float)
signal show_damage_number(position: Vector2, amount: int, is_critical: bool)
signal screen_shake(intensity: float, duration: float)
signal transition_started(transition_type: String)
signal transition_completed(transition_type: String)

# ============================================================================
# INPUT EVENTS
# ============================================================================
signal input_mode_changed(mode: String)
signal pause_requested()
signal resume_requested()
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

# ============================================================================
# GAME STATE EVENTS
# ============================================================================
signal game_state_changed(old_state: int, new_state: int)
signal scene_change_requested(scene_path: String, params: Dictionary)
signal scene_loaded(scene_name: String)
signal save_completed(slot: int)
signal load_completed(slot: int)

# ============================================================================
# AI/GENERATION EVENTS
# ============================================================================
signal ai_request_completed(request_id: String, response: String)
signal ai_generation_started(content_type: String)
signal ai_generation_completed(content_type: String, result: Variant)
signal content_generated(content_type: String, content_id: String)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func emit_delayed(signal_name: String, delay_ms: int, args: Array = []) -> void:
	## Emit a signal after a delay (non-blocking)
	await get_tree().create_timer(delay_ms / 1000.0).timeout
	emit_signal(signal_name, *args)

func connect_once(signal_name: String, callable: Callable) -> void:
	## Connect to a signal, auto-disconnecting after first emission
	var wrapper = func(arg1 = null, arg2 = null, arg3 = null, arg4 = null):
		callable.call(arg1, arg2, arg3, arg4)
		disconnect(signal_name, wrapper)
	connect(signal_name, wrapper)

func safe_emit(signal_name: String, args: Array = []) -> void:
	## Emit signal with error handling
	if has_signal(signal_name):
		emit_signal(signal_name, *args)
	else:
		push_warning("EventBus: Signal '%s' does not exist" % signal_name)
