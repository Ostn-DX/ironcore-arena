extends Control
class_name ResultsScreen
## ResultsScreen — displays detailed battle results, stats, and rewards.
## Shown after battle ends with options to continue, restart, or edit loadout.

signal continue_pressed
signal restart_pressed
signal edit_loadout_pressed
signal next_arena_pressed

# UI Elements (created dynamically)
var background: Panel = null
var title_label: Label = null
var grade_label: Label = null
var stats_container: VBoxContainer = null
var rewards_container: HBoxContainer = null
var buttons_container: HBoxContainer = null

# Animation
var appear_tween: Tween = null

# Colors
const COLOR_VICTORY: Color = Color(0.2, 0.9, 0.2)
const COLOR_DEFEAT: Color = Color(0.9, 0.2, 0.2)
const COLOR_S_RANK: Color = Color(1.0, 0.84, 0.0)  # Gold
const COLOR_A_RANK: Color = Color(0.8, 0.9, 1.0)  # Silver-ish
const COLOR_B_RANK: Color = Color(0.8, 0.5, 0.3)  # Bronze-ish
const COLOR_DEFAULT: Color = Color(0.7, 0.7, 0.7)


func _ready() -> void:
    visible = false
    mouse_filter = MOUSE_FILTER_STOP


# ============================================================================
# DISPLAY
# ============================================================================

func show_results(result: BattleManager.BattleResult, rewards: Dictionary) -> void:
    ## Display battle results
    visible = true
    
    # Clear previous
    for child in get_children():
        child.queue_free()
    
    # Create UI elements
    _create_background()
    _create_title_section(result)
    _create_grade_display(result)
    _create_condition_display(result)
    _create_stats_section(result)
    _create_rewards_section(rewards, result.victory)
    _create_buttons(result.victory)
    
    # Animate in
    _animate_appear()


func _create_background() -> void:
    ## Semi-transparent background
    var bg: ColorRect = ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0, 0, 0, 0.7)
    add_child(bg)
    
    # Main panel
    background = Panel.new()
    background.set_anchors_preset(Control.PRESET_CENTER)
    background.size = Vector2(600, 700)
    background.position = Vector2(340, 10)  # Center in 1280x720
    add_child(background)


func _create_title_section(result: BattleManager.BattleResult) -> void:
    ## Victory/Defeat title
    title_label = Label.new()
    title_label.text = "VICTORY!" if result.victory else "DEFEAT"
    title_label.add_theme_font_size_override("font_size", 48)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.position = Vector2(440, 40)
    title_label.size = Vector2(400, 60)
    title_label.modulate = COLOR_VICTORY if result.victory else COLOR_DEFEAT
    add_child(title_label)
    
    # Arena name subtitle
    var arena_label: Label = Label.new()
    arena_label.text = result.arena_name
    arena_label.add_theme_font_size_override("font_size", 20)
    arena_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    arena_label.position = Vector2(440, 105)
    arena_label.size = Vector2(400, 30)
    arena_label.modulate = Color(0.8, 0.8, 0.8)
    add_child(arena_label)


func _create_grade_display(result: BattleManager.BattleResult) -> void:
    ## Large grade letter
    grade_label = Label.new()
    grade_label.text = result.get_grade()
    grade_label.add_theme_font_size_override("font_size", 96)
    grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    grade_label.position = Vector2(540, 140)
    grade_label.size = Vector2(200, 100)
    
    # Color based on grade
    match result.get_grade():
        "S": grade_label.modulate = COLOR_S_RANK
        "A": grade_label.modulate = COLOR_A_RANK
        "B": grade_label.modulate = COLOR_B_RANK
        "C", "D": grade_label.modulate = COLOR_DEFAULT
        "F": grade_label.modulate = COLOR_DEFEAT
    
    add_child(grade_label)


func _create_condition_display(result: BattleManager.BattleResult) -> void:
    ## End condition text
    var condition_label: Label = Label.new()
    condition_label.text = result.get_condition_string()
    condition_label.add_theme_font_size_override("font_size", 18)
    condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    condition_label.position = Vector2(440, 245)
    condition_label.size = Vector2(400, 25)
    condition_label.modulate = Color(0.7, 0.7, 0.7)
    add_child(condition_label)


func _create_stats_section(result: BattleManager.BattleResult) -> void:
    ## Container for stats
    stats_container = VBoxContainer.new()
    stats_container.position = Vector2(380, 290)
    stats_container.size = Vector2(520, 200)
    stats_container.theme_override_constants/separation = 8
    add_child(stats_container)
    
    # Section title
    var section_title: Label = Label.new()
    section_title.text = "Battle Statistics"
    section_title.add_theme_font_size_override("font_size", 20)
    section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats_container.add_child(section_title)
    
    # Separator
    var separator: HSeparator = HSeparator.new()
    stats_container.add_child(separator)
    
    # Time row
    _add_stat_row("Time", _format_time(result.completion_time), _format_time(result.par_time))
    
    # Bots row
    _add_stat_row("Enemy Bots Destroyed", str(result.enemy_bots_destroyed), str(result.player_bots_lost) + " lost")
    
    # Detailed stats from WinLossManager if available
    if result.battle_stats.size() > 0:
        var stats: Dictionary = result.battle_stats
        
        if stats.has("accuracy"):
            var accuracy_pct: float = stats["accuracy"] * 100
            _add_stat_row("Shot Accuracy", "%.1f%%" % accuracy_pct)
        
        if stats.has("damage_dealt") and stats.has("damage_taken"):
            _add_stat_row("Damage", "Dealt: %d" % stats["damage_dealt"], "Taken: %d" % stats["damage_taken"])
        
        if stats.has("kd_ratio"):
            _add_stat_row("K/D Ratio", "%.2f" % stats["kd_ratio"])
        
        if stats.has("commands_issued"):
            _add_stat_row("Commands Issued", str(stats["commands_issued"]))


func _add_stat_row(label: String, value: String, extra: String = "") -> void:
    ## Add a stat row to the container
    var row: HBoxContainer = HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var label_node: Label = Label.new()
    label_node.text = label + ":"
    label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label_node.add_theme_font_size_override("font_size", 16)
    row.add_child(label_node)
    
    var value_node: Label = Label.new()
    value_node.text = value
    value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_node.add_theme_font_size_override("font_size", 16)
    value_node.modulate = Color(0.9, 0.9, 0.9)
    row.add_child(value_node)
    
    if extra != "":
        var extra_node: Label = Label.new()
        extra_node.text = "  (" + extra + ")"
        extra_node.add_theme_font_size_override("font_size", 14)
        extra_node.modulate = Color(0.5, 0.5, 0.5)
        row.add_child(extra_node)
    
    stats_container.add_child(row)


func _create_rewards_section(rewards: Dictionary, victory: bool) -> void:
    ## Rewards container
    rewards_container = HBoxContainer.new()
    rewards_container.position = Vector2(380, 510)
    rewards_container.size = Vector2(520, 80)
    rewards_container.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(rewards_container)
    
    if not victory:
        # No rewards on defeat
        var no_reward_label: Label = Label.new()
        no_reward_label.text = "No rewards for defeat"
        no_reward_label.add_theme_font_size_override("font_size", 18)
        no_reward_label.modulate = Color(0.5, 0.5, 0.5)
        rewards_container.add_child(no_reward_label)
        return
    
    # Credits icon and amount
    var credits_container: VBoxContainer = VBoxContainer.new()
    credits_container.alignment = BoxContainer.ALIGNMENT_CENTER
    
    var credits_icon: Label = Label.new()
    credits_icon.text = "💰"
    credits_icon.add_theme_font_size_override("font_size", 32)
    credits_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    credits_container.add_child(credits_icon)
    
    var credits_label: Label = Label.new()
    var base: int = rewards.get("base_credits", 0)
    var bonus: int = rewards.get("bonus_credits", 0)
    if bonus > 0:
        credits_label.text = "%d (+ %d bonus)" % [base, bonus]
    else:
        credits_label.text = str(base)
    credits_label.add_theme_font_size_override("font_size", 20)
    credits_label.modulate = Color(1.0, 0.84, 0.0)
    credits_container.add_child(credits_label)
    
    var credits_title: Label = Label.new()
    credits_title.text = "Credits Earned"
    credits_title.add_theme_font_size_override("font_size", 14)
    credits_title.modulate = Color(0.6, 0.6, 0.6)
    credits_container.add_child(credits_title)
    
    rewards_container.add_child(credits_container)


func _create_buttons(victory: bool) -> void:
    ## Button container
    buttons_container = HBoxContainer.new()
    buttons_container.position = Vector2(340, 610)
    buttons_container.size = Vector2(600, 60)
    buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
    buttons_container.theme_override_constants/separation = 20
    add_child(buttons_container)
    
    # Continue/Next button
    var continue_btn: Button = Button.new()
    continue_btn.text = "Continue" if victory else "Retry"
    continue_btn.size = Vector2(140, 50)
    continue_btn.pressed.connect(_on_continue)
    buttons_container.add_child(continue_btn)
    
    # Restart button
    var restart_btn: Button = Button.new()
    restart_btn.text = "Restart"
    restart_btn.size = Vector2(140, 50)
    restart_btn.pressed.connect(_on_restart)
    buttons_container.add_child(restart_btn)
    
    # Edit loadout button
    var edit_btn: Button = Button.new()
    edit_btn.text = "Edit Bot"
    edit_btn.size = Vector2(140, 50)
    edit_btn.pressed.connect(_on_edit_loadout)
    buttons_container.add_child(edit_btn)
    
    # Next arena button (only on victory)
    if victory:
        var next_btn: Button = Button.new()
        next_btn.text = "Next Arena →"
        next_btn.size = Vector2(140, 50)
        next_btn.pressed.connect(_on_next_arena)
        buttons_container.add_child(next_btn)


func _animate_appear() -> void:
    ## Animate results screen appearing
    modulate.a = 0
    scale = Vector2(0.9, 0.9)
    
    appear_tween = create_tween()
    appear_tween.set_ease(Tween.EASE_OUT)
    appear_tween.set_trans(Tween.TRANS_BACK)
    appear_tween.tween_property(self, "modulate:a", 1.0, 0.3)
    appear_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3)


# ============================================================================
# BUTTON HANDLERS
# ============================================================================

func _on_continue() -> void:
    continue_pressed.emit()


func _on_restart() -> void:
    restart_pressed.emit()


func _on_edit_loadout() -> void:
    edit_loadout_pressed.emit()


func _on_next_arena() -> void:
    next_arena_pressed.emit()


# ============================================================================
# UTILITY
# ============================================================================

func _format_time(seconds: float) -> String:
    ## Format seconds as MM:SS
    var mins: int = int(seconds) / 60
    var secs: int = int(seconds) % 60
    return "%02d:%02d" % [mins, secs]


func hide_results() -> void:
    ## Hide the results screen
    visible = false
    for child in get_children():
        child.queue_free()


func is_showing() -> bool:
    return visible
