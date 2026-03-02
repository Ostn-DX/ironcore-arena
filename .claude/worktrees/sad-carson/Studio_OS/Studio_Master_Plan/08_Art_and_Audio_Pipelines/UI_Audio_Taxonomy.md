---
title: UI Audio Taxonomy
type: system
layer: design
status: active
tags:
  - audio
  - ui
  - taxonomy
  - sounds
  - interface
depends_on:
  - "[Audio_Pipeline_Overview]]"
  - "[[SFX_List_Generation]"
used_by:
  - "[SFX_Generation_Routing]"
---

# UI Audio Taxonomy

## Purpose

Standardized categorization of UI sounds to ensure consistent audio feedback across all interface interactions.

---

## UI Sound Categories

### 1. Button Sounds

#### Hover States

| Sound | Description | Pitch | Duration |
|-------|-------------|-------|----------|
| `ui_button_hover_soft` | Gentle hover feedback | Medium | 0.05s |
| `ui_button_hover_tech` | Digital hover beep | High | 0.03s |
| `ui_button_hover_mech` | Mechanical click | Low | 0.08s |

#### Click/Press States

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_button_click_standard` | Neutral click | Most buttons |
| `ui_button_click_primary` | Emphasized click | Primary actions |
| `ui_button_click_danger` | Warning tone | Delete/exit |
| `ui_button_click_confirm` | Positive tone | Confirm actions |

#### Release States

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_button_release` | Release feedback | Hold-to-confirm |
| `ui_button_release_cancel` | Cancel tone | Release outside |

### 2. Toggle Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_toggle_on` | Activation sound | Checkboxes, switches |
| `ui_toggle_off` | Deactivation sound | Unchecking |
| `ui_toggle_slide` | Slider movement | Value sliders |

### 3. Navigation Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_nav_open` | Menu open | Any menu |
| `ui_nav_close` | Menu close | Closing menu |
| `ui_nav_tab` | Tab switch | Tabbed interfaces |
| `ui_nav_back` | Go back | Back navigation |
| `ui_nav_forward` | Go forward | Forward navigation |

### 4. Feedback Sounds

#### Success/Confirmation

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_feedback_success` | Positive chime | Success actions |
| `ui_feedback_confirm` | Confirmation | Acknowledged |
| `ui_feedback_complete` | Task complete | Progress done |

#### Warning/Error

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_feedback_error` | Error buzz | Invalid action |
| `ui_feedback_warning` | Warning tone | Caution needed |
| `ui_feedback_denied` | Access denied | Restricted action |

#### Information

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_feedback_notify` | Notification | New message |
| `ui_feedback_alert` | Alert | Important info |
| `ui_feedback_update` | Status update | Progress update |

### 5. Input Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_input_type` | Typing | Keyboard input |
| `ui_input_delete` | Backspace | Deletion |
| `ui_input_submit` | Enter/Submit | Form submission |

### 6. Inventory/Collection Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_item_pickup` | Item acquired | Loot/collect |
| `ui_item_equip` | Item equipped | Gear change |
| `ui_item_use` | Item consumed | Using item |
| `ui_item_drop` | Item dropped | Discarding |
| `ui_currency_gain` | Money gained | Rewards |
| `ui_currency_spend` | Money spent | Purchases |

### 7. Progress Sounds

| Sound | Description | Use Case |
|-------|-------------|----------|
| `ui_progress_start` | Begin progress | Loading start |
| `ui_progress_tick` | Progress increment | Step complete |
| `ui_progress_complete` | Progress done | Loading finish |
| `ui_level_up` | Level increase | Character growth |
| `ui_achievement` | Achievement unlock | Trophy/award |

---

## Sound Variation Strategy

### Why Variations Matter

Repetitive identical sounds become annoying. Use variations for frequently heard sounds.

### Variation Counts

| Sound Type | Base Count | Variations | Total |
|------------|-----------|------------|-------|
| Button Click | 1 | 2-3 | 3-4 |
| Footstep | 1 | 5-7 | 6-8 |
| Weapon Swing | 1 | 3-4 | 4-5 |
| UI Hover | 1 | 1-2 | 2-3 |
| Collect Item | 1 | 2 | 3 |

### Randomization Parameters

```python
class UISoundPlayer:
    def __init__(self, sound_variations):
        self.variations = sound_variations
    
    def play(self, pitch_range=(-0.1, 0.1), volume_range=(-2, 0)):
        """Play with randomization"""
        sound = random.choice(self.variations)
        pitch = random.uniform(*pitch_range)
        volume = random.uniform(*volume_range)
        
        sound.play(pitch=pitch, volume_db=volume)
```

---

## UI Sound Design Principles

### 1. Consistency

- Same action = same sound category
- Maintain audio "language" across UI

### 2. Feedback Clarity

- Positive actions = ascending/bright sounds
- Negative actions = descending/dark sounds
- Neutral actions = neutral/mid sounds

### 3. Frequency Awareness

| Frequency | Use |
|-----------|-----|
| High (>2kHz) | Attention, alerts |
| Mid (500Hz-2kHz) | Standard feedback |
| Low (<500Hz) | Heavy, important |

### 4. Duration Guidelines

| Sound Type | Max Duration |
|------------|--------------|
| Hover | 0.1s |
| Click | 0.2s |
| Confirm | 0.5s |
| Alert | 1.0s |
| Achievement | 2.0s |

---

## Naming Convention

```
ui_{element}_{action}_{variant}

Examples:
ui_button_click_01.wav
ui_button_hover_soft.wav
ui_toggle_on.wav
ui_feedback_success_chime.wav
ui_nav_menu_open.wav
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  UI AUDIO TAXONOMY QUICK REFERENCE                     │
├────────────────────────────────────────────────────────┤
│  BUTTONS:                                              │
│  • hover, click, release                               │
│  TOGGLES:                                              │
│  • on, off, slide                                      │
│  NAVIGATION:                                           │
│  • open, close, tab, back, forward                     │
│  FEEDBACK:                                             │
│  • success, error, warning, notify                     │
│  INPUT:                                                │
│  • type, delete, submit                                │
│  INVENTORY:                                            │
│  • pickup, equip, use, drop, currency                  │
│  PROGRESS:                                             │
│  • start, tick, complete, level_up, achievement        │
├────────────────────────────────────────────────────────┤
│  NAMING: ui_{element}_{action}_{variant}               │
│  DURATION: 0.1s (hover) to 2.0s (achievement)          │
│  VARIATIONS: 2-4 for frequently heard sounds           │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[SFX_List_Generation]] - UI sounds in master list
- [[SFX_Generation_Routing]] - Generation method selection
- [[Audio_Format_Standards]] - File format requirements
- [[Audio_Validation_Gates]] - Quality checks
