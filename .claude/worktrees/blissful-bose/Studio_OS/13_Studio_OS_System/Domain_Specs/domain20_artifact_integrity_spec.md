---
title: "D20: Artifact Integrity Specification"
type: specification
layer: system
status: active
domain: studio_os
tags:
  - specification
  - domain
  - studio_os
depends_on: []
used_by: []
---

# Domain 20: Artifact Integrity Validation Layer Specification
## AI-Native Game Studio OS - Comprehensive Technical Specification

---

## 1. INTEGRITY CHECK ALGORITHMS

### 1.1 SHA-256 Cryptographic Hashing
```
H: {0,1}* → {0,1}^256
H(m) = Σ_{i=0}^{15} h_i · 2^{16i} where h_i ∈ [0, 65535]

Algorithm SHA256_FILE(file):
    Input: file path P
    Output: 64-character hex digest D
    
    1. Initialize hash state S ← SHA256_INIT()
    2. For each chunk C in READ_CHUNKS(P, 65536):
       S ← SHA256_UPDATE(S, C)
    3. D ← SHA256_FINAL(S)
    4. Return D

Complexity: O(n) where n = |file| in bytes
Memory: O(1) - fixed 256-bit state + 64KB buffer
```

### 1.2 Merkle Tree for Bundle Integrity
```
MerkleTree(T) where T = {t_1, t_2, ..., t_n} artifacts

Construction:
    Level 0 (leaves): L_0 = {H(t_i) | i ∈ [1,n]}
    Level k: L_k = {H(L_{k-1}[2j] || L_{k-1}[2j+1]) | j ∈ [0, |L_{k-1}|/2)}
    Root: R = L_{⌈log₂n⌉}[0]

Verification Path:
    Path(t_i) = {sibling_hash_at_each_level}
    Verify(t_i, Path) = (Root' == Root)

Properties:
    - Inclusion proof: O(log n)
    - Batch verification: O(1) per additional item
    - Tamper detection: Any bit flip → root mismatch
```

### 1.3 Checksum Validation Matrix
| Checksum Type | Algorithm | Bit Width | Use Case |
|--------------|-----------|-----------|----------|
| Fast Check | CRC32 | 32 | Runtime streaming |
| Standard | SHA-256 | 256 | Artifact verification |
| High Security | SHA-3-256 | 256 | Signed releases |
| Legacy | MD5 | 128 | Compatibility only |

---

## 2. SHA-256 HASHING REQUIREMENTS

### 2.1 Artifact Type Hashing Matrix

| ArtifactType | HashLocation | ValidationFreq | Encoding | BlockSize |
|--------------|--------------|----------------|----------|-----------|
| Markdown | `manifest.json:artifacts[].hash` | On change (Δt < 100ms) | hex | 64KB |
| JSON | `._integrity.sha256` embedded | On load (pre-parse) | base64 | Full file |
| Binary | `.sha256` sidecar file | On deploy (pre-transfer) | hex | 1MB |
| Image | EXIF:UserComment | On render (lazy) | base64 | Stream |
| Audio | ID3:TXXX:integrity | On decode | hex | 256KB |
| Video | manifest + segment hashes | On segment fetch | hex | 2MB |
| Archive | Central directory record | On extract | hex | 4MB |
| Database | WAL checksum pages | On commit | CRC+SHA | Page size |

### 2.2 Hash Computation Protocol
```python
HASH_PROTOCOL = {
    "preprocessing": {
        "normalize_line_endings": True,   # CRLF → LF
        "strip_bom": True,                # Remove UTF-8 BOM
        "sort_json_keys": True,           # Canonical JSON
        "exclude_fields": ["_integrity", "_metadata", "_signature"]
    },
    "computation": {
        "algorithm": "SHA-256",
        "output_format": "hex",           # or "base64"
        "chunk_size": 65536,              # bytes
        "parallel_threshold": 10485760    # 10MB → parallel hash
    },
    "storage": {
        "prefix": "sha256:",              # Algorithm identifier
        "case": "lowercase",
        "encoding": "utf-8"
    }
}
```

### 2.3 Parallel Hashing for Large Files
```
PARALLEL_HASH(file, k threads):
    n ← |file|
    chunk_size ← ⌈n/k⌉
    
    For i ∈ [0, k-1] in parallel:
        start ← i × chunk_size
        end ← min((i+1) × chunk_size, n)
        h_i ← SHA256(file[start:end])
    
    Return SHA256(h_0 || h_1 || ... || h_{k-1})
```

---

## 3. MANIFEST VALIDATION RULES

### 3.1 Manifest Schema v1.0
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "manifest": {
    "version": "1.0.0",
    "created_at": "2024-01-15T09:30:00Z",
    "generator": "aigs-os-integrity@v2.1.0",
    
    "artifacts": [
      {
        "path": "docs/design.md",
        "hash": "sha256:a1b2c3d4e5f6...",
        "size": 15420,
        "mimetype": "text/markdown",
        "modified": "2024-01-15T09:25:00Z",
        "dependencies": ["assets/logo.png"]
      }
    ],
    
    "bundles": [
      {
        "name": "core-assets",
        "merkle_root": "sha256:deadbeef...",
        "artifacts": ["path1", "path2"],
        "compression": "zstd"
      }
    ],
    
    "signature": {
      "alg": "Ed25519",
      "pubkey": "base64:...",
      "sig": "base64:...",
      "timestamp": 1705312200
    }
  }
}
```

### 3.2 Validation Rule Engine
```
RULESET ManifestValidation:
    
    R1: Schema Compliance
        ∀k ∈ manifest.keys(): k ∈ SCHEMA.required ∪ SCHEMA.optional
        manifest.version MATCHES /^\d+\.\d+\.\d+$/
        
    R2: Hash Format Validation
        ∀a ∈ manifest.artifacts:
            a.hash MATCHES /^sha256:[a-f0-9]{64}$/
            
    R3: Path Sanitization
        ∀a ∈ manifest.artifacts:
            NOT a.path CONTAINS ".."
            NOT a.path STARTSWITH "/"
            a.path MATCHES /^[a-zA-Z0-9_\-\.\/]+$/
            
    R4: Size Consistency
        ∀a ∈ manifest.artifacts:
            file(a.path).size == a.size
            
    R5: Temporal Validity
        manifest.created_at ≤ NOW()
        manifest.signature.timestamp ∈ [NOW()-Δt, NOW()+Δt]
        
    R6: Dependency Acyclicity
        G = (V=artifacts, E=dependencies)
        ASSERT is_dag(G)  # No circular dependencies
        
    R7: Signature Verification
        VERIFY(manifest.signature.pubkey,
               CANONICALIZE(manifest - signature),
               manifest.signature.sig) == TRUE
```

### 3.3 Validation Severity Levels
| Code | Severity | Rule | Auto-Repair |
|------|----------|------|-------------|
| V001 | CRITICAL | Signature invalid | No - reject |
| V002 | CRITICAL | Schema violation | No - reject |
| V003 | HIGH | Hash mismatch | Yes - recompute |
| V004 | HIGH | Size mismatch | Yes - update manifest |
| V005 | MEDIUM | Missing dependency | Yes - fetch from registry |
| V006 | MEDIUM | Timestamp drift | Yes - warn + accept |
| V007 | LOW | Unknown artifact field | Yes - ignore |
| V008 | INFO | Outdated format | Yes - migrate |

---

## 4. DEPENDENCY VERIFICATION

### 4.1 Dependency Graph Model
```
DependencyGraph = (A, D, V, C)

Where:
    A = Set of artifacts {a₁, a₂, ..., aₙ}
    D ⊆ A × A = Dependency relations (aᵢ depends on aⱼ)
    V: A → Hash = Version function (content-addressed)
    C: A → 2^A = Closure function (transitive deps)

Properties:
    - Acyclic: ∀a ∈ A: a ∉ C(a)  # No self-dependency cycles
    - Deterministic: V(a) = V(a') ⟹ C(a) = C(a')
    - Monotonic: a' ⊇ a ⟹ V(a') ≠ V(a)
```

### 4.2 Dependency Resolution Algorithm
```
RESOLVE(root_artifact, registry):
    resolved ← ∅
    queue ← [root_artifact]
    conflicts ← ∅
    
    While queue ≠ ∅:
        current ← DEQUEUE(queue)
        
        If current.hash ∈ resolved:
            If resolved[current.hash].version ≠ current.version:
                CONFLICTS.ADD({current, resolved[current.hash]})
            Continue
            
        manifest ← registry.FETCH(current.hash)
        
        If manifest IS NULL:
            ERROR("Missing dependency: " + current.hash)
            
        If NOT VERIFY_HASH(manifest, current.expected_hash):
            ERROR("Dependency hash mismatch: " + current.path)
            
        resolved[current.hash] ← manifest
        
        For dep IN manifest.dependencies:
            ENQUEUE(queue, dep)
    
    Return (resolved, conflicts)
```

### 4.3 Dependency Lock File Format
```json
{
  "lock_version": "2.0",
  "resolved_at": "2024-01-15T10:00:00Z",
  "root": "sha256:abc123...",
  "dependencies": {
    "sha256:abc123...": {
      "path": "lib/core.lua",
      "source": "registry://aigs-libs/core/v1.2.3",
      "hash": "sha256:abc123...",
      "deps": ["sha256:def456..."]
    },
    "sha256:def456...": {
      "path": "lib/utils.lua",
      "source": "registry://aigs-libs/utils/v2.0.1",
      "hash": "sha256:def456...",
      "deps": []
    }
  },
  "integrity": {
    "merkle_root": "sha256:deadbeef...",
    "algorithm": "sha256"
  }
}
```

### 4.4 Version Constraint Resolution
| Constraint | Semantics | Satisfied By |
|------------|-----------|--------------|
| `=1.2.3` | Exact | Only 1.2.3 |
| `^1.2.3` | Compatible | 1.x.x where x ≥ 2.3 |
| `~1.2.3` | Approximately | 1.2.x where x ≥ 3 |
| `>=1.2.3` | Minimum | Any ≥ 1.2.3 |
| `1.2.3 <= 2.0.0` | Range | [1.2.3, 2.0.0] |
| `*` | Wildcard | Any version |

---

## 5. CORRUPTION DETECTION

### 5.1 Detection Model
```
Corruption Detection Framework:

Let:
    F = File system state
    M = Manifest state
    H = Hash function
    
Detection Predicate:
    CORRUPTED(f) ⟺ H(f) ≠ M.hash(f) ∨ |f| ≠ M.size(f)
    
Corruption Types:
    T1: Bit rot (single bit flip)      P ≈ 10⁻¹⁵ per bit-year
    T2: Silent data corruption (block)  P ≈ 10⁻¹⁸ per byte
    T3: Malicious tampering             Detection: signature fail
    T4: Partial write (crash)           Detection: size mismatch
    T5: Metadata corruption             Detection: parse fail
```

### 5.2 Detection Algorithms
```
ALGORITHM DetectCorruption(artifact, manifest):
    # Phase 1: Metadata Check
    If NOT EXISTS(artifact.path):
        Return (MISSING, "File not found")
        
    actual_size ← STAT(artifact.path).size
    If actual_size ≠ manifest.size:
        Return (SIZE_MISMATCH, {expected: manifest.size, actual: actual_size})
    
    # Phase 2: Fast Checksum (optional)
    If manifest.crc32 IS NOT NULL:
        actual_crc ← CRC32(artifact.path)
        If actual_crc ≠ manifest.crc32:
            Return (CRC_MISMATCH, {expected: manifest.crc32, actual: actual_crc})
    
    # Phase 3: Cryptographic Hash
    actual_hash ← SHA256(artifact.path)
    If actual_hash ≠ manifest.hash:
        Return (HASH_MISMATCH, {expected: manifest.hash, actual: actual_hash})
    
    Return (VALID, nil)

ALGORITHM DetectCorruptionBatch(artifacts, parallel=True):
    If parallel:
        results ← PARALLEL_MAP(DetectCorruption, artifacts, n_workers=8)
    Else:
        results ← MAP(DetectCorruption, artifacts)
    
    corrupted ← FILTER(results, r → r.status ≠ VALID)
    Return corrupted
```

### 5.3 Continuous Integrity Monitoring
```
MONITORING_CONFIG = {
    "watch_mode": "inotify",      # inotify | fsevents | polling
    "polling_interval_ms": 5000,   # For polling mode
    "debounce_ms": 100,            # Coalesce rapid changes
    "verify_on_change": True,
    "background_scan": {
        "enabled": True,
        "interval_hours": 24,
        "throttle_mbps": 100
    }
}

EVENT_HANDLER(event):
    Switch event.type:
        Case MODIFY:
            If event.path IN manifest.artifacts:
                result ← DetectCorruption(event.path, manifest)
                If result.status ≠ VALID:
                    TRIGGER("integrity.violation", result)
                    
        Case DELETE:
            If event.path IN manifest.artifacts:
                TRIGGER("integrity.missing", event.path)
                
        Case CREATE:
            If event.path NOT IN manifest.artifacts:
                TRIGGER("integrity.unknown", event.path)
```

### 5.4 Corruption Detection Matrix
| Detection Method | Coverage | Latency | Overhead | Accuracy |
|-----------------|----------|---------|----------|----------|
| On-access | Read operations | Immediate | None | 100% |
| Periodic scan | All artifacts | Hours | Medium | 100% |
| Real-time watch | Watched paths | <100ms | Low | 100% |
| Sampling | Random subset | Minutes | Low | Statistical |
| Merkle sync | Bundle roots | On sync | Low | 100% |

---

## 6. REPAIR PROCEDURES

### 6.1 Repair Strategy Decision Tree
```
REPAIR(artifact, failure_type, context):
    
    If failure_type == MISSING:
        If context.backup_available:
            RETURN RestoreFromBackup(artifact)
        If context.registry_available:
            RETURN FetchFromRegistry(artifact.hash)
        RETURN ERROR("Cannot repair: no source available")
        
    If failure_type == HASH_MISMATCH:
        If context.allow_rebuild:
            RETURN RebuildArtifact(artifact)
        If context.has_version_control:
            RETURN RestoreFromVCS(artifact.path)
        RETURN RestoreFromBackup(artifact)
        
    If failure_type == SIZE_MISMATCH:
        # Truncated or extended file
        If context.partial_recovery:
            RETURN AttemptPartialRecovery(artifact)
        RETURN FullRestore(artifact)
        
    If failure_type == SIGNATURE_INVALID:
        # Security violation - do not auto-repair
        RETURN ERROR("Security violation: manual intervention required")
```

### 6.2 Repair Procedures Specification
```
PROCEDURE RestoreFromBackup(artifact):
    backup_path ← LOOKUP_BACKUP(artifact.hash)
    
    If backup_path IS NULL:
        Return (FAILED, "No backup found for hash")
        
    If VERIFY_HASH(backup_path, artifact.expected_hash):
        ATOMIC_REPLACE(artifact.path, backup_path)
        Return (SUCCESS, "Restored from backup")
    Else:
        Return (FAILED, "Backup also corrupted")

PROCEDURE FetchFromRegistry(artifact_hash, registry):
    sources ← registry.LOOKUP(artifact_hash)
    
    For source IN sources ORDER BY latency:
        Try:
            data ← HTTP_GET(source.url)
            If SHA256(data) == artifact_hash:
                ATOMIC_WRITE(artifact.path, data)
                Return (SUCCESS, "Fetched from " + source.url)
        Catch e:
            CONTINUE
            
    Return (FAILED, "All registry sources failed")

PROCEDURE RebuildArtifact(artifact, build_system):
    If NOT EXISTS(artifact.build_script):
        Return (FAILED, "No build script available")
        
    result ← build_system.EXECUTE(artifact.build_script)
    
    If result.exit_code ≠ 0:
        Return (FAILED, "Build failed: " + result.stderr)
        
    built_hash ← SHA256(result.output_path)
    
    If built_hash ≠ artifact.expected_hash:
        Return (FAILED, "Build reproducibility failure")
        
    ATOMIC_REPLACE(artifact.path, result.output_path)
    Return (SUCCESS, "Rebuilt successfully")

PROCEDURE AttemptPartialRecovery(artifact, known_good_regions):
    fd ← OPEN(artifact.path, READWRITE)
    
    For region IN ScanCorruption(fd):
        If region IN known_good_regions:
            WRITE(fd, region.offset, known_good_regions[region])
        Else:
            # Mark as unrecoverable
            TRIGGER("partial_recovery.failed_region", region)
    
    CLOSE(fd)
    Return (PARTIAL, "Partial recovery completed")
```

### 6.3 Repair Verification
```
VERIFY_REPAIR(artifact, original_manifest):
    # Post-repair validation
    new_hash ← SHA256(artifact.path)
    
    If new_hash ≠ original_manifest.hash:
        Return (FAILED, "Repair verification failed")
        
    # Extended validation
    If artifact.type == "executable":
        If NOT TEST_RUN(artifact.path, timeout=5s):
            Return (FAILED, "Executable test failed")
            
    If artifact.type == "json":
        If NOT JSON_PARSE(artifact.path):
            Return (FAILED, "JSON parse failed")
            
    Return (SUCCESS, "Repair verified")
```

### 6.4 Repair Escalation Matrix
| Failure | Primary Repair | Secondary | Tertiary | Escalation |
|---------|---------------|-----------|----------|------------|
| Missing | Registry fetch | Backup restore | Rebuild | Manual |
| Hash mismatch | Backup restore | Registry fetch | Rebuild | Manual |
| Size mismatch | Full restore | Partial recovery | - | Manual |
| Signature fail | - | - | - | Security team |
| Parse fail | Format recovery | Backup restore | - | Manual |

---

## 7. SUCCESS CRITERIA (Measurable)

### 7.1 Quantitative Metrics
```
METRIC IntegrityCoverage:
    Definition: Percentage of artifacts with verified hashes
    Formula: |{a ∈ A : verified(a)}| / |A| × 100%
    Target: ≥ 99.9%
    Measurement: Continuous
    
METRIC DetectionLatency:
    Definition: Time from corruption to detection
    Formula: t_detection - t_corruption
    Target: P95 < 5 seconds (real-time), P95 < 24 hours (batch)
    Measurement: Synthetic corruption injection
    
METRIC FalsePositiveRate:
    Definition: Valid artifacts flagged as corrupt
    Formula: |false_positives| / |total_checks| × 100%
    Target: < 0.001%
    Measurement: Audit logs
    
METRIC RepairSuccessRate:
    Definition: Successful repairs / total repair attempts
    Formula: |successful_repairs| / |repair_attempts| × 100%
    Target: ≥ 95%
    Measurement: Repair log analysis
    
METRIC MeanTimeToRepair:
    Definition: Average time to restore integrity
    Formula: Σ(t_repair_complete - t_detected) / |repairs|
    Target: P95 < 60 seconds
    Measurement: Repair telemetry
    
METRIC HashComputationThroughput:
    Definition: Data hashed per unit time
    Formula: total_bytes_hashed / total_time_seconds
    Target: ≥ 500 MB/s (single thread), ≥ 2 GB/s (parallel)
    Measurement: Benchmark suite
```

### 7.2 Success Criteria Matrix
| Criterion | Metric | Threshold | Critical |
|-----------|--------|-----------|----------|
| Coverage | IntegrityCoverage | ≥ 99.9% | Yes |
| Speed | DetectionLatency | P95 < 5s | Yes |
| Accuracy | FalsePositiveRate | < 0.001% | Yes |
| Reliability | RepairSuccessRate | ≥ 95% | Yes |
| Performance | HashComputationThroughput | ≥ 500 MB/s | No |
| Completeness | ManifestValidationPass | 100% | Yes |
| Security | SignatureVerificationPass | 100% | Yes |
| Consistency | DependencyResolutionPass | 100% | Yes |

### 7.3 SLA Definitions
```
SLA_TIERS = {
    "critical": {
        "artifacts": ["executables", "manifests", "signatures"],
        "detection_slo": "< 1 second",
        "repair_slo": "< 30 seconds",
        "availability": "99.999%"
    },
    "standard": {
        "artifacts": ["configs", "assets", "data"],
        "detection_slo": "< 5 minutes",
        "repair_slo": "< 5 minutes",
        "availability": "99.9%"
    },
    "background": {
        "artifacts": ["logs", "caches", "temp"],
        "detection_slo": "< 24 hours",
        "repair_slo": "best effort",
        "availability": "99%"
    }
}
```

---

## 8. FAILURE STATES

### 8.1 Failure Classification
```
FAILURE_TYPES = {
    # Integrity Failures
    "F001": {
        "name": "HASH_MISMATCH",
        "severity": "CRITICAL",
        "description": "Computed hash differs from manifest",
        "auto_repair": True,
        "escalation": None
    },
    "F002": {
        "name": "SIGNATURE_INVALID",
        "severity": "CRITICAL",
        "description": "Cryptographic signature verification failed",
        "auto_repair": False,
        "escalation": "security_team"
    },
    "F003": {
        "name": "MANIFEST_CORRUPT",
        "severity": "CRITICAL",
        "description": "Manifest file itself is corrupted",
        "auto_repair": False,
        "escalation": "admin"
    },
    
    # Dependency Failures
    "F004": {
        "name": "DEPENDENCY_MISSING",
        "severity": "HIGH",
        "description": "Required dependency not found",
        "auto_repair": True,
        "escalation": None
    },
    "F005": {
        "name": "DEPENDENCY_CYCLE",
        "severity": "HIGH",
        "description": "Circular dependency detected",
        "auto_repair": False,
        "escalation": "dev_team"
    },
    "F006": {
        "name": "VERSION_CONFLICT",
        "severity": "MEDIUM",
        "description": "Multiple versions of same dependency required",
        "auto_repair": True,
        "escalation": None
    },
    
    # System Failures
    "F007": {
        "name": "REGISTRY_UNAVAILABLE",
        "severity": "HIGH",
        "description": "Cannot contact artifact registry",
        "auto_repair": False,
        "escalation": "ops_team"
    },
    "F008": {
        "name": "INSUFFICIENT_STORAGE",
        "severity": "HIGH",
        "description": "Not enough space for repair operations",
        "auto_repair": False,
        "escalation": "ops_team"
    },
    "F009": {
        "name": "PERMISSION_DENIED",
        "severity": "MEDIUM",
        "description": "Cannot access artifact for verification",
        "auto_repair": False,
        "escalation": "admin"
    },
    
    # Transient Failures
    "F010": {
        "name": "TIMEOUT",
        "severity": "LOW",
        "description": "Operation exceeded time limit",
        "auto_repair": True,
        "escalation": None
    },
    "F011": {
        "name": "NETWORK_ERROR",
        "severity": "LOW",
        "description": "Temporary network failure",
        "auto_repair": True,
        "escalation": None
    }
}
```

### 8.2 Failure State Machine
```
States: IDLE → VERIFYING → [VALID | CORRUPTED | ERROR]
                      ↓
                REPAIRING → [REPAIRED | REPAIR_FAILED]
                      ↓
                ESCALATED → [RESOLVED | UNRESOLVED]

Transitions:
    VERIFYING → VALID:       hash_match ∧ signature_valid
    VERIFYING → CORRUPTED:   hash_mismatch ∨ size_mismatch
    VERIFYING → ERROR:       io_error ∨ timeout
    CORRUPTED → REPAIRING:   auto_repair_enabled
    CORRUPTED → ESCALATED:   ¬auto_repair_enabled
    REPAIRING → REPAIRED:    verify_repair_success
    REPAIRING → REPAIR_FAILED: repair_attempts > max
    REPAIR_FAILED → ESCALATED: always
```

### 8.3 Failure Recovery Procedures
```
RECOVERY_PROCEDURES = {
    "HASH_MISMATCH": {
        "immediate": "Quarantine artifact",
        "assessment": "Check backup availability",
        "action": "Restore from backup or registry",
        "verification": "Re-hash and compare",
        "rollback": "Restore original if repair fails"
    },
    "SIGNATURE_INVALID": {
        "immediate": "HALT - Do not proceed",
        "assessment": "Security team investigation",
        "action": "Manual verification required",
        "verification": "Out-of-band key verification",
        "rollback": "N/A - Security incident"
    },
    "DEPENDENCY_CYCLE": {
        "immediate": "Log cycle details",
        "assessment": "Analyze dependency graph",
        "action": "Manual dependency restructuring",
        "verification": "Re-run cycle detection",
        "rollback": "Revert to last known good state"
    }
}
```

---

## 9. INTEGRATION SURFACE

### 9.1 API Interface Definition
```protobuf
syntax = "proto3";

service IntegrityService {
    // Core verification
    rpc VerifyArtifact(VerifyRequest) returns (VerifyResponse);
    rpc VerifyBundle(BundleVerifyRequest) returns (BundleVerifyResponse);
    rpc VerifyManifest(ManifestVerifyRequest) returns (ManifestVerifyResponse);
    
    // Batch operations
    rpc BatchVerify(BatchVerifyRequest) returns (stream BatchVerifyResponse);
    
    // Repair operations
    rpc RepairArtifact(RepairRequest) returns (RepairResponse);
    rpc GetRepairStatus(RepairStatusRequest) returns (RepairStatusResponse);
    
    // Monitoring
    rpc StreamIntegrityEvents(EventFilter) returns (stream IntegrityEvent);
    rpc GetIntegrityReport(ReportRequest) returns (IntegrityReport);
    
    // Management
    rpc RegisterArtifact(RegisterRequest) returns (RegisterResponse);
    rpc UpdateManifest(UpdateManifestRequest) returns (UpdateManifestResponse);
}

message VerifyRequest {
    string artifact_path = 1;
    string expected_hash = 2;
    HashAlgorithm algorithm = 3;
}

message VerifyResponse {
    VerificationStatus status = 1;
    string computed_hash = 2;
    int64 verification_time_ms = 3;
    string error_message = 4;
}

enum VerificationStatus {
    VALID = 0;
    INVALID_HASH = 1;
    INVALID_SIZE = 2;
    MISSING = 3;
    PERMISSION_DENIED = 4;
    ERROR = 5;
}
```

### 9.2 REST API Endpoints
```yaml
openapi: 3.0.0
info:
  title: Artifact Integrity API
  version: 1.0.0

paths:
  /api/v1/integrity/verify:
    post:
      summary: Verify single artifact
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                path: { type: string }
                hash: { type: string }
      responses:
        200:
          description: Verification result
          content:
            application/json:
              schema:
                type: object
                properties:
                  valid: { type: boolean }
                  computed_hash: { type: string }
                  duration_ms: { type: integer }

  /api/v1/integrity/verify/batch:
    post:
      summary: Batch verify artifacts
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                artifacts:
                  type: array
                  items:
                    type: object
                    properties:
                      path: { type: string }
                      hash: { type: string }
      responses:
        200:
          description: Batch results
          content:
            application/json:
              schema:
                type: object
                properties:
                  total: { type: integer }
                  valid: { type: integer }
                  invalid: { type: integer }
                  results:
                    type: array
                    items:
                      type: object
                      properties:
                        path: { type: string }
                        valid: { type: boolean }
                        error: { type: string }

  /api/v1/integrity/repair:
    post:
      summary: Repair corrupted artifact
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                path: { type: string }
                source: { type: string, enum: [auto, backup, registry, rebuild] }
      responses:
        200:
          description: Repair result
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  method: { type: string }
                  duration_ms: { type: integer }

  /api/v1/integrity/manifest:
    get:
      summary: Get manifest for path
      parameters:
        - name: path
          in: query
          schema: { type: string }
    put:
      summary: Update manifest
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Manifest'

  /api/v1/integrity/events:
    get:
      summary: Stream integrity events (SSE)
      responses:
        200:
          description: Server-sent events stream
          content:
            text/event-stream:
              schema:
                type: string
```

### 9.3 Event Interface
```typescript
// Event Types
interface IntegrityEvent {
    timestamp: number;           // Unix timestamp (ms)
    event_type: IntegrityEventType;
    severity: 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
    artifact_path?: string;
    details: Record<string, unknown>;
    correlation_id: string;
}

type IntegrityEventType =
    | 'ARTIFACT_VERIFIED'
    | 'ARTIFACT_CORRUPTED'
    | 'ARTIFACT_REPAIRED'
    | 'ARTIFACT_MISSING'
    | 'MANIFEST_UPDATED'
    | 'SIGNATURE_INVALID'
    | 'DEPENDENCY_RESOLVED'
    | 'DEPENDENCY_CONFLICT'
    | 'SCAN_STARTED'
    | 'SCAN_COMPLETED'
    | 'REPAIR_STARTED'
    | 'REPAIR_FAILED'
    | 'REGISTRY_SYNC';

// Event subscription
interface EventFilter {
    event_types?: IntegrityEventType[];
    severity_min?: 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
    artifact_paths?: string[];
    since_timestamp?: number;
}
```

### 9.4 Integration Points
| System | Interface | Direction | Purpose |
|--------|-----------|-----------|---------|
| Build System | gRPC | Incoming | Post-build verification |
| Deployment | REST API | Incoming | Pre-deploy checks |
| Registry | gRPC | Outgoing | Artifact fetch/verify |
| Monitoring | SSE | Outgoing | Event streaming |
| Storage | Native | Bidirectional | File operations |
| VCS | REST | Outgoing | Version recovery |
| Security | gRPC | Outgoing | Signature verification |

---

## 10. JSON SCHEMAS

### 10.1 Manifest Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigs.io/schemas/manifest-v1.json",
  "title": "Artifact Manifest",
  "type": "object",
  "required": ["version", "created_at", "artifacts"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "generator": {
      "type": "string",
      "pattern": "^[a-z0-9-]+@v\\d+\\.\\d+\\.\\d+$"
    },
    "artifacts": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/ArtifactEntry"
      },
      "minItems": 1
    },
    "bundles": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/BundleEntry"
      }
    },
    "signature": {
      "$ref": "#/definitions/Signature"
    }
  },
  "definitions": {
    "ArtifactEntry": {
      "type": "object",
      "required": ["path", "hash"],
      "properties": {
        "path": {
          "type": "string",
          "pattern": "^[a-zA-Z0-9_\\-\\.\\/]+$"
        },
        "hash": {
          "type": "string",
          "pattern": "^sha256:[a-f0-9]{64}$"
        },
        "size": {
          "type": "integer",
          "minimum": 0
        },
        "mimetype": {
          "type": "string"
        },
        "modified": {
          "type": "string",
          "format": "date-time"
        },
        "dependencies": {
          "type": "array",
          "items": { "type": "string" }
        },
        "metadata": {
          "type": "object"
        }
      }
    },
    "BundleEntry": {
      "type": "object",
      "required": ["name", "merkle_root", "artifacts"],
      "properties": {
        "name": { "type": "string" },
        "merkle_root": {
          "type": "string",
          "pattern": "^sha256:[a-f0-9]{64}$"
        },
        "artifacts": {
          "type": "array",
          "items": { "type": "string" }
        },
        "compression": {
          "type": "string",
          "enum": ["none", "gzip", "zstd", "lz4"]
        }
      }
    },
    "Signature": {
      "type": "object",
      "required": ["alg", "pubkey", "sig"],
      "properties": {
        "alg": {
          "type": "string",
          "enum": ["Ed25519", "ECDSA-P256", "RSA-PSS-2048"]
        },
        "pubkey": {
          "type": "string",
          "pattern": "^base64:[A-Za-z0-9+/=]+$"
        },
        "sig": {
          "type": "string",
          "pattern": "^base64:[A-Za-z0-9+/=]+$"
        },
        "timestamp": {
          "type": "integer",
          "minimum": 0
        }
      }
    }
  }
}
```

### 10.2 Lock File Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigs.io/schemas/lockfile-v2.json",
  "title": "Dependency Lock File",
  "type": "object",
  "required": ["lock_version", "resolved_at", "root", "dependencies"],
  "properties": {
    "lock_version": {
      "type": "string",
      "const": "2.0"
    },
    "resolved_at": {
      "type": "string",
      "format": "date-time"
    },
    "root": {
      "type": "string",
      "pattern": "^sha256:[a-f0-9]{64}$"
    },
    "dependencies": {
      "type": "object",
      "patternProperties": {
        "^sha256:[a-f0-9]{64}$": {
          "$ref": "#/definitions/DependencyEntry"
        }
      },
      "additionalProperties": false
    },
    "integrity": {
      "type": "object",
      "required": ["merkle_root", "algorithm"],
      "properties": {
        "merkle_root": {
          "type": "string",
          "pattern": "^sha256:[a-f0-9]{64}$"
        },
        "algorithm": {
          "type": "string",
          "const": "sha256"
        }
      }
    }
  },
  "definitions": {
    "DependencyEntry": {
      "type": "object",
      "required": ["path", "source", "hash"],
      "properties": {
        "path": { "type": "string" },
        "source": {
          "type": "string",
          "pattern": "^[a-z]+://.+$"
        },
        "hash": {
          "type": "string",
          "pattern": "^sha256:[a-f0-9]{64}$"
        },
        "deps": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^sha256:[a-f0-9]{64}$"
          }
        }
      }
    }
  }
}
```

### 10.3 Verification Report Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigs.io/schemas/verification-report-v1.json",
  "title": "Integrity Verification Report",
  "type": "object",
  "required": ["report_id", "generated_at", "summary", "results"],
  "properties": {
    "report_id": {
      "type": "string",
      "format": "uuid"
    },
    "generated_at": {
      "type": "string",
      "format": "date-time"
    },
    "manifest_hash": {
      "type": "string",
      "pattern": "^sha256:[a-f0-9]{64}$"
    },
    "summary": {
      "type": "object",
      "required": ["total", "valid", "invalid", "missing"],
      "properties": {
        "total": { "type": "integer", "minimum": 0 },
        "valid": { "type": "integer", "minimum": 0 },
        "invalid": { "type": "integer", "minimum": 0 },
        "missing": { "type": "integer", "minimum": 0 },
        "duration_ms": { "type": "integer", "minimum": 0 }
      }
    },
    "results": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/VerificationResult"
      }
    }
  },
  "definitions": {
    "VerificationResult": {
      "type": "object",
      "required": ["path", "status"],
      "properties": {
        "path": { "type": "string" },
        "status": {
          "type": "string",
          "enum": ["VALID", "INVALID_HASH", "INVALID_SIZE", "MISSING", "ERROR"]
        },
        "expected_hash": { "type": "string" },
        "computed_hash": { "type": "string" },
        "expected_size": { "type": "integer" },
        "actual_size": { "type": "integer" },
        "verification_time_ms": { "type": "integer" },
        "error_message": { "type": "string" }
      }
    }
  }
}
```

### 10.4 Event Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigs.io/schemas/integrity-event-v1.json",
  "title": "Integrity Event",
  "type": "object",
  "required": ["timestamp", "event_type", "severity", "correlation_id"],
  "properties": {
    "timestamp": {
      "type": "integer",
      "minimum": 0
    },
    "event_type": {
      "type": "string",
      "enum": [
        "ARTIFACT_VERIFIED",
        "ARTIFACT_CORRUPTED",
        "ARTIFACT_REPAIRED",
        "ARTIFACT_MISSING",
        "MANIFEST_UPDATED",
        "SIGNATURE_INVALID",
        "DEPENDENCY_RESOLVED",
        "DEPENDENCY_CONFLICT",
        "SCAN_STARTED",
        "SCAN_COMPLETED",
        "REPAIR_STARTED",
        "REPAIR_FAILED",
        "REGISTRY_SYNC"
      ]
    },
    "severity": {
      "type": "string",
      "enum": ["INFO", "WARN", "ERROR", "CRITICAL"]
    },
    "artifact_path": { "type": "string" },
    "details": { "type": "object" },
    "correlation_id": {
      "type": "string",
      "format": "uuid"
    }
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Hash Engine
```python
class HashEngine:
    """Cryptographic hash computation engine"""
    
    ALGORITHMS = {
        'sha256': hashlib.sha256,
        'sha3_256': hashlib.sha3_256,
        'blake2b': lambda: hashlib.blake2b(digest_size=32)
    }
    
    CHUNK_SIZE = 65536  # 64KB
    PARALLEL_THRESHOLD = 10 * 1024 * 1024  # 10MB
    
    def __init__(self, algorithm: str = 'sha256'):
        self.algorithm = algorithm
        self.hasher_class = self.ALGORITHMS[algorithm]
    
    def hash_file(self, path: str) -> str:
        """Compute hash of file at path"""
        size = os.path.getsize(path)
        
        if size > self.PARALLEL_THRESHOLD:
            return self._parallel_hash(path, size)
        
        hasher = self.hasher_class()
        with open(path, 'rb') as f:
            while chunk := f.read(self.CHUNK_SIZE):
                hasher.update(chunk)
        
        return f"{self.algorithm}:{hasher.hexdigest()}"
    
    def _parallel_hash(self, path: str, size: int, workers: int = 4) -> str:
        """Parallel hash for large files"""
        chunk_size = (size + workers - 1) // workers
        
        def hash_chunk(start: int, end: int) -> bytes:
            hasher = self.hasher_class()
            with open(path, 'rb') as f:
                f.seek(start)
                remaining = end - start
                while remaining > 0:
                    to_read = min(self.CHUNK_SIZE, remaining)
                    hasher.update(f.read(to_read))
                    remaining -= to_read
            return hasher.digest()
        
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = []
            for i in range(workers):
                start = i * chunk_size
                end = min((i + 1) * chunk_size, size)
                futures.append(executor.submit(hash_chunk, start, end))
            
            chunk_hashes = [f.result() for f in futures]
        
        # Combine chunk hashes
        final_hasher = self.hasher_class()
        for h in chunk_hashes:
            final_hasher.update(h)
        
        return f"{self.algorithm}:{final_hasher.hexdigest()}"
    
    def hash_bytes(self, data: bytes) -> str:
        """Compute hash of byte string"""
        hasher = self.hasher_class()
        hasher.update(data)
        return f"{self.algorithm}:{hasher.hexdigest()}"
    
    def verify_file(self, path: str, expected_hash: str) -> bool:
        """Verify file against expected hash"""
        computed = self.hash_file(path)
        return computed.lower() == expected_hash.lower()
```

### 11.2 Manifest Manager
```python
class ManifestManager:
    """Manifest creation, validation, and management"""
    
    SCHEMA_VERSION = "1.0.0"
    
    def __init__(self, hash_engine: HashEngine):
        self.hash_engine = hash_engine
        self.validator = self._load_schema_validator()
    
    def create_manifest(
        self,
        root_path: str,
        include_patterns: List[str] = None,
        exclude_patterns: List[str] = None
    ) -> Dict:
        """Create manifest from directory"""
        manifest = {
            "version": self.SCHEMA_VERSION,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "generator": f"aigs-os-integrity@{VERSION}",
            "artifacts": [],
            "bundles": []
        }
        
        for filepath in self._walk_files(root_path, include_patterns, exclude_patterns):
            rel_path = os.path.relpath(filepath, root_path)
            file_hash = self.hash_engine.hash_file(filepath)
            file_stat = os.stat(filepath)
            
            artifact = {
                "path": rel_path,
                "hash": file_hash,
                "size": file_stat.st_size,
                "modified": datetime.fromtimestamp(
                    file_stat.st_mtime, tz=timezone.utc
                ).isoformat()
            }
            
            manifest["artifacts"].append(artifact)
        
        return manifest
    
    def validate_manifest(self, manifest: Dict) -> ValidationResult:
        """Validate manifest against schema and rules"""
        errors = []
        warnings = []
        
        # Schema validation
        try:
            self.validator.validate(manifest)
        except ValidationError as e:
            errors.append(f"Schema violation: {e.message}")
            return ValidationResult(False, errors, warnings)
        
        # Rule validation
        for artifact in manifest.get("artifacts", []):
            # Path validation
            if ".." in artifact["path"]:
                errors.append(f"Invalid path (contains ..): {artifact['path']}")
            
            if artifact["path"].startswith("/"):
                errors.append(f"Invalid path (absolute): {artifact['path']}")
            
            # Hash format validation
            if not re.match(r'^sha256:[a-f0-9]{64}$', artifact["hash"]):
                errors.append(f"Invalid hash format: {artifact['hash']}")
        
        # Dependency acyclicity check
        deps_graph = self._build_dependency_graph(manifest)
        if not self._is_acyclic(deps_graph):
            errors.append("Circular dependencies detected")
        
        return ValidationResult(len(errors) == 0, errors, warnings)
    
    def sign_manifest(
        self,
        manifest: Dict,
        private_key: bytes,
        algorithm: str = "Ed25519"
    ) -> Dict:
        """Sign manifest with private key"""
        # Create canonical form (excluding signature)
        manifest_copy = {k: v for k, v in manifest.items() if k != "signature"}
        canonical = json.dumps(manifest_copy, sort_keys=True, separators=(',', ':'))
        
        # Sign
        if algorithm == "Ed25519":
            signing_key = ed25519.Ed25519PrivateKey.from_private_bytes(private_key)
            signature = signing_key.sign(canonical.encode())
            pubkey = signing_key.public_key().public_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PublicFormat.Raw
            )
        else:
            raise ValueError(f"Unsupported algorithm: {algorithm}")
        
        manifest["signature"] = {
            "alg": algorithm,
            "pubkey": f"base64:{base64.b64encode(pubkey).decode()}",
            "sig": f"base64:{base64.b64encode(signature).decode()}",
            "timestamp": int(time.time())
        }
        
        return manifest
    
    def verify_signature(self, manifest: Dict) -> bool:
        """Verify manifest signature"""
        if "signature" not in manifest:
            return False
        
        sig_data = manifest["signature"]
        manifest_copy = {k: v for k, v in manifest.items() if k != "signature"}
        canonical = json.dumps(manifest_copy, sort_keys=True, separators=(',', ':'))
        
        if sig_data["alg"] == "Ed25519":
            pubkey = base64.b64decode(sig_data["pubkey"].replace("base64:", ""))
            signature = base64.b64decode(sig_data["sig"].replace("base64:", ""))
            
            verify_key = ed25519.Ed25519PublicKey.from_public_bytes(pubkey)
            try:
                verify_key.verify(signature, canonical.encode())
                return True
            except InvalidSignature:
                return False
        
        return False
```

### 11.3 Integrity Monitor
```python
class IntegrityMonitor:
    """Real-time integrity monitoring"""
    
    def __init__(
        self,
        manifest_manager: ManifestManager,
        hash_engine: HashEngine,
        event_handler: Callable
    ):
        self.manifest_manager = manifest_manager
        self.hash_engine = hash_engine
        self.event_handler = event_handler
        self.manifest = None
        self.watchers = {}
    
    def load_manifest(self, manifest_path: str):
        """Load manifest for monitoring"""
        with open(manifest_path) as f:
            self.manifest = json.load(f)
        
        # Validate before monitoring
        result = self.manifest_manager.validate_manifest(self.manifest)
        if not result.valid:
            raise ValueError(f"Invalid manifest: {result.errors}")
    
    def start_monitoring(self, watch_mode: str = "auto"):
        """Start file system monitoring"""
        if watch_mode == "auto":
            watch_mode = self._detect_best_watcher()
        
        if watch_mode == "inotify":
            self._start_inotify_watcher()
        elif watch_mode == "fsevents":
            self._start_fsevents_watcher()
        else:
            self._start_polling_watcher()
    
    def _start_inotify_watcher(self):
        """Linux inotify-based watching"""
        import inotify.adapters
        
        watcher = inotify.adapters.Inotify()
        
        for artifact in self.manifest["artifacts"]:
            dir_path = os.path.dirname(artifact["path"])
            if dir_path not in self.watchers:
                watcher.add_watch(dir_path.encode())
                self.watchers[dir_path] = watcher
        
        def event_loop():
            for event in watcher.event_gen(yield_nones=False):
                (_, type_names, path, filename) = event
                full_path = os.path.join(path.decode(), filename.decode())
                self._handle_fs_event(full_path, type_names)
        
        threading.Thread(target=event_loop, daemon=True).start()
    
    def _handle_fs_event(self, path: str, event_types: List[str]):
        """Handle file system event"""
        # Find matching artifact
        artifact = self._find_artifact_by_path(path)
        if not artifact:
            return
        
        if 'IN_MODIFY' in event_types or 'IN_CLOSE_WRITE' in event_types:
            # File modified - verify integrity
            result = self._verify_artifact(artifact)
            
            if result.status != "VALID":
                self.event_handler({
                    "timestamp": int(time.time() * 1000),
                    "event_type": "ARTIFACT_CORRUPTED",
                    "severity": "ERROR",
                    "artifact_path": path,
                    "details": result.to_dict(),
                    "correlation_id": str(uuid.uuid4())
                })
    
    def _verify_artifact(self, artifact: Dict) -> VerificationResult:
        """Verify single artifact"""
        path = artifact["path"]
        expected_hash = artifact["hash"]
        expected_size = artifact.get("size")
        
        # Check existence
        if not os.path.exists(path):
            return VerificationResult("MISSING", None, None)
        
        # Check size
        actual_size = os.path.getsize(path)
        if expected_size and actual_size != expected_size:
            return VerificationResult(
                "INVALID_SIZE",
                None,
                {"expected_size": expected_size, "actual_size": actual_size}
            )
        
        # Check hash
        computed_hash = self.hash_engine.hash_file(path)
        if computed_hash != expected_hash:
            return VerificationResult(
                "INVALID_HASH",
                computed_hash,
                {"expected_hash": expected_hash}
            )
        
        return VerificationResult("VALID", computed_hash, None)
    
    def run_full_scan(self) -> VerificationReport:
        """Run complete integrity scan"""
        results = []
        summary = {"total": 0, "valid": 0, "invalid": 0, "missing": 0}
        start_time = time.time()
        
        for artifact in self.manifest["artifacts"]:
            result = self._verify_artifact(artifact)
            results.append({
                "path": artifact["path"],
                "status": result.status,
                **result.details
            })
            
            summary["total"] += 1
            if result.status == "VALID":
                summary["valid"] += 1
            elif result.status == "MISSING":
                summary["missing"] += 1
            else:
                summary["invalid"] += 1
        
        summary["duration_ms"] = int((time.time() - start_time) * 1000)
        
        return VerificationReport(
            report_id=str(uuid.uuid4()),
            generated_at=datetime.utcnow().isoformat() + "Z",
            summary=summary,
            results=results
        )
```

### 11.4 Repair Engine
```python
class RepairEngine:
    """Artifact repair and recovery"""
    
    def __init__(
        self,
        hash_engine: HashEngine,
        registry_client: RegistryClient,
        backup_manager: BackupManager
    ):
        self.hash_engine = hash_engine
        self.registry = registry_client
        self.backup = backup_manager
        self.repair_strategies = {
            "MISSING": self._repair_missing,
            "INVALID_HASH": self._repair_hash_mismatch,
            "INVALID_SIZE": self._repair_size_mismatch
        }
    
    def repair(
        self,
        artifact: Dict,
        failure_type: str,
        strategy: str = "auto"
    ) -> RepairResult:
        """Repair corrupted artifact"""
        if failure_type not in self.repair_strategies:
            return RepairResult(False, f"Unknown failure type: {failure_type}")
        
        repair_fn = self.repair_strategies[failure_type]
        return repair_fn(artifact, strategy)
    
    def _repair_missing(self, artifact: Dict, strategy: str) -> RepairResult:
        """Repair missing artifact"""
        expected_hash = artifact["hash"]
        
        # Try backup first
        if strategy in ("auto", "backup"):
            backup_data = self.backup.retrieve(expected_hash)
            if backup_data:
                if self._verify_and_write(artifact, backup_data):
                    return RepairResult(True, "Restored from backup")
        
        # Try registry
        if strategy in ("auto", "registry"):
            registry_data = self.registry.fetch(expected_hash)
            if registry_data:
                if self._verify_and_write(artifact, registry_data):
                    return RepairResult(True, "Fetched from registry")
        
        return RepairResult(False, "No repair source available")
    
    def _repair_hash_mismatch(self, artifact: Dict, strategy: str) -> RepairResult:
        """Repair hash mismatch"""
        # Same as missing - restore from known-good source
        return self._repair_missing(artifact, strategy)
    
    def _repair_size_mismatch(self, artifact: Dict, strategy: str) -> RepairResult:
        """Repair size mismatch (usually truncated)"""
        # Full restore required
        return self._repair_missing(artifact, strategy)
    
    def _verify_and_write(self, artifact: Dict, data: bytes) -> bool:
        """Verify data and write to artifact path"""
        # Verify hash
        computed_hash = self.hash_engine.hash_bytes(data)
        if computed_hash != artifact["hash"]:
            return False
        
        # Atomic write
        path = artifact["path"]
        temp_path = f"{path}.tmp.{uuid.uuid4().hex}"
        
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(temp_path, 'wb') as f:
                f.write(data)
            
            os.replace(temp_path, path)
            return True
        except Exception:
            if os.path.exists(temp_path):
                os.unlink(temp_path)
            return False
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Complete Workflow: Build to Deploy

```bash
# Step 1: Build artifacts
$ aigs-build --project my-game --output ./build
[INFO] Building 47 artifacts...
[INFO] Build complete: ./build/

# Step 2: Generate manifest
$ aigs-integrity create-manifest \
    --root ./build \
    --output ./build/manifest.json \
    --sign --key ~/.aigs/signing.key
[INFO] Creating manifest for 47 artifacts
[INFO] Computing hashes... [47/47] 100%
[INFO] Signing manifest with Ed25519
[INFO] Manifest written: ./build/manifest.json

# Step 3: Verify manifest
$ aigs-integrity verify-manifest ./build/manifest.json
[INFO] Validating manifest schema... OK
[INFO] Verifying signatures... OK
[INFO] Checking dependency graph... OK
[SUCCESS] Manifest valid

# Step 4: Pre-deployment verification
$ aigs-integrity verify-bundle \
    --manifest ./build/manifest.json \
    --root ./build
[INFO] Verifying 47 artifacts...
[PROGRESS] 47/47 100% (12.4 MB/s)
[SUCCESS] All artifacts verified

# Step 5: Deploy with integrity check
$ aigs-deploy \
    --source ./build \
    --target production \
    --verify
[INFO] Deploying to production...
[INFO] Pre-deployment verification... OK
[INFO] Transferring artifacts... [47/47] 100%
[INFO] Post-deployment verification... OK
[SUCCESS] Deployment complete
```

### 12.2 Runtime Monitoring Example

```python
# Initialize integrity system
from aigs.integrity import IntegrityService, HashEngine, ManifestManager

service = IntegrityService(
    hash_engine=HashEngine('sha256'),
    manifest_manager=ManifestManager(),
    config={
        'watch_mode': 'inotify',
        'auto_repair': True,
        'repair_sources': ['registry', 'backup']
    }
)

# Load manifest
service.load_manifest('/game/assets/manifest.json')

# Subscribe to events
@service.on_event
def handle_integrity_event(event):
    if event['severity'] == 'CRITICAL':
        pager.duty_engineer(event)
    elif event['event_type'] == 'ARTIFACT_CORRUPTED':
        logger.error(f"Corruption detected: {event['artifact_path']}")
        metrics.increment('integrity.violations')

# Start monitoring
service.start_monitoring()

# Run periodic full scan
report = service.run_full_scan()
print(f"Scan complete: {report.summary.valid}/{report.summary.total} valid")
```

### 12.3 Corruption Detection and Repair

```python
# Simulated corruption scenario
import os
import random

# Original file is valid
artifact_path = '/game/assets/texture.png'
result = service.verify_artifact(artifact_path)
assert result.status == 'VALID'

# Simulate bit rot (flip random byte)
with open(artifact_path, 'r+b') as f:
    f.seek(random.randint(0, os.path.getsize(artifact_path) - 1))
    byte = f.read(1)
    f.seek(-1, 1)
    f.write(bytes([byte[0] ^ 0xFF]))  # Flip all bits

# Detection on next access
result = service.verify_artifact(artifact_path)
print(f"Status: {result.status}")  # INVALID_HASH
print(f"Expected: {result.expected_hash}")
print(f"Computed: {result.computed_hash}")

# Automatic repair
repair_result = service.repair(artifact_path, result)
print(f"Repair: {'SUCCESS' if repair_result.success else 'FAILED'}")
print(f"Method: {repair_result.method}")

# Verify repair
result = service.verify_artifact(artifact_path)
assert result.status == 'VALID'
```

### 12.4 Event Stream Example

```javascript
// Client-side event monitoring
const eventSource = new EventSource('/api/v1/integrity/events');

eventSource.addEventListener('ARTIFACT_CORRUPTED', (e) => {
    const event = JSON.parse(e.data);
    console.error(`Corruption: ${event.artifact_path}`);
    
    // Trigger repair workflow
    fetch('/api/v1/integrity/repair', {
        method: 'POST',
        body: JSON.stringify({
            path: event.artifact_path,
            source: 'auto'
        })
    });
});

eventSource.addEventListener('SIGNATURE_INVALID', (e) => {
    const event = JSON.parse(e.data);
    // Security alert - do not auto-repair
    security.alert({
        severity: 'critical',
        message: 'Signature validation failed',
        details: event
    });
});
```

### 12.5 Performance Benchmark

```bash
# Hash throughput benchmark
$ aigs-integrity benchmark --algorithm sha256 --size 1GB
Algorithm: SHA-256
File size: 1.00 GB
Threads:   1
Time:      1.89 s
Throughput: 529.1 MB/s

Threads:   4
Time:      0.52 s
Throughput: 1.92 GB/s

# Batch verification benchmark
$ aigs-integrity benchmark --batch --count 10000
Artifacts:  10,000
Total size: 2.45 GB
Parallel:   8 workers
Time:       4.73 s
Throughput: 518.2 MB/s
Artifacts/s: 2,114

# Full system scan
$ aigs-integrity scan --manifest ./manifest.json --report
Scanning 47,382 artifacts...
[████████████████████] 100% (47,382/47,382)
Duration: 23.4 s
Valid:    47,380
Invalid:  2
Missing:  0
Report:   ./integrity-report-20240115-103022.json
```

---

## APPENDIX: MATHEMATICAL PROOFS

### A.1 Hash Collision Probability
```
For SHA-256 (n = 256 bits):

Birthday bound: P(collision) ≈ 1 - exp(-k² / 2^(n+1))

For k = 2^64 hashes:
    P ≈ 1 - exp(-2^128 / 2^257) ≈ 2^-129 ≈ 10^-39

For practical purposes (k < 2^50):
    P(collision) < 10^-27 (negligible)
```

### A.2 Merkle Tree Security
```
Merkle root commitment:
    Root = H(H(H(a₁)||H(a₂)) || H(H(a₃)||H(a₄)))

Tamper detection:
    If any aᵢ → aᵢ', then H(aᵢ) ≠ H(aᵢ')
    This propagates up: parent_hash ≠ parent_hash'
    Ultimately: Root ≠ Root'

Proof size for n artifacts: O(log n) hashes
Verification cost: O(log n) hash operations
```

### A.3 Dependency Graph Complexity
```
Resolution complexity:
    - Acyclicity check: O(V + E) via DFS
    - Topological sort: O(V + E)
    - Version constraint solving: NP-complete in general
    - Practical resolution (bounded versions): O(V²)

Where:
    V = number of artifacts
    E = number of dependency edges
```

---

**Document Version:** 1.0.0  
**Last Updated:** 2024-01-15  
**Classification:** Technical Specification - Domain 20
