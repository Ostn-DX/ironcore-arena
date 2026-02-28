---
title: Music Direction Spec
type: template
layer: design
status: active
tags:
  - audio
  - music
  - direction
  - generation
  - spec
depends_on:
  - "[Audio_Pipeline_Overview]"
used_by:
  - "[SFX_Generation_Routing]"
---

# Music Direction Spec

## Purpose

Standardized specification for music generation that ensures consistent style, mood, and technical quality across all game music.

---

## Music Categories

### 1. Background Music (BGM)

**Purpose**: Establish atmosphere, support gameplay without distraction

| Type | Energy | Loop | Duration |
|------|--------|------|----------|
| Exploration | Low-Medium | Yes | 2-4 min |
| Town/Hub | Low | Yes | 3-5 min |
| Dungeon | Medium | Yes | 2-4 min |
| Boss | High | Yes | 2-3 min |

### 2. Combat Music

**Purpose**: Increase tension, signal danger

| Type | Energy | Loop | Duration |
|------|--------|------|----------|
| Minor Combat | Medium-High | Yes | 1-2 min |
| Major Combat | High | Yes | 2-3 min |
| Boss Battle | Very High | Yes | 3-5 min |
| Victory | High | No | 0:30-1:00 |

### 3. Menu/UI Music

**Purpose**: Set tone, fill silence

| Type | Energy | Loop | Duration |
|------|--------|------|----------|
| Main Menu | Low-Medium | Yes | 2-3 min |
| Pause Menu | Low | Yes | 1-2 min |
| Credits | Medium | No | 3-5 min |

---

## Music Spec Template

```yaml
music_spec:
  track_id: "bgm_forest_exploration"
  name: "Forest Exploration"
  
  category: "background"
  context: "Player exploring forest areas"
  
  mood:
    primary: "peaceful"
    secondary: "mysterious"
    intensity: 3  # 1-10 scale
  
  style:
    genre: "orchestral"
    instrumentation: ["strings", "flute", "harp", "soft percussion"]
    tempo: "moderate"  # slow, moderate, fast
    key: "major"  # major, minor, atonal
  
  technical:
    duration: "3:00"
    loop_point: "0:00"  # Seamless loop start
    bpm: 90
    time_signature: "4/4"
  
  references:
    - "Zelda: Breath of the Wild - Forest"
    - "Ori and the Blind Forest - Main Theme"
  
  generation:
    method: "MusicGen"  # or "asset_pack", "commission"
    prompt: "peaceful orchestral forest exploration music, strings and flute, moderate tempo, major key, game soundtrack"
    negative_prompt: "vocals, heavy percussion, dissonant, jarring"
```

---

## Generation Methods

### 1. Asset Packs (Recommended for Consistency)

**Best For**: Complete soundtracks, proven quality

**Sources**:
| Source | Price | License |
|--------|-------|---------|
| Unity Asset Store | $15-50 | Game license |
| PremiumBeat | $40-200/track | Various |
| Epidemic Sound | Subscription | Game license |
| Artlist | Subscription | Game license |

### 2. Local AI Generation (MusicGen)

**Best For**: Custom music, prototyping

**Setup**:
```bash
pip install audiocraft
```

**Generation**:
```python
from audiocraft.models import MusicGen

model = MusicGen.get_pretrained('facebook/musicgen-medium')
model.set_generation_params(duration=30)  # seconds

descriptions = [
    "peaceful orchestral forest music, strings and flute, 90bpm, game soundtrack"
]

wav = model.generate(descriptions)
```

**Pros**:
- Free after setup
- Customizable
- Fast iteration

**Cons**:
- Quality varies
- May need editing
- Limited control over structure

### 3. Stable Audio

**Best For**: Longer tracks, ambient music

**Setup**:
```bash
pip install stable-audio-tools
```

**Pros**:
- Longer generation (up to 95s)
- Good for ambient
- Local execution

### 4. Paid Services (Selective)

**Best For**: High-quality, specific needs

| Service | Cost | Best For |
|---------|------|----------|
| Suno | $10-30/mo | Full songs with vocals |
| Udio | $10-30/mo | High-quality instrumentals |
| AIVA | Subscription | Classical/orchestral |

---

## Prompt Engineering for Music

### Structure

```
[GENRE] + [INSTRUMENTATION] + [MOOD] + [TEMPO] + [CONTEXT] + [STYLE REFERENCE]
```

### Examples

| Track Type | Prompt |
|------------|--------|
| Forest BGM | "peaceful orchestral fantasy music, strings and woodwinds, mysterious and calm, moderate tempo, game exploration soundtrack, zelda style" |
| Battle | "intense orchestral battle music, heavy brass and percussion, epic and urgent, fast tempo, boss fight music, dark souls style" |
| Town | "cheerful medieval town music, lute and flute, warm and welcoming, moderate tempo, rpg village music, skyrim style" |
| Menu | "ambient electronic menu music, synthesizers and pads, calm and atmospheric, slow tempo, sci-fi game menu, deus ex style" |

### Negative Prompts

```
vocals, lyrics, jarring transitions, abrupt endings, 
off-key notes, clipping, distortion, 
inappropriate mood (happy for dark scene)
```

---

## Looping Requirements

### Seamless Loop Checklist

- [ ] Start and end at same volume level
- [ ] No reverb tail at end (or tail continues seamlessly)
- [ ] Consistent tempo throughout
- [ ] No key changes at loop point
- [ ] Crossfade compatible (if needed)

### Loop Point Detection

```python
import librosa
import numpy as np

def find_loop_points(audio_path):
    """Find potential seamless loop points"""
    y, sr = librosa.load(audio_path)
    
    # Find zero crossings
    zero_crossings = librosa.zero_crossings(y)
    
    # Find similar segments
    # (Simplified - real implementation would use correlation)
    
    return loop_points
```

---

## Technical Specifications

### Format Requirements

| Setting | Value | Reason |
|---------|-------|--------|
| Format | OGG Vorbis | Good compression, quality |
| Sample Rate | 44.1 kHz | CD quality standard |
| Bitrate | 128-192 kbps | Balance quality/size |
| Channels | Stereo | Spatial audio |

### File Size Targets

| Track Type | Target Size | Max Size |
|------------|-------------|----------|
| Short Loop (1-2 min) | 1-2 MB | 3 MB |
| Medium Loop (2-4 min) | 2-4 MB | 6 MB |
| Long Track (4-5 min) | 4-6 MB | 10 MB |

---

## Dynamic Music Systems

### Horizontal Resequencing

**Concept**: Switch between different versions of same track

```
Base Track (exploration)
    ↓
Combat Layer (adds percussion)
    ↓
Intensity Layer (adds brass)
```

### Vertical Remixing

**Concept**: Mix layers in real-time

```
Layer 1: Base melody (always on)
Layer 2: Percussion (combat only)
Layer 3: Intensity (boss only)
```

### Stem Export

For dynamic systems, export separate stems:

```
track_forest_base.ogg
track_forest_percussion.ogg
track_forest_brass.ogg
track_forest_strings.ogg
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  MUSIC DIRECTION QUICK REFERENCE                       │
├────────────────────────────────────────────────────────┤
│  CATEGORIES:                                           │
│  • Background (exploration, town, dungeon)             │
│  • Combat (minor, major, boss, victory)                │
│  • Menu (main, pause, credits)                         │
├────────────────────────────────────────────────────────┤
│  GENERATION METHODS:                                   │
│  1. Asset Packs (recommended for consistency)          │
│  2. MusicGen (local, customizable)                     │
│  3. Stable Audio (longer tracks)                       │
│  4. Paid (Suno/Udio for high quality)                  │
├────────────────────────────────────────────────────────┤
│  FORMAT: OGG Vorbis, 44.1kHz, 128-192kbps              │
│  LOOP: Must be seamless                                │
│  SIZE: 1-6 MB per track                                │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Music in audio pipeline
- [[SFX_Generation_Routing]] - Similar routing decisions
- [[Audio_Format_Standards]] - File format requirements
- [[Audio_Validation_Gates]] - Quality checks
