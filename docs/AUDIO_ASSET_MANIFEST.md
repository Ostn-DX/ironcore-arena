# Ironcore Arena - Audio Asset Manifest
## Placeholder Sound Effects for MVP Testing

---

## SOUND EFFECTS NEEDED

### Weapon Sounds
| File | Trigger | Description |
|------|---------|-------------|
| `sfx_shoot_laser.wav` | Laser fired | Short high-pitch zap |
| `sfx_shoot_machinegun.wav` | MG fired | Rapid low thud |
| `sfx_shoot_cannon.wav` | Cannon fired | Deep boom |
| `sfx_shoot_rocket.wav` | Rocket fired | Whoosh + trail |
| `sfx_shoot_plasma.wav` | Plasma fired | Electric hum burst |

### Impact Sounds
| File | Trigger | Description |
|------|---------|-------------|
| `sfx_hit_armor.wav` | Bullet hits armor | Metallic clank |
| `sfx_hit_shield.wav` | Shield absorbs | Energy hum |
| `sfx_hit_chassis.wav` | Chassis damaged | Crunch |
| `sfx_explosion_small.wav` | Bot destroyed | Pop + debris |
| `sfx_explosion_large.wav` | Arena hazard | Big boom |

### UI Sounds
| File | Trigger | Description |
|------|---------|-------------|
| `sfx_ui_click.wav` | Button click | Short blip |
| `sfx_ui_hover.wav` | Button hover | Subtle tick |
| `sfx_ui_back.wav` | Go back | Descending tone |
| `sfx_ui_error.wav` | Invalid action | Buzz |
| `sfx_ui_confirm.wav` | Action confirmed | Bright ding |

### Game Sounds
| File | Trigger | Description |
|------|---------|-------------|
| `sfx_battle_start.wav` | Battle begins | Dramatic sting |
| `sfx_battle_win.wav` | Victory | Triumphant fanfare |
| `sfx_battle_loss.wav` | Defeat | Sad descent |
| `sfx_credits_gain.wav` | Credits received | Coin jingle |
| `sfx_part_unlock.wav` | New part unlocked | Success chime |
| `sfx_repair.wav` | Bot repairing | Mechanical whir |
| `sfx_boost.wav` | Speed boost | Power up |

---

## MUSIC TRACKS

### Combat Music
| File | BPM | Description |
|------|-----|-------------|
| `music_battle_01.ogg` | 140 | Fast-paced electronic |
| `music_battle_02.ogg` | 120 | Medium intensity |
| `music_boss.ogg` | 160 | High intensity |

### Menu Music
| File | BPM | Description |
|------|-----|-------------|
| `music_menu.ogg` | 90 | Ambient atmospheric |
| `music_build.ogg` | 100 | Industrial rhythmic |
| `music_victory.ogg` | 120 | Triumphant |

---

## IMPLEMENTATION STATUS

### ✅ Placeholder Strategy
For MVP testing, we'll use:
1. **Synthesized beeps** for UI sounds (can generate programmatically)
2. **Empty/short files** for combat sounds (visuals first)
3. **Looping ambient** for music (1-2 tracks max)

### 🔄 Generation Plan
Using simple synthesis:
- Sine waves for UI
- Saw waves for weapons
- Noise bursts for explosions
- Simple loops for music

**Total needed: ~25 sound files**

---

*Document Version: 1.0*
*Audio to be generated or sourced for Beta*
