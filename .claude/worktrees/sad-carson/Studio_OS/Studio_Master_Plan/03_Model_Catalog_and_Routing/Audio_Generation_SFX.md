---
title: Audio Generation (SFX)
type: agent
layer: execution
status: active
tags:
  - audio
  - sfx
  - sound
  - effects
  - generation
  - local
  - api
depends_on:
  - "[Model_Catalog_Overview]"
used_by:
  - "[Audio_Integration_Routing]"
---

# Audio Generation (SFX)

## Model Class: Sound Effect Generation Tools

SFX generation tools create game audio effects from text descriptions or reference sounds. These range from local lightweight models to API-based professional services, each with different quality, latency, and cost profiles.

### Supported Tools

| Tool | Type | Quality | Latency | Cost |
|------|------|---------|---------|------|
| ElevenLabs SFX | API | Excellent | 2-5s | $0.10-0.50/sound |
| AudioLDM 2 | Local | Good | 10-30s | $0 (hardware) |
| Stable Audio Open | Local | Good | 15-45s | $0 (hardware) |
| Freesound API | Library | Variable | 1s | Free with attribution |
| SFXR/BFXR | Procedural | Retro | Instant | Free |
| Meta's AudioGen | API/Local | Good | 5-15s | API dependent |

### Capability Profile

**Strengths:**
- Generate unique sounds from descriptions
- Style-consistent sound families
- Rapid iteration on sound design
- No licensing concerns for generated audio
- Can match visual events precisely
- Easy variation generation

**Weaknesses:**
- Quality varies by model
- May require multiple attempts
- Limited control over exact parameters
- Complex layered sounds challenging
- Real-time generation often impractical
- Some sounds still better from libraries

### Optimal Sound Types

**Well-Suited for Generation:**
- UI sounds (clicks, beeps, notifications)
- Ambient backgrounds (wind, rain, machinery)
- Magical effects (spells, power-ups)
- Sci-fi sounds (lasers, engines, beeps)
- Creature vocals (roars, chirps)
- Impact sounds (variations)

**Better from Libraries:**
- Realistic instruments
- Human speech
- Complex environmental scenes
- Licensed brand sounds
- Highly specific real-world sounds

### Generation Approaches

**1. Text-to-SFX (Primary)**
```
Prompt: "Futuristic laser gun shot, high-pitched, sci-fi"
Output: 2-second WAV file
```

**2. Reference-Based**
```
Input: Reference sound + variation prompt
Output: Similar sound with variation
```

**3. Parameter-Based (Procedural)**
```
Parameters: wave type, attack, decay, pitch sweep
Output: Retro game sound
```

### Technical Specifications

**Output Formats:**
- Primary: 44.1kHz 16-bit WAV
- Compressed: 48kHz OGG Vorbis
- Loop-friendly: Seamless loop points

**Generation Parameters:**
```yaml
sfx_generation:
  duration: 0.5-10.0  # seconds
  sample_rate: 44100
  bit_depth: 16
  channels: 1  # mono for SFX
  
  # Style parameters
  category: "ui|combat|ambient|magic|sci-fi"
  intensity: "low|medium|high"
  variation_count: 3  # for randomization
```

### Local vs API Decision Matrix

| Factor | Local | API |
|--------|-------|-----|
| Quality | Good | Excellent |
| Latency | 10-45s | 2-5s |
| Cost | Hardware only | Per-generation |
| Privacy | Full | Limited |
| Control | High | Medium |
| Volume | Unlimited | Rate limited |

### Cost Profile

| Approach | Cost/Sound | Monthly (100 sounds) |
|----------|------------|---------------------|
| Local (AudioLDM) | $0.02* | $2 |
| ElevenLabs API | $0.20 | $20 |
| Freesound | $0 | $0 |
| Hybrid | $0.05 | $5 |

*Electricity + hardware amortization

### Quality Benchmarks

| Model | UI Sounds | Ambient | Combat | Magic | Sci-Fi |
|-------|-----------|---------|--------|-------|--------|
| ElevenLabs | 9/10 | 8/10 | 8/10 | 9/10 | 9/10 |
| AudioLDM 2 | 7/10 | 7/10 | 6/10 | 7/10 | 7/10 |
| Stable Audio | 7/10 | 8/10 | 6/10 | 7/10 | 8/10 |
| SFXR | 6/10 | 3/10 | 5/10 | 4/10 | 6/10 |

### Integration Workflow

```
1. Identify SFX need from design doc
2. Generate description from context
3. Select generation approach (local/API)
4. Generate with variations
5. Review and select
6. Export to game format
7. Integrate into audio system
8. Test in-game
```

### Prompt Engineering

**Effective Prompt Structure:**
```
[Sound Type], [Quality], [Context], [Duration]

Examples:
- "Sword clash, metallic ring, combat, 0.5 seconds"
- "Magic heal spell, ethereal chime, fantasy, 2 seconds"
- "UI button click, subtle, interface, 0.1 seconds"
```

### Failure Patterns

1. **Muddy Output**: Unclear sound definition
   - *Detection*: Lacks clarity, multiple overlapping
   - *Remediation*: Simplify prompt, reduce duration

2. **Wrong Category**: Sound doesn't match context
   - *Detection*: Visual-audio mismatch
   - *Remediation*: Add context to prompt

3. **Quality Inconsistency**: Batch quality varies
   - *Detection*: Some outputs poor
   - *Remediation*: Generate extras, curate best

4. **Timing Issues**: Wrong duration for game event
   - *Detection*: Audio-visual sync off
   - *Remediation*: Regenerate with exact duration

### Best Practices

1. Generate 3-5 variations per sound
2. Use consistent prompt patterns
3. Maintain SFX naming conventions
4. Test in-game, not just isolated
5. Version control generated assets
6. Document generation parameters

### Integration

Used primarily by:
- [[Audio_Integration_Routing]]: SFX pipeline
