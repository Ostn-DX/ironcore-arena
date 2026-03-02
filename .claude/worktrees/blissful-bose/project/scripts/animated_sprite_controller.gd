class_name AnimatedSpriteController extends Node

## Bridges gameplay StateMachine to AnimatedSprite2D visuals.
## Handles animation state mapping, variant switching, and automatic playback.
## Attach this node as a child of your entity and call bind() to connect.

signal animation_state_changed(new_state: String)
signal animation_finished(anim_name: String)
signal animation_looped(anim_name: String)

## Standard animation state constants
const ANIM_IDLE: String = "idle"
const ANIM_MOVE: String = "move"
const ANIM_SHOOT: String = "shoot"
const ANIM_HIT: String = "hit"
const ANIM_DEATH: String = "death"
const ANIM_RELOAD: String = "reload"
const ANIM_SPAWN: String = "spawn"
const ANIM_STUN: String = "stun"
const ANIM_SPECIAL: String = "special"

## Default animation to play when state is unknown
const DEFAULT_ANIMATION: String = ANIM_IDLE

var _state_machine: Node = null
var _animated_sprite: AnimatedSprite2D = null
var _asset_key: String = ""
var _current_variant: String = ""
var _current_state: String = ""
var _auto_update: bool = true
var _flip_h: bool = false
var _flip_v: bool = false


func _ready() -> void:
    # Auto-bind if children are found
    _try_auto_bind()


func _process(_delta: float) -> void:
    # Sync flip state with animated sprite
    if _animated_sprite:
        _animated_sprite.flip_h = _flip_h
        _animated_sprite.flip_v = _flip_v


## Binds the controller to a state machine and animated sprite.
## This is the main setup method for the controller.
## @param state_machine The state machine node to listen to (must have state_changed signal)
## @param animated_sprite The AnimatedSprite2D to control
## @param asset_key The asset key to load from the registry
func bind(state_machine: Node, animated_sprite: AnimatedSprite2D, asset_key: String) -> void:
    _state_machine = state_machine
    _animated_sprite = animated_sprite
    _asset_key = asset_key
    
    # Connect to state changes
    if _state_machine:
        if _state_machine.has_signal("state_changed"):
            _state_machine.state_changed.connect(_on_state_changed)
        elif _state_machine.has_signal("state_entered"):
            _state_machine.state_entered.connect(_on_state_changed)
    
    # Connect to animation signals
    if _animated_sprite:
        if not _animated_sprite.animation_finished.is_connected(_on_animation_finished):
            _animated_sprite.animation_finished.connect(_on_animation_finished)
        if not _animated_sprite.animation_looped.is_connected(_on_animation_looped):
            _animated_sprite.animation_looped.connect(_on_animation_looped)
    
    # Load initial sprite frames
    _refresh_sprite_frames()
    
    print("AnimatedSpriteController: Bound to asset '" + asset_key + "'")


## Sets the visual variant (low/medium/high/ultra).
## Clears and reloads sprite frames for the new variant.
## @param variant The quality variant to use
func set_variant(variant: String) -> void:
    if variant == _current_variant:
        return
    
    var old_variant := _current_variant
    _current_variant = variant
    
    _refresh_sprite_frames()
    
    # Restore current animation if possible
    if _current_state != "" and _animated_sprite:
        if _animated_sprite.sprite_frames:
            if _animated_sprite.sprite_frames.has_animation(_current_state):
                _animated_sprite.play(_current_state)
    
    print("AnimatedSpriteController: Variant changed from '" + old_variant + "' to '" + variant + "'")


## Applies an animation state directly without going through state machine.
## Useful for one-shot animations or scripted sequences.
## @param state_name The animation state to play
func apply_state(state_name: String) -> void:
    if state_name == _current_state:
        # Still restart the animation for hit/shoot effects
        if state_name not in [ANIM_HIT, ANIM_SHOOT, ANIM_SPAWN]:
            return
    
    _current_state = state_name
    
    if _animated_sprite and _animated_sprite.sprite_frames:
        if _animated_sprite.sprite_frames.has_animation(state_name):
            _animated_sprite.play(state_name)
            animation_state_changed.emit(state_name)
        else:
            # Fall back to idle if animation not found
            if _animated_sprite.sprite_frames.has_animation(ANIM_IDLE):
                _animated_sprite.play(ANIM_IDLE)
                animation_state_changed.emit(ANIM_IDLE)
            else:
                push_warning("AnimatedSpriteController: Animation '" + state_name + "' not found and no idle animation available")


## Plays a one-shot animation and returns to previous state when done.
## @param one_shot_anim The one-shot animation to play
## @param return_state The state to return to after (defaults to current state)
func play_one_shot(one_shot_anim: String, return_state: String = "") -> void:
    if not _animated_sprite or not _animated_sprite.sprite_frames:
        return
    
    if not _animated_sprite.sprite_frames.has_animation(one_shot_anim):
        push_warning("AnimatedSpriteController: One-shot animation '" + one_shot_anim + "' not found")
        return
    
    var return_to := return_state if not return_state.is_empty() else _current_state
    
    # Store callback for when animation finishes
    _pending_return_state = return_to
    _is_one_shot = true
    
    _animated_sprite.play(one_shot_anim)


var _pending_return_state: String = ""
var _is_one_shot: bool = false


## Gets the current animation state.
## @return The current animation state name
func get_current_state() -> String:
    return _current_state


## Gets the current asset key.
## @return The asset key being used
func get_asset_key() -> String:
    return _asset_key


## Gets the current variant.
## @return The current variant being used
func get_variant() -> String:
    return _current_variant


## Sets horizontal flip.
## @param flip Whether to flip horizontally
func set_flip_h(flip: bool) -> void:
    _flip_h = flip
    if _animated_sprite:
        _animated_sprite.flip_h = flip


## Sets vertical flip.
## @param flip Whether to flip vertically
func set_flip_v(flip: bool) -> void:
    _flip_v = flip
    if _animated_sprite:
        _animated_sprite.flip_v = flip


## Gets horizontal flip state.
## @return true if flipped horizontally
func get_flip_h() -> bool:
    return _flip_h


## Gets vertical flip state.
## @return true if flipped vertically
func get_flip_v() -> bool:
    return _flip_v


## Pauses the current animation.
func pause() -> void:
    if _animated_sprite:
        _animated_sprite.pause()


## Resumes the current animation.
func resume() -> void:
    if _animated_sprite:
        _animated_sprite.play()


## Stops the current animation.
func stop() -> void:
    if _animated_sprite:
        _animated_sprite.stop()


## Sets the animation speed scale.
## @param speed The speed multiplier (1.0 = normal)
func set_speed_scale(speed: float) -> void:
    if _animated_sprite:
        _animated_sprite.speed_scale = speed


## Gets the animation speed scale.
## @return The current speed multiplier
func get_speed_scale() -> float:
    if _animated_sprite:
        return _animated_sprite.speed_scale
    return 1.0


## Sets whether to automatically update from state machine.
## @param enabled Whether to auto-update
func set_auto_update(enabled: bool) -> void:
    _auto_update = enabled


## Checks if auto-update is enabled.
## @return true if auto-updating
func is_auto_update_enabled() -> bool:
    return _auto_update


## Handles state changes from the state machine.
func _on_state_changed(new_state: String) -> void:
    if not _auto_update:
        return
    
    var anim_state := _map_state_to_animation(new_state)
    apply_state(anim_state)


## Maps state machine states to animation states.
## Override this method in subclasses for custom mappings.
## @param state The state machine state name
## @return The corresponding animation state name
func _map_state_to_animation(state: String) -> String:
    var state_lower := state.to_lower()
    
    match state_lower:
        # Idle states
        "idle", "patrol", "wait", "stand", "guard", "alert_idle":
            return ANIM_IDLE
        
        # Movement states
        "move", "chase", "flee", "walk", "run", "wander", "seek", "evade":
            return ANIM_MOVE
        
        # Attack states
        "attack", "shoot", "shooting", "fire", "melee", "cast":
            return ANIM_SHOOT
        
        # Damage states
        "hit", "damaged", "hurt", "stagger", "knockback":
            return ANIM_HIT
        
        # Death states
        "dead", "death", "die", "destroyed", "eliminated":
            return ANIM_DEATH
        
        # Reload states
        "reload", "reloading", "cooldown", "recharge":
            return ANIM_RELOAD
        
        # Spawn states
        "spawn", "appear", "enter", "teleport_in":
            return ANIM_SPAWN
        
        # Stun states
        "stun", "stunned", "frozen", "paralyzed", "disabled":
            return ANIM_STUN
        
        # Special states
        "special", "ability", "skill", "ultimate", "power_up":
            return ANIM_SPECIAL
        
        # Default
        _:
            return DEFAULT_ANIMATION


## Refreshes sprite frames from the registry.
func _refresh_sprite_frames() -> void:
    if not _animated_sprite:
        return
    
    var registry := _get_registry()
    if not registry:
        push_warning("AnimatedSpriteController: AssetRegistry not available")
        return
    
    if _asset_key.is_empty():
        return
    
    var frames := registry.get_sprite_frames(_asset_key, _current_variant)
    if frames:
        _animated_sprite.sprite_frames = frames
        
        # Auto-play idle if available
        if frames.has_animation(ANIM_IDLE):
            _animated_sprite.play(ANIM_IDLE)
            _current_state = ANIM_IDLE
    else:
        push_warning("AnimatedSpriteController: Failed to load sprite frames for '" + _asset_key + "'")


## Handles animation finished signal.
func _on_animation_finished() -> void:
    if _animated_sprite:
        animation_finished.emit(_animated_sprite.animation)
    
    # Handle one-shot return
    if _is_one_shot and not _pending_return_state.is_empty():
        _is_one_shot = false
        apply_state(_pending_return_state)
        _pending_return_state = ""


## Handles animation looped signal.
func _on_animation_looped() -> void:
    if _animated_sprite:
        animation_looped.emit(_animated_sprite.animation)


## Tries to auto-bind to children if not explicitly bound.
func _try_auto_bind() -> void:
    if _state_machine and _animated_sprite:
        return  # Already bound
    
    # Look for AnimatedSprite2D in children
    if not _animated_sprite:
        _animated_sprite = _find_animated_sprite(get_parent())
    
    # Look for StateMachine in siblings or parent
    if not _state_machine:
        _state_machine = _find_state_machine(get_parent())


## Finds an AnimatedSprite2D in the node hierarchy.
func _find_animated_sprite(node: Node) -> AnimatedSprite2D:
    if not node:
        return null
    
    # Check direct children
    for child in node.get_children():
        if child is AnimatedSprite2D:
            return child
    
    # Check self
    if node is AnimatedSprite2D:
        return node
    
    return null


## Finds a StateMachine in the node hierarchy.
func _find_state_machine(node: Node) -> Node:
    if not node:
        return null
    
    # Check if node has state machine signals
    if node.has_signal("state_changed") or node.has_signal("state_entered"):
        return node
    
    # Check children
    for child in node.get_children():
        if child.has_signal("state_changed") or child.has_signal("state_entered"):
            return child
    
    # Check parent
    if node.get_parent():
        var parent := node.get_parent()
        if parent.has_signal("state_changed") or parent.has_signal("state_entered"):
            return parent
    
    return null


## Gets the AssetRegistry singleton.
func _get_registry() -> AssetRegistry:
    if Engine.has_singleton("AssetRegistry"):
        return Engine.get_singleton("AssetRegistry") as AssetRegistry
    
    # Try to find in scene
    var root := get_tree().root
    return root.find_child("AssetRegistry", true, false) as AssetRegistry


## Unbinds all connections and resets the controller.
func unbind() -> void:
    if _state_machine:
        if _state_machine.has_signal("state_changed"):
            if _state_machine.state_changed.is_connected(_on_state_changed):
                _state_machine.state_changed.disconnect(_on_state_changed)
        if _state_machine.has_signal("state_entered"):
            if _state_machine.state_entered.is_connected(_on_state_changed):
                _state_machine.state_entered.disconnect(_on_state_changed)
    
    if _animated_sprite:
        if _animated_sprite.animation_finished.is_connected(_on_animation_finished):
            _animated_sprite.animation_finished.disconnect(_on_animation_finished)
        if _animated_sprite.animation_looped.is_connected(_on_animation_looped):
            _animated_sprite.animation_looped.disconnect(_on_animation_looped)
    
    _state_machine = null
    _animated_sprite = null
    _asset_key = ""
    _current_state = ""


## Checks if the controller is properly bound.
## @return true if bound to both state machine and animated sprite
func is_bound() -> bool:
    return _state_machine != null and _animated_sprite != null


## Returns true if the current animation is playing.
## @return true if animation is playing
func is_playing() -> bool:
    if _animated_sprite:
        return _animated_sprite.is_playing()
    return false


## Gets the current animation name from the sprite.
## @return The current animation name or empty string
func get_current_animation() -> String:
    if _animated_sprite:
        return _animated_sprite.animation
    return ""


## Gets the frame count of the current animation.
## @return Number of frames in current animation, or 0
func get_frame_count() -> int:
    if _animated_sprite and _animated_sprite.sprite_frames:
        return _animated_sprite.sprite_frames.get_frame_count(_animated_sprite.animation)
    return 0


## Gets the current frame index.
## @return Current frame index, or -1
func get_frame() -> int:
    if _animated_sprite:
        return _animated_sprite.frame
    return -1
