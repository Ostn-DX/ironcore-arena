---
title: Voice TTS Routing
type: decision
layer: execution
status: active
tags:
  - audio
  - voice
  - tts
  - routing
  - generation
depends_on:
  - "[Audio_Pipeline_Overview]"
used_by:
  - "[Audio_Validation_Gates]"
---

# Voice TTS Routing

## Purpose

Define when and how to use text-to-speech (TTS) for game voice content, balancing quality, cost, and appropriateness.

---

## TTS Use Cases

### Appropriate Uses

| Use Case | Example | Priority |
|----------|---------|----------|
| UI Voice | "Health low", "Ammo depleted" | High |
| Navigation | "Turn left", "Objective updated" | Medium |
| Tutorial | "Press jump to climb" | Medium |
| Placeholder | Prototype dialogue | High |
| Accessibility | Screen reader content | High |
| NPC Barks | Background chatter | Low |
| Announcer | "Round start", "Victory" | Medium |

### Inappropriate Uses

| Use Case | Why Not | Alternative |
|----------|---------|-------------|
| Main character dialogue | Quality insufficient | Voice actor |
| Emotional story moments | TTS lacks emotion | Voice actor |
| Iconic character voices | Needs personality | Voice actor |
| Long narrative sequences | Listener fatigue | Voice actor |

---

## TTS Routing Decision Tree

```
Need voice audio?
│
├─▶ Is it for prototype/placeholder?
│   ├─▶ Yes → LOCAL TTS (fast, free)
│   └─▶ No → Continue
│
├─▶ Is it UI/functional only?
│   ├─▶ Yes → LOCAL TTS
│   └─▶ No → Continue
│
├─▶ Is emotion/nuance critical?
│   ├─▶ Yes → VOICE ACTOR
│   └─▶ No → Continue
│
├─▶ Is quality more important than cost?
│   ├─▶ Yes → PAID TTS API
│   └─▶ No → LOCAL TTS
│
└─▶ LOCAL TTS (default)
```

---

## TTS Options

### 1. Local TTS (Primary)

**Best For**: UI voices, prototypes, high volume

| Tool | Quality | Speed | Setup |
|------|---------|-------|-------|
| Coqui TTS | Good | Medium | Medium |
| Piper | Good | Fast | Easy |
| XTTS v2 | Very Good | Medium | Medium |
| MMS (Meta) | Medium | Fast | Easy |

#### Piper Setup (Recommended for UI)

```bash
# Install
pip install piper-tts

# Download voice
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx

# Generate
piper-tts --model en_US-lessac-medium.onnx --output_file output.wav "Health critical"
```

#### Coqui TTS Setup

```bash
# Install
pip install TTS

# Generate
python -c "from TTS.api import TTS; tts = TTS('tts_models/en/ljspeech/tacotron2-DDC'); tts.tts_to_file('Hello world', file_path='output.wav')"
```

#### XTTS v2 (Voice Cloning)

```python
from TTS.api import TTS

# Clone voice from sample
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")

tts.tts_to_file(
    text="Hello, I am your guide.",
    speaker_wav="reference_voice.wav",
    language="en",
    file_path="output.wav"
)
```

### 2. Paid TTS APIs (Selective)

**Best For**: High quality, specific needs

| Service | Cost | Quality | Best For |
|---------|------|---------|----------|
| ElevenLabs | $5-30/mo | Excellent | Character voices |
| Play.ht | $15-30/mo | Very Good | Narration |
| Azure TTS | Pay-per-use | Good | Enterprise |
| Google Cloud TTS | Pay-per-use | Good | Scale |

#### ElevenLabs Example

```python
from elevenlabs import generate, save

audio = generate(
    text="Welcome to the game.",
    voice="Bella",  # or custom voice ID
    model="eleven_monolingual_v1"
)

save(audio, "welcome.mp3")
```

### 3. Voice Actor (Quality Priority)

**Best For**: Main characters, story content

| Factor | Consideration |
|--------|---------------|
| Cost | $200-500/hour |
| Quality | Highest |
| Time | 1-2 weeks |
| Rights | Negotiate usage |

---

## Voice Selection Guidelines

### UI/Functional Voices

| Context | Voice Characteristics |
|---------|----------------------|
| Sci-Fi | Synthetic, processed |
| Fantasy | Natural, warm |
| Horror | Distorted, unsettling |
| Casual | Friendly, neutral |

### Character Voices

| Character Type | Voice Approach |
|----------------|----------------|
| Hero/Protagonist | Paid TTS or voice actor |
| NPC (minor) | Local TTS |
| NPC (major) | Paid TTS or voice actor |
| Enemy | Local TTS with effects |
| Announcer | Local TTS, clear and neutral |

---

## Voice Processing

### Common Effects

| Effect | Use Case | Tool |
|--------|----------|------|
| Pitch shift | Gender/age change | Audacity, SoX |
| Robot/Vocoder | Sci-fi characters | Vocoder plugins |
| Reverb | Distance/space | Reverb plugins |
| Distortion | Monsters/demons | Distortion plugins |
| Echo | Cave/space | Delay plugins |

### Batch Processing Script

```bash
#!/bin/bash
# Apply robot effect to all voice files

for file in voice_raw/*.wav; do
  sox "$file" "voice_processed/$(basename $file)" \
    pitch -300 \
    overdrive 10 \
    reverb 50 50 100 100 0 0
    
done
```

---

## Cost Comparison

| Method | Setup | Per Line | 1000 Lines | Quality |
|--------|-------|----------|------------|---------|
| Local TTS | $0-500 (GPU) | $0.001 | $1 | Medium-Good |
| Paid TTS | $0 | $0.01-0.05 | $10-50 | Very Good |
| Voice Actor | $0 | $2-5 | $2000-5000 | Excellent |

---

## File Specifications

| Setting | Value |
|---------|-------|
| Format | OGG Vorbis |
| Sample Rate | 44.1 kHz |
| Bitrate | 96-128 kbps |
| Channels | Mono (UI), Stereo (character) |
| Max Duration | 10 seconds (UI), 30 seconds (dialogue) |

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  VOICE TTS ROUTING QUICK REFERENCE                     │
├────────────────────────────────────────────────────────┤
│  DECISION ORDER:                                       │
│  1. Local TTS (default)                                │
│  2. Paid TTS (quality critical)                        │
│  3. Voice Actor (emotional/narrative)                  │
├────────────────────────────────────────────────────────┤
│  LOCAL TOOLS:                                          │
│  • Piper - Fast, lightweight, UI voices                │
│  • Coqui TTS - Good quality, customizable              │
│  • XTTS v2 - Voice cloning                             │
├────────────────────────────────────────────────────────┤
│  PAID TOOLS (selective):                               │
│  • ElevenLabs - Best quality, character voices         │
│  • Play.ht - Good narration                            │
├────────────────────────────────────────────────────────┤
│  FORMAT: OGG Vorbis, 44.1kHz, 96-128kbps, Mono         │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Voice in audio pipeline
- [[SFX_List_Generation]] - Voice lines in SFX list
- [[Audio_Format_Standards]] - File format requirements
- [[Audio_Validation_Gates]] - Quality checks
