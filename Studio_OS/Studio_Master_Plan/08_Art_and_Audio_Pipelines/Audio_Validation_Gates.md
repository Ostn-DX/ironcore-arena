---
title: Audio Validation Gates
type: gate
layer: enforcement
status: active
tags:
  - audio
  - validation
  - gates
  - quality-control
depends_on:
  - "[Audio_Pipeline_Overview]]"
  - "[[Audio_Format_Standards]"
used_by:
  - "[SFX_Generation_Routing]]"
  - "[[Music_Direction_Spec]"
---

# Audio Validation Gates

## Purpose

Automated checkpoints that validate audio assets against defined standards before they enter the production pipeline.

---

## Gate Philosophy

**Every audio asset passes through gates. Gates are automated. Gates don't negotiate.**

---

## Gate 1: Format Gate

**Purpose**: Ensure correct file format

### Checks

| Check | Rule | Auto-Fix |
|-------|------|----------|
| Extension | Must be .ogg (or approved) | No |
| Valid file | File is not corrupt | No |
| Sample rate | 44100 Hz (or approved) | Yes |
| Channels | Matches category (mono/stereo) | Yes |

### Validation Script

```python
from pydub import AudioSegment
import os

def format_gate(file_path, category):
    """Returns (passed, errors, warnings)"""
    errors = []
    warnings = []
    
    # Check extension
    if not file_path.endswith('.ogg'):
        errors.append("File must be OGG format")
    
    try:
        audio = AudioSegment.from_ogg(file_path)
        
        # Sample rate check
        if audio.frame_rate != 44100:
            warnings.append(f"Sample rate {audio.frame_rate}, recommended 44100")
        
        # Channel check
        expected_channels = 1 if category in ['sfx', 'voice'] else 2
        if audio.channels != expected_channels:
            errors.append(f"Expected {expected_channels} channels, got {audio.channels}")
        
    except Exception as e:
        errors.append(f"File corrupt or unreadable: {e}")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 2: Duration Gate

**Purpose**: Ensure appropriate duration for asset type

### Duration Limits

| Asset Type | Min Duration | Max Duration |
|------------|--------------|--------------|
| UI SFX | 0.01s | 1.0s |
| Weapon SFX | 0.1s | 3.0s |
| Ambient Loop | 5.0s | 60.0s |
| Music | 30.0s | 300.0s |
| Voice Line | 0.5s | 10.0s |

### Validation Script

```python
def duration_gate(file_path, category):
    """Returns (passed, errors, warnings)"""
    from pydub import AudioSegment
    
    errors = []
    warnings = []
    
    audio = AudioSegment.from_ogg(file_path)
    duration = len(audio) / 1000  # Convert to seconds
    
    limits = {
        'ui': (0.01, 1.0),
        'weapon': (0.1, 3.0),
        'ambient': (5.0, 60.0),
        'music': (30.0, 300.0),
        'voice': (0.5, 10.0),
    }
    
    min_dur, max_dur = limits.get(category, (0.1, 60.0))
    
    if duration < min_dur:
        errors.append(f"Duration {duration:.2f}s below minimum {min_dur}s")
    if duration > max_dur:
        warnings.append(f"Duration {duration:.2f}s exceeds recommended {max_dur}s")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 3: Volume/Loudness Gate

**Purpose**: Ensure consistent loudness across assets

### Loudness Targets (LUFS)

| Asset Type | Target | Range |
|------------|--------|-------|
| UI SFX | -14 LUFS | -16 to -12 |
| Weapon SFX | -12 LUFS | -14 to -10 |
| Ambient | -20 LUFS | -22 to -18 |
| Music | -16 LUFS | -18 to -14 |
| Voice | -16 LUFS | -18 to -14 |

### Validation Script

```python
import numpy as np
from pydub import AudioSegment

def loudness_gate(file_path, category):
    """Returns (passed, errors, warnings) - simplified LUFS estimate"""
    errors = []
    warnings = []
    
    audio = AudioSegment.from_ogg(file_path)
    
    # Convert to numpy array
    samples = np.array(audio.get_array_of_samples())
    
    # Calculate RMS (simplified loudness estimate)
    rms = np.sqrt(np.mean(samples**2))
    db = 20 * np.log10(rms / 32768)  # Convert to dBFS
    
    # Map to approximate LUFS (very simplified)
    estimated_lufs = db - 3
    
    targets = {
        'ui': -14,
        'weapon': -12,
        'ambient': -20,
        'music': -16,
        'voice': -16,
    }
    
    target = targets.get(category, -16)
    
    if abs(estimated_lufs - target) > 6:
        errors.append(f"Loudness {estimated_lufs:.1f} LUFS far from target {target} LUFS")
    elif abs(estimated_lufs - target) > 3:
        warnings.append(f"Loudness {estimated_lufs:.1f} LUFS differs from target {target} LUFS")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 4: Quality Gate

**Purpose**: Detect audio quality issues

### Checks

| Check | Rule | Detection |
|-------|------|-----------|
| Clipping | No samples at max amplitude | Sample value = 32767 or -32768 |
| Silence | Not completely silent | RMS > threshold |
| DC Offset | Centered around zero | Mean ≈ 0 |
| Noise floor | Acceptable noise level | Dynamic range > threshold |

### Validation Script

```python
import numpy as np
from pydub import AudioSegment

def quality_gate(file_path):
    """Returns (passed, errors, warnings)"""
    errors = []
    warnings = []
    
    audio = AudioSegment.from_ogg(file_path)
    samples = np.array(audio.get_array_of_samples())
    
    # Clipping detection
    max_val = np.max(np.abs(samples))
    if max_val >= 32767:
        clip_count = np.sum(np.abs(samples) >= 32767)
        errors.append(f"Clipping detected: {clip_count} samples at max amplitude")
    
    # Silence detection
    rms = np.sqrt(np.mean(samples**2))
    if rms < 10:  # Very quiet
        errors.append("Audio appears to be silent or near-silent")
    
    # DC offset
    mean = np.mean(samples)
    if abs(mean) > 100:
        warnings.append(f"DC offset detected: {mean:.1f}")
    
    # Dynamic range
    if max_val > 0:
        dynamic_range_db = 20 * np.log10(max_val / rms) if rms > 0 else 0
        if dynamic_range_db < 3:
            warnings.append(f"Low dynamic range: {dynamic_range_db:.1f} dB")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 5: Loop Gate (for Loops)

**Purpose**: Ensure seamless looping

### Checks

| Check | Rule | Method |
|-------|------|--------|
| Loop points | Start and end compatible | Cross-correlation |
| Volume match | Same level at start/end | Compare RMS |
| Phase match | Similar waveform | Compare samples |

### Validation Script

```python
import numpy as np
from pydub import AudioSegment

def loop_gate(file_path):
    """Returns (passed, errors, warnings) - for looping audio"""
    errors = []
    warnings = []
    
    audio = AudioSegment.from_ogg(file_path)
    samples = np.array(audio.get_array_of_samples())
    
    # Compare start and end (last 100ms vs first 100ms)
    sample_rate = audio.frame_rate
    compare_samples = int(0.1 * sample_rate)  # 100ms
    
    start = samples[:compare_samples]
    end = samples[-compare_samples:]
    
    # RMS comparison
    start_rms = np.sqrt(np.mean(start**2))
    end_rms = np.sqrt(np.mean(end**2))
    
    rms_diff_db = 20 * np.log10(start_rms / end_rms) if end_rms > 0 else 0
    
    if abs(rms_diff_db) > 3:
        warnings.append(f"Volume mismatch at loop point: {rms_diff_db:.1f} dB")
    
    # Correlation (simplified)
    correlation = np.corrcoef(start, end)[0, 1]
    if correlation < 0.5:
        warnings.append(f"Low correlation at loop point: {correlation:.2f}")
    
    return len(errors) == 0, errors, warnings
```

---

## Gate 6: Naming Gate

**Purpose**: Ensure consistent naming

### Naming Convention

```
audio_{category}_{description}_{variant}

Examples:
audio_ui_button_click_01.ogg
audio_weapon_sword_swing_01.ogg
audio_music_forest_exploration.ogg
audio_voice_npc_greeting_01.ogg
```

### Validation Script

```python
def naming_gate(filename):
    """Returns (passed, errors, warnings)"""
    errors = []
    warnings = []
    
    # Check prefix
    if not filename.startswith('audio_'):
        warnings.append("Filename should start with 'audio_'")
    
    # Check category
    valid_categories = ['ui', 'weapon', 'music', 'voice', 'ambient', 'sfx']
    has_category = any(f'_{cat}_' in filename for cat in valid_categories)
    if not has_category:
        errors.append(f"Filename must include category: {valid_categories}")
    
    # Check lowercase
    if filename != filename.lower():
        warnings.append("Filename should be lowercase")
    
    # Check extension
    if not filename.endswith('.ogg'):
        errors.append("File must be .ogg")
    
    return len(errors) == 0, errors, warnings
```

---

## Full Validation Pipeline

```python
def validate_audio(file_path, category, is_loop=False):
    """Run all validation gates"""
    
    results = {
        'file': file_path,
        'category': category,
        'gates': {}
    }
    
    gates = [
        ('naming', naming_gate),
        ('format', lambda f: format_gate(f, category)),
        ('duration', lambda f: duration_gate(f, category)),
        ('loudness', lambda f: loudness_gate(f, category)),
        ('quality', quality_gate),
    ]
    
    if is_loop:
        gates.append(('loop', loop_gate))
    
    for gate_name, gate_func in gates:
        passed, errors, warnings = gate_func(file_path)
        results['gates'][gate_name] = {
            'passed': passed,
            'errors': errors,
            'warnings': warnings
        }
    
    results['overall_passed'] = all(
        g['passed'] for g in results['gates'].values()
    )
    
    return results
```

---

## Quick Reference

```
┌────────────────────────────────────────────────────────┐
│  AUDIO VALIDATION GATES QUICK REFERENCE                │
├────────────────────────────────────────────────────────┤
│  GATE 1: Format                                        │
│  ✓ OGG format ✓ 44.1kHz ✓ Correct channels            │
├────────────────────────────────────────────────────────┤
│  GATE 2: Duration                                      │
│  ✓ Within category limits                              │
├────────────────────────────────────────────────────────┤
│  GATE 3: Loudness                                      │
│  ✓ Within LUFS target range                            │
├────────────────────────────────────────────────────────┤
│  GATE 4: Quality                                       │
│  ✓ No clipping ✓ Not silent ✓ Good dynamic range      │
├────────────────────────────────────────────────────────┤
│  GATE 5: Loop (if applicable)                          │
│  ✓ Seamless loop points                                │
├────────────────────────────────────────────────────────┤
│  GATE 6: Naming                                        │
│  ✓ Correct prefix ✓ Category included ✓ Lowercase     │
└────────────────────────────────────────────────────────┘
```

---

## Related Systems

- [[Audio_Pipeline_Overview]] - Audio philosophy
- [[Audio_Format_Standards]] - Format requirements
- [[SFX_Generation_Routing]] - Generation validation
- [[Music_Direction_Spec]] - Music validation
