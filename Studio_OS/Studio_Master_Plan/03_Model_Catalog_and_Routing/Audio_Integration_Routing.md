---
title: Audio Integration Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - audio
  - integration
  - sfx
  - music
  - voice
  - pipeline
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Audio_Generation_SFX]]"
  - "[[Audio_Generation_Music]]"
  - "[[Audio_Generation_Voice]"
used_by: []
---

# Audio Integration Routing

## Audio Pipeline Classification and Routing

Audio integration involves generating, processing, and integrating sound effects, music, and voice into the game. Routing depends on audio type, quality requirements, and production stage.

### Audio Type Classification

| Type | Description | Generation | Routing |
|------|-------------|------------|---------|
| SFX - UI | Clicks, beeps, notifications | Local/API | SFX Pipeline |
| SFX - Combat | Weapons, impacts, spells | Local/API | SFX Pipeline |
| SFX - Ambient | Environment, background | Local | SFX Pipeline |
| SFX - Creature | Vocals, footsteps | Local/API | SFX Pipeline |
| Music - Theme | Main themes, leitmotifs | Human/API | Music Pipeline |
| Music - Background | Ambient tracks | API/Local | Music Pipeline |
| Music - Stinger | Short cues | API | Music Pipeline |
| Voice - NPC | Dialogue, barks | TTS/Human | Voice Pipeline |
| Voice - Narration | Story, tutorial | TTS/Human | Voice Pipeline |

### Routing Decision Tree

```
Audio Request
│
├── Type = SFX - UI
│   └── Route: Local SFX Generation (AudioLDM)
│       └── Generate variations
│       └── Select best
│       └── Export to game format
│
├── Type = SFX - Combat
│   └── Route: Local + API (ElevenLabs)
│       └── Local: Generate base sounds
│       └── API: Polish critical sounds
│       └── Create variations
│
├── Type = SFX - Ambient
│   └── Route: Local SFX Generation
│       └── Generate loops
│       └── Ensure seamless looping
│       └── Layer if needed
│
├── Type = SFX - Creature
│   └── Route: Local + API
│       └── Local: Generate variations
│       └── API: Final polish
│       └── Create emotion variants
│
├── Type = Music - Theme (Main)
│   └── Route: Human Composer Recommended
│       └── AI for prototyping only
│       └── Human for production
│
├── Type = Music - Background
│   └── Route: API Music Generation (Suno/Udio)
│       └── Generate tracks
│       └── Create variations
│       └── Export loops
│
├── Type = Music - Stinger
│   └── Route: API Music Generation
│       └── Short generation
│       └── Quick iteration
│
├── Type = Voice - NPC (ambient)
│   └── Route: TTS API (ElevenLabs)
│       └── Generate dialogue
│       └── Review for pronunciation
│       └── Fix issues
│
├── Type = Voice - NPC (critical)
│   └── Route: Human Voice Actor
│       └── TTS for prototyping only
│
└── Type = Voice - Narration
    └── Route: TTS API
        └── Generate narration
        └── Review and fix
        └── Polish if needed
```

### Owner Agent: Audio Agent

The Audio Agent owns audio pipeline coordination.

**Responsibilities:**
- Classify audio type and requirements
- Select generation approach
- Coordinate with audio director
- Process generated audio
- Validate audio quality
- Integrate into game

### Permitted Models by Audio Type

| Audio Type | Primary | Polish | Human |
|------------|---------|--------|-------|
| SFX - UI | Local | Local | - |
| SFX - Combat | Local | API | - |
| SFX - Ambient | Local | Local | - |
| SFX - Creature | Local | API | - |
| Music - Theme | Human | Human | Required |
| Music - Background | API | API | Review |
| Music - Stinger | API | API | - |
| Voice - NPC (ambient) | TTS | TTS | - |
| Voice - NPC (critical) | Human | Human | Required |
| Voice - Narration | TTS | TTS | Review |

### Context Pack Contents

**SFX Generation:**
```yaml
context_pack:
  # SFX specification
  description: "Sword clash, metallic ring"
  category: "combat"
  duration: "0.5 seconds"
  intensity: "high"
  
  # Technical specs
  format: "WAV"
  sample_rate: 44100
  channels: 1  # mono
  
  # Game context
  trigger_event: "weapon_collision"
  variation_count: 3
```

**Music Generation:**
```yaml
context_pack:
  # Music specification
  genre: "orchestral"
  mood: "epic battle"
  tempo: "fast"
  duration: "3 minutes"
  
  # Technical specs
  format: "WAV"
  sample_rate: 48000
  channels: 2  # stereo
  
  # Game context
  usage: "boss_battle"
  loop_point: "auto"
  intensity_layers: 3
```

**Voice Generation:**
```yaml
context_pack:
  # Voice specification
  text: "Welcome to the village, traveler."
  character: "village_elder"
  emotion: "friendly"
  
  # Technical specs
  format: "WAV"
  sample_rate: 48000
  channels: 1  # mono
  
  # Voice settings
  voice_id: "character_voice_01"
  stability: 0.5
  clarity: 0.75
```

### Audio Processing Pipeline

```
1. Generate audio (local or API)
2. Review and select best
3. Process for game:
   a. Normalize levels
   b. Apply compression if needed
   c. Trim silence
   d. Create loops (music/ambient)
   e. Create variations
4. Export to game format
5. Validate in engine
6. Integrate into build
```

### Gates Required

**Pre-Generation Gates:**
1. **Audio Direction**: Style defined
2. **Technical Specs**: Format, sample rate specified
3. **Usage Defined**: How audio will be triggered

**Post-Generation Gates:**
1. **Quality Check**: Meets audio standards
2. **Technical Validation**: Correct format, levels
3. **Engine Test**: Works in game
4. **Performance Check**: Memory budget OK
5. **Audio Director Approval**: For key assets

### Quality Thresholds

| Audio Type | Min Quality | Review Required |
|------------|-------------|-----------------|
| SFX - UI | 7/10 | Automated |
| SFX - Combat | 8/10 | Spot-check |
| SFX - Ambient | 7/10 | Automated |
| Music - Theme | 9/10 | Audio director |
| Music - Background | 7/10 | Spot-check |
| Voice - NPC | 8/10 | Review |
| Voice - Narration | 9/10 | Audio director |

### Cost Estimates

| Audio Type | Generation | Processing | Total/Asset |
|------------|------------|------------|-------------|
| SFX - UI | $0.001 | $0 | $0.001 |
| SFX - Combat | $0.05 | $0 | $0.05 |
| SFX - Ambient | $0.01 | $0 | $0.01 |
| Music - Theme | $500-5000* | $0 | $500-5000 |
| Music - Background | $0.50 | $0 | $0.50 |
| Voice - NPC | $0.02 | $0 | $0.02 |
| Voice - Narration | $0.05 | $0 | $0.05 |

*Human composer cost

### Best Practices

1. Use local generation for SFX iteration
2. Reserve API for final SFX polish
3. Use human composers for main themes
4. Use TTS for prototyping voice
5. Normalize audio levels consistently
6. Test in-game with other audio
7. Monitor memory usage

### Audio Budget Management

```yaml
audio_budget:
  monthly_generation:
    local_sfx: unlimited
    api_sfx: $50
    api_music: $100
    tts_voice: $100
  
  per_asset_type:
    sfx: $0.01
    music_theme: $500*
    music_bg: $0.50
    voice: $0.02
```

*Human composer

### Integration

Uses:
- [[Audio_Generation_SFX]]: For sound effects
- [[Audio_Generation_Music]]: For music
- [[Audio_Generation_Voice]]: For voice
