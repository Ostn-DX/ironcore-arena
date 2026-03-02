---
title: Audio Format Standards
type: rule
layer: enforcement
status: active
tags:
  - audio
  - format
  - standards
  - wav
  - ogg
  - mp3
depends_on:
  - "[Audio_Pipeline_Overview]"
used_by:
  - "[Audio_Validation_Gates]"
---

# Audio Format Standards

## Purpose

Define audio file format requirements for each use case, ensuring optimal quality, file size, and engine compatibility.

---

## Format Comparison

| Format | Compression | Quality | Size | Loop | Use Case |
|--------|-------------|---------|------|------|----------|
| WAV | None | Lossless | Large | Yes | Source, short SFX |
| OGG | Lossy | Good | Small | Yes | **Default for game** |
| MP3 | Lossy | Good | Small | No* | Music (non-looping) |
| FLAC | Lossless | Lossless | Medium | Yes | Archive, source |
| AAC | Lossy | Very Good | Small | No* | iOS preference |

*MP3 and AAC have padding that prevents seamless looping

---

## Format by Asset Type

### SFX (Sound Effects)

**Primary Format**: OGG Vorbis

```yaml
sfx_format:
  format: "OGG Vorbis"
  sample_rate: 44100  # Hz
  channels: 1  # Mono for positional audio
  quality: 0.6  # Vorbis quality (0-1)
  
  # Size targets
  ui_sfx: "< 50 KB"
  weapon_sfx: "< 200 KB"
  ambient_loops: "< 2 MB"
```

**Why OGG for SFX**:
- ✅ Small file size
- ✅ Seamless looping
- ✅ Good quality at low bitrates
- ✅ Patent-free
- ✅ Universal engine support

### Music

**Primary Format**: OGG Vorbis

```yaml
music_format:
  format: "OGG Vorbis"
  sample_rate: 44100
  channels: 2  # Stereo
  bitrate: "128-192 kbps"
  
  # Size targets
  short_loop: "1-2 MB"
  medium_loop: "2-4 MB"
  long_track: "4-6 MB"
```

**Why OGG for Music**:
- ✅ Seamless looping (critical for game music)
- ✅ Good compression
- ✅ No licensing fees

**Exception**: Use MP3 for non-looping tracks (credits, intro)

### Voice

**Primary Format**: OGG Vorbis

```yaml
voice_format:
  format: "OGG Vorbis"
  sample_rate: 44100
  channels: 1  # Mono for UI, Stereo for cinematic
  bitrate: "96-128 kbps"
  
  # Size targets
  ui_voice: "< 100 KB"
  dialogue_line: "< 500 KB"
```

---

## Conversion Pipeline

### Source → Game-Ready

```
Source (WAV/FLAC) → Process → Export → OGG
```

### Batch Conversion Script

```bash
#!/bin/bash
# Convert all WAV to OGG with appropriate settings

# SFX (mono, lower quality)
for file in sfx_source/*.wav; do
  ffmpeg -i "$file" \
    -ac 1 \
    -ar 44100 \
    -q:a 4 \
    "sfx/$(basename "$file" .wav).ogg"
done

# Music (stereo, higher quality)
for file in music_source/*.wav; do
  ffmpeg -i "$file" \
    -ac 2 \
    -ar 44100 \
    -q:a 6 \
    "music/$(basename "$file" .wav).ogg"
done

# Voice (mono, medium quality)
for file in voice_source/*.wav; do
  ffmpeg -i "$file" \
    -ac 1 \
    -ar 44100 \
    -q:a 5 \
    "voice/$(basename "$file" .wav).ogg"
done
```

### Python Batch Converter

```python
import os
import subprocess

def convert_to_ogg(input_path, output_path, category='sfx'):
    """Convert audio to OGG with category-appropriate settings"""
    
    settings = {
        'sfx': {'channels': 1, 'quality': 4},
        'music': {'channels': 2, 'quality': 6},
        'voice': {'channels': 1, 'quality': 5},
    }
    
    config = settings.get(category, settings['sfx'])
    
    cmd = [
        'ffmpeg',
        '-i', input_path,
        '-ac', str(config['channels']),
        '-ar', '44100',
        '-q:a', str(config['quality']),
        '-y',  # Overwrite output
        output_path
    ]
    
    subprocess.run(cmd, check=True)
    print(f"Converted: {input_path} -> {output_path}")

# Batch convert
def batch_convert(source_dir, output_dir, category):
    os.makedirs(output_dir, exist_ok=True)
    
    for filename in os.listdir(source_dir):
        if filename.endswith('.wav'):
            input_path = os.path.join(source_dir, filename)
            output_path = os.path.join(
                output_dir, 
                filename.replace('.wav', '.ogg')
            )
            convert_to_ogg(input_path, output_path, category)

# Usage
batch_convert('sfx_source/', 'sfx/', 'sfx')
batch_convert('music_source/', 'music/', 'music')
batch_convert('voice_source/', 'voice/', 'voice')
```

---

## Quality Settings

### Vorbis Quality Levels

| Quality | Bitrate (mono) | Bitrate (stereo) | Use Case |
|---------|---------------|------------------|----------|
| -1 | 45 kbps | 64 kbps | Placeholder |
| 0 | 64 kbps | 96 kbps | Low quality |
| 4 | 128 kbps | 160 kbps | SFX, voice |
| 6 | 192 kbps | 256 kbps | Music |
| 10 | 500 kbps | 500 kbps | Archive |

### Recommended by Category

| Category | Quality | Approx Bitrate |
|----------|---------|----------------|
| UI SFX | 4 | 128 kbps mono |
| Weapon SFX | 5 | 160 kbps mono |
| Ambient | 5 | 160 kbps stereo |
| Music | 6 | 256 kbps stereo |
| Voice | 4-5 | 128-160 kbps mono |

---

## Platform Considerations

### Mobile

| Consideration | Recommendation |
|---------------|----------------|
| Format | OGG or AAC (iOS) |
| Sample Rate | 22050 Hz acceptable |
| Compression | Higher (quality 3-4) |
| Total Budget | < 100 MB audio |

### Web

| Consideration | Recommendation |
|---------------|----------------|
| Format | OGG (primary), MP3 (fallback) |
| Compression | Quality 4-5 |
| Streaming | Consider for music |
| Total Budget | < 50 MB initial |

### Console/PC

| Consideration | Recommendation |
|---------------|----------------|
| Format | OGG |
| Quality | 5-6 |
| Sample Rate | 44100 or 48000 Hz |
| Total Budget | < 500 MB |

---

## Validation

### Format Check Script

```python
import os
from pydub import AudioSegment

def validate_audio_file(file_path, category):
    """Validate audio file against standards"""
    
    errors = []
    warnings = []
    
    # Check extension
    if not file_path.endswith('.ogg'):
        errors.append("File must be OGG format")
    
    try:
        audio = AudioSegment.from_ogg(file_path)
        
        # Check sample rate
        if audio.frame_rate != 44100:
            warnings.append(f"Sample rate is {audio.frame_rate}, recommended 44100")
        
        # Check channels
        expected_channels = 1 if category in ['sfx', 'voice'] else 2
        if audio.channels != expected_channels:
            errors.append(f"Expected {expected_channels} channels, got {audio.channels}")
        
        # Check file size
        file_size = os.path.getsize(file_path)
        size_limits = {
            'sfx': 200 * 1024,      # 200 KB
            'music': 6 * 1024 * 1024,  # 6 MB
            'voice': 500 * 1024,    # 500 KB
        }
        
        limit = size_limits.get(category, 1024 * 1024)
        if file_size > limit:
            warnings.append(f"File size {file_size/1024:.1f}KB exceeds recommended {limit/1024:.1f}KB")
        
    except Exception as e:
        errors.append(f"File validation failed: {e}")
    
    return len(errors) == 0, errors, warnings
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  AUDIO FORMAT QUICK REFERENCE                          │
├────────────────────────────────────────────────────────┤
│  DEFAULT FORMAT: OGG Vorbis                            │
├────────────────────────────────────────────────────────┤
│  SFX:                                                  │
│  • Mono, 44.1kHz, Quality 4 (~128kbps)                 │
│  • Target: < 200 KB                                    │
├────────────────────────────────────────────────────────┤
│  MUSIC:                                                │
│  • Stereo, 44.1kHz, Quality 6 (~256kbps)               │
│  • Target: 2-6 MB per track                            │
├────────────────────────────────────────────────────────┤
│  VOICE:                                                │
│  • Mono, 44.1kHz, Quality 4-5 (~128-160kbps)           │
│  • Target: < 500 KB per line                           │
├────────────────────────────────────────────────────────┤
│  AVOID: MP3 for looping audio (padding issues)         │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Audio philosophy
- [[SFX_Generation_Routing]] - SFX format selection
- [[Music_Direction_Spec]] - Music format requirements
- [[Voice_TTS_Routing]] - Voice format requirements
- [[Audio_Validation_Gates]] - Format validation
