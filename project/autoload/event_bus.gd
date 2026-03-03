extends Node
## EventBus - Global event coordination for Bible-compliant UI screens
## Provides decoupled communication between game systems

# Menu Events
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal game_quit_requested

# Career Events
signal career_started
signal career_continued
signal career_loaded(save_slot: int)

# Builder Events
signal bot_modified(bot_index: int)
signal loadout_saved
signal item_purchased(item_id: String, cost: int)

# Battle Events
signal battle_started(arena_id: String)
signal battle_ended(result: Dictionary)
signal battle_paused
signal battle_resumed

# Economy Events
signal credits_changed(new_amount: int, delta: int)
signal part_unlocked(part_id: String)

# Progress Events
signal arena_completed(arena_id: String)
signal tier_unlocked(tier: int)

# Settings Events
signal settings_changed(setting_name: String, value: Variant)
signal audio_volume_changed(channel: String, volume: float)

func _ready() -> void:
	print("EventBus initialized")

## Bible B1.3: Safe emit helper
func emit_event(event_name: String, args: Array = []) -> void:
	## Safely emit a signal by name
	if has_signal(event_name):
		emit_signal(event_name, args)
