---
title: Audio_Taxonomy_and_Generation
type: system
layer: design
status: planned
tags:
  - audio
  - taxonomy
  - generation
  - sfx
depends_on: []
used_by:
  - "[Batch_Generation_Workflow]"
---

# Audio Taxonomy and Generation

## Purpose
Organize audio needs and define generation strategy for sound effects and music.

## Audio Categories

### SFX Categories

| Code | Category | Examples | Count |
|------|----------|----------|-------|
| `wpn` | Weapons | Fire, reload, impact | 20 |
| `eng` | Engines | Idle, move, boost | 15 |
| `exp` | Explosions | Small, medium, large | 10 |
| `ui` | Interface | Click, hover, confirm | 15 |
| `env` | Environment | Ambient, hazard | 10 |
| `mus` | Music | Battle, menu, victory | 5 |

### Weapon SFX Breakdown
```
wpn_mg_fire      # Machine gun fire
wpn_mg_impact    # Machine gun impact
wpn_cannon_fire  # Cannon fire
wpn_cannon_impact # Cannon explosion
wpn_beam_fire    # Beam weapon loop
wpn_beam_impact  # Beam impact
```

## Generation Methods

### Method 1: Procedural (Current)
**Tools:** Godot AudioStreamGenerator
**Cost:** $0 (runtime generation)
**Quality:** Placeholder
**Use:** Development, testing

### Method 2: AI Generation
**Tools:** ElevenLabs, AudioLDM
**Cost:** $0.05-0.20 per SFX
**Quality:** Good
**Use:** Production SFX

### Method 3: Library
**Tools:** Epidemic Sound, Splice
**Cost:** $15-50/month subscription
**Quality:** Professional
**Use:** Music, premium SFX

## Prompt Structure (AI Generation)

### SFX Prompt
```
[Action] + [Source] + [Characteristics] + [Duration]

Example:
"Machine gun rapid fire, mechanical action with metallic 
ring, 0.5 seconds, sharp attack, quick decay"
```

### Music Prompt
```
[Genre] + [Mood] + [Instrumentation] + [Tempo] + [Structure]

Example:
"Electronic industrial battle music, aggressive and driving, 
synthesizers and drums, 140 BPM, looping 60 seconds"
```

## File Organization

```
audio/
├── sfx/
│   ├── wpn/
│   │   ├── wpn_mg_fire.wav
│   │   └── wpn_cannon_fire.wav
│   ├── eng/
│   ├── exp/
│   └── ui/
├── music/
│   ├── mus_battle_loop.ogg
│   ├── mus_menu_loop.ogg
│   └── mus_victory.ogg
└── ambient/
    └── env_arena_hum.ogg
```

## Format Standards

| Type | Format | Sample Rate | Compression |
|------|--------|-------------|-------------|
| SFX | WAV | 44.1kHz | Uncompressed |
| Music | OGG | 44.1kHz | Q5 |
| Ambient | OGG | 44.1kHz | Q3 |

## Generation Pipeline

```
Need Identification
       ↓
Prompt Creation
       ↓
AI Generation
       ↓
Format Conversion
       ↓
Volume Normalization
       ↓
In-Game Testing
       ↓
Approval / Reject
```

## Cost Estimation

| Phase | Method | Cost | Timeline |
|-------|--------|------|----------|
| Prototype | Procedural | $0 | Now |
| Alpha | AI Generation | $50-100 | Week 2 |
| Beta | Mixed | $100-200 | Month 2 |
| Release | Professional | $500-1000 | Month 4 |

## Related
[[Batch_Generation_Workflow]]
[[Asset_Validation_Gates]]
