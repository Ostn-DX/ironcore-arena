extends Control
class_name ShopScreen
## ShopScreen — UI for browsing and purchasing components.

signal shop_closed
signal component_selected(component_id: String)
signal component_purchased(component_id: String)

# Shop manager reference
var shop_manager: ShopManager = null

# UI Elements
var title_label: Label = null
var credits_label: Label = null
var category_buttons: Dictionary = {}
var component_list: VBoxContainer = null
var component_details: Panel = null
var detail_name: Label = null
var detail_description: Label = null
var detail_stats: VBoxContainer = null
var detail_cost: Label = null
var detail_tier: Label = null
var buy_button: Button = null

# Currently selected component
var selected_component: Dictionary = {}

# Colors
const COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5)
const COLOR_AFFORDABLE: Color = Color(0.2, 0.9, 0.2)
const COLOR_UNAFFORDABLE: Color = Color(0.9, 0.3, 0.3)
const COLOR_TIER_0: Color = Color(0.8, 0.8, 0.8)
const COLOR_TIER_1: Color = Color(0.6, 0.8, 1.0)
const COLOR_TIER_2: Color = Color(0.9, 0.7, 1.0)
const COLOR_TIER_3: Color = Color(1.0, 0.8, 0.4)


func _ready() -> void:
    # Create ShopManager
    shop_manager = ShopManager.new()
    shop_manager.name = "ShopManager"
    shop_manager.component_purchased.connect(_on_component_purchased)
    shop_manager.purchase_failed.connect(_on_purchase_failed)
    add_child(shop_manager)
    
    _setup_ui()
    _refresh_display()


func _setup_ui() -> void:
    ## Setup the shop UI
    set_anchors_preset(Control.PRESET_FULL_RECT)
    
    # Background
    var bg: ColorRect = ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.08, 0.08, 0.12, 1.0)
    add_child(bg)
    
    # Title bar
    var title_bar: HBoxContainer = HBoxContainer.new()
    title_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
    title_bar.size = Vector2(1280, 60)
    title_bar.position = Vector2(20, 10)
    add_child(title_bar)
    
    title_label = Label.new()
    title_label.text = "COMPONENT SHOP"
    title_label.add_theme_font_size_override("font_size", 32)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_bar.add_child(title_label)
    
    credits_label = Label.new()
    credits_label.text = "Credits: 0"
    credits_label.add_theme_font_size_override("font_size", 24)
    credits_label.modulate = Color(1.0, 0.84, 0.0)
    title_bar.add_child(credits_label)
    
    # Category buttons
    var category_bar: HBoxContainer = HBoxContainer.new()
    category_bar.position = Vector2(20, 80)
    category_bar.size = Vector2(600, 40)
    add_child(category_bar)
    
    for category in ShopManager.CATEGORIES:
        var btn: Button = Button.new()
        btn.text = category.capitalize()
        btn.size = Vector2(100, 35)
        btn.pressed.connect(_on_category_pressed.bind(category))
        category_bar.add_child(btn)
        category_buttons[category] = btn
    
    # Tier filter
    var tier_label: Label = Label.new()
    tier_label.text = "Tier Filter:"
    tier_label.position = Vector2(650, 85)
    tier_label.size = Vector2(80, 25)
    add_child(tier_label)
    
    var tier_filter: OptionButton = OptionButton.new()
    tier_filter.position = Vector2(740, 80)
    tier_filter.size = Vector2(150, 35)
    tier_filter.add_item("All Tiers", -1)
    tier_filter.add_item("Tier 1", 0)
    tier_filter.add_item("Tier 2", 1)
    tier_filter.add_item("Tier 3", 2)
    tier_filter.add_item("Tier 4", 3)
    tier_filter.item_selected.connect(_on_tier_selected)
    add_child(tier_filter)
    
    # Close button
    var close_btn: Button = Button.new()
    close_btn.text = "Close Shop"
    close_btn.position = Vector2(1150, 80)
    close_btn.size = Vector2(100, 35)
    close_btn.pressed.connect(_on_close)
    add_child(close_btn)
    
    # Component list (left side)
    var list_panel: Panel = Panel.new()
    list_panel.position = Vector2(20, 130)
    list_panel.size = Vector2(700, 550)
    add_child(list_panel)
    
    var list_title: Label = Label.new()
    list_title.text = "Available Components"
    list_title.add_theme_font_size_override("font_size", 18)
    list_title.position = Vector2(30, 140)
    list_title.size = Vector2(300, 25)
    add_child(list_title)
    
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.position = Vector2(30, 170)
    scroll.size = Vector2(680, 500)
    add_child(scroll)
    
    component_list = VBoxContainer.new()
    component_list.add_theme_constant_override("separation", 5)
    scroll.add_child(component_list)
    
    # Component details (right side)
    component_details = Panel.new()
    component_details.position = Vector2(740, 130)
    component_details.size = Vector2(510, 550)
    add_child(component_details)
    
    var details_title: Label = Label.new()
    details_title.text = "Component Details"
    details_title.add_theme_font_size_override("font_size", 18)
    details_title.position = Vector2(750, 140)
    details_title.size = Vector2(300, 25)
    add_child(details_title)
    
    # Detail content
    detail_name = Label.new()
    detail_name.text = "Select a component"
    detail_name.add_theme_font_size_override("font_size", 24)
    detail_name.position = Vector2(760, 180)
    detail_name.size = Vector2(470, 35)
    add_child(detail_name)
    
    detail_tier = Label.new()
    detail_tier.text = ""
    detail_tier.position = Vector2(760, 215)
    detail_tier.size = Vector2(470, 25)
    add_child(detail_tier)
    
    detail_description = Label.new()
    detail_description.text = ""
    detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_description.position = Vector2(760, 250)
    detail_description.size = Vector2(470, 80)
    add_child(detail_description)
    
    var stats_title: Label = Label.new()
    stats_title.text = "Stats:"
    stats_title.position = Vector2(760, 340)
    stats_title.size = Vector2(100, 25)
    add_child(stats_title)
    
    detail_stats = VBoxContainer.new()
    detail_stats.position = Vector2(760, 370)
    detail_stats.size = Vector2(470, 150)
    add_child(detail_stats)
    
    detail_cost = Label.new()
    detail_cost.text = ""
    detail_cost.add_theme_font_size_override("font_size", 20)
    detail_cost.position = Vector2(760, 530)
    detail_cost.size = Vector2(470, 30)
    add_child(detail_cost)
    
    buy_button = Button.new()
    buy_button.text = "Purchase"
    buy_button.position = Vector2(760, 570)
    buy_button.size = Vector2(200, 50)
    buy_button.disabled = true
    buy_button.pressed.connect(_on_buy_pressed)
    add_child(buy_button)


func _refresh_display() -> void:
    ## Refresh the entire shop display
    _update_credits()
    _update_component_list()
    _update_category_buttons()


func _update_credits() -> void:
    ## Update credits display
    if shop_manager:
        var credits: int = shop_manager.get_player_credits()
        credits_label.text = "💰 %d" % credits


func _update_category_buttons() -> void:
    ## Highlight current category
    for category in category_buttons:
        var btn: Button = category_buttons[category]
        if shop_manager and shop_manager.current_category == category:
            btn.modulate = Color(0.8, 0.9, 1.0)
        else:
            btn.modulate = Color.WHITE


func _update_component_list() -> void:
    ## Update the list of components
    # Clear existing
    for child in component_list.get_children():
        child.queue_free()
    
    if not shop_manager:
        return
    
    var components: Array[Dictionary] = shop_manager.get_filtered_components()
    
    for component in components:
        var row: Button = Button.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.custom_minimum_size = Vector2(0, 50)
        row.alignment = HORIZONTAL_ALIGNMENT_LEFT
        
        # Format text
        var owned: int = shop_manager.get_owned_quantity(component["id"])
        var cost_text: String = "FREE" if shop_manager.is_arcade_mode() else "%d CR" % component["cost"]
        row.text = "%s  |  %s  |  Owned: %d" % [component["name"], cost_text, owned]
        
        # Color based on tier
        var tier: int = component["tier"]
        match tier:
            0: row.modulate = COLOR_TIER_0
            1: row.modulate = COLOR_TIER_1
            2: row.modulate = COLOR_TIER_2
            3: row.modulate = COLOR_TIER_3
        
        # Check if can afford
        var can_buy: Dictionary = shop_manager.can_purchase(component["id"])
        if not can_buy["can_buy"]:
            if "credits" in can_buy["reason"].to_lower():
                row.modulate = COLOR_UNAFFORDABLE
            elif "tier" in can_buy["reason"].to_lower():
                row.modulate = COLOR_LOCKED
        
        row.pressed.connect(_on_component_selected.bind(component))
        component_list.add_child(row)


func _update_component_details() -> void:
    ## Update the details panel
    if selected_component.is_empty():
        detail_name.text = "Select a component"
        detail_tier.text = ""
        detail_description.text = ""
        detail_cost.text = ""
        
        for child in detail_stats.get_children():
            child.queue_free()
        
        buy_button.disabled = true
        return
    
    # Name and tier
    detail_name.text = selected_component["name"]
    detail_tier.text = shop_manager.get_tier_display_name(selected_component["tier"])
    
    match selected_component["tier"]:
        0: detail_tier.modulate = COLOR_TIER_0
        1: detail_tier.modulate = COLOR_TIER_1
        2: detail_tier.modulate = COLOR_TIER_2
        3: detail_tier.modulate = COLOR_TIER_3
    
    # Description
    detail_description.text = selected_component["description"]
    
    # Stats
    for child in detail_stats.get_children():
        child.queue_free()
    
    var stats: Dictionary = shop_manager.get_component_stats(selected_component["id"])
    for stat_name in stats:
        var stat_label: Label = Label.new()
        stat_label.text = "%s: %s" % [stat_name, str(stats[stat_name])]
        detail_stats.add_child(stat_label)
    
    # Cost and buy button
    var can_buy: Dictionary = shop_manager.can_purchase(selected_component["id"])
    
    if shop_manager.is_arcade_mode():
        detail_cost.text = "FREE (Arcade Mode)"
        detail_cost.modulate = COLOR_AFFORDABLE
        buy_button.disabled = false
        buy_button.text = "Add to Inventory"
    elif can_buy["can_buy"]:
        detail_cost.text = "Cost: %d credits" % selected_component["cost"]
        detail_cost.modulate = COLOR_AFFORDABLE
        buy_button.disabled = false
        buy_button.text = "Purchase"
    else:
        detail_cost.text = can_buy["reason"]
        detail_cost.modulate = COLOR_UNAFFORDABLE
        buy_button.disabled = true
        buy_button.text = "Cannot Purchase"


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_category_pressed(category: String) -> void:
    if shop_manager:
        shop_manager.set_category(category)
        _refresh_display()


func _on_tier_selected(index: int) -> void:
    if shop_manager:
        var tier: int = index - 1  # -1 for "All"
        shop_manager.set_tier_filter(tier)
        _refresh_display()


func _on_component_selected(component: Dictionary) -> void:
    selected_component = component
    _update_component_details()
    component_selected.emit(component["id"])


func _on_buy_pressed() -> void:
    if selected_component.is_empty() or not shop_manager:
        return
    
    var success: bool = shop_manager.purchase_component(selected_component["id"])
    if success:
        component_purchased.emit(selected_component["id"])
        _refresh_display()
        _update_component_details()


func _on_component_purchased(component_id: String, _quantity: int, _credits: int) -> void:
    print("ShopScreen: Purchased ", component_id)


func _on_purchase_failed(component_id: String, reason: String) -> void:
    print("ShopScreen: Purchase failed - ", reason)


func _on_close() -> void:
    shop_closed.emit()


# ============================================================================
# PUBLIC API
# ============================================================================

func open_shop() -> void:
    visible = true
    if shop_manager:
        shop_manager.open_shop()
    _refresh_display()


func close_shop() -> void:
    visible = false
    if shop_manager:
        shop_manager.close_shop()
