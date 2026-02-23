extends Node
class_name CampaignManager
## CampaignManager - handles campaign progression and arena configurations.

signal arena_unlocked(arena_id: String)
signal campaign_completed(campaign_id: String)
signal tier_unlocked(tier: int)

@onready var _game_state = get_node("/root/GameState")
@onready var _data_loader = get_node("/root/DataLoader")

# Campaign data
var current_campaign: String = "main"
var campaign_data: Dictionary = {}
var arena_configs: Dictionary = {}

const CAMPAIGN_PATH: String = "res://../data/campaign.json"


func _ready() -> void:
	_load_campaign_data()


func _load_campaign_data() -> void:
	## Load campaign configuration from JSON
	var file: FileAccess = FileAccess.open(CAMPAIGN_PATH, FileAccess.READ)
	if not file:
		push_warning("CampaignManager: Could not load campaign.json")
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		push_error("CampaignManager: Failed to parse campaign.json")
		return
	
	var data: Dictionary = json.data
	campaign_data = data.get("campaigns", {})
	arena_configs = data.get("arena_configs", {})
	
	print("CampaignManager: Loaded %d campaigns, %d arena configs" % [
		campaign_data.size(),
		arena_configs.size()
	])


# ============================================================================
# CAMPAIGN PROGRESSION
# ============================================================================

func get_current_campaign() -> Dictionary:
	## Get the current campaign data
	return campaign_data.get(current_campaign, {})


func get_campaign_tiers() -> Array:
	## Get all tiers in the current campaign
	var campaign: Dictionary = get_current_campaign()
	return campaign.get("tiers", [])


func get_current_tier() -> int:
	## Get the player's current tier
	return _game_state.current_tier


func get_tier_data(tier: int) -> Dictionary:
	## Get data for a specific tier
	var tiers: Array = get_campaign_tiers()
	for t in tiers:
		if t.get("tier", -1) == tier:
			return t
	return {}


func get_next_arena() -> String:
	## Get the next arena the player should play
	var current_tier: int = get_current_tier()
	var tier_data: Dictionary = get_tier_data(current_tier)
	var arenas: Array = tier_data.get("arenas", [])
	
	for arena_id in arenas:
		if not _game_state.is_arena_completed(arena_id):
			return arena_id
	
	return ""


func is_campaign_complete() -> bool:
	## Check if the entire campaign is complete
	var tiers: Array = get_campaign_tiers()
	
	for tier_data in tiers:
		var tier: int = tier_data.get("tier", 0)
		if tier > get_current_tier():
			continue
		
		var arenas: Array = tier_data.get("arenas", [])
		for arena_id in arenas:
			if not _game_state.is_arena_completed(arena_id):
				return false
	
	return true


# ============================================================================
# ARENA CONFIGURATION
# ============================================================================

func get_arena_config(arena_id: String) -> Dictionary:
	## Get configuration for an arena
	return arena_configs.get(arena_id, {})


func get_arena_enemies(arena_id: String) -> Array:
	## Get enemy loadouts for an arena
	var config: Dictionary = get_arena_config(arena_id)
	return config.get("enemy_loadouts", [])


func get_arena_obstacles(arena_id: String) -> Array:
	## Get obstacle placements for an arena
	var config: Dictionary = get_arena_config(arena_id)
	return config.get("obstacles", [])


func get_arena_tips(arena_id: String) -> Array:
	## Get loading tips for an arena
	var config: Dictionary = get_arena_config(arena_id)
	return config.get("tips", [])


func get_arena_difficulty(arena_id: String) -> String:
	## Get difficulty rating for an arena
	var config: Dictionary = get_arena_config(arena_id)
	return config.get("difficulty", "medium")


# ============================================================================
# UTILITY
# ============================================================================

func get_arena_display_info(arena_id: String) -> Dictionary:
	## Get combined display info for an arena
	var arena_data: Dictionary = _data_loader.get_arena(arena_id) if _data_loader else {}
	var config: Dictionary = get_arena_config(arena_id)
	
	return {
		"id": arena_id,
		"name": arena_data.get("name", "Unknown Arena"),
		"tier": arena_data.get("tier", 0),
		"difficulty": config.get("difficulty", "medium"),
		"enemy_count": config.get("enemy_count", 1),
		"dimensions": arena_data.get("dimensions", [800, 600]),
		"weight_limit": arena_data.get("weight_limit", 120),
		"par_time": arena_data.get("par_time", 120),
		"base_reward": arena_data.get("base_reward", 100),
		"is_completed": _game_state.is_arena_completed(arena_id) if _game_state else false,
		"is_unlocked": _game_state.is_arena_unlocked(arena_id) if _game_state else false
	}


func get_all_arena_info() -> Array[Dictionary]:
	## Get display info for all arenas in campaign order
	var result: Array[Dictionary] = []
	var tiers: Array = get_campaign_tiers()
	
	for tier_data in tiers:
		var arenas: Array = tier_data.get("arenas", [])
		for arena_id in arenas:
			result.append(get_arena_display_info(arena_id))
	
	return result
