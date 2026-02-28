---
title: Audio Pipeline Overview
type: pipeline
layer: architecture
status: active
tags:
  - audio
  - pipeline
  - automation
  - overview
  - philosophy
depends_on: []
used_by:
  - "[SFX_List_Generation]]"
  - "[[SFX_Generation_Routing]]"
  - "[[Music_Direction_Spec]]"
  - "[[Voice_TTS_Routing]"
---

# Audio Pipeline Overview

## Philosophy: Sound is Half the Experience

Audio in games is often underestimated but critically important. The AI-Native Game Studio audio pipeline treats sound design as a systematic, automatable process—generating SFX, music, and voice with minimal human intervention while maintaining quality.

---

## Core Principles

### 1. Procedural Over Bespoke

**Prefer procedural/generative audio when possible:**
- Footsteps from material samples + randomization
- Ambient soundscapes from layered loops
- Dynamic music systems over static tracks

**Why**: More variation, smaller file sizes, easier iteration

### 2. Asset Pack Priority

**Same rule as art**: Check asset packs before generation
- SFX packs are abundant and affordable
- Music packs cover many genres
- Voice packs exist for common needs

### 3. Local Generation First

**Primary tools run locally:**
- AudioLDM / AudioCraft for SFX
- Stable Audio / MusicGen for music
- Coqui TTS / Piper for voice

**Benefits**: No API costs, no rate limits, full control

### 4. Batch Generation

**Generate in categories, not individually:**
- All UI sounds in one batch
- All weapon sounds in one batch
- All ambient loops in one batch

---

## Audio Categories

| Category | Generation Method | Priority |
|----------|------------------|----------|
| **SFX** | | |
| UI Sounds | Local generation / Asset packs | High |
| Weapon Sounds | Local generation | High |
| Ambient Loops | Asset packs / Local generation | Medium |
| Character Sounds | Local generation | Medium |
| **Music** | | |
| Background Music | MusicGen / Asset packs | High |
| Battle Music | MusicGen / Asset packs | Medium |
| Menu Music | Asset packs | Low |
| **Voice** | | |
| UI Voice | TTS (local) | Medium |
| Character Voice | TTS (local) / Voice packs | Low |
| Narration | TTS (paid if quality critical) | Low |

---

## Pipeline Stages

```
Design Intent → Audio List → Source Selection → Generate/Buy → 
Validate → Mix → Implement → Test
```

| Stage | Automation | Human Role |
|-------|-----------|------------|
| Design Intent | Template-driven | Fill form |
| Audio List | Auto-generate from design doc | Review/approve |
| Source Selection | Rule-based routing | Override if needed |
| Generate/Buy | Automated execution | Monitor |
| Validate | Automated checks | Review failures |
| Mix | Template-based mixing | Fine-tune key sounds |
| Implement | Scripted integration | Verify in-engine |
| Test | Automated + playtest | Report issues |

---

## Tool Stack

### SFX Generation

| Tool | Type | Best For |
|------|------|----------|
| AudioCraft (local) | AI Generation | General SFX, ambient |
| AudioLDM 2 (local) | AI Generation | Specific sound effects |
| ElevenLabs Sound Effects | Paid API | High-quality specific sounds |
| SFXR / BFXR | Procedural | Retro game sounds |

### Music Generation

| Tool | Type | Best For |
|------|------|----------|
| MusicGen (local) | AI Generation | Background music |
| Stable Audio (local) | AI Generation | Longer tracks, ambient |
| Suno / Udio | Paid API | High-quality vocals |
| Asset packs | Pre-made | Proven, consistent |

### Voice Generation

| Tool | Type | Best For |
|------|------|----------|
| Coqui TTS (local) | AI TTS | Character voices |
| Piper (local) | AI TTS | Fast, lightweight |
| ElevenLabs | Paid API | High-quality, emotional |
| XTTS v2 (local) | Voice Clone | Custom character voices |

### Audio Processing

| Tool | Purpose |
|------|---------|
| Audacity | Editing, basic processing |
| Reaper | Advanced mixing |
| FFmpeg | Batch conversion |
| Wwise / FMOD | Middleware integration |

---

## Cost Model

| Approach | Cost per 100 SFX | Cost per 10 min Music | Cost per 1000 Voice Lines |
|----------|-----------------|----------------------|---------------------------|
| Local Generation | $1-2 (electricity) | $2-5 | $1-2 |
| Asset Packs | $10-50 | $20-100 | $50-200 |
| Paid APIs | $20-50 | $50-200 | $50-150 |
| Manual Creation | $500-2000 | $1000-5000 | $2000-10000 |

**Decision Rule**: Asset Pack → Local Generation → Paid API → Manual

---

## File Size Budgets

| Category | Target Size | Compression |
|----------|-------------|-------------|
| UI SFX | < 50 KB each | OGG Vorbis |
| Weapon SFX | < 200 KB each | OGG Vorbis |
| Ambient Loops | < 2 MB each | OGG Vorbis |
| Music Tracks | < 5 MB each | OGG Vorbis |
| Voice Lines | < 100 KB each | OGG Vorbis |

**Total Audio Budget**: < 100 MB for mobile, < 500 MB for PC/console

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| SFX Coverage | 100% of design doc | Items with audio / total |
| Generation Rate | >20 SFX/hour | Local generation speed |
| Integration Time | <10 min per batch | From generation to in-engine |
| File Size | Within budget | Total audio size |
| Bug Rate | <5% | Audio-related bugs / total |

---

## Anti-Patterns

❌ Generating music when asset packs exist
❌ Using uncompressed WAV for everything
❌ No audio mixing - all sounds at 100%
❌ Missing UI feedback sounds
❌ Music that doesn't loop seamlessly
❌ Voice lines without subtitle support

---

## Related Systems

- [[SFX_List_Generation]] - From design to audio list
- [[SFX_Generation_Routing]] - Tool selection for SFX
- [[Music_Direction_Spec]] - Music generation parameters
- [[Voice_TTS_Routing]] - Voice generation decisions
- [[Audio_Format_Standards]] - File format requirements
- [[Audio_Validation_Gates]] - Quality checks
