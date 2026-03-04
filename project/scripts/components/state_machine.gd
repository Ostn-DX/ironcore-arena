extends Node
class_name StateMachine
## StateMachine - Hierarchical state machine for entity behavior
## Part of Studio Architecture: Component System

signal state_changed(new_state: String, old_state: String)
signal state_transition_failed(from_state: String, to_state: String, reason: String)

@export var initial_state: String = ""
@export var enable_logging: bool = false

var states: Dictionary = {}  # name -> State
var current_state: State = null
var current_state_name: String = ""
var previous_state_name: String = ""
var _is_transitioning: bool = false

func _ready() -> void:
	# Auto-discover child states
	for child in get_children():
		if child is State:
			register_state(child)
	
	# Enter initial state
	if not initial_state.is_empty() and states.has(initial_state):
		change_state(initial_state)

func register_state(state: State) -> void:
	## Register a state with the machine
	states[state.name] = state
	state.state_machine = self
	
	if enable_logging:
		print("StateMachine: Registered state '%s'" % state.name)

func unregister_state(state_name: String) -> bool:
	## Unregister a state
	if not states.has(state_name):
		return false
	
	if current_state_name == state_name:
		push_warning("StateMachine: Cannot unregister current state '%s'" % state_name)
		return false
	
	states.erase(state_name)
	return true

func change_state(new_state_name: String, params: Dictionary = {}) -> bool:
	## Transition to a new state
	if _is_transitioning:
		push_warning("StateMachine: Transition already in progress")
		state_transition_failed.emit(current_state_name, new_state_name, "transition_in_progress")
		return false
	
	if not states.has(new_state_name):
		push_error("StateMachine: State '%s' not found" % new_state_name)
		state_transition_failed.emit(current_state_name, new_state_name, "state_not_found")
		return false
	
	if current_state_name == new_state_name:
		return true  # Already in this state
	
	_is_transitioning = true
	
	var old_state_name = current_state_name
	var new_state = states[new_state_name]
	
	# Exit current state
	if current_state:
		if enable_logging:
			print("StateMachine: Exiting state '%s'" % old_state_name)
		current_state.exit()
	
	# Transition
	previous_state_name = old_state_name
	current_state = new_state
	current_state_name = new_state_name
	
	# Enter new state
	if enable_logging:
		print("StateMachine: Entering state '%s'" % new_state_name)
	current_state.enter(params)
	
	_is_transitioning = false
	
	state_changed.emit(new_state_name, old_state_name)
	return true

func can_change_to(state_name: String) -> bool:
	## Check if we can transition to a state
	if not states.has(state_name):
		return false
	if _is_transitioning:
		return false
	if current_state and not current_state.can_exit():
		return false
	return states[state_name].can_enter()

func get_state(state_name: String) -> State:
	return states.get(state_name, null)

func get_current_state() -> State:
	return current_state

func get_available_states() -> Array[String]:
	var available: Array[String] = []
	for state_name in states:
		if can_change_to(state_name):
			available.append(state_name)
	return available

func revert_to_previous_state() -> bool:
	## Go back to the previous state
	if previous_state_name.is_empty():
		return false
	return change_state(previous_state_name)

func _process(delta: float) -> void:
	if current_state and not _is_transitioning:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state and not _is_transitioning:
		current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state and not _is_transitioning:
		current_state.handle_input(event)

func get_debug_info() -> Dictionary:
	return {
		"current_state": current_state_name,
		"previous_state": previous_state_name,
		"available_states": states.keys(),
		"is_transitioning": _is_transitioning
	}

# ============================================================================
# BASE STATE CLASS
# ============================================================================

class_name State extends Node

var state_machine: StateMachine = null

func enter(params: Dictionary = {}) -> void:
	## Called when entering this state
	pass

func exit() -> void:
	## Called when exiting this state
	pass

func update(delta: float) -> void:
	## Called every frame
	pass

func physics_update(delta: float) -> void:
	## Called every physics frame
	pass

func handle_input(event: InputEvent) -> void:
	## Called for input events
	pass

func can_enter() -> bool:
	## Override to add conditions for entering this state
	return true

func can_exit() -> bool:
	## Override to add conditions for exiting this state
	return true

func transition_to(state_name: String, params: Dictionary = {}) -> bool:
	## Convenience method to transition to another state
	if state_machine:
		return state_machine.change_state(state_name, params)
	return false
