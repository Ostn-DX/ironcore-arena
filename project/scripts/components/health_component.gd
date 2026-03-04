extends Node
class_name HealthComponent
## HealthComponent - Reusable health/damage system
## Part of Studio Architecture: Component System

signal health_changed(current: float, maximum: float, percent: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float)
signal died()
signal invincibility_changed(is_invincible: bool)

@export var max_health: float = 100.0
@export var starting_health: float = -1.0  # -1 = use max_health
@export var invincibility_time: float = 0.0
@export var destroy_on_death: bool = true

var current_health: float:
	set(value):
		var old_health = current_health
		current_health = clampf(value, 0.0, max_health)
		if old_health != current_health:
			var percent = get_health_percent()
			health_changed.emit(current_health, max_health, percent)
			
			# Check for death
			if current_health <= 0.0 and old_health > 0.0:
				died.emit()
				if destroy_on_death:
					_handle_death()

var is_invincible: bool = false:
	set(value):
		if is_invincible != value:
			is_invincible = value
			invincibility_changed.emit(is_invincible)

var _invincibility_timer: Timer
var _is_dead: bool = false

func _ready() -> void:
	# Initialize health
	if starting_health < 0:
		current_health = max_health
	else:
		current_health = starting_health
	
	# Setup invincibility timer
	if invincibility_time > 0.0:
		_invincibility_timer = Timer.new()
		_invincibility_timer.one_shot = true
		_invincibility_timer.wait_time = invincibility_time
		# Bible B1.3: Safe signal connection
		if _invincibility_timer and is_instance_valid(_invincibility_timer):
		    if not _invincibility_timer.timeout.is_connected(_on_invincibility_timeout):
		        _invincibility_timer.timeout.connect(_on_invincibility_timeout)
		add_child(_invincibility_timer)
	
	# Connect to EventBus for game-wide events
	if EventBus:
		EventBus.game_state_changed.connect(_on_game_state_changed)

func take_damage(amount: float, source: Node = null) -> void:
	## Apply damage to this entity
	if _is_dead:
		return
	
	if is_invincible or amount <= 0.0:
		return
	
	current_health -= amount
	damage_taken.emit(amount, source)
	
	# Trigger screen effects
	if EventBus and get_parent().is_in_group("player"):
		EventBus.screen_shake.emit(5.0, 0.2)
	
	# Start invincibility frames
	if invincibility_time > 0.0 and _invincibility_timer:
		is_invincible = true
		_invincibility_timer.start()

func heal(amount: float) -> void:
	## Heal this entity
	if _is_dead or amount <= 0.0:
		return
	
	var old_health = current_health
	current_health += amount
	healed.emit(current_health - old_health)

func set_health_percent(percent: float) -> void:
	## Set health as a percentage (0.0 - 1.0)
	current_health = max_health * clampf(percent, 0.0, 1.0)

func get_health_percent() -> float:
	## Get current health as percentage (0.0 - 1.0)
	return current_health / max_health if max_health > 0.0 else 0.0

func is_alive() -> bool:
	return not _is_dead and current_health > 0.0

func kill() -> void:
	## Instantly kill this entity
	if _is_dead:
		return
	current_health = 0.0
	died.emit()
	if destroy_on_death:
		_handle_death()

func reset() -> void:
	## Reset health to starting values
	_is_dead = false
	if starting_health < 0:
		current_health = max_health
	else:
		current_health = starting_health

func _handle_death() -> void:
	_is_dead = true
	
	# Emit to EventBus for game tracking
	if EventBus:
		var parent = get_parent()
		if parent.is_in_group("enemy"):
			EventBus.enemy_died.emit(parent, parent.global_position if parent.has_method("global_position") else Vector2.ZERO, 100)
		elif parent.is_in_group("player"):
			EventBus.player_damaged.emit(current_health, null)
	
	# Delay destruction to allow death effects
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(get_parent()):
		get_parent().queue_free()

func _on_invincibility_timeout() -> void:
	is_invincible = false

func _on_game_state_changed(new_state: int) -> void:
	# Pause health changes during certain states
	match new_state:
		GameManager.GameState.BATTLE_PAUSED:
			set_process(false)
		GameManager.GameState.BATTLE_ACTIVE:
			set_process(true)

# ============================================================================
# DEBUG HELPERS
# ============================================================================

func get_debug_info() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"percent": get_health_percent(),
		"is_invincible": is_invincible,
		"is_alive": is_alive(),
		"is_dead": _is_dead
	}
