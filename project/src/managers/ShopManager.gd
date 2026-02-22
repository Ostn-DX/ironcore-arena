extends Node
class_name ShopManager
## ShopManager — handles shop logic, component availability, and purchasing.

signal shop_opened
signal shop_closed
signal component_purchased(component_id: String, quantity: int, remaining_credits: int)
signal purchase_failed(component_id: String, reason: String)
signal category_changed(category: String)
signal tier_filter_changed(tier: int)

@onready var _game_state = get_node("/root/GameState")
@onready var _data_loader = get_node("/root/DataLoader")

# Shop categories
const CATEGORIES: Array[String] = ["all", "chassis", "plating", "weapons"]

# Current shop state
var current_category: String = "all"
var current_tier_filter: int = -1  # -1 = all tiers
var search_query: String = ""

# Cache of available components
var available_components: Array[Dictionary] = []


func _ready() -> void:
    _refresh_available_components()


# ============================================================================
# SHOP MANAGEMENT
# ============================================================================

func open_shop() -> void:
    ## Open the shop - refreshes available inventory
    _refresh_available_components()
    shop_opened.emit()
    print("ShopManager: Shop opened")


func close_shop() -> void:
    ## Close the shop
    shop_closed.emit()
    print("ShopManager: Shop closed")


func _refresh_available_components() -> void:
    ## Refresh list of components available for purchase
    available_components.clear()
    
    var player_tier: int = _game_state.current_tier if GameState else 0
    
    # Get all components from DataLoader
    
        # Chassis
        for chassis in _data_loader.get_all_chassis():
            if _is_component_available(chassis, player_tier):
                available_components.append(_normalize_component(chassis, "chassis"))
        
        # Plating
        for plating in _data_loader.get_all_plating():
            if _is_component_available(plating, player_tier):
                available_components.append(_normalize_component(plating, "plating"))
        
        # Weapons
        for weapon in _data_loader.get_all_weapons():
            if _is_component_available(weapon, player_tier):
                available_components.append(_normalize_component(weapon, "weapons"))
    
    print("ShopManager: Refreshed %d available components" % available_components.size())


func _is_component_available(component: Dictionary, player_tier: int) -> bool:
    ## Check if a component is available based on tier
    var component_tier: int = component.get("tier", 0)
    
    # Components are available if tier <= player tier + 1
    # (Show next tier's components as preview/incentive)
    return component_tier <= player_tier + 1


func _normalize_component(component: Dictionary, category: String) -> Dictionary:
    ## Normalize component data for shop display
    return {
        "id": component.get("id", ""),
        "name": component.get("name", "Unknown"),
        "description": component.get("description", ""),
        "category": category,
        "tier": component.get("tier", 0),
        "cost": component.get("cost", 0),
        "raw_data": component
    }


# ============================================================================
# FILTERING
# ============================================================================

func set_category(category: String) -> void:
    ## Set component category filter
    if category in CATEGORIES:
        current_category = category
        category_changed.emit(category)


func set_tier_filter(tier: int) -> void:
    ## Set tier filter (-1 for all tiers)
    current_tier_filter = tier
    tier_filter_changed.emit(tier)


func set_search_query(query: String) -> void:
    ## Set search filter
    search_query = query.to_lower()


func get_filtered_components() -> Array[Dictionary]:
    ## Get components matching current filters
    var filtered: Array[Dictionary] = []
    
    for component in available_components:
        # Category filter
        if current_category != "all" and component["category"] != current_category:
            continue
        
        # Tier filter
        if current_tier_filter != -1 and component["tier"] != current_tier_filter:
            continue
        
        # Search filter
        if search_query != "":
            var name: String = component["name"].to_lower()
            var desc: String = component["description"].to_lower()
            if not (search_query in name or search_query in desc):
                continue
        
        filtered.append(component)
    
    # Sort by tier then by cost
    filtered.sort_custom(func(a, b): 
        if a["tier"] != b["tier"]:
            return a["tier"] < b["tier"]
        return a["cost"] < b["cost"]
    )
    
    return filtered


# ============================================================================
# PURCHASING
# ============================================================================

func can_purchase(component_id: String, quantity: int = 1) -> Dictionary:
    ## Check if player can purchase component
    ## Returns: {"can_buy": bool, "reason": String}
    
    # Find component
    var component: Dictionary = {}
    for c in available_components:
        if c["id"] == component_id:
            component = c
            break
    
    if component.is_empty():
        return {"can_buy": false, "reason": "Component not available"}
    
    # Check tier lock
    var player_tier: int = _game_state.current_tier if GameState else 0
    if component["tier"] > player_tier:
        return {"can_buy": false, "reason": "Requires tier %d" % component["tier"]}
    
    # Check cost
    var total_cost: int = component["cost"] * quantity
    if GameState and _game_state.credits < total_cost:
        return {"can_buy": false, "reason": "Not enough credits (%d needed)" % total_cost}
    
    # Arcade mode always allows
    if GameState and _game_state.is_arcade_mode():
        return {"can_buy": true, "reason": ""}
    
    return {"can_buy": true, "reason": ""}


func purchase_component(component_id: String, quantity: int = 1) -> bool:
    ## Purchase a component
    
    # Check if can buy
    var check: Dictionary = can_purchase(component_id, quantity)
    if not check["can_buy"]:
        purchase_failed.emit(component_id, check["reason"])
        print("ShopManager: Purchase failed - ", check["reason"])
        return false
    
    # Find component
    var component: Dictionary = {}
    for c in available_components:
        if c["id"] == component_id:
            component = c
            break
    
    if component.is_empty():
        purchase_failed.emit(component_id, "Component not found")
        return false
    
    var total_cost: int = component["cost"] * quantity
    
    # Deduct credits
    
        if not _game_state.spend_credits(total_cost):
            purchase_failed.emit(component_id, "Transaction failed")
            return false
        
        # Add component to inventory
        _game_state.add_part(component_id, quantity)
        
        component_purchased.emit(component_id, quantity, _game_state.credits)
        print("ShopManager: Purchased %dx %s for %d credits" % [quantity, component_id, total_cost])
        return true
    
    purchase_failed.emit(component_id, "GameState not available")
    return false


func get_component_cost(component_id: String) -> int:
    ## Get the cost of a component
    for c in available_components:
        if c["id"] == component_id:
            return c["cost"]
    return 0


func get_owned_quantity(component_id: String) -> int:
    ## Get how many of a component the player owns
    
        return _game_state.get_part_quantity(component_id)
    return 0


# ============================================================================
# STATS & INFO
# ============================================================================

func get_component_stats(component_id: String) -> Dictionary:
    ## Get detailed stats for a component
    for c in available_components:
        if c["id"] == component_id:
            var data: Dictionary = c["raw_data"]
            var category: String = c["category"]
            
            match category:
                "chassis":
                    return {
                        "HP": data.get("hp_base", 0),
                        "Speed": data.get("speed_base", 0),
                        "Capacity": data.get("weight_capacity", 0),
                        "Weight": data.get("weight_self", 0)
                    }
                "plating":
                    return {
                        "HP Bonus": data.get("hp_bonus", 0),
                        "Damage Reduction": "%.0f%%" % (data.get("damage_reduction", 0) * 100),
                        "Weight": data.get("weight", 0)
                    }
                "weapons":
                    return {
                        "Damage": "%d-%d" % [data.get("damage_min", 0), data.get("damage_max", 0)],
                        "Fire Rate": data.get("fire_rate", 0),
                        "Range": data.get("range_maximum", 0),
                        "Accuracy": "%.0f%%" % (data.get("accuracy", 0) * 100),
                        "Weight": data.get("weight", 0)
                    }
    
    return {}


func get_category_display_name(category: String) -> String:
    match category:
        "chassis": return "Chassis"
        "plating": return "Plating"
        "weapons": return "Weapons"
        _: return "All Components"


func get_tier_display_name(tier: int) -> String:
    match tier:
        0: return "Tier 1 - Starter"
        1: return "Tier 2 - Standard"
        2: return "Tier 3 - Advanced"
        3: return "Tier 4 - Elite"
        _: return "All Tiers"


# ============================================================================
# SHOP STATE
# ============================================================================

func get_player_credits() -> int:
    
        return _game_state.credits
    return 0


func get_player_tier() -> int:
    
        return _game_state.current_tier
    return 0


func is_arcade_mode() -> bool:
    
        return _game_state.is_arcade_mode()
    return false
