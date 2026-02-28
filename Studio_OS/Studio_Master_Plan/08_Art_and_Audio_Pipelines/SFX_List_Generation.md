---
title: SFX List Generation
type: pipeline
layer: design
status: active
tags:
  - audio
  - sfx
  - list
  - generation
  - design-intent
depends_on:
  - "[Audio_Pipeline_Overview]"
used_by:
  - "[SFX_Generation_Routing]]"
  - "[[Audio_Validation_Gates]"
---

# SFX List Generation

## Purpose

Systematically identify and document all sound effects needed for a game, ensuring nothing is missed and providing a clear roadmap for audio production.

---

## SFX Categories

### 1. UI Sounds

**Trigger**: Player interacts with interface

| Sound | Trigger | Priority |
|-------|---------|----------|
| Button Hover | Mouse over button | Low |
| Button Click | Button pressed | High |
| Button Confirm | Action confirmed | High |
| Button Cancel | Action cancelled | Medium |
| Menu Open | Menu opened | Medium |
| Menu Close | Menu closed | Medium |
| Error | Invalid action | Medium |
| Notification | Alert/message | Medium |
| Slider Tick | Value changed | Low |
| Typewriter | Text appearing | Low |

### 2. Gameplay Sounds

**Trigger**: Core game mechanics

| Sound | Trigger | Priority |
|-------|---------|----------|
| Jump | Character jumps | High |
| Land | Character lands | High |
| Footstep | Character moves | High |
| Attack | Weapon swing | High |
| Hit | Attack connects | High |
| Damage | Player damaged | High |
| Death | Character dies | High |
| Collect | Item picked up | High |
| Use Item | Item consumed | Medium |
| Equip | Gear equipped | Low |

### 3. Weapon Sounds

**Trigger**: Combat actions

| Sound | Trigger | Priority |
|-------|---------|----------|
| Weapon Draw | Weapon equipped | Medium |
| Weapon Sheathe | Weapon stowed | Low |
| Swing | Attack initiated | High |
| Impact | Hit target | High |
| Block | Attack blocked | Medium |
| Parry | Attack parried | Medium |
| Reload | Reloading | Medium |
| Empty Click | No ammo | Medium |
| Charge | Charging attack | Medium |
| Special | Special ability | High |

### 4. Ambient Sounds

**Trigger**: Environmental presence

| Sound | Context | Priority |
|-------|---------|----------|
| Wind | Outdoor areas | Medium |
| Rain | Weather | Medium |
| Fire | Camps/torches | Low |
| Water | Rivers/oceans | Medium |
| Birds | Forests | Low |
| Insects | Swamps/night | Low |
| Machinery | Industrial | Medium |
| Crowd | Towns/arenas | Low |
| Cave | Underground | Medium |
| Space | Sci-fi void | Low |

### 5. Character Sounds

**Trigger**: Character actions/states

| Sound | Trigger | Priority |
|-------|---------|----------|
| Footstep | Movement | High |
| Breathing | Idle/exertion | Low |
| Pain | Taking damage | High |
| Death | Dying | High |
| Effort | Heavy action | Medium |
| Emote | Expression | Low |
| Dialogue | Speaking | Medium |

---

## SFX List Template

```yaml
sfx_list:
  project: "Game Name"
  version: "1.0"
  last_updated: "2024-01-15"
  
  categories:
    ui:
      - id: "ui_button_click"
        name: "Button Click"
        description: "Standard button press feedback"
        trigger: "Player clicks any button"
        priority: high
        quantity: 3  # Variations needed
        duration: "0.1-0.3s"
        source: "generate"  # generate, pack, or manual
        
      - id: "ui_error"
        name: "Error Sound"
        description: "Invalid action feedback"
        trigger: "Player attempts invalid action"
        priority: medium
        quantity: 1
        duration: "0.3-0.5s"
        source: "generate"
    
    gameplay:
      - id: "player_jump"
        name: "Player Jump"
        description: "Character jump sound"
        trigger: "Player presses jump"
        priority: high
        quantity: 3
        duration: "0.2-0.4s"
        source: "generate"
        
      - id: "player_footstep"
        name: "Footsteps"
        description: "Character footstep sounds"
        trigger: "Player moves on ground"
        priority: high
        quantity: 6  # Per surface type
        duration: "0.1-0.2s"
        source: "generate"
        variants:
          - surface: "grass"
            quantity: 6
          - surface: "stone"
            quantity: 6
          - surface: "wood"
            quantity: 6
    
    weapons:
      - id: "sword_swing"
        name: "Sword Swing"
        description: "Sword attack sound"
        trigger: "Player swings sword"
        priority: high
        quantity: 4
        duration: "0.2-0.4s"
        source: "generate"
        
      - id: "sword_impact"
        name: "Sword Impact"
        description: "Sword hitting target"
        trigger: "Sword connects with enemy"
        priority: high
        quantity: 4
        duration: "0.1-0.3s"
        source: "generate"
```

---

## Automated List Generation

### From Design Documents

```python
def generate_sfx_list_from_design(design_doc):
    """Parse design doc and generate SFX list"""
    
    sfx_list = {
        'ui': [],
        'gameplay': [],
        'weapons': [],
        'ambient': [],
        'character': []
    }
    
    # Extract UI elements
    for ui_element in design_doc.get('ui_elements', []):
        if ui_element['type'] in ['button', 'slider', 'checkbox']:
            sfx_list['ui'].append({
                'id': f"ui_{ui_element['id']}_click",
                'name': f"{ui_element['name']} Click",
                'trigger': f"Player interacts with {ui_element['name']}",
                'priority': 'high' if ui_element['frequency'] == 'common' else 'medium'
            })
    
    # Extract abilities/actions
    for action in design_doc.get('player_actions', []):
        sfx_list['gameplay'].append({
            'id': f"player_{action['id']}",
            'name': action['name'],
            'trigger': f"Player uses {action['name']}",
            'priority': 'high'
        })
    
    # Extract weapons
    for weapon in design_doc.get('weapons', []):
        sfx_list['weapons'].append({
            'id': f"{weapon['id']}_swing",
            'name': f"{weapon['name']} Swing",
            'trigger': f"Player attacks with {weapon['name']}",
            'priority': 'high'
        })
        sfx_list['weapons'].append({
            'id': f"{weapon['id']}_impact",
            'name': f"{weapon['name']} Impact",
            'trigger': f"{weapon['name']} hits target",
            'priority': 'high'
        })
    
    return sfx_list
```

---

## SFX Count Estimation

### By Game Type

| Game Type | UI | Gameplay | Weapons | Ambient | Character | Total |
|-----------|-----|----------|---------|---------|-----------|-------|
| Puzzle | 10 | 15 | 0 | 5 | 5 | 35 |
| Platformer | 15 | 30 | 0 | 10 | 15 | 70 |
| Action RPG | 20 | 40 | 30 | 20 | 25 | 135 |
| FPS | 15 | 25 | 50 | 15 | 20 | 125 |
| Strategy | 25 | 35 | 20 | 15 | 10 | 105 |

**Rule of Thumb**: Budget 100-150 SFX for a medium-complexity game.

---

## Priority Matrix

| Priority | Definition | Production Order |
|----------|------------|------------------|
| Critical | Game cannot ship without | Week 1 |
| High | Major gameplay impact | Week 2-3 |
| Medium | Noticeable if missing | Week 4-6 |
| Low | Nice to have | Week 7+ |

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  SFX LIST QUICK REFERENCE                              │
├────────────────────────────────────────────────────────┤
│  CATEGORIES:                                           │
│  • UI (10-25 sounds)                                   │
│  • Gameplay (20-40 sounds)                             │
│  • Weapons (0-50 sounds)                               │
│  • Ambient (10-30 sounds)                              │
│  • Character (10-30 sounds)                            │
├────────────────────────────────────────────────────────┤
│  TYPICAL TOTAL: 100-150 SFX                            │
├────────────────────────────────────────────────────────┤
│  PRIORITY ORDER:                                       │
│  1. Critical → 2. High → 3. Medium → 4. Low            │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Audio philosophy
- [[SFX_Generation_Routing]] - Tool selection from list
- [[UI_Audio_Taxonomy]] - Detailed UI sound categories
- [[Audio_Validation_Gates]] - Quality checks
