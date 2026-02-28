---
title: SFX Generation Routing
type: decision
layer: execution
status: active
tags:
  - audio
  - sfx
  - generation
  - routing
  - tools
depends_on:
  - "[Audio_Pipeline_Overview]]"
  - "[[SFX_List_Generation]"
used_by:
  - "[Audio_Validation_Gates]"
---

# SFX Generation Routing

## Purpose

Route each SFX need to the most appropriate generation method—balancing quality, cost, and time.

---

## Routing Decision Tree

```
Need SFX?
│
├─▶ Check Asset Packs First
│   ├─▶ Pack exists and fits? → BUY PACK
│   └─▶ No suitable pack? → Continue
│
├─▶ Can Local Generation Work?
│   ├─▶ Sound is describable? → LOCAL AI
│   ├─▶ Sound needs synthesis? → PROCEDURAL
│   └─▶ Sound too specific? → Continue
│
├─▶ Is Quality Critical?
│   ├─▶ Yes (key sound, iconic) → PAID API
│   └─▶ No → LOCAL AI with more iterations
│
└─▶ MANUAL (last resort)
```

---

## Generation Methods

### 1. Asset Packs (First Choice)

**Best For**: Common sounds, complete sets

**Sources**:
| Source | Price Range | Strengths |
|--------|-------------|-----------|
| Unity Asset Store | $10-50 | Large selection, quality ratings |
| Epic Marketplace | $15-60 | High quality, engine integration |
| Pro Sound Effects | $50-200 | Professional, comprehensive |
| Sonniss | Free-$100 | Game-focused, good organization |

**When to Use**:
- UI sound packs
- Weapon sound libraries
- Ambient environment packs
- Footstep collections

**Example**:
```yaml
sfx: "sci-fi weapon sounds"
decision: "asset_pack"
pack: "Sci-Fi Weapons Pack Vol.1"
cost: $29.99
coverage: "95% of weapon needs"
```

### 2. Local AI Generation (Primary)

**Best For**: Custom sounds, specific descriptions

**Tools**:

| Tool | Setup | Quality | Speed |
|------|-------|---------|-------|
| AudioCraft (MusicGen) | Medium | Good | Fast |
| AudioLDM 2 | Medium | Very Good | Medium |
| Stable Audio Open | Easy | Good | Fast |

**AudioCraft Setup**:
```bash
pip install audiocraft
```

**Generation Example**:
```python
from audiocraft.models import AudioGen

model = AudioGen.get_pretrained('facebook/audiogen-medium')
model.set_generation_params(duration=2)

descriptions = [
    "sword swing whoosh",
    "metal sword clashing",
    "magic spell casting"
]

wav = model.generate(descriptions)
```

**When to Use**:
- Unique sound descriptions
- Prototyping
- Filling gaps in packs
- Custom character sounds

### 3. Procedural Generation

**Best For**: Retro sounds, simple waveforms

**Tools**:

| Tool | Best For | Output |
|------|----------|--------|
| SFXR | Retro 8-bit sounds | WAV |
| BFXR | Enhanced SFXR | WAV |
| LabChirp | Complex waveforms | WAV |
| ChipTone | Game-specific | WAV |

**When to Use**:
- Pixel art games
- Retro aesthetics
- Simple UI sounds
- Placeholder sounds

### 4. Paid API (Selective)

**Best For**: High-quality, specific sounds

**Services**:

| Service | Cost | Quality | Speed |
|---------|------|---------|-------|
| ElevenLabs Sound Effects | $0.10-0.30/sound | Excellent | Fast |
| Play.ht | $0.05-0.15/sound | Good | Fast |

**When to Use**:
- Key iconic sounds
- Rush deadlines
- Sounds local tools can't produce
- Marketing/promotional content

### 5. Manual Recording (Last Resort)

**Best For**: Unique sounds, foley

**When to Use**:
- Very specific real-world sounds
- Trademark sounds
- When budget allows for custom work

---

## Routing by SFX Type

| SFX Type | Primary | Secondary | Avoid |
|----------|---------|-----------|-------|
| UI Clicks | Asset Pack | Procedural (SFXR) | Paid API |
| UI Confirm | Asset Pack | Local AI | Manual |
| Footsteps | Asset Pack | Local AI | Paid API |
| Weapon Swing | Local AI | Asset Pack | Manual |
| Weapon Impact | Asset Pack | Local AI | Paid API |
| Magic Spells | Local AI | Asset Pack | Manual |
| Ambient Loops | Asset Pack | Local AI | Paid API |
| Character Voices | TTS Local | Voice Pack | Paid TTS |
| Explosions | Asset Pack | Local AI | Manual |
| Creature Sounds | Local AI | Asset Pack | Manual |

---

## Cost Comparison

| Method | Setup Cost | Per Sound | 100 Sounds | Quality |
|--------|-----------|-----------|------------|---------|
| Asset Pack | $0 | $0.10-0.50 | $10-50 | High |
| Local AI | $500-1500 (GPU) | $0.01 | $1 | Medium-High |
| Procedural | $0 | $0 | $0 | Low-Medium |
| Paid API | $0 | $0.10-0.30 | $10-30 | Very High |
| Manual | $0 | $50-200 | $5000-20000 | Highest |

---

## Batch Generation Workflow

### Local AI Batch Script

```python
import os
from audiocraft.models import AudioGen

def batch_generate_sfx(sfx_list, output_dir):
    """Generate SFX in batches"""
    
    model = AudioGen.get_pretrained('facebook/audiogen-medium')
    model.set_generation_params(duration=2)
    
    batch_size = 4  # Generate 4 at a time
    
    for i in range(0, len(sfx_list), batch_size):
        batch = sfx_list[i:i+batch_size]
        descriptions = [sfx['description'] for sfx in batch]
        
        print(f"Generating batch {i//batch_size + 1}/{(len(sfx_list)-1)//batch_size + 1}")
        wav = model.generate(descriptions)
        
        for j, sfx in enumerate(batch):
            output_path = os.path.join(output_dir, f"{sfx['id']}.wav")
            model.save_wav(wav[j], output_path)
            print(f"  Saved: {output_path}")

# Usage
sfx_list = [
    {'id': 'sword_swing_01', 'description': 'sword swing whoosh'},
    {'id': 'sword_impact_01', 'description': 'metal sword hitting armor'},
    # ... more SFX
]

batch_generate_sfx(sfx_list, 'output/sfx/')
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  SFX GENERATION ROUTING QUICK REFERENCE                │
├────────────────────────────────────────────────────────┤
│  DECISION ORDER:                                       │
│  1. Asset Pack → 2. Local AI → 3. Procedural          │
│  4. Paid API (selective) → 5. Manual (last resort)    │
├────────────────────────────────────────────────────────┤
│  LOCAL TOOLS:                                          │
│  • AudioCraft - General SFX                            │
│  • AudioLDM 2 - Specific sounds                        │
│  • SFXR/BFXR - Retro sounds                            │
├────────────────────────────────────────────────────────┤
│  PAID TOOLS (selective use):                           │
│  • ElevenLabs Sound Effects                            │
│  • Play.ht                                             │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Audio philosophy
- [[SFX_List_Generation]] - Input to routing
- [[Asset_Pack_First_Rule]] - Same principle for audio
- [[Audio_Validation_Gates]] - Post-generation checks
