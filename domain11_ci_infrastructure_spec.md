# Domain 11: CI / Headless Simulation Infrastructure Specification
## AI-Native Game Studio OS - Technical Specification v1.0

---

## 1. HEADLESS SIMULATION ARCHITECTURE

### 1.1 No-GPU Mode Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         HEADLESS SIMULATION STACK                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Sim Core   │  │  Renderer   │  │  Physics    │  │   AI Inference      │ │
│  │  (CPU)      │  │  (Null)     │  │  (CPU)      │  │   (CPU/Optional)    │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
│         └─────────────────┴─────────────────┴──────────────────┘            │
│                                    │                                         │
│                           ┌────────┴────────┐                                │
│                           │  Sim Controller │                                │
│                           │  (Orchestrator) │                                │
│                           └────────┬────────┘                                │
│                                    │                                         │
│                    ┌───────────────┼───────────────┐                        │
│                    ▼               ▼               ▼                        │
│              ┌─────────┐    ┌─────────┐    ┌─────────┐                      │
│              │  State  │    │  Event  │    │  Frame  │                      │
│              │  Buffer │    │  Queue  │    │  Buffer │                      │
│              └─────────┘    └─────────┘    └─────────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Null Renderer Specification:**
| Component | Mode | Output |
|-----------|------|--------|
| `NullRenderDevice` | Headless | Void framebuffer |
| `NullTextureManager` | Stub | 1x1 placeholder textures |
| `NullShaderCompiler` | Passthrough | Precompiled SPIR-V |
| `NullCommandBuffer` | No-op | Immediate return |
| `NullSwapchain` | Disabled | Frame counter only |

**CPU Physics Fallback:**
```cpp
// Deterministic physics stepping
PhysicsConfig {
    fixed_timestep: 1/60.0,      // Δt = 16.667ms
    max_substeps: 8,              // n_max = 8
    solver_iterations: 4,         // k_solver = 4
    deterministic_mode: true,     // ε_tolerance = 1e-6
    thread_count: T_phys ≤ N_cores
}
```

### 1.2 Batch Execution Model

**Batch Definition:**
```
B = {S₁, S₂, ..., Sₙ} where n = |B| ≤ N_max_batch

Each simulation Sᵢ = ⟨Cᵢ, Dᵢ, Tᵢ, Oᵢ⟩
- Cᵢ: Configuration (seed, parameters)
- Dᵢ: Duration in ticks
- Tᵢ: Timeout threshold
- Oᵢ: Output specification
```

**Batch Execution Equation:**
```
T_batch = max(T₁, T₂, ..., Tₙ) + T_overhead
Speedup = ΣT_serial / T_batch ≈ n / (1 + α·n)
where α = coordination overhead coefficient (typically 0.05-0.15)
```

**Batch Scheduler:**
```
SchedulerPolicy {
    strategy: [FIFO | Priority | ShortestJobFirst],
    max_concurrent: N_workers,
    preemption: [none | checkpoint | kill],
    retry_policy: {
        max_attempts: 3,
        backoff: exponential(1s, 2s, 4s)
    }
}
```

### 1.3 Parallel Instance Architecture

**Worker Pool Topology:**
```
┌────────────────────────────────────────────────────────────┐
│                      CI Orchestrator                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐     ┌─────────┐    │
│  │ Queue   │  │ Monitor │  │ Metrics │     │ Logger  │    │
│  │ Manager │  │ Service │  │ Emitter │     │ Service │    │
│  └────┬────┘  └─────────┘  └─────────┘     └─────────┘    │
│       │                                                    │
│       ▼                                                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Worker Pool (N_workers)                 │   │
│  │  ┌─────┐ ┌─────┐ ┌─────┐        ┌─────┐            │   │
│  │  │ W₁  │ │ W₂  │ │ W₃  │  ...   │ Wₙ  │            │   │
│  │  │[S₁] │ │[S₂] │ │[S₃] │        │[Sₙ] │            │   │
│  │  └──┬──┘ └──┬──┘ └──┬──┘        └──┬──┘            │   │
│  │     └───────┴───────┴────────────────┘              │   │
│  │              Shared State Store                      │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

**Resource Allocation Formula:**
```
R_total = Σ(R_cpu + R_mem + R_disk) ≤ R_available

Per-worker resources:
- CPU: C_worker = C_total / N_workers
- RAM: M_worker = M_total / N_workers  
- Disk: D_worker = D_quota / N_workers
```

---

## 2. CI PIPELINE STAGES

### 2.1 Pipeline DAG

```
                    ┌─────────┐
                    │  START  │
                    └────┬────┘
                         │
                    ┌────▼────┐
              ┌─────┤  BUILD  ├─────┐
              │     │ (10min) │     │
              │     └────┬────┘     │
              │          │          │
         [FAIL]    ┌─────┴─────┐ [FAIL]
              │    │           │    │
              │    ▼           ▼    │
              │ ┌──────┐   ┌──────┐ │
              │ │LINT  │   │FORMAT│ │
              │ │(2min)│   │(1min)│ │
              │ └──┬───┘   └──┬───┘ │
              │    └────┬─────┘     │
              │         │           │
              │    ┌────▼────┐      │
              └────┤UNIT TEST├──────┘
                   │ (5min)  │
                   └────┬────┘
                   [FAIL]│[PASS]
                        │
              ┌─────────┼─────────┐
              │         │         │
              ▼         ▼         ▼
         ┌────────┐ ┌────────┐ ┌────────┐
         │SIM TEST│ │COVERAGE│ │BENCHMARK
         │(30min) │ │(15min) │ │(20min) │
         └───┬────┘ └────────┘ └────────┘
             │
        [PASS]│[FAIL]
             │
        ┌────▼────────┐
        │ INTEGRATION │
        │   (60min)   │
        └──────┬──────┘
               │
          ┌────┴────┐
          ▼         ▼
     ┌────────┐ ┌────────┐
     │ DEPLOY │ │ REPORT │
     │(5min)  │ │(2min)  │
     └────────┘ └────────┘
```

### 2.2 Stage Specifications

| Stage | Purpose | Timeout | Parallel | Artifacts | Failure Action |
|-------|---------|---------|----------|-----------|----------------|
| **Build** | Compile all targets, generate binaries | 10min | Yes (matrix) | Binaries, compile_commands.json | Halt pipeline |
| **Lint** | Static analysis, code quality | 2min | Yes | SARIF reports | Continue (warn) |
| **Format** | Code style validation | 1min | Yes | Diff patches | Halt if fixable |
| **UnitTest** | Fast unit tests (no sim) | 5min | Yes (sharded) | Test results, coverage | Halt pipeline |
| **SimTest** | Determinism validation | 30min | Yes (parallel) | Sim traces, checksums | Halt pipeline |
| **Coverage** | Code coverage analysis | 15min | No | Coverage reports | Continue |
| **Benchmark** | Performance regression | 20min | Yes | Benchmark results | Continue (warn) |
| **Integration** | Full integration suite | 60min | Yes (matrix) | Test logs, artifacts | Halt pipeline |
| **Deploy** | Artifact deployment | 5min | No | Deployed packages | Alert on fail |
| **Report** | Generate summary | 2min | No | HTML reports | Continue |

### 2.3 Stage Configuration Schema

```yaml
# pipeline_stage.yaml
stages:
  build:
    timeout: 600  # seconds
    parallel:
      matrix:
        platform: [linux-x64, linux-arm64, windows-x64]
        config: [debug, release]
      max_parallel: 6
    artifacts:
      paths: ["build/**", "compile_commands.json"]
      retention: 7d
    
  sim_test:
    timeout: 1800
    parallel:
      shards: 8
      workers_per_shard: 4
    resources:
      cpu: 4
      memory: "8Gi"
    artifacts:
      paths: ["sim_traces/**", "checksums.json", "metrics.json"]
      retention: 30d
```

---

## 3. PARALLEL TEST EXECUTION MODEL

### 3.1 Worker Pool Sizing

**Optimal Worker Count:**
```
N_optimal = min(N_cpu_cores × α_util, N_memory_bound, N_io_bound)

where:
- α_util = 0.75 (target CPU utilization)
- N_memory_bound = M_available / M_per_test
- N_io_bound = I_max_throughput / I_per_test
```

**Dynamic Scaling:**
```python
def calculate_workers(queue_depth, avg_duration, target_latency):
    """
    N_workers = ceil(queue_depth × avg_duration / target_latency)
    bounded by: N_min ≤ N_workers ≤ N_max
    """
    required = math.ceil(queue_depth * avg_duration / target_latency)
    return clamp(required, N_min, N_max)
```

### 3.2 Test Sharding Algorithm

**Hash-Based Sharding:**
```
shard_id = H(test_name) mod N_shards

where H is a consistent hash function:
H(s) = fnv1a_64(s) >> (64 - log₂(N_shards))
```

**Duration-Aware Sharding:**
```
Objective: minimize makespan T_max = max(T_shard₁, ..., T_shardₙ)

Greedy algorithm:
1. Sort tests by duration descending: t₁ ≥ t₂ ≥ ... ≥ tₘ
2. For each test, assign to shard with minimum current load
3. Result: T_max ≤ (Σtᵢ / N_shards) + t_max
```

### 3.3 Resource Limits

| Resource | Default Limit | Maximum | Enforcement |
|----------|--------------|---------|-------------|
| CPU | 2 cores | 16 cores | cgroup cpu.quota |
| Memory | 4 GiB | 64 GiB | cgroup memory.limit |
| Disk I/O | 100 MB/s | 500 MB/s | blkio.throttle |
| Network | 10 MB/s | 100 MB/s | tc qdisc |
| File Descriptors | 1024 | 65536 | ulimit -n |
| Processes | 512 | 4096 | ulimit -u |

**Resource Quota Enforcement:**
```
┌─────────────────────────────────────────┐
│           Resource Controller            │
├─────────────────────────────────────────┤
│  cgroup v2 hierarchy:                   │
│  /sys/fs/cgroup/ci.slice/               │
│    ├── worker-001/                      │
│    │   ├── cpu.max = "200000 100000"    │
│    │   ├── memory.max = 4G              │
│    │   └── io.max = "8:0 rbps=104857600"│
│    ├── worker-002/                      │
│    └── ...                              │
└─────────────────────────────────────────┘
```

---

## 4. ARTIFACT COLLECTION AND STORAGE

### 4.1 Artifact Taxonomy

```
Artifacts A = {A_build, A_test, A_sim, A_metrics, A_logs}

A_build = {binaries, libraries, headers, symbols}
A_test = {junit_xml, coverage_data, test_logs}
A_sim = {traces, checksums, state_dumps, replays}
A_metrics = {timing, memory, cpu, custom}
A_logs = {stdout, stderr, system_logs, crash_dumps}
```

### 4.2 Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Artifact Storage                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐      ┌─────────────┐      ┌────────────┐  │
│   │   Hot Tier  │      │   Warm Tier │      │  Cold Tier │  │
│   │  (SSD/NVMe) │ ───► │  (HDD/S3)   │ ───► │  (Glacier) │  │
│   │   7 days    │      │   30 days   │      │  365 days  │  │
│   │  < 10GB     │      │  < 100GB    │      │  unlimited │  │
│   └─────────────┘      └─────────────┘      └────────────┘  │
│          │                    │                    │         │
│          ▼                    ▼                    ▼         │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Artifact Metadata Store                 │   │
│   │  {id, path, size, checksum, created, expires, refs}  │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Artifact Lifecycle

```
Phase        │ Duration │ Action
─────────────┼──────────┼────────────────────────────────
Active       │ 0-7d     │ Immediate access, hot storage
Retained     │ 7-30d    │ Warm storage, indexed access
Archived     │ 30-365d  │ Cold storage, restore required
Purged       │ >365d    │ Deleted per retention policy
```

### 4.4 Artifact Schema

```json
{
  "artifact": {
    "id": "uuid-v4",
    "pipeline_id": "pipeline-uuid",
    "stage": "sim_test",
    "name": "sim_trace_tick_1000.bin",
    "type": "application/octet-stream",
    "size_bytes": 1048576,
    "checksum": {
      "sha256": "abc123...",
      "blake3": "def456..."
    },
    "metadata": {
      "created_at": "2024-01-15T10:30:00Z",
      "expires_at": "2024-02-15T10:30:00Z",
      "compression": "zstd:9",
      "encryption": "aes-256-gcm"
    },
    "storage": {
      "tier": "hot",
      "uri": "s3://artifacts-bucket/...",
      "replicas": 3
    },
    "references": [
      {"type": "test_run", "id": "test-123"},
      {"type": "simulation", "id": "sim-456"}
    ]
  }
}
```

---

## 5. DETERMINISM VALIDATION IN CI

### 5.1 Determinism Model

**Deterministic Execution Definition:**
```
A simulation S is deterministic iff:
∀ seed ∈ Seeds, ∀ run₁, run₂ ∈ Runs:
  State(S, seed, run₁, t) = State(S, seed, run₂, t) ∀ t ∈ [0, T]

where State(s, t) = ⟨E(t), P(t), A(t), R(t)⟩
- E(t): Entity state at tick t
- P(t): Physics state at tick t  
- A(t): AI state at tick t
- R(t): Random number generator state at tick t
```

### 5.2 Determinism Checksum Hierarchy

```
Level 0 (Frame):   H₀(t) = hash(EntityPositions(t))
Level 1 (Tick):    H₁(t) = hash(H₀(t) ∪ PhysicsState(t))
Level 2 (Snapshot): H₂(k) = hash(∪ₜ₌ₖₙ⁽ᵏ⁺¹⁾ⁿ H₁(t))  // n ticks per snapshot
Level 3 (Run):     H₃ = hash(∪ₖ H₂(k))  // Full run hash
```

### 5.3 CI Determinism Validation Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│              Determinism Validation Flow                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Input: Build artifact + test configuration                  │
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────────┐                 │
│  │  Stage 1: Reference Run (Run A)         │                 │
│  │  - Execute with seed S_ref               │                 │
│  │  - Collect checksums H₃^A                │                 │
│  │  - Store as golden reference             │                 │
│  └─────────────────┬───────────────────────┘                 │
│                    │                                         │
│                    ▼                                         │
│  ┌─────────────────────────────────────────┐                 │
│  │  Stage 2: Verification Runs (Runs B-N)  │                 │
│  │  - Execute N-1 additional runs           │                 │
│  │  - Same seed S_ref, different workers    │                 │
│  │  - Collect checksums H₃^B ... H₃^N       │                 │
│  └─────────────────┬───────────────────────┘                 │
│                    │                                         │
│                    ▼                                         │
│  ┌─────────────────────────────────────────┐                 │
│  │  Stage 3: Cross-Validation              │                 │
│  │  - Verify: H₃^A = H₃^B = ... = H₃^N     │                 │
│  │  - Per-tick diff analysis on mismatch    │                 │
│  │  - Generate determinism report            │                 │
│  └─────────────────┬───────────────────────┘                 │
│                    │                                         │
│              [PASS]│[FAIL]                                   │
│                    │                                         │
│         ┌─────────┴─────────┐                               │
│         ▼                   ▼                               │
│    ┌─────────┐         ┌─────────┐                          │
│    │  PASS   │         │  FAIL   │                          │
│    │ Continue│         │ Bisect  │                          │
│    └─────────┘         │ & Report│                          │
│                        └─────────┘                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 5.4 Non-Determinism Detection

**Bisection Algorithm for Failure Localization:**
```
Given: Run A (pass) with checksums C^A[0..T]
       Run B (fail) with checksums C^B[0..T]
       First mismatch at tick t_mismatch

Bisect(t_start, t_end):
    if t_end - t_start <= 1:
        return t_start  // Found exact tick
    
    t_mid = (t_start + t_end) / 2
    state_mid_A = replay_to(A, t_mid)
    state_mid_B = replay_to(B, t_mid)
    
    if state_mid_A == state_mid_B:
        return Bisect(t_mid, t_end)  // Divergence in second half
    else:
        return Bisect(t_start, t_mid)  // Divergence in first half
```

### 5.5 Determinism Metrics

| Metric | Definition | Target | Critical |
|--------|------------|--------|----------|
| Checksum Match Rate | % of runs with matching checksums | 100% | ≥99.9% |
| Drift Detection Time | Ticks to detect divergence | <100 | <10 |
| Replay Fidelity | State reconstruction accuracy | 100% | ≥99.99% |
| Seed Coverage | Unique seeds tested per commit | ≥10 | ≥5 |

---

## 6. FAILURE REPORTING AND TICKETING

### 6.1 Failure Classification

```
Failure Types F = {F_build, F_test, F_sim, F_infra, F_timeout}

F_build = {compile_error, link_error, lint_violation}
F_test = {assertion_fail, exception, crash, hang}
F_sim = {determinism_fail, state_divergence, checksum_mismatch}
F_infra = {worker_failure, network_error, disk_full}
F_timeout = {stage_timeout, test_timeout, global_timeout}
```

### 6.2 Failure Severity Matrix

| Failure Type | Severity | Auto-Retry | Ticket | Notify |
|--------------|----------|------------|--------|--------|
| Compile Error | Critical | No | Yes | Team |
| Unit Test Fail | High | No | Yes | Author |
| Determinism Fail | Critical | No | Yes | Team + Arch |
| Timeout | Medium | Yes (×2) | On retry fail | Author |
| Infra Error | Low | Yes (×3) | On retry fail | Ops |
| Flaky Test | Medium | Yes (×3) | If persistent | Author |

### 6.3 Ticketing Integration

```
┌─────────────────────────────────────────────────────────────┐
│              Failure → Ticket Pipeline                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Failure Detected ──┐                                        │
│                     │                                        │
│                     ▼                                        │
│  ┌─────────────────────────────────────┐                     │
│  │ 1. Deduplication                    │                     │
│  │    - Hash: H(failure_signature)     │                     │
│  │    - Check against open tickets     │                     │
│  │    - Skip if duplicate within 24h   │                     │
│  └─────────────┬───────────────────────┘                     │
│                │                                             │
│                ▼                                             │
│  ┌─────────────────────────────────────┐                     │
│  │ 2. Context Enrichment               │                     │
│  │    - Git commit: SHA, author, msg   │                     │
│  │    - Build logs: last 100 lines     │                     │
│  │    - Test output: failure context   │                     │
│  │    - Artifacts: links to traces     │                     │
│  └─────────────┬───────────────────────┘                     │
│                │                                             │
│                ▼                                             │
│  ┌─────────────────────────────────────┐                     │
│  │ 3. Ticket Creation                  │                     │
│  │    - System: JIRA/GitHub Issues     │                     │
│  │    - Labels: ci-failure, [type]     │                     │
│  │    - Assignee: commit author        │                     │
│  │    - Priority: severity-based       │                     │
│  └─────────────┬───────────────────────┘                     │
│                │                                             │
│                ▼                                             │
│  ┌─────────────────────────────────────┐                     │
│  │ 4. Notification                     │                     │
│  │    - Slack: #ci-failures            │                     │
│  │    - Email: author + watchers       │                     │
│  │    - PagerDuty: critical only       │                     │
│  └─────────────────────────────────────┘                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6.4 Ticket Schema

```json
{
  "ticket": {
    "id": "CI-2024-001234",
    "type": "ci_failure",
    "title": "[CI] SimTest determinism failure in test_npc_behavior",
    "description": {
      "summary": "Checksum mismatch detected at tick 15432",
      "failure_type": "determinism_fail",
      "pipeline": "main-pipeline-#5678",
      "stage": "sim_test",
      "commit": {
        "sha": "abc123def456",
        "author": "dev@example.com",
        "message": "Update NPC decision tree",
        "timestamp": "2024-01-15T10:30:00Z"
      },
      "failure_details": {
        "test_name": "test_npc_behavior",
        "run_count": 5,
        "mismatch_count": 2,
        "first_mismatch_tick": 15432,
        "checksum_expected": "a1b2c3...",
        "checksum_actual": "d4e5f6..."
      },
      "logs_url": "https://ci.example.com/logs/5678/sim_test",
      "artifacts": [
        "s3://artifacts/5678/sim_trace_ref.bin",
        "s3://artifacts/5678/sim_trace_fail.bin"
      ]
    },
    "labels": ["ci-failure", "determinism", "simulation", "high-priority"],
    "assignee": "dev@example.com",
    "priority": "High",
    "created_at": "2024-01-15T10:45:00Z",
    "linked_pipelines": ["main-pipeline-#5678"]
  }
}
```

---

## 7. SUCCESS CRITERIA (MEASURABLE)

### 7.1 Pipeline Metrics

| Metric | Formula | Target | SLA |
|--------|---------|--------|-----|
| **Pipeline Duration** | T_pipeline = ΣT_stages | < 30min | < 45min |
| **Build Success Rate** | SR_build = N_pass / N_total | ≥ 98% | ≥ 95% |
| **Test Pass Rate** | SR_test = N_tests_pass / N_tests_total | ≥ 99% | ≥ 97% |
| **Determinism Rate** | DR = N_deterministic / N_sim_runs | 100% | ≥ 99.9% |
| **Flaky Test Rate** | FR = N_flaky / N_total_tests | < 1% | < 5% |
| **Artifact Availability** | AA = T_available / T_total | ≥ 99.9% | ≥ 99% |

### 7.2 Performance Metrics

| Metric | Definition | Target | Critical |
|--------|------------|--------|----------|
| **Sim Throughput** | Ticks/second in headless mode | ≥ 1000 | ≥ 500 |
| **Parallel Efficiency** | Speedup / N_workers | ≥ 0.85 | ≥ 0.70 |
| **Worker Utilization** | Active_time / Total_time | ≥ 80% | ≥ 60% |
| **Queue Latency** | Time from submit to start | < 30s | < 2min |
| **Recovery Time** | Time to recover from worker failure | < 60s | < 5min |

### 7.3 Quality Gates

```
Gate Conditions (ALL must pass):

G1: Build
   - No compile errors
   - No link errors
   - Lint score ≥ 90%

G2: Unit Tests
   - Pass rate = 100%
   - Coverage ≥ 80% (new code)
   - Coverage ≥ 70% (overall)

G3: Sim Tests
   - Determinism: 100% checksum match
   - All scenarios pass
   - No state divergence

G4: Integration
   - All integration tests pass
   - Performance regression < 5%
   - Memory leak: none detected
```

### 7.4 Metric Collection

```python
# metrics_collector.py
class CIMetrics:
    def record_pipeline(self, pipeline_id, stages):
        self.timing_histogram.observe(
            pipeline_duration=sum(s.duration for s in stages),
            build_duration=stages['build'].duration,
            test_duration=stages['test'].duration,
        )
        self.counter.inc(
            pipelines_total=1,
            pipelines_success=sum(1 for s in stages if s.status == 'pass'),
        )
    
    def record_sim_determinism(self, test_id, runs):
        checksums = [r.checksum for r in runs]
        unique_checksums = len(set(checksums))
        self.gauge.set(
            determinism_score=1.0 if unique_checksums == 1 else 0.0,
            mismatch_count=unique_checksums - 1,
        )
```

---

## 8. FAILURE STATES

### 8.1 Failure State Machine

```
                         ┌──────────┐
                         │  PENDING │
                         └────┬─────┘
                              │ trigger
                              ▼
                    ┌─────────────────┐
              ┌─────┤    RUNNING      ├─────┐
              │     │                 │     │
              │     └─────────────────┘     │
              │              │              │
         [success]      [failure]      [timeout]
              │              │              │
              ▼              ▼              ▼
         ┌────────┐    ┌────────┐    ┌────────┐
         │SUCCESS │    │  FAIL  │    │ TIMEOUT│
         └───┬────┘    └───┬────┘    └───┬────┘
             │             │             │
             │             ▼             │
             │      ┌─────────────┐      │
             │      │ AUTO-RETRY? │      │
             │      └──────┬──────┘      │
             │        [yes]│[no]          │
             │             │              │
             │      ┌──────┴──────┐       │
             │      ▼             ▼       │
             │ ┌─────────┐   ┌─────────┐  │
             │ │ RETRY   │   │  ALERT  │  │
             │ │ (n<max) │   │ TICKET  │  │
             │ └────┬────┘   └─────────┘  │
             │      │                     │
             └──────┴─────────────────────┘
```

### 8.2 Failure State Definitions

| State | Definition | Entry Condition | Exit Action |
|-------|------------|-----------------|-------------|
| **PENDING** | Queued for execution | Pipeline triggered | Transition to RUNNING |
| **RUNNING** | Actively executing | Worker assigned | Success/Failure/Timeout |
| **SUCCESS** | All stages passed | All gates pass | Report success, store artifacts |
| **FAILED** | One or more stages failed | Any gate fails | Analyze, retry, or alert |
| **TIMEOUT** | Exceeded time limit | T_elapsed > T_limit | Mark failed, capture state |
| **CANCELLED** | Manually aborted | User intervention | Clean up, partial artifacts |
| **RETRYING** | Attempting recovery | Auto-retry enabled | Return to RUNNING or FAIL |

### 8.3 Failure Recovery Procedures

```
Procedure: HandleWorkerFailure(worker_id)
─────────────────────────────────────────
1. Mark worker as UNHEALTHY
2. Migrate in-flight tasks to other workers
3. Capture worker logs and state
4. Restart worker container/process
5. Health check: verify worker readiness
6. Return worker to pool on success
7. Alert ops if restart fails after 3 attempts

Procedure: HandleDeterminismFailure(test_id)
────────────────────────────────────────────
1. Capture checksums from all runs
2. Identify first divergent tick via bisection
3. Collect state dumps at t-1, t, t+1
4. Generate diff report
5. Create ticket with artifacts
6. Block merge if on main branch
7. Notify simulation team

Procedure: HandleInfrastructureFailure()
────────────────────────────────────────
1. Identify failure scope (worker/node/cluster)
2. Quarantine affected resources
3. Drain queues to healthy workers
4. Scale up replacement capacity
5. Root cause analysis
6. Update runbooks
```

### 8.4 Failure Escalation

```
Level 1 (0-15min):  Auto-retry, no notification
Level 2 (15-30min): Notify commit author via Slack
Level 3 (30-60min): Create ticket, email team lead
Level 4 (60min+):   Page on-call engineer
Level 5 (2hr+):     Escalate to engineering manager
```

---

## 9. INTEGRATION SURFACE

### 9.1 External System Interfaces

```
┌─────────────────────────────────────────────────────────────┐
│                  Integration Surface                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Version     │  │ Artifact    │  │ Notification│          │
│  │ Control     │  │ Storage     │  │ System      │          │
│  │ (Git)       │  │ (S3/MinIO)  │  │ (Slack)     │          │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │
│         │                │                │                  │
│         └────────────────┼────────────────┘                  │
│                          │                                   │
│                    ┌─────┴─────┐                             │
│                    │  CI Core  │                             │
│                    │  System   │                             │
│                    └─────┬─────┘                             │
│                          │                                   │
│         ┌────────────────┼────────────────┐                  │
│         │                │                │                  │
│  ┌──────┴──────┐  ┌──────┴──────┐  ┌──────┴──────┐          │
│  │ Ticketing   │  │ Metrics     │  │ Secrets     │          │
│  │ (JIRA)      │  │ (Prometheus)│  │ (Vault)     │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 API Surface

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/v1/pipeline` | POST | Trigger pipeline | API key |
| `/api/v1/pipeline/{id}` | GET | Get pipeline status | API key |
| `/api/v1/pipeline/{id}/cancel` | POST | Cancel pipeline | API key |
| `/api/v1/artifact/{id}` | GET | Download artifact | Signed URL |
| `/api/v1/artifact/{id}/upload` | PUT | Upload artifact | API key |
| `/api/v1/worker` | GET | List workers | Admin |
| `/api/v1/worker/{id}/logs` | GET | Get worker logs | Admin |
| `/api/v1/metrics` | GET | Prometheus metrics | None |
| `/api/v1/webhook/github` | POST | GitHub webhook | HMAC |
| `/api/v1/webhook/slack` | POST | Slack slash commands | OAuth |

### 9.3 Event Bus Interface

```
Event Types:
├── pipeline.triggered
├── pipeline.started
├── pipeline.stage_started
├── pipeline.stage_completed
├── pipeline.completed
├── pipeline.failed
├── test.started
├── test.completed
├── test.failed
├── artifact.uploaded
├── worker.assigned
├── worker.released
└── worker.failed

Event Schema:
{
  "event_type": "pipeline.stage_completed",
  "timestamp": "2024-01-15T10:30:00Z",
  "pipeline_id": "uuid",
  "stage": "sim_test",
  "status": "success",
  "duration_ms": 120000,
  "metadata": {...}
}
```

### 9.4 Configuration Interface

```yaml
# ci-config.yaml
version: "2.0"

pipeline:
  name: "main-pipeline"
  triggers:
    - type: push
      branches: [main, develop]
    - type: pull_request
      branches: [main]
  
  stages:
    - name: build
      image: "ci/builder:v1.2.3"
      commands:
        - cmake -B build -DCMAKE_BUILD_TYPE=Release
        - cmake --build build -j$(nproc)
      artifacts:
        - path: "build/bin/*"
          retention: 30d
    
    - name: sim_test
      image: "ci/sim-runner:v1.2.3"
      needs: [build]
      matrix:
        shard: [1, 2, 3, 4, 5, 6, 7, 8]
      resources:
        cpu: 4
        memory: "8Gi"
      commands:
        - ./run_sim_tests --shard ${{ matrix.shard }} --shards 8
      timeout: 1800
      determinism:
        runs: 5
        checksum_interval: 100
```

---

## 10. JSON SCHEMAS

### 10.1 Pipeline Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://ci.gstudio.io/schemas/pipeline.json",
  "title": "CI Pipeline",
  "type": "object",
  "required": ["id", "stages", "trigger"],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid"
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 128
    },
    "status": {
      "type": "string",
      "enum": ["pending", "running", "success", "failed", "cancelled"]
    },
    "trigger": {
      "type": "object",
      "required": ["type", "source"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["push", "pull_request", "manual", "scheduled", "webhook"]
        },
        "source": {
          "type": "string"
        },
        "commit": {
          "type": "object",
          "properties": {
            "sha": {"type": "string", "pattern": "^[a-f0-9]{40}$"},
            "message": {"type": "string"},
            "author": {"type": "string", "format": "email"},
            "timestamp": {"type": "string", "format": "date-time"}
          }
        }
      }
    },
    "stages": {
      "type": "array",
      "items": {"$ref": "#/definitions/stage"}
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "started_at": {
      "type": "string",
      "format": "date-time"
    },
    "completed_at": {
      "type": "string",
      "format": "date-time"
    }
  },
  "definitions": {
    "stage": {
      "type": "object",
      "required": ["name", "status"],
      "properties": {
        "name": {"type": "string"},
        "status": {
          "type": "string",
          "enum": ["pending", "running", "success", "failed", "skipped"]
        },
        "started_at": {"type": "string", "format": "date-time"},
        "completed_at": {"type": "string", "format": "date-time"},
        "duration_ms": {"type": "integer", "minimum": 0},
        "artifacts": {
          "type": "array",
          "items": {"$ref": "#/definitions/artifact"}
        }
      }
    },
    "artifact": {
      "type": "object",
      "required": ["id", "name", "path"],
      "properties": {
        "id": {"type": "string", "format": "uuid"},
        "name": {"type": "string"},
        "path": {"type": "string"},
        "size_bytes": {"type": "integer", "minimum": 0},
        "checksum": {"type": "string"},
        "content_type": {"type": "string"}
      }
    }
  }
}
```

### 10.2 Simulation Run Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://ci.gstudio.io/schemas/simulation_run.json",
  "title": "Simulation Run",
  "type": "object",
  "required": ["id", "config", "results"],
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid"
    },
    "pipeline_id": {
      "type": "string",
      "format": "uuid"
    },
    "config": {
      "type": "object",
      "required": ["seed", "duration_ticks"],
      "properties": {
        "seed": {
          "type": "integer",
          "minimum": 0
        },
        "duration_ticks": {
          "type": "integer",
          "minimum": 1
        },
        "scenario": {
          "type": "string"
        },
        "parameters": {
          "type": "object"
        }
      }
    },
    "results": {
      "type": "object",
      "properties": {
        "status": {
          "type": "string",
          "enum": ["success", "failed", "timeout", "error"]
        },
        "ticks_executed": {
          "type": "integer"
        },
        "duration_ms": {
          "type": "integer"
        },
        "checksums": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "tick": {"type": "integer"},
              "level": {"type": "integer"},
              "hash": {"type": "string"}
            }
          }
        },
        "final_checksum": {
          "type": "string"
        },
        "artifacts": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }
}
```

### 10.3 Determinism Report Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://ci.gstudio.io/schemas/determinism_report.json",
  "title": "Determinism Validation Report",
  "type": "object",
  "required": ["test_id", "runs", "deterministic"],
  "properties": {
    "test_id": {"type": "string"},
    "test_name": {"type": "string"},
    "runs": {
      "type": "array",
      "minItems": 2,
      "items": {
        "type": "object",
        "properties": {
          "run_id": {"type": "string"},
          "worker_id": {"type": "string"},
          "final_checksum": {"type": "string"},
          "duration_ms": {"type": "integer"}
        }
      }
    },
    "deterministic": {"type": "boolean"},
    "unique_checksums": {"type": "integer"},
    "mismatches": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "run_a": {"type": "string"},
          "run_b": {"type": "string"},
          "first_divergent_tick": {"type": "integer"},
          "checksum_a": {"type": "string"},
          "checksum_b": {"type": "string"}
        }
      }
    },
    "analysis": {
      "type": "object",
      "properties": {
        "bisection_performed": {"type": "boolean"},
        "divergence_point": {"type": "integer"},
        "state_dumps": {
          "type": "array",
          "items": {"type": "string"}
        }
      }
    }
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Components

```python
# ci_orchestrator.py
class CIOrchestrator:
    def __init__(self, config):
        self.worker_pool = WorkerPool(config.workers)
        self.queue = PriorityQueue()
        self.artifact_store = ArtifactStore(config.storage)
        self.metrics = MetricsCollector()
        
    async def run_pipeline(self, pipeline_def):
        pipeline = Pipeline(pipeline_def)
        
        for stage in pipeline.stages:
            self.metrics.record_stage_start(stage)
            
            try:
                with timeout(stage.timeout):
                    results = await self.execute_stage(stage)
                
                if not self.validate_stage_results(stage, results):
                    raise StageValidationError()
                    
                artifacts = await self.collect_artifacts(stage, results)
                await self.artifact_store.store(artifacts)
                
            except TimeoutError:
                await self.handle_timeout(stage)
                raise PipelineFailed()
            except Exception as e:
                await self.handle_failure(stage, e)
                raise PipelineFailed()
                
        return PipelineSuccess(pipeline)

    async def execute_stage(self, stage):
        if stage.parallel:
            return await self.execute_parallel(stage)
        else:
            worker = await self.worker_pool.acquire()
            try:
                return await worker.execute(stage)
            finally:
                await self.worker_pool.release(worker)
    
    async def execute_parallel(self, stage):
        shards = self.shard_work(stage)
        tasks = [self.execute_shard(shard) for shard in shards]
        return await asyncio.gather(*tasks)
```

```python
# sim_test_runner.py
class SimTestRunner:
    def __init__(self, determinism_validator):
        self.validator = determinism_validator
        
    async def run_sim_test(self, test_config):
        runs = []
        
        # Execute multiple runs for determinism validation
        for i in range(test_config.determinism_runs):
            run = await self.execute_single_run(
                seed=test_config.seed,
                duration=test_config.duration_ticks,
                worker_id=f"worker-{i}"
            )
            runs.append(run)
        
        # Validate determinism
        report = self.validator.validate(runs)
        
        if not report.deterministic:
            await self.handle_nondeterminism(report)
            
        return report
    
    async def execute_single_run(self, seed, duration, worker_id):
        sim = HeadlessSimulation(seed=seed)
        checksums = []
        
        for tick in range(duration):
            sim.step()
            
            if tick % CHECKSUM_INTERVAL == 0:
                checksum = sim.compute_checksum(level=2)
                checksums.append({"tick": tick, "hash": checksum})
        
        return SimRun(
            worker_id=worker_id,
            final_checksum=checksums[-1]["hash"],
            checksums=checksums,
            duration_ticks=duration
        )
```

```python
# determinism_validator.py
class DeterminismValidator:
    def validate(self, runs: List[SimRun]) -> DeterminismReport:
        checksums = [r.final_checksum for r in runs]
        unique = set(checksums)
        
        report = DeterminismReport(
            deterministic=(len(unique) == 1),
            unique_checksums=len(unique),
            runs=runs
        )
        
        if not report.deterministic:
            report.mismatches = self.find_mismatches(runs)
            report.analysis = self.bisect_divergence(runs)
            
        return report
    
    def bisect_divergence(self, runs: List[SimRun]) -> DivergenceAnalysis:
        # Find first pair with mismatch
        run_a, run_b = self.find_mismatch_pair(runs)
        
        # Binary search for first divergent tick
        tick = self.binary_search_divergence(run_a, run_b)
        
        return DivergenceAnalysis(
            divergence_point=tick,
            state_dumps=self.capture_state_dumps(run_a, run_b, tick)
        )
    
    def binary_search_divergence(self, run_a, run_b, lo=0, hi=None):
        if hi is None:
            hi = len(run_a.checksums)
            
        if hi - lo <= 1:
            return lo
            
        mid = (lo + hi) // 2
        
        if run_a.checksums[mid] == run_b.checksums[mid]:
            return self.binary_search_divergence(run_a, run_b, mid, hi)
        else:
            return self.binary_search_divergence(run_a, run_b, lo, mid)
```

### 11.2 Worker Implementation

```python
# worker.py
class SimulationWorker:
    def __init__(self, worker_id, resource_limits):
        self.id = worker_id
        self.resources = ResourceController(resource_limits)
        self.sim_process = None
        
    async def execute(self, task):
        # Apply resource limits
        await self.resources.apply_limits()
        
        # Start simulation process
        self.sim_process = await asyncio.create_subprocess_exec(
            task.binary_path,
            *task.arguments,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=task.environment
        )
        
        # Stream output
        stdout, stderr = await self.sim_process.communicate()
        
        return TaskResult(
            returncode=self.sim_process.returncode,
            stdout=stdout,
            stderr=stderr,
            artifacts=await self.collect_artifacts()
        )
```

### 11.3 Configuration Implementation

```yaml
# config/worker-pool.yaml
worker_pool:
  min_workers: 4
  max_workers: 64
  scale_up_threshold: 0.8
  scale_down_threshold: 0.3
  
  worker_template:
    image: "ci/sim-worker:v1.2.3"
    resources:
      cpu: 4
      memory: "8Gi"
      disk: "50Gi"
    
  health_check:
    interval: 30s
    timeout: 10s
    failure_threshold: 3
    
  retry_policy:
    max_retries: 3
    backoff: exponential
    initial_delay: 1s

# config/storage.yaml
artifact_storage:
  backend: s3
  bucket: "ci-artifacts"
  region: "us-east-1"
  
  tiers:
    hot:
      storage_class: STANDARD
      retention_days: 7
      max_size: "10GB"
    
    warm:
      storage_class: STANDARD_IA
      retention_days: 30
      transition_after_days: 7
    
    cold:
      storage_class: GLACIER
      retention_days: 365
      transition_after_days: 30
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Complete Pipeline Execution

```
SCENARIO: Developer pushes commit to main branch
─────────────────────────────────────────────────

10:00:00 - Git push detected
           Commit: abc123def456
           Author: dev@example.com
           Message: "Update NPC AI behavior tree"

10:00:01 - Webhook received by CI system
           Pipeline "main-pipeline" triggered
           Pipeline ID: pipe-2024-0115-001

10:00:02 - Pipeline queued
           Position in queue: 1
           Estimated start: immediate

10:00:03 - STAGE: BUILD started
           Workers assigned: 6 (matrix: 3 platforms × 2 configs)
           Timeout: 600s

10:04:15 - BUILD completed
           Duration: 252s
           Artifacts: 18 binaries, compile_commands.json
           Status: SUCCESS

10:04:16 - STAGE: UNIT TEST started
           Test shards: 8
           Tests per shard: ~125
           Timeout: 300s

10:06:42 - UNIT TEST completed
           Duration: 146s
           Tests run: 1000
           Passed: 1000
           Failed: 0
           Coverage: 78.3%
           Status: SUCCESS

10:06:43 - STAGE: SIM TEST started
           Determinism runs: 5
           Scenarios: 12
           Workers: 20 (4 per run × 5 runs)
           Timeout: 1800s

10:18:22 - SIM TEST completed
           Duration: 699s
           Runs executed: 60 (12 scenarios × 5 runs)
           Determinism: 100% (all checksums match)
           Ticks executed: 3,600,000
           Status: SUCCESS

10:18:23 - STAGE: INTEGRATION started
           Test suites: 4
           Timeout: 3600s

10:35:47 - INTEGRATION completed
           Duration: 1044s
           Tests passed: 456
           Tests failed: 0
           Performance regression: +2.1% (within threshold)
           Status: SUCCESS

10:35:48 - STAGE: DEPLOY started
           Deploy target: staging
           Artifacts: 18 binaries

10:36:12 - DEPLOY completed
           Duration: 24s
           Packages deployed: 6
           Status: SUCCESS

10:36:13 - STAGE: REPORT started
           Generating summary report

10:36:15 - REPORT completed
           Duration: 2s
           Report URL: https://ci.example.com/reports/pipe-2024-0115-001

10:36:15 - PIPELINE COMPLETED
           Total duration: 2162s (36m 2s)
           Status: SUCCESS
           All quality gates passed
```

### 12.2 Determinism Failure Scenario

```
SCENARIO: Determinism failure detected and handled
──────────────────────────────────────────────────

11:00:00 - SIM TEST started for commit def789abc012

11:05:23 - Sim test "test_npc_combat" running
           Run 1: Checksum = a1b2c3d4e5f6...
           Run 2: Checksum = a1b2c3d4e5f6...
           Run 3: Checksum = x9y8z7w6v5u4...  <-- MISMATCH!
           Run 4: Checksum = a1b2c3d4e5f6...
           Run 5: Checksum = x9y8z7w6v5u4...  <-- MISMATCH!

11:05:24 - DETERMINISM FAILURE detected
           Unique checksums: 2
           Failure rate: 40% (2/5 runs)

11:05:25 - Bisection started
           Comparing Run 1 (pass) vs Run 3 (fail)
           
11:05:30 - Bisection iteration 1
           Tick 5000: checksums match
           Tick 10000: checksums differ
           
11:05:35 - Bisection iteration 2
           Tick 7500: checksums match
           Tick 8750: checksums differ
           
11:05:40 - Bisection iteration 3
           Tick 8125: checksums match
           Tick 8437: checksums differ
           
11:05:45 - Bisection complete
           First divergent tick: 8437
           
11:05:46 - State dumps captured
           Run 1: state_dump_ref_tick_8437.bin
           Run 3: state_dump_fail_tick_8437.bin
           
11:05:47 - Artifact upload started
           Uploading: sim_traces, state_dumps, checksums
           
11:05:52 - Artifact upload complete
           
11:05:53 - Ticket created
           Ticket ID: CI-2024-001235
           Title: [CI] Determinism failure in test_npc_combat
           Assignee: dev@example.com (commit author)
           Priority: High
           
11:05:54 - Notifications sent
           Slack: #ci-failures
           Email: dev@example.com
           
11:05:55 - Pipeline marked FAILED
           Block merge: YES
           
11:06:00 - Developer notified
           dev@example.com receives ticket notification
```

### 12.3 Operational Commands

```bash
# Trigger manual pipeline run
ci-cli pipeline trigger \
  --branch feature/new-ai \
  --commit abc123 \
  --pipeline main-pipeline

# Check pipeline status
ci-cli pipeline status pipe-2024-0115-001

# View simulation traces
ci-cli artifact download \
  --pipeline pipe-2024-0115-001 \
  --artifact sim_trace_tick_1000.bin \
  --output ./traces/

# Replay simulation for debugging
ci-cli sim replay \
  --trace ./traces/sim_trace.bin \
  --tick 8437 \
  --interactive

# View determinism report
ci-cli report determinism \
  --pipeline pipe-2024-0115-001 \
  --test test_npc_combat

# Scale worker pool
ci-cli workers scale \
  --pool sim-workers \
  --count 32

# Quarantine flaky worker
ci-cli worker quarantine worker-042 \
  --reason "Memory corruption detected"
```

---

## APPENDIX: MATHEMATICAL NOTATION REFERENCE

| Symbol | Meaning |
|--------|---------|
| S | Simulation instance |
| B | Batch of simulations |
| N_workers | Number of parallel workers |
| T_batch | Total batch execution time |
| H(t) | Checksum at tick t |
| Δt | Fixed timestep |
| ε_tolerance | Floating-point tolerance |
| α_util | Target CPU utilization |
| SR | Success rate |
| DR | Determinism rate |

---

*Specification Version: 1.0*
*Last Updated: 2024-01-15*
*Owner: Domain 11 - CI Infrastructure*
