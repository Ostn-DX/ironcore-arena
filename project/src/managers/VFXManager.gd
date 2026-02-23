extends Node
class_name VFXManager
## VFXManager - handles visual effects, particles, and screen effects.

# Effect types
enum EffectType {
	EXPLOSION_SMALL,
	EXPLOSION_LARGE,
	MUZZLE_FLASH,
	PROJECTILE_TRAIL,
	HIT_SPARK,
	SHIELD_HIT,
	ENGINE_TRAIL,
	COUNTDOWN_POP
}

# Screen shake
var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var camera: Camera2D = null

# Effect pools
var effect_pools: Dictionary = {}
var active_effects: Array[Node] = []

# Settings
var effects_enabled: bool = true
var particles_enabled: bool = true


func _ready() -> void:
	_setup_pools()


func _process(delta: float) -> void:
	_process_screen_shake(delta)


func _setup_pools() -> void:
	## Setup effect object pools
	pass  # Pools created on demand


# ============================================================================
# SCREEN SHAKE
# ============================================================================

func shake_screen(intensity: float, duration: float = 0.5) -> void:
	## Trigger screen shake
	if not effects_enabled:
		return
	
	shake_intensity = intensity
	shake_decay = intensity / duration if duration > 0 else 5.0


func _process_screen_shake(delta: float) -> void:
	## Process screen shake effect
	if shake_intensity <= 0.001 or not camera:
		return
	
	# Apply shake offset
	var shake_x: float = randf_range(-shake_intensity, shake_intensity)
	var shake_y: float = randf_range(-shake_intensity, shake_intensity)
	camera.offset = Vector2(shake_x, shake_y)
	
	# Decay
	shake_intensity = move_toward(shake_intensity, 0, shake_decay * delta)
	
	if shake_intensity <= 0.001:
		camera.offset = Vector2.ZERO


func set_camera(cam: Camera2D) -> void:
	## Set the camera to apply effects to
	camera = cam


# ============================================================================
# PARTICLE EFFECTS
# ============================================================================

func spawn_explosion(position: Vector2, size: String = "medium", color: Color = Color.ORANGE) -> void:
	## Spawn explosion effect
	if not effects_enabled or not particles_enabled:
		return
	
	# Trigger screen shake for large explosions
	match size:
		"small": shake_screen(2.0, 0.2)
		"medium": shake_screen(5.0, 0.3)
		"large": shake_screen(10.0, 0.5)
	
	# Create explosion particles
	var particle_count: int = 8 if size == "small" else (16 if size == "medium" else 32)
	
	for i in range(particle_count):
		var angle: float = (i / float(particle_count)) * TAU
		var speed: float = randf_range(50, 150)
		var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * speed
		
		_spawn_particle(position, velocity, color, randf_range(0.3, 0.8))


func spawn_muzzle_flash(position: Vector2, direction: float, color: Color = Color.YELLOW) -> void:
	## Spawn muzzle flash effect
	if not effects_enabled:
		return
	
	# Flash
	var flash: ColorRect = ColorRect.new()
	flash.size = Vector2(20, 10)
	flash.position = position - Vector2(10, 5)
	flash.rotation = direction
	flash.color = color
	flash.modulate.a = 0.8
	
	get_tree().current_scene.add_child(flash)
	
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(flash.queue_free)
	
	# Spark particles
	for i in range(3):
		var angle: float = direction + randf_range(-0.3, 0.3)
		var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * randf_range(80, 150)
		_spawn_particle(position, velocity, color.lightened(0.3), 0.15)


func spawn_hit_spark(position: Vector2, normal: Vector2, color: Color = Color.WHITE) -> void:
	## Spawn hit spark effect
	if not effects_enabled:
		return
	
	for i in range(5):
		var angle: float = atan2(normal.y, normal.x) + randf_range(-0.5, 0.5)
		var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * randf_range(30, 80)
		_spawn_particle(position, velocity, color, randf_range(0.1, 0.3))


func spawn_projectile_trail(start_pos: Vector2, end_pos: Vector2, color: Color = Color.YELLOW) -> void:
	## Spawn projectile trail effect
	if not effects_enabled:
		return
	
	var line: Line2D = Line2D.new()
	line.points = [start_pos, end_pos]
	line.width = 3
	line.default_color = color
	line.modulate.a = 0.6
	
	get_tree().current_scene.add_child(line)
	
	var tween: Tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)


func spawn_engine_trail(position: Vector2, velocity: Vector2, color: Color = Color.CYAN) -> void:
	## Spawn engine trail particle
	if not effects_enabled or not particles_enabled:
		return
	
	var particle: ColorRect = ColorRect.new()
	particle.size = Vector2(4, 4)
	particle.position = position - Vector2(2, 2)
	particle.color = color
	particle.modulate.a = 0.5
	
	get_tree().current_scene.add_child(particle)
	
	# Fade and shrink
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.tween_property(particle, "size", Vector2.ZERO, 0.3)
	tween.chain().tween_callback(particle.queue_free)


func spawn_damage_number(position: Vector2, amount: int, is_critical: bool = false) -> void:
	## Spawn floating damage number
	if not effects_enabled:
		return
	
	var label: Label = Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 16 if not is_critical else 24)
	label.modulate = Color.RED if not is_critical else Color.YELLOW
	label.position = position - Vector2(10, 20)
	
	get_tree().current_scene.add_child(label)
	
	# Float up and fade
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)


func spawn_countdown_popup(number: int, position: Vector2) -> void:
	## Spawn countdown number popup
	if not effects_enabled:
		return
	
	var label: Label = Label.new()
	label.text = str(number)
	label.add_theme_font_size_override("font_size", 72)
	label.modulate = Color.WHITE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = position - Vector2(36, 36)
	label.size = Vector2(72, 72)
	
	get_tree().current_scene.add_child(label)
	
	# Scale up then fade
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(label.queue_free)


# ============================================================================
# UTILITY METHODS
# ============================================================================

func _spawn_particle(position: Vector2, velocity: Vector2, color: Color, lifetime: float) -> void:
	## Spawn a simple particle
	var particle: ColorRect = ColorRect.new()
	particle.size = Vector2(3, 3)
	particle.position = position - Vector2(1.5, 1.5)
	particle.color = color
	
	get_tree().current_scene.add_child(particle)
	
	# Animate
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(particle, "position", position + velocity * lifetime, lifetime)
	tween.tween_property(particle, "modulate:a", 0.0, lifetime)
	tween.tween_property(particle, "size", Vector2.ZERO, lifetime)
	tween.chain().tween_callback(particle.queue_free)


func clear_all_effects() -> void:
	## Clear all active effects
	for effect in active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()


func set_effects_enabled(enabled: bool) -> void:
	## Enable/disable all effects
	effects_enabled = enabled


func set_particles_enabled(enabled: bool) -> void:
	## Enable/disable particles specifically
	particles_enabled = enabled
