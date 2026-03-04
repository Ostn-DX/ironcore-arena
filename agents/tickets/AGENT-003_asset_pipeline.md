## ID
AGENT-003

## Title
Design Asset Pipeline and Animation System

## Goal
Create production-ready asset import pipeline with sprite atlases, animation state machines, and hot-reload for rapid art iteration. When final art arrives, integration must be painless.

## Problem Statement
Current state: Procedural sprites generated at runtime. No atlases. No animation system. When pixel art arrives:
- Replacing sprites will break scenes
- No batching = performance issues
- No animation state machine = jerky transitions
- No hot-reload = slow iteration

This ticket designs the pipeline so art drops in seamlessly.

## Allowed Files
- project/autoload/GameManager.gd (read)
- project/autoload/VFXManager.gd (read)
- project/resources/ (new resources go here)
- project/assets/ (for atlases)

## New Files
- project/resources/sprite_atlas.gd (Resource class)
- project/resources/animation_state.gd (Resource class)
- project/scripts/components/sprite_component.gd
- project/scripts/components/animation_component.gd
- project/tools/atlas_builder.gd (editor tool)
- project/tools/animation_preview.gd (editor tool)
- docs/ASSET_PIPELINE.md (documentation)

## Forbidden Files
- scenes/*.tscn (no scene modifications)
- src/entities/*.gd (no entity changes yet)
- Any modification to procedural generation code

## Architecture

### 1. SpriteAtlas Resource (sprite_atlas.gd)
```gdscript
class_name SpriteAtlas
extends Resource

@export var atlas_texture: Texture2D
@export var regions: Dictionary # name -> Rect2
@export var metadata: Dictionary # name -> {pivot, border, etc.}

func get_region(name: String) -> Rect2:
func get_pivot(name: String) -> Vector2:
func has_sprite(name: String) -> bool:

## Editor import plugin integration
## When artist drops spritesheet.png + spritesheet.json
## Creates SpriteAtlas resource automatically
```

### 2. AnimationState Resource (animation_state.gd)
```gdscript
class_name AnimationState
extends Resource

@export var state_name: String
@export var sprite_name: String # Reference to SpriteAtlas region
@export var frame_count: int = 1
@export var fps: float = 12.0
@export var loop: bool = true
@export var transitions: Array[AnimationTransition]

func get_duration() -> float:
func get_frame_at_time(t: float) -> int:
```

### 3. AnimationTransition Resource
```gdscript
class_name AnimationTransition
extends Resource

@export var from_state: String
@export var to_state: String
@export var condition: String # "is_moving", "health < 0.5", etc.
@export var blend_duration: float = 0.1
@export var interruptible: bool = true
```

### 4. SpriteComponent (sprite_component.gd)
```gdscript
class_name SpriteComponent
extends Node2D

@export var atlas: SpriteAtlas
@export var current_sprite: String = "idle"
@export var flip_h: bool = false
@export var modulate: Color = Color.WHITE

func set_sprite(name: String) -> void:
func set_flip(flip: bool) -> void:

## Replaces direct Sprite2D usage
## Handles atlas lookup, pivot application
```

### 5. AnimationComponent (animation_component.gd)
```gdscript
class_name AnimationComponent
extends Node

@export var sprite_component: SpriteComponent
@export var state_machine: AnimationStateMachine

signal state_changed(new_state: String)

func play(state_name: String) -> void:
func update(delta: float) -> void: # Call from _process
func set_parameter(name: String, value: Variant) -> void:

## Integrates with existing StateMachine component
## States: idle, move, attack, damage, death
```

### 6. Atlas Builder Tool (atlas_builder.gd)
```gdscript
## Editor plugin/script
## Usage: Project -> Tools -> Build Sprite Atlases

## Input: assets/sprites_raw/ (folder of PNGs)
## Output: assets/atlases/
##   - chassis_atlas.png
##   - chassis_atlas.json
##   - chassis_atlas.tres (SpriteAtlas resource)

## Features:
## - Packs sprites with max texture size (2048x2048)
## - Generates JSON mapping for debugging
## - Reports duplicate names, missing frames
```

### 7. Animation Preview Tool (animation_preview.gd)
```gdscript
## Editor window for previewing animations
## Usage: Double-click .tres file -> Preview Animation

## Shows:
## - Sprite with animation playing
## - State machine graph (nodes and transitions)
## - Parameter sliders for testing conditions
## - Frame timing visualization
```

## Migration Strategy

### Phase 1: Parallel Implementation (This Ticket)
- Build pipeline alongside existing procedural sprites
- Create components but don't integrate yet
- Test with sample art assets

### Phase 2: Gradual Migration (Future Tickets)
- One entity type at a time
- Chassis first (most visible)
- Weapons second
- Effects last

### Phase 3: Remove Procedural (v0.2.0)
- Delete SpriteGenerator
- Procedural becomes fallback only

## Integration Points (Document, Don't Modify)

For future integration, document how to:

1. **Replace Bot sprite**:
   ```gdscript
   # In Bot._ready():
   # REMOVE: var sprite = Sprite2D.new()
   # ADD: var sprite = SpriteComponent.new()
   # ADD: sprite.atlas = preload("res://assets/atlases/chassis_atlas.tres")
   ```

2. **Connect to StateMachine**:
   ```gdscript
   # AnimationComponent listens to StateMachine state changes
   # On "attacking" state -> play("attack")
   # On "moving" state -> play("move")
   ```

3. **Hot-reload**:
   ```gdscript
   # In editor tool:
   # FileSystemDock signal file_changed -> reload atlas
   # SpriteComponent auto-updates texture reference
   ```

## Deliverable Structure
```
agent_runs/AGENT-003/
  NEW_FILES/
    - resources/sprite_atlas.gd
    - resources/animation_state.gd
    - resources/animation_transition.gd
    - resources/animation_state_machine.gd
    - scripts/components/sprite_component.gd
    - scripts/components/animation_component.gd
    - tools/atlas_builder.gd
    - tools/animation_preview.gd
    - docs/ASSET_PIPELINE.md
  MODIFICATIONS/
    - (none - parallel implementation)
  TESTS/
    - test_sprite_atlas.gd
    - test_animation_component.gd
  INTEGRATION_GUIDE.md
  CHANGELOG.md
```

## Sample Assets to Create
Include sample assets for testing:
- `assets/test/chassis_test_atlas.png` (4x4 grid of colored rectangles)
- `assets/test/chassis_test_atlas.json` (region definitions)
- `resources/test_chassis_atlas.tres` (pre-built resource)

## Acceptance Criteria
- [ ] AC1: SpriteAtlas resource loads and displays correct regions
- [ ] AC2: AnimationComponent plays states with correct timing
- [ ] AC3: AtlasBuilder packs 50+ sprites into < 2048x2048 texture
- [ ] AC4: Hot-reload updates sprites in running game (editor)
- [ ] AC5: State machine transitions work (idle → move → attack)
- [ ] AC6: Documentation shows exact migration steps
- [ ] AC7: Sample assets demonstrate full pipeline
- [ ] AC8: No modification to existing scenes or entities

## Performance Requirements
- One draw call per atlas (batching)
- < 1ms to switch animation state
- Atlas texture memory < 50MB total

## Notes
- Use Godot's built-in Resource system
- Leverage EditorPlugin for tools
- Don't break existing procedural system
- Design for artist workflow (not programmer convenience)
