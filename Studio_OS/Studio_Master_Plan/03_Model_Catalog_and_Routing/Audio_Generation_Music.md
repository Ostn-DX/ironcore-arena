---
title: Audio Generation (Music)
type: agent
layer: execution
status: active
tags:
  - audio
  - music
  - generation
  - soundtrack
  - bgm
  - local
  - api
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Audio_Generation_SFX]"
used_by:
  - "[Audio_Integration_Routing]"
---

# Audio Generation (Music)

## Model Class: Music Generation Tools

Music generation tools create background music, themes, and ambient soundtracks for games. This domain requires careful quality evaluation as generated music often lacks the emotional depth and structure of composed music.

### Supported Tools

| Tool | Type | Quality | Control | Cost |
|------|------|---------|---------|------|
| Suno | API | Good | Low | $10/mo subscription |
| Udio | API | Good | Low | Subscription |
| Stable Audio | API/Local | Good | Medium | API/credits |
| MusicGen | Local | Moderate | High | Hardware only |
| AudioCraft | Local | Moderate | High | Hardware only |
| AIVA | API | Good | Medium | Subscription |
| Human Composer | Manual | Excellent | Full | Project-based |

### Capability Profile

**Strengths:**
- Rapid prototyping of musical ideas
- Generate variations on themes
- Style-consistent music families
- No licensing for generated tracks
- Iterative refinement possible
- Cost-effective for indie budgets

**Weaknesses:**
- Limited structural complexity
- Emotional depth often lacking
- Repetition in longer tracks
- Limited control over specific sections
- Quality inconsistent across genres
- May lack memorable melodies
- Difficulty with interactive/adaptive music

### Optimal Use Cases

**Well-Suited for Generation:**
- Prototype music for early development
- Ambient background tracks
- Menu/lobby music
- Short jingles and stingers
- Placeholder music
- Variations on existing themes

**Better from Composers:**
- Main themes and leitmotifs
- Emotionally critical scenes
- Complex interactive music
- Memorable melodies
- Final production music

### Generation Approaches

**1. Text-to-Music**
```
Prompt: "Epic orchestral battle music, intense, 2 minutes"
Output: Full music track
```

**2. Style Reference**
```
Reference: "Hans Zimmer style, Dark Knight"
Variation: Similar mood, different melody
```

**3. Stem Generation**
```
Generate: Individual instrument layers
Combine: In audio middleware for interactivity
```

### Technical Specifications

**Output Formats:**
- Primary: 48kHz 24-bit WAV
- Compressed: 48kHz OGG Vorbis (quality 6)
- Loop-friendly: Marked loop points

**Generation Parameters:**
```yaml
music_generation:
  duration: 30-300  # seconds
  sample_rate: 48000
  bit_depth: 24
  channels: 2  # stereo
  
  # Musical parameters
  genre: "orchestral|electronic|ambient|rock|folk"
  mood: "epic|tense|peaceful|mysterious|triumphant"
  tempo: "slow|medium|fast|variable"
  structure: "loop|linear|layered"
  
  # Game-specific
  intensity_layers: 3  # for adaptive music
  loop_point: "auto|manual"
```

### Quality vs Cost Analysis

| Approach | Quality | Cost/Track | Best For |
|----------|---------|------------|----------|
| Human Composer | 10/10 | $500-5000 | Main themes |
| Suno/Udio | 7/10 | $0.50-2 | Prototypes |
| Stable Audio | 6/10 | $0.20-1 | Background |
| MusicGen | 5/10 | $0.05* | Placeholders |
| Stock Music | 6/10 | $20-100/license | Quick solutions |

*Hardware cost

### ROI Warning

**When Generation Makes Sense:**
- Budget < $5,000 for music
- Need 10+ tracks
- Prototype/early access phase
- Ambient/background focus
- Rapid iteration needed

**When Composers Are Better:**
- Budget > $10,000
- Strong audio brand identity
- Emotionally critical scenes
- Memorable themes required
- Complex interactive systems

### Integration Workflow

```
1. Define musical needs from design
2. Generate reference/prototype tracks
3. Review with audio director
4. Iterate on selected direction
5. Generate full track set
6. Create variations (intensity layers)
7. Export to game format
8. Implement in audio middleware
9. Test in-game with gameplay
```

### Prompt Engineering

**Effective Prompt Structure:**
```
[Genre], [Mood], [Instrumentation], [Context], [Duration]

Examples:
- "Orchestral, epic battle, full orchestra, boss fight, 3 minutes"
- "Electronic ambient, mysterious, synth pads, exploration, 5 minutes loop"
- "Folk acoustic, peaceful, guitar and flute, village theme, 2 minutes"
```

### Failure Patterns

1. **Repetitive Structure**: Loops too obviously
   - *Detection*: Listener notices repetition
   - *Remediation*: Generate longer, add variation

2. **Emotional Flatness**: Lacks impact
   - *Detection*: Playtest feedback
   - *Remediation*: Human composer for key tracks

3. **Wrong Energy**: Doesn't match gameplay
   - *Detection*: Audio-visual mismatch
   - *Remediation*: Adjust tempo/intensity in prompt

4. **Mix Issues**: Poor balance
   - *Detection*: Frequencies clash with SFX
   - *Remediation*: Generate stems, remix

### Best Practices

1. Use generation for prototyping, not final
2. Generate multiple options per track
3. Test in-game, not just isolated
4. Create intensity variations for adaptive music
5. Maintain consistent style across tracks
6. Document generation parameters
7. Plan for human composer upgrade path

### Cost Governance

**Monthly Budget Tiers:**
- Indie: $50-100 (mostly local + limited API)
- Small Studio: $200-500 (API + some composer)
- Mid Studio: $1000-5000 (hybrid approach)
- AAA: $10000+ (composer-led)

### Integration

Used primarily by:
- [[Audio_Integration_Routing]]: Music pipeline
