# Determinism Gates
## AI-Native Game Studio OS - Deterministic Execution Protocols

---

## Seed Hierarchy

```
SEED_HIERARCHY := {
  master_seed:    u64,      // Global session seed
  frame_seed:     u64,      // Per-frame derived: H(master_seed || frame_n)
  entity_seed:    u64,      // Per-entity derived: H(frame_seed || entity_id)
  event_seed:     u64,      // Per-event derived: H(entity_seed || event_hash)
}

DERIVATION: seed_child = SHA3_256(parent_seed || salt || counter)[:8]
SALT_SPACE: 2^128 (collision-resistant domain separation)
```

---

## Initialization Protocol

```python
def init_determinism_session(master_seed: u64) -> DeterminismContext:
    ctx = DeterminismContext()
    ctx.master_seed = master_seed
    ctx.rng_state = SplitMix64(master_seed)
    ctx.frame_counter = 0
    ctx.tick_counter = 0
    ctx.state_hash_chain = [SHA3_256(master_seed.to_bytes())]
    return ctx
```

---

## RNG State Tracking

```
RNG_STATE_VECTOR := {
  algorithm:      "SplitMix64" | "Xoshiro256**" | "PCG64",
  state:          [u64; 4],           // Algorithm state
  stream_id:      u64,                // Parallel stream identifier
  call_counter:   u128,               // Total invocations (monotonic)
  last_value:     u64,                // Last output (parity check)
}

STATE_SERIALIZATION: 
  bytes = algorithm_id(1) || state(32) || stream_id(8) || counter(16)
  checksum = CRC32C(bytes)
```

---

## RNG Call Interception

```python
@determinism_gate
def rng_next(ctx: DeterminismContext) -> u64:
    value = ctx.rng_algorithm.next()
    ctx.rng_state.call_counter += 1
    ctx.rng_state.last_value = value
    
    # Log to determinism audit trail
    ctx.audit_log.append({
        'frame': ctx.frame_counter,
        'tick': ctx.tick_counter,
        'counter': ctx.rng_state.call_counter,
        'value': value
    })
    
    return value
```

---

## Replay Verification

```
REPLAY_VERIFICATION := {
  input_log:      [InputEvent],       // Recorded inputs
  expected_hash:  [u8; 32],           // Expected final state hash
  tolerance:      ε = 1e-9,           // FP tolerance
  max_frames:     u64,                // Simulation duration
}

VERIFICATION_ALGORITHM:
  1. Initialize with identical seed
  2. Replay input_log in frame-locked order
  3. Capture state_hash every frame
  4. Compare: |actual_hash - expected_hash| ≡ 0
  5. Report divergence point if mismatch
```

---

## Replay Divergence Detection

```python
def verify_replay(ctx: DeterminismContext, 
                  recorded_log: InputLog,
                  expected_hashes: [StateHash]) -> ReplayResult:
    
    for frame_idx, (inputs, expected_hash) in enumerate(
        zip(recorded_log.frames, expected_hashes)):
        
        ctx.process_frame(inputs)
        actual_hash = ctx.compute_state_hash()
        
        if actual_hash != expected_hash:
            return ReplayResult(
                status=DIVERGENCE_DETECTED,
                frame=frame_idx,
                expected=expected_hash,
                actual=actual_hash,
                diff=compute_state_diff(ctx, expected_hash)
            )
    
    return ReplayResult(status=VERIFIED, frame=None)
```

---

## Platform FP Behavior Matrix

| Platform | Precision | Internal | Mitigation | Cost |
|----------|-----------|----------|------------|------|
| x86/x64 | 64-bit | 80-bit FPU | `-mfpmath=sse -msse2` | 2% |
| ARM64 | 64-bit | 64-bit | Standard | 0% |
| WASM | 64-bit | 64-bit | `-ffloat-store` | 1% |
| CUDA | 64-bit | Varies | `--fmad=false` | 5% |
| Metal | 64-bit | 32/64 | `fastMathEnabled=false` | 8% |
| OpenCL | 64-bit | Varies | `-cl-fp32-correctly-rounded-divide-sqrt` | 3% |

---

## FP Determinism Enforcement

```
FP_DETERMINISM_CONFIG := {
  # Compiler flags per platform
  msvc: "/fp:strict /arch:AVX2",
  gcc: "-ffloat-store -fexcess-precision=standard -msse2",
  clang: "-ffp-model=strict -msse2",
  nvcc: "--fmad=false --prec-div=true --prec-sqrt=true",
  
  # Runtime settings
  ftz: false,           # Flush-to-zero disabled
  daz: false,           # Denormals-are-zero disabled
  rounding: "nearest",  # IEEE 754 round-to-nearest
}
```

---

## FP Tolerance Matrix

| Operation | Tolerance (ε) |
|-----------|---------------|
| add_sub | 1e-12 |
| mul | 1e-12 |
| div | 1e-10 |
| sqrt | 1e-10 |
| trig | 1e-9 |
| exp_log | 1e-9 |

---

## FP Inconsistency Detection

```python
def detect_fp_inconsistency(value: f64, 
                            expected: f64, 
                            operation: str) -> FPCheck:
    ε = FP_TOLERANCE[operation]
    
    if expected == 0:
        absolute_error = abs(value - expected)
        if absolute_error > ε:
            return FPCheck(FAIL, absolute_error, ε, "absolute")
    else:
        relative_error = abs((value - expected) / expected)
        if relative_error > ε:
            return FPCheck(FAIL, relative_error, ε, "relative")
    
    return FPCheck(PASS, 0, ε, None)
```

---

## Cross-Platform FP Validation

```
FP_VALIDATION_SUITE := [
    # (operation, inputs, expected_bit_pattern)
    ("add", [1.0, 2.0], 0x4008000000000000),
    ("mul", [0.1, 0.2], 0x3FB999999999999A),
    ("div", [1.0, 3.0], 0x3FD5555555555555),
    ("sqrt", [2.0], 0x3FF6A09E667F3BCD),
    ("sin", [π/4], 0x3FE6A09E667F3BCD),
    ("exp", [1.0], 0x4005BF0A8B145769),
]

VALIDATION_PROCEDURE:
  For each platform:
    For each test_case in FP_VALIDATION_SUITE:
      result = execute(test_case.operation, test_case.inputs)
      assert bitcast_u64(result) == test_case.expected_bit_pattern
```

---

## Checkpoint Schedule

```
Checkpoint Schedule:
├── Every 1000 ticks (runtime checkpoint)
├── Every frame boundary (frame checkpoint)
├── Every input event (input checkpoint)
└── On state mutation (mutation checkpoint)

Checkpoint Format:
{
  "frame_number": 12345,
  "tick_number": 12345000,
  "state_hash": "sha256:abc123...",
  "rng_state": {...},
  "input_log_hash": "sha256:def456...",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

*Last Updated: 2024-01-15*
