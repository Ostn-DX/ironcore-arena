extends Control
class_name TutorialManager
## TutorialManager — guides new players through game mechanics.

signal tutorial_completed
signal tutorial_skipped

# Tutorial steps
enum TutorialStep {
	NONE,
	WELCOME,
	BUILDER_INTRO,
	COMPONENTS_EXPLAINED,
	WEIGHT_LIMIT,
	FIRST_BATTLE,
	MOVEMENT,
	ATTACKING,
	COMMANDS,
	VICTORY,
	SHOP_INTRO,
	CAMPAIGN_PROGRESS,
	COMPLETE
}

# Current state
var current_step: TutorialStep = TutorialStep.NONE
var tutorial_active: bool = false

# UI Elements
var tutorial_panel: Panel = null
var title_label: Label = null
var content_label: Label = null
var instruction_label: Label = null
var continue_button: Button = null
var skip_button: Button = null
var highlight_overlay: ColorRect = null

# Step content
const TUTORIAL_CONTENT: Dictionary = {
	TutorialStep.WELCOME: {
		"title": "Welcome to Ironcore Arena!",
		"content": "In this game, you'll build combat robots and battle them in arena combat.\n\nYour goal: Become the Ironcore Champion by defeating all opponents.",
		"instruction": "Click Continue to start the tutorial."
	},
	TutorialStep.BUILDER_INTRO: {
		"title": "The Bot Builder",
		"content": "Before each battle, you'll design your bot in the Builder.\n\nChoose a chassis (body), weapons, armor, and other components to create your perfect fighting machine.",
		"instruction": "Let's look at the different component types."
	},
	TutorialStep.COMPONENTS_EXPLAINED: {
		"title": "Component Types",
		"content": "• CHASSIS: Determines your bot's size, speed, and weight capacity\n• WEAPONS: Your offensive capabilities (machine guns, cannons, etc.)\n• ARMOR: Increases HP and reduces damage\n• MOBILITY: Affects movement speed\n• SENSORS: Improves targeting range",
		"instruction": "Higher tier components are stronger but heavier."
	},
	TutorialStep.WEIGHT_LIMIT: {
		"title": "Weight Limit",
		"content": "Every chassis has a WEIGHT LIMIT. You cannot exceed this when building your bot.\n\nHeavy armor and big weapons weigh more - find the right balance for your strategy!",
		"instruction": "Lighter builds are faster. Heavier builds hit harder."
	},
	TutorialStep.FIRST_BATTLE: {
		"title": "Your First Battle",
		"content": "Battles are fought automatically, but you can issue tactical commands to influence the outcome.\n\nWatch your bot fight and intervene when needed!",
		"instruction": "Let's learn the controls."
	},
	TutorialStep.MOVEMENT: {
		"title": "Moving Your Bot",
		"content": "To move your bot:\n\n1. CLICK and HOLD on your BLUE bot\n2. DRAG to where you want it to go\n3. RELEASE to issue the move command",
		"instruction": "Try it now! Click and drag your bot."
	},
	TutorialStep.ATTACKING: {
		"title": "Attacking Enemies",
		"content": "To attack an enemy:\n\n1. CLICK and HOLD on your BLUE bot\n2. DRAG to the RED enemy you want to attack\n3. RELEASE to issue the attack command",
		"instruction": "Your bot will focus fire on that target!"
	},
	TutorialStep.COMMANDS: {
		"title": "Command Types",
		"content": "• MOVE: Drag to empty space - bot moves there\n• ATTACK: Drag to enemy - bot focuses fire\n• FOLLOW: Drag to ally - bot stays near teammate\n\nCommands last for several seconds. Use them wisely!",
		"instruction": "Command cooldown: 0.5 seconds between commands."
	},
	TutorialStep.VICTORY: {
		"title": "Victory!",
		"content": "When you win a battle, you'll earn:\n\n• CREDITS: Spend in the shop\n• GRADE: S/A/B/C/D/F based on performance\n• PROGRESS: Unlock new arenas and tiers",
		"instruction": "Faster wins = better grades = bigger rewards!"
	},
	TutorialStep.SHOP_INTRO: {
		"title": "The Component Shop",
		"content": "Spend your credits in the shop to buy new components.\n\nBetter components = stronger bots = easier victories!\n\nHigher tiers unlock as you progress through the campaign.",
		"instruction": "Buy components, then equip them in the Builder."
	},
	TutorialStep.CAMPAIGN_PROGRESS: {
		"title": "Campaign Progression",
		"content": "Complete all arenas in a tier to advance to the next.\n\nEach tier unlocks stronger components and tougher opponents.\n\nCan you reach Tier 4 and defeat the Juggernaut?",
		"instruction": "Your progress is saved automatically."
	},
	TutorialStep.COMPLETE: {
		"title": "Tutorial Complete!",
		"content": "You're ready to become the Ironcore Champion!\n\n• Build smart\n• Command wisely\n• Upgrade often\n\nGood luck in the arena!",
		"instruction": "Click Finish to start your campaign."
	}
}


func _ready() -> void:
	_setup_ui()
	hide_tutorial()


func _setup_ui() -> void:
	## Setup tutorial UI elements
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	
	# Highlight overlay (for highlighting UI elements)
	highlight_overlay = ColorRect.new()
	highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_overlay.color = Color(0, 0, 0, 0.7)
	highlight_overlay.visible = false
	add_child(highlight_overlay)
	
	# Tutorial panel
	tutorial_panel = Panel.new()
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.size = Vector2(600, 400)
	tutorial_panel.position = Vector2(340, 160)
	add_child(tutorial_panel)
	
	# Title
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(360, 180)
	title_label.size = Vector2(560, 40)
	add_child(title_label)
	
	# Content
	content_label = Label.new()
	content_label.add_theme_font_size_override("font_size", 16)
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.position = Vector2(360, 230)
	content_label.size = Vector2(560, 200)
	add_child(content_label)
	
	# Instruction
	instruction_label = Label.new()
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.modulate = Color(0.8, 0.9, 1.0)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.position = Vector2(360, 440)
	instruction_label.size = Vector2(560, 30)
	add_child(instruction_label)
	
	# Continue button
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.position = Vector2(590, 490)
	continue_button.size = Vector2(100, 40)
	continue_button.pressed.connect(_on_continue)
	add_child(continue_button)
	
	# Skip button
	skip_button = Button.new()
	skip_button.text = "Skip Tutorial"
	skip_button.position = Vector2(360, 490)
	skip_button.size = Vector2(100, 40)
	skip_button.pressed.connect(_on_skip)
	add_child(skip_button)


func start_tutorial() -> void:
	## Start the tutorial sequence
	tutorial_active = true
	current_step = TutorialStep.WELCOME
	_show_current_step()
	show_tutorial()


func show_tutorial() -> void:
	## Show the tutorial UI
	visible = true
	tutorial_panel.visible = true
	title_label.visible = true
	content_label.visible = true
	instruction_label.visible = true
	continue_button.visible = true
	skip_button.visible = true


func hide_tutorial() -> void:
	## Hide the tutorial UI
	visible = false
	tutorial_panel.visible = false
	title_label.visible = false
	content_label.visible = false
	instruction_label.visible = false
	continue_button.visible = false
	skip_button.visible = false
	highlight_overlay.visible = false


func _show_current_step() -> void:
	## Display current step content
	if not TUTORIAL_CONTENT.has(current_step):
		hide_tutorial()
		return
	
	var content: Dictionary = TUTORIAL_CONTENT[current_step]
	
	title_label.text = content["title"]
	content_label.text = content["content"]
	instruction_label.text = content["instruction"]
	
	# Update button text for final step
	if current_step == TutorialStep.COMPLETE:
		continue_button.text = "Finish"
		skip_button.visible = false


func next_step() -> void:
	## Advance to next tutorial step
	current_step = current_step + 1 as TutorialStep
	
	if current_step > TutorialStep.COMPLETE:
		_complete_tutorial()
	else:
		_show_current_step()


func _complete_tutorial() -> void:
	## Tutorial completed
	tutorial_active = false
	hide_tutorial()
	
	# Mark tutorial as complete in save
	if GameState:
		GameState.settings["tutorial_completed"] = true
		GameState.save_game()
	
	tutorial_completed.emit()


func _on_continue() -> void:
	## Handle continue button
	if AudioManager:
		AudioManager.play_ui_click()
	
	if current_step == TutorialStep.COMPLETE:
		_complete_tutorial()
	else:
		next_step()


func _on_skip() -> void:
	## Handle skip button
	if AudioManager:
		AudioManager.play_ui_cancel()
	
	hide_tutorial()
	tutorial_active = false
	
	# Mark as complete even if skipped
	if GameState:
		GameState.settings["tutorial_completed"] = true
		GameState.save_game()
	
	tutorial_skipped.emit()


func is_tutorial_completed() -> bool:
	## Check if tutorial was already completed
	if GameState:
		return GameState.settings.get("tutorial_completed", false)
	return false


func should_show_tutorial() -> bool:
	## Determine if tutorial should be shown
	# Show if not completed and this is a new game
	if is_tutorial_completed():
		return false
	
	if GameState:
		# Don't show if player has already won battles
		if GameState.completed_arenas.size() > 0:
			return false
	
	return true
