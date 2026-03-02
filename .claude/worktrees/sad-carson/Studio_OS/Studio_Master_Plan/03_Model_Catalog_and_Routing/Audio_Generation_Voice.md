---
title: Audio Generation (Voice)
type: agent
layer: execution
status: active
tags:
  - audio
  - voice
  - tts
  - narration
  - dialogue
  - local
  - api
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Audio_Generation_SFX]"
used_by:
  - "[Audio_Integration_Routing]"
---

# Audio Generation (Voice)

## Model Class: Text-to-Speech and Voice Generation Tools

Voice generation tools convert text to spoken dialogue for games. Modern TTS has reached near-human quality for many use cases, making it viable for indie and mid-tier productions.

### Supported Tools

| Tool | Type | Quality | Languages | Cost |
|------|------|---------|-----------|------|
| ElevenLabs | API | Excellent | 29+ | $5-330/mo |
| Play.ht | API | Excellent | 100+ | $30-99/mo |
| Azure TTS | API | Very Good | 75+ | Pay-per-use |
| Google Cloud TTS | API | Very Good | 40+ | Pay-per-use |
| Coqui TTS | Local | Good | 10+ | Hardware only |
| Piper | Local | Good | 20+ | Hardware only |
| XTTS | Local | Good | 17+ | Hardware only |

### Capability Profile

**Strengths:**
- Near-human quality for many voices
- Rapid iteration on dialogue
- Consistent voice across sessions
- Multiple languages and accents
- Voice cloning from samples
- Emotional expression control
- No actor scheduling needed

**Weaknesses:**
- Can sound synthetic in long passages
- Limited acting nuance
- Pronunciation issues with proper nouns
- Emotional range limited vs actors
- Voice cloning quality varies
- Some languages lower quality
- API costs scale with dialogue volume

### Optimal Use Cases

**Well-Suited for TTS:**
- Prototype/narrative testing
- System announcements
- NPC ambient dialogue
- Tutorial narration
- Placeholder dialogue
- Multi-language versions
- Games with high dialogue volume

**Better from Voice Actors:**
- Main character dialogue
- Emotionally critical scenes
- Cinematic moments
- Iconic character voices
- Complex acting requirements

### Generation Approaches

**1. Standard TTS**
```
Text: "Welcome to the village, traveler."
Voice: Pre-defined character voice
Output: WAV file
```

**2. Voice Cloning**
```
Samples: 1-5 minutes of actor voice
Text: New dialogue
Output: Cloned voice speaking new lines
```

**3. Emotional TTS**
```
Text: "We must retreat!"
Emotion: "urgent, fearful"
Output: Emotionally inflected speech
```

### Technical Specifications

**Output Formats:**
- Primary: 48kHz 24-bit WAV
- Compressed: 48kHz OGG Vorbis
- Streaming: Optimized for real-time

**Generation Parameters:**
```yaml
voice_generation:
  sample_rate: 48000
  bit_depth: 24
  channels: 1  # mono for dialogue
  
  # Voice parameters
  voice_id: "character_voice_01"
  stability: 0.5  # consistency vs variety
  clarity: 0.75   # articulation
  
  # Performance
  emotion: "neutral|happy|sad|angry|excited"
  speed: 1.0  # playback speed multiplier
  
  # Cloning (if applicable)
  clone_samples: 3  # minutes of reference
```

### Local vs API Decision Matrix

| Factor | Local | API |
|--------|-------|-----|
| Quality | Good | Excellent |
| Voice Variety | Limited | Extensive |
| Voice Cloning | Basic | Advanced |
| Languages | 10-20 | 40-100+ |
| Latency | 1-5s | 0.5-2s |
| Cost | Hardware | Per-character |
| Privacy | Full | Limited |

### Cost Profile

| Tool | Cost/1K chars | 10K lines* | Monthly |
|------|---------------|------------|---------|
| ElevenLabs | $0.10 | $100 | $100-330 |
| Azure TTS | $0.016 | $16 | $16+ |
| Google TTS | $0.016 | $16 | $16+ |
| Coqui (local) | $0.001** | $1 | $10 |
| Piper (local) | $0.001** | $1 | $10 |

*Average 100 chars/line
**Hardware cost

### Quality Benchmarks

| Tool | Naturalness | Clarity | Emotion | Acting |
|------|-------------|---------|---------|--------|
| ElevenLabs | 9/10 | 9/10 | 8/10 | 7/10 |
| Play.ht | 9/10 | 9/10 | 7/10 | 6/10 |
| Azure | 8/10 | 9/10 | 6/10 | 5/10 |
| Coqui | 7/10 | 8/10 | 5/10 | 4/10 |
| Piper | 6/10 | 8/10 | 4/10 | 3/10 |

### Integration Workflow

```
1. Write dialogue in script format
2. Tag lines with character voice IDs
3. Batch generate dialogue
4. Review for pronunciation issues
5. Fix proper nouns with phonetic hints
6. Re-generate failed lines
7. Export to game format
8. Implement in dialogue system
9. Test in-game with lip sync
```

### Prompt Engineering for TTS

**Text Preparation:**
```
# Use phonetic hints for proper nouns
"Welcome to {AY-ther-ee-uh}, the city of light."

# Use punctuation for pacing
"Wait... did you hear that?"

# Break long sentences
"This is the first part. This is the second part."
```

### Failure Patterns

1. **Pronunciation Errors**: Names/terms wrong
   - *Detection*: Review playback
   - *Remediation*: Phonetic spelling, custom pronunciation

2. **Inconsistent Voice**: Same character sounds different
   - *Detection*: Playback comparison
   - *Remediation*: Increase stability, regenerate

3. **Emotional Flatness**: Lacks appropriate emotion
   - *Detection*: Playtest feedback
   - *Remediation*: Use emotional TTS, adjust prompt

4. **Audio Artifacts**: Clicks, pops, distortion
   - *Detection*: Audio analysis
   - *Remediation*: Regenerate, check source text

### Best Practices

1. Create voice style guide per character
2. Batch generate for consistency
3. Review 100% of generated dialogue
4. Maintain pronunciation dictionary
5. Version control voice settings
6. Plan for actor replacement path
7. Test with lip sync early

### Cost Governance

**Budget Planning:**
- Calculate total character count
- Add 20% for regeneration
- Choose tier based on volume
- Monitor monthly usage
- Cache generated audio

### Integration

Used primarily by:
- [[Audio_Integration_Routing]]: Voice/dialogue pipeline
