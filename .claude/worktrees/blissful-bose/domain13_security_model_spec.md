# Domain 13: Security / Credential Isolation Model Specification
## AI-Native Game Studio OS - Security Architecture v1.0

---

## 1. CREDENTIAL ISOLATION ARCHITECTURE

### 1.1 Secret Compartments (SC)

**Mathematical Model:**
```
∀ secret s ∈ S: ∃! compartment c ∈ C | s ∈ c
C = {c₁, c₂, ..., cₙ} where cᵢ ∩ cⱼ = ∅ for i ≠ j
```

**Compartment Hierarchy:**
| Level | Compartment | Contents | Isolation Boundary |
|-------|-------------|----------|-------------------|
| L0 | System Core | Kernel creds, HW keys | Hardware enclave |
| L1 | Service Vault | DB passwords, API roots | Network namespace |
| L2 | Agent Runtime | Session tokens, temp keys | Process cgroup |
| L3 | User Context | User prefs, session data | User namespace |
| L4 | External | Third-party tokens | Proxy boundary |

**Compartment Isolation Functions:**
```python
isolation_function(cᵢ, cⱼ) = {
    memory: cᵢ.heap ∩ cⱼ.heap = ∅
    network: cᵢ.netns ≠ cⱼ.netns
    filesystem: cᵢ.fs_root ∩ cⱼ.fs_root = ∅
    process: cᵢ.pidns ∩ cⱼ.pidns = ∅
}
```

### 1.2 Environment Separation

**Environment Tiers:**
```
E = {E_prod, E_staging, E_dev, E_local}
∀ e₁, e₂ ∈ E: credential(e₁) ∩ credential(e₂) = ∅
```

**Separation Matrix:**
| Source | Target | Credential Sharing |
|--------|--------|-------------------|
| prod | staging | STRICT DENY |
| prod | dev | STRICT DENY |
| staging | dev | DENY |
| dev | local | ALLOW (sanitized) |

**Environment Detection:**
```
env_id = HMAC(SHA256(node_fingerprint || deployment_timestamp), master_key)
env_validation = verify_chain_of_trust(env_id, root_ca)
```

### 1.3 Access Boundaries

**Boundary Definition:**
```
B = {(s, r, a) | s ∈ Subjects, r ∈ Resources, a ∈ Actions}
BoundaryCheck(s, r, a) = {
    ALLOW if (s.role ∩ r.required_roles) ≠ ∅ ∧ a ∈ s.permitted_actions
    DENY otherwise
}
```

**Boundary Types:**
| Boundary | Mechanism | Enforcement Point |
|----------|-----------|-------------------|
| Network | mTLS + SPIFFE | Service mesh sidecar |
| Process | seccomp + capabilities | Container runtime |
| Data | Field-level encryption | Application layer |
| Time | Token TTL + refresh | Auth middleware |

---

## 2. SECRET MANAGEMENT SYSTEM

### 2.1 Secret Classification & Lifecycle

| SecretType | Storage | Rotation | TTL | Max Versions |
|------------|---------|----------|-----|--------------|
| API Keys | HashiCorp Vault | 90 days | 24h lease | 3 |
| OAuth Tokens | Environment + Memory | 30 days | 1h session | 1 |
| TLS Certs | Filesystem (tmpfs) | 1 year | 90d auto-renew | 2 |
| DB Credentials | Vault Dynamic | 7 days | 1h dynamic | 5 |
| Encryption Keys | HSM/KMS | 1 year | N/A | 2 |
| Service Accounts | Vault K8s Auth | 90 days | 24h | 3 |
| Signing Keys | HSM | 2 years | N/A | 2 |
| Session Secrets | Redis Encrypted | 7 days | 24h | 1 |

### 2.2 Secret Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SECRET MANAGEMENT LAYERS                  │
├─────────────────────────────────────────────────────────────┤
│  L4: Application Cache (encrypted in-memory, TTL=300s)       │
├─────────────────────────────────────────────────────────────┤
│  L3: Sidecar Agent (local vault agent, cache=5m)             │
├─────────────────────────────────────────────────────────────┤
│  L2: Regional Vault Cluster (3-node HA, auto-unseal)         │
├─────────────────────────────────────────────────────────────┤
│  L1: HSM/KMS Integration (FIPS 140-2 Level 3)                │
├─────────────────────────────────────────────────────────────┤
│  L0: Root Key Ceremony (Shamir n-of-m, offline storage)      │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Rotation Protocol

```python
rotation_protocol(secret_type):
    t_current = now()
    t_created = secret.created_at
    t_rotation = secret.rotation_period
    
    if (t_current - t_created) >= t_rotation:
        new_secret = generate(secret_type.params)
        new_secret.version = secret.version + 1
        
        # Phase 1: Create new, dual-active
        deploy(new_secret, status=DUAL_ACTIVE)
        
        # Phase 2: Migrate consumers (max 24h)
        await consumer_migration_complete(timeout=24h)
        
        # Phase 3: Revoke old
        revoke(secret, grace_period=1h)
        
        # Phase 4: Archive
        archive(secret, retention=90d)
```

---

## 3. ACCESS CONTROL MATRICES

### 3.1 Role-Based Access Control (RBAC)

| Role | Secrets | Read | Write | Execute | Admin | Scope |
|------|---------|------|-------|---------|-------|-------|
| system-agent | service-token | R | - | E | - | namespace-scoped |
| system-core | all-system | R | - | E | - | cluster-scoped |
| agent-runtime | session-tokens | R | W | E | - | pod-scoped |
| agent-executor | execution-keys | R | - | E | - | job-scoped |
| admin-security | all-secrets | R | W | E | A | global |
| admin-ops | operational | R | W | E | - | region-scoped |
| developer | dev-sandbox | R | W | E | - | project-scoped |
| auditor | audit-logs | R | - | - | - | read-only-all |
| external-service | integration-keys | R | - | E | - | endpoint-scoped |
| human-user | personal-tokens | R | W | - | - | user-scoped |

### 3.2 Attribute-Based Access Control (ABAC) Extensions

```json
{
  "policy": {
    "effect": "allow",
    "principal": {
      "role": "agent-runtime",
      "namespace": "${resource.namespace}",
      "labels": {
        "security-tier": "trusted"
      }
    },
    "action": ["secrets:read", "secrets:lease"],
    "resource": {
      "type": "secret",
      "classification": ["internal", "confidential"],
      "path": "/games/${principal.game_id}/*"
    },
    "conditions": {
      "time": {"start": "08:00", "end": "20:00", "tz": "UTC"},
      "mfa": {"required": true},
      "rate_limit": {"requests_per_minute": 100}
    }
  }
}
```

### 3.3 Permission Inheritance Graph

```
                    ┌─────────────┐
                    │   root      │
                    │  (HSM key)  │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
      ┌────┴────┐     ┌────┴────┐    ┌────┴────┐
      │ cluster │     │  ops    │    │  audit  │
      │  root   │     │  root   │    │  root   │
      └────┬────┘     └────┬────┘    └─────────┘
           │               │
    ┌──────┼──────┐   ┌────┴────┐
    │      │      │   │ staging │
┌───┴─┐ ┌──┴─┐ ┌──┴┐  │  root   │
│game │ │svc │ │sys│  └────┬────┘
│root │ │root│ │root│      │
└──┬──┘ └────┘ └────┘ ┌────┴────┐
   │                   │  dev    │
┌──┴──┐                │  root   │
│agent│                └─────────┘
│root │
└─────┘
```

---

## 4. ENCRYPTION STANDARDS

### 4.1 Cryptographic Primitives

| Data State | Algorithm | Key Size | Mode/Protocol | Compliance |
|------------|-----------|----------|---------------|------------|
| At-rest | AES-256-GCM | 256-bit | GCM (96-bit IV) | FIPS 197 |
| At-rest (alt) | ChaCha20-Poly1305 | 256-bit | AEAD | RFC 8439 |
| In-transit | TLS 1.3 | P-256/X25519 | AEAD ciphers only | RFC 8446 |
| Key exchange | ECDH | P-384 | ephemeral | NIST SP 800-56A |
| Signing | Ed25519 | 256-bit | deterministic | RFC 8032 |
| Signing (alt) | ECDSA | P-384 | SHA-384 | FIPS 186-5 |
| Hashing | SHA-3-256 | - | - | FIPS 202 |
| KDF | HKDF-SHA256 | variable | extract-then-expand | RFC 5869 |
| Password | Argon2id | - | m=64MB, t=3, p=4 | OWASP |

### 4.2 Key Hierarchy

```
┌──────────────────────────────────────────────────────────────┐
│                    KEY HIERARCHY (KEK/DEK)                   │
├──────────────────────────────────────────────────────────────┤
│  DK (Data Key) - per-object, encrypted by KEK                │
│  KEK (Key Encryption Key) - per-service, encrypted by MEK    │
│  MEK (Master Encryption Key) - per-region, in HSM            │
│  HEK (HSM Encryption Key) - root of trust, hardware-bound    │
└──────────────────────────────────────────────────────────────┘

Encryption: ciphertext = AES-256-GCM(DK, plaintext)
Key Wrap: wrapped_key = RSA-OAEP-4096(KEK_public, DK)
```

### 4.3 Encryption Context

```json
{
  "encryption_context": {
    "service": "game-engine",
    "environment": "production",
    "region": "us-east-1",
    "resource_type": "save_game",
    "resource_id": "save_abc123",
    "timestamp": 1699900000,
    "key_version": "v2"
  }
}
```

### 4.4 Cipher Suite Configuration

```
TLS 1.3 Cipher Suites (priority order):
1. TLS_AES_256_GCM_SHA384
2. TLS_CHACHA20_POLY1305_SHA256
3. TLS_AES_128_GCM_SHA256

TLS 1.2 (legacy, deprecation target 2025-Q2):
- ECDHE-RSA-AES256-GCM-SHA384
- ECDHE-ECDSA-AES256-GCM-SHA384

Forbidden:
- CBC mode ciphers
- RC4, DES, 3DES
- MD5, SHA1 for signatures
- RSA key exchange (no forward secrecy)
```

---

## 5. AUDIT LOGGING REQUIREMENTS

### 5.1 Log Event Taxonomy

| Event Category | Event Types | Retention | Sensitivity |
|----------------|-------------|-----------|-------------|
| authentication | login, logout, mfa, failure | 7 years | high |
| authorization | access_granted, access_denied | 7 years | high |
| secret_access | read, write, lease, revoke | 7 years | critical |
| key_operation | generate, rotate, destroy | 10 years | critical |
| admin_action | policy_change, config_update | 10 years | critical |
| system_event | startup, shutdown, error | 3 years | medium |
| data_access | read, write, delete, export | 7 years | high |
| network_event | connect, disconnect, block | 1 year | medium |

### 5.2 Log Schema

```json
{
  "audit_event": {
    "version": "1.0",
    "event_id": "uuid-v4",
    "timestamp": "2024-01-15T10:30:00.000Z",
    "timestamp_unix_ns": 1705317000000000000,
    "severity": "INFO|WARN|ERROR|CRITICAL",
    "category": "authentication|authorization|secret_access|...",
    "event_type": "login_success|access_denied|secret_read|...",
    "actor": {
      "type": "user|service|agent|system",
      "id": "actor-identifier",
      "auth_method": "mfa|token|certificate|iam",
      "ip_address": "1.2.3.4",
      "user_agent": "...",
      "session_id": "sess-abc123"
    },
    "target": {
      "type": "secret|resource|policy|system",
      "id": "target-identifier",
      "classification": "public|internal|confidential|restricted",
      "path": "/secrets/production/db/credentials"
    },
    "action": {
      "operation": "read|write|execute|delete",
      "status": "success|failure|denied|error",
      "reason": "optional-reason-code"
    },
    "context": {
      "request_id": "req-xyz789",
      "trace_id": "trace-123abc",
      "environment": "production",
      "region": "us-east-1",
      "service": "game-engine-api"
    },
    "result": {
      "success": true,
      "error_code": null,
      "error_message": null
    },
    "integrity": {
      "hash_algorithm": "SHA-256",
      "hash_value": "abc123...",
      "previous_hash": "def456...",
      "signature": "signed-hash..."
    }
  }
}
```

### 5.3 Log Integrity Chain

```python
log_integrity_chain(log_entry, previous_entry):
    # Merkle tree-style integrity
    entry_hash = SHA256(
        log_entry.timestamp ||
        log_entry.event_type ||
        log_entry.actor.id ||
        log_entry.target.id ||
        log_entry.action.operation ||
        previous_entry.integrity.hash_value
    )
    
    log_entry.integrity.hash_value = entry_hash
    log_entry.integrity.signature = HSM_Sign(entry_hash, audit_signing_key)
    
    return log_entry
```

### 5.4 Log Shipping & Storage

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Application │───▶│  Fluent Bit │───▶│    Kafka    │───▶│  SIEM/Splunk │
│   (stdout)   │    │  (agent)    │    │  (buffer)   │    │  (analysis)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                              │
                              ▼
                       ┌─────────────┐
                       │  Cold Store │
                       │  (S3/GCS)   │
                       │  10+ years  │
                       └─────────────┘
```

---

## 6. BREACH RESPONSE PROCEDURES

### 6.1 Incident Severity Classification

| Severity | Criteria | Response Time | Escalation |
|----------|----------|---------------|------------|
| P0-Critical | Root key compromise, mass credential exposure | 15 min | CEO, Legal, SOC |
| P1-High | Service account compromise, unauthorized admin access | 30 min | CISO, Engineering |
| P2-Medium | Individual credential leak, policy violation | 2 hours | Security Team |
| P3-Low | Failed auth attempts, anomaly detection | 24 hours | On-call Engineer |

### 6.2 Response Playbook: Credential Compromise

```
PHASE 1: DETECTION (0-15 min)
├── Alert triggered: anomaly detection / honeypot / external report
├── Automated containment: isolate affected service
├── Page on-call security engineer
└── Create incident channel (Slack/PagerDuty)

PHASE 2: CONTAINMENT (15-60 min)
├── Identify scope: which secrets, which services, which data
├── Rotate compromised credentials (emergency rotation)
├── Revoke all active sessions/tokens for affected accounts
├── Enable enhanced monitoring on affected systems
└── Preserve evidence: snapshot logs, memory dumps

PHASE 3: ERADICATION (1-24 hours)
├── Patch vulnerability that enabled compromise
├── Force password reset for affected users
├── Re-image compromised hosts
├── Verify no persistence mechanisms remain
└── Rotate all potentially exposed secrets (blast radius)

PHASE 4: RECOVERY (24-72 hours)
├── Gradual service restoration with enhanced monitoring
├── Verify integrity of restored systems
├── Update detection rules based on attack pattern
└── Document timeline and actions taken

PHASE 5: POST-INCIDENT (72+ hours)
├── Root cause analysis (5 Whys)
├── Update runbooks and detection rules
├── Security training if human error
├── Legal/regulatory notification if required
└── Publish internal post-mortem
```

### 6.3 Emergency Credential Rotation

```python
emergency_rotation(affected_secrets):
    for secret in affected_secrets:
        # Immediate revocation
        revoke_all_leases(secret, immediate=True)
        
        # Generate new without grace period
        new_secret = generate(secret.type, params=secret.params)
        new_secret.emergency_rotation = True
        
        # Force immediate deployment
        force_deploy(new_secret, services=secret.consumers)
        
        # Verify rotation
        verify_consumer_connectivity(secret.consumers, timeout=5m)
        
        # Archive old with incident tag
        archive(secret, retention=forever, tag=incident_id)
```

### 6.4 Communication Matrix

| Stakeholder | P0 | P1 | P2 | P3 |
|-------------|----|----|----|----|
| CEO/Board | Immediate | 4h | 24h | Weekly |
| Legal | Immediate | 1h | 4h | - |
| Customers | 4h | 24h | 72h | - |
| Regulators | As required | As required | - | - |
| Engineering | Immediate | 15m | 1h | 24h |
| Public | 24h | 72h | - | - |

---

## 7. SUCCESS CRITERIA (Measurable)

### 7.1 Security Metrics

| Metric | Target | Measurement | Frequency |
|--------|--------|-------------|-----------|
| Secret Rotation Compliance | 100% | (rotated_on_time / total_secrets) × 100 | Weekly |
| Encryption Coverage | 100% | (encrypted_data / total_sensitive_data) × 100 | Continuous |
| Access Control Enforcement | 100% | (enforced_requests / total_requests) × 100 | Continuous |
| Audit Log Completeness | 99.99% | (logged_events / expected_events) × 100 | Daily |
| MTTD (Mean Time to Detect) | < 5 min | detection_time - event_time | Per incident |
| MTTR (Mean Time to Respond) | < 15 min (P0) | response_start - detection_time | Per incident |
| MTTR (Mean Time to Remediate) | < 4 hours (P0) | full_recovery - detection_time | Per incident |
| False Positive Rate | < 1% | false_positives / total_alerts | Weekly |
| Secret Sprawl Index | < 10 | unique_secrets / services | Monthly |
| Credential Reuse Rate | 0% | reused_credentials / total_credentials | Quarterly |

### 7.2 Compliance Metrics

| Control | Requirement | Evidence |
|---------|-------------|----------|
| Key Generation | FIPS 140-2 validated | HSM certification |
| Access Reviews | Quarterly | Review logs |
| Penetration Testing | Annual | Third-party report |
| Vulnerability Scanning | Weekly | Scan reports |
| Encryption Verification | Continuous | Cipher suite monitoring |

### 7.3 Operational Metrics

| Metric | Target | SLA |
|--------|--------|-----|
| Secret Retrieval Latency | p99 < 50ms | 99.9% |
| Vault Availability | 99.99% | Monthly |
| Authentication Latency | p99 < 100ms | 99.9% |
| Rotation Downtime | 0 (zero-downtime) | 100% |

---

## 8. FAILURE STATES

### 8.1 Failure Mode Analysis

| Failure Mode | Impact | Detection | Mitigation |
|--------------|--------|-----------|------------|
| Vault Unavailable | Cannot retrieve secrets | Health check | Local cache fallback, circuit breaker |
| HSM Failure | Cannot decrypt/encrypt | HSM health | Fail-secure, secondary HSM |
| Certificate Expiry | TLS failures | Cert monitoring | Auto-renewal, 30d warning |
| Secret Leak | Credential exposure | DLP scanning | Immediate rotation, incident response |
| Privilege Escalation | Unauthorized access | Anomaly detection | Just-in-time access, approval gates |
| Audit Log Loss | Compliance failure | Log shipping health | Multi-target shipping, buffer |
| Key Compromise | Complete breach | Key usage anomaly | Emergency rotation, key ceremony |
| Rotation Failure | Stale credentials | Rotation job alert | Manual intervention, rollback |
| Network Partition | Split-brain | Consensus health | Quorum enforcement, fencing |
| Insider Threat | Malicious admin | Dual-control logs | MFA, approval workflows, logging |

### 8.2 Failure State Machine

```
                    ┌─────────────┐
                    │   NORMAL    │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  DEGRADED   │ │   ALERT     │ │  RECOVERY   │
    │  (fallback) │ │  (investigate)│ │   (active)  │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
           │    ┌──────────┘               │
           │    │                          │
           ▼    ▼                          ▼
    ┌─────────────┐                ┌─────────────┐
    │   FAILED    │◄───────────────│   NORMAL    │
    │ (incident)  │   recovery     │  (restored) │
    └─────────────┘                └─────────────┘
```

### 8.3 Circuit Breaker Configuration

```python
circuit_breaker_config = {
    "vault_connection": {
        "failure_threshold": 5,
        "recovery_timeout": 30,
        "half_open_max_calls": 3,
        "fallback": "local_cache"
    },
    "hsm_operations": {
        "failure_threshold": 3,
        "recovery_timeout": 60,
        "fallback": "fail_secure"
    },
    "secret_rotation": {
        "failure_threshold": 2,
        "recovery_timeout": 300,
        "fallback": "manual_approval"
    }
}
```

---

## 9. INTEGRATION SURFACE

### 9.1 API Endpoints

| Endpoint | Method | Auth | Rate Limit | Purpose |
|----------|--------|------|------------|---------|
| /v1/secrets/{path} | GET | Token | 1000/min | Retrieve secret |
| /v1/secrets/{path} | PUT | Token | 100/min | Store secret |
| /v1/secrets/{path} | DELETE | Token | 50/min | Delete secret |
| /v1/auth/login | POST | - | 10/min | Authenticate |
| /v1/auth/renew | POST | Token | 100/min | Renew token |
| /v1/auth/revoke | POST | Token | 100/min | Revoke token |
| /v1/rotate/{path} | POST | Admin | 10/min | Rotate secret |
| /v1/audit/query | POST | Auditor | 60/min | Query audit logs |
| /v1/health | GET | - | - | Health check |
| /v1/metrics | GET | Internal | - | Prometheus metrics |

### 9.2 Webhook Events

| Event | Payload | Destination | Retry |
|-------|---------|-------------|-------|
| secret.created | Secret metadata | Configured endpoints | 3x |
| secret.rotated | Rotation details | Configured endpoints | 3x |
| secret.revoked | Revocation details | Configured endpoints | 3x |
| auth.failure | Failure context | SIEM | 5x |
| policy.violation | Violation details | Security team | 5x |

### 9.3 SDK Integration Points

```python
# Python SDK Example
from gamestudio.security import SecretManager, Encryption

# Initialize
sm = SecretManager(
    vault_addr="https://vault.internal:8200",
    auth_method="kubernetes",
    role="game-engine"
)

# Retrieve secret
secret = sm.get_secret("games/production/db/password")

# Encrypt data
encrypted = Encryption.encrypt(
    plaintext=sensitive_data,
    context={"game_id": "game-123", "user_id": "user-456"}
)

# Audit context
with sm.audit_context(action="save_game"):
    db.save(encrypted)
```

### 9.4 Service Mesh Integration

```yaml
# Istio DestinationRule for mTLS
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: security-mtls
spec:
  host: "*.security.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

---

## 10. JSON SCHEMAS

### 10.1 Secret Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.io/schemas/secret/v1",
  "title": "Secret",
  "type": "object",
  "required": ["path", "data", "metadata"],
  "properties": {
    "path": {
      "type": "string",
      "pattern": "^/[a-z0-9-]+(/[a-z0-9-]+)*$"
    },
    "data": {
      "type": "object",
      "additionalProperties": {
        "type": "string",
        "maxLength": 65536
      }
    },
    "metadata": {
      "type": "object",
      "required": ["created_at", "version", "rotation_policy"],
      "properties": {
        "created_at": {"type": "string", "format": "date-time"},
        "updated_at": {"type": "string", "format": "date-time"},
        "version": {"type": "integer", "minimum": 1},
        "rotation_policy": {
          "type": "object",
          "properties": {
            "enabled": {"type": "boolean"},
            "interval_days": {"type": "integer", "minimum": 1},
            "next_rotation": {"type": "string", "format": "date-time"}
          }
        },
        "classification": {
          "type": "string",
          "enum": ["public", "internal", "confidential", "restricted"]
        },
        "labels": {
          "type": "object",
          "additionalProperties": {"type": "string"}
        }
      }
    }
  }
}
```

### 10.2 Access Policy Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.io/schemas/access-policy/v1",
  "title": "AccessPolicy",
  "type": "object",
  "required": ["policy_id", "effect", "principal", "action", "resource"],
  "properties": {
    "policy_id": {"type": "string", "format": "uuid"},
    "effect": {"type": "string", "enum": ["allow", "deny"]},
    "principal": {
      "type": "object",
      "properties": {
        "type": {"type": "string", "enum": ["user", "service", "group", "role"]},
        "id": {"type": "string"},
        "attributes": {"type": "object"}
      }
    },
    "action": {
      "type": "array",
      "items": {"type": "string", "pattern": "^[a-z]+:[a-z]+$"}
    },
    "resource": {
      "type": "object",
      "properties": {
        "type": {"type": "string"},
        "path": {"type": "string"},
        "attributes": {"type": "object"}
      }
    },
    "conditions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "type": {"type": "string", "enum": ["time", "ip", "mfa", "rate_limit"]},
          "operator": {"type": "string", "enum": ["eq", "ne", "gt", "lt", "in", "not_in"]},
          "value": {}
        }
      }
    }
  }
}
```

### 10.3 Audit Event Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.io/schemas/audit-event/v1",
  "title": "AuditEvent",
  "type": "object",
  "required": ["event_id", "timestamp", "category", "actor", "target", "action"],
  "properties": {
    "event_id": {"type": "string", "format": "uuid"},
    "version": {"type": "string", "pattern": "^\\d+\\.\\d+$"},
    "timestamp": {"type": "string", "format": "date-time"},
    "timestamp_unix_ns": {"type": "integer"},
    "severity": {"type": "string", "enum": ["INFO", "WARN", "ERROR", "CRITICAL"]},
    "category": {"type": "string"},
    "event_type": {"type": "string"},
    "actor": {
      "type": "object",
      "required": ["type", "id"],
      "properties": {
        "type": {"type": "string"},
        "id": {"type": "string"},
        "auth_method": {"type": "string"},
        "ip_address": {"type": "string", "format": "ipv4"},
        "session_id": {"type": "string"}
      }
    },
    "target": {
      "type": "object",
      "required": ["type", "id"],
      "properties": {
        "type": {"type": "string"},
        "id": {"type": "string"},
        "classification": {"type": "string"},
        "path": {"type": "string"}
      }
    },
    "action": {
      "type": "object",
      "required": ["operation", "status"],
      "properties": {
        "operation": {"type": "string"},
        "status": {"type": "string", "enum": ["success", "failure", "denied", "error"]},
        "reason": {"type": "string"}
      }
    },
    "integrity": {
      "type": "object",
      "required": ["hash_algorithm", "hash_value"],
      "properties": {
        "hash_algorithm": {"type": "string"},
        "hash_value": {"type": "string"},
        "previous_hash": {"type": "string"},
        "signature": {"type": "string"}
      }
    }
  }
}
```

### 10.4 Encryption Bundle Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.io/schemas/encryption-bundle/v1",
  "title": "EncryptionBundle",
  "type": "object",
  "required": ["version", "ciphertext", "encrypted_key", "algorithm"],
  "properties": {
    "version": {"type": "string", "enum": ["v1"]},
    "algorithm": {"type": "string", "enum": ["AES-256-GCM", "ChaCha20-Poly1305"]},
    "ciphertext": {"type": "string", "contentEncoding": "base64"},
    "encrypted_key": {"type": "string", "contentEncoding": "base64"},
    "iv": {"type": "string", "contentEncoding": "base64"},
    "auth_tag": {"type": "string", "contentEncoding": "base64"},
    "key_id": {"type": "string"},
    "encryption_context": {"type": "object"},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Security Service

```python
class SecurityService:
    """Core security service for credential isolation and management."""
    
    def __init__(self, config: SecurityConfig):
        self.vault = VaultClient(config.vault_addr, config.vault_auth)
        self.hsm = HSMClient(config.hsm_config)
        self.audit = AuditLogger(config.audit_config)
        self.cache = EncryptedCache(config.cache_config)
        self.policy_engine = PolicyEngine(config.policies)
        
    def get_secret(self, path: str, context: RequestContext) -> Secret:
        # 1. Authorization check
        if not self.policy_engine.authorize(context.actor, "secrets:read", path):
            self.audit.log_access_denied(context, path)
            raise AccessDeniedError(f"Access denied to {path}")
        
        # 2. Cache check
        cached = self.cache.get(path, context.actor.id)
        if cached and not cached.is_expired():
            self.audit.log_cache_hit(context, path)
            return cached.decrypt(self.hsm)
        
        # 3. Vault retrieval
        secret = self.vault.read(path)
        
        # 4. Decrypt DEK with KEK from HSM
        dek = self.hsm.decrypt(secret.encrypted_key, secret.key_id)
        plaintext = AES256GCM.decrypt(dek, secret.ciphertext, secret.iv)
        
        # 5. Cache with TTL
        self.cache.set(path, secret, ttl=secret.lease_duration)
        
        # 6. Audit
        self.audit.log_secret_access(context, path, "success")
        
        return Secret(plaintext=plaintext, metadata=secret.metadata)
    
    def rotate_secret(self, path: str, context: RequestContext) -> RotationResult:
        # Verify admin privileges
        if not context.actor.has_role("admin-security"):
            raise AccessDeniedError("Rotation requires admin-security role")
        
        # Acquire distributed lock
        with self.vault.lock(f"rotation/{path}", ttl=300):
            old_secret = self.vault.read(path)
            
            # Generate new secret
            new_secret = self._generate_secret(old_secret.type, old_secret.params)
            new_secret.version = old_secret.version + 1
            
            # Encrypt with new DEK
            dek = self.hsm.generate_data_key()
            new_secret.ciphertext = AES256GCM.encrypt(dek, new_secret.plaintext)
            new_secret.encrypted_key = self.hsm.encrypt(dek, key_id="kek-current")
            
            # Store with dual-active flag
            self.vault.write(path, new_secret, metadata={"status": "dual-active"})
            
            # Notify consumers
            self._notify_rotation(path, new_secret)
            
            # Wait for migration
            if self._await_migration(path, timeout=86400):
                # Revoke old
                self.vault.revoke_leases(old_secret.lease_ids)
                self.vault.patch_metadata(path, {"status": "active"})
            else:
                # Rollback
                self.vault.delete(f"{path}@v{new_secret.version}")
                raise RotationTimeoutError()
            
            self.audit.log_rotation(context, path, old_secret.version, new_secret.version)
            
            return RotationResult(success=True, new_version=new_secret.version)
```

### 11.2 Policy Engine

```python
class PolicyEngine:
    """ABAC policy evaluation engine."""
    
    def __init__(self, policies: List[Policy]):
        self.policies = policies
        self.compiled_policies = self._compile_policies()
    
    def authorize(self, actor: Actor, action: str, resource: str, 
                  context: Dict = None) -> bool:
        request = AuthzRequest(
            actor=actor,
            action=action,
            resource=resource,
            context=context or {},
            timestamp=datetime.utcnow()
        )
        
        # Evaluate policies (deny-override)
        decisions = []
        for policy in self.compiled_policies:
            if self._matches(policy, request):
                decisions.append(policy.effect)
        
        if "deny" in decisions:
            return False
        if "allow" in decisions:
            return True
        return False  # Default deny
    
    def _matches(self, policy: CompiledPolicy, request: AuthzRequest) -> bool:
        return (
            self._match_principal(policy.principal, request.actor) and
            self._match_action(policy.action, request.action) and
            self._match_resource(policy.resource, request.resource) and
            self._match_conditions(policy.conditions, request)
        )
    
    def _match_conditions(self, conditions: List[Condition], 
                          request: AuthzRequest) -> bool:
        for condition in conditions:
            if not self._evaluate_condition(condition, request):
                return False
        return True
    
    def _evaluate_condition(self, condition: Condition, 
                            request: AuthzRequest) -> bool:
        if condition.type == "time":
            current = request.timestamp.time()
            return condition.start <= current <= condition.end
        elif condition.type == "mfa":
            return request.actor.mfa_verified or not condition.required
        elif condition.type == "rate_limit":
            return self._check_rate_limit(request.actor.id, condition.limit)
        return True
```

### 11.3 Audit Logger

```python
class AuditLogger:
    """Tamper-evident audit logging."""
    
    def __init__(self, config: AuditConfig):
        self.signing_key = HSM.get_signing_key(config.key_id)
        self.previous_hash = self._load_last_hash()
        self.buffer = []
        self.shippers = [KafkaShipper(), S3Shipper(), SIEMShipper()]
    
    def log(self, event: AuditEvent):
        # Add integrity chain
        event.integrity = self._compute_integrity(event)
        
        # Sign
        event.signature = self.signing_key.sign(event.integrity.hash_value)
        
        # Buffer
        self.buffer.append(event)
        
        # Flush if threshold reached
        if len(self.buffer) >= 100:
            self._flush()
    
    def _compute_integrity(self, event: AuditEvent) -> Integrity:
        hash_input = (
            f"{event.timestamp_unix_ns}"
            f"{event.event_type}"
            f"{event.actor.id}"
            f"{event.target.id}"
            f"{self.previous_hash}"
        )
        hash_value = SHA256(hash_input.encode()).hexdigest()
        
        integrity = Integrity(
            hash_algorithm="SHA-256",
            hash_value=hash_value,
            previous_hash=self.previous_hash
        )
        
        self.previous_hash = hash_value
        return integrity
    
    def _flush(self):
        for shipper in self.shippers:
            try:
                shipper.send(self.buffer)
            except Exception as e:
                # Failover to next shipper
                continue
        self.buffer = []
        self._save_last_hash(self.previous_hash)
```

### 11.4 Encryption Service

```python
class EncryptionService:
    """Field-level encryption service."""
    
    ALGORITHMS = {
        "AES-256-GCM": AES256GCM,
        "ChaCha20-Poly1305": ChaCha20Poly1305
    }
    
    def __init__(self, hsm: HSMClient):
        self.hsm = hsm
    
    def encrypt(self, plaintext: bytes, context: Dict, 
                algorithm: str = "AES-256-GCM") -> EncryptionBundle:
        # Generate DEK
        dek = os.urandom(32)
        
        # Generate IV/nonce
        iv = os.urandom(12)  # 96 bits for GCM
        
        # Encrypt plaintext
        cipher = self.ALGORITHMS[algorithm]
        ciphertext, auth_tag = cipher.encrypt(dek, plaintext, iv)
        
        # Encrypt DEK with KEK
        key_id = self.hsm.get_current_key_id()
        encrypted_key = self.hsm.encrypt(dek, key_id)
        
        return EncryptionBundle(
            version="v1",
            algorithm=algorithm,
            ciphertext=base64encode(ciphertext),
            encrypted_key=base64encode(encrypted_key),
            iv=base64encode(iv),
            auth_tag=base64encode(auth_tag),
            key_id=key_id,
            encryption_context=context,
            timestamp=datetime.utcnow().isoformat()
        )
    
    def decrypt(self, bundle: EncryptionBundle) -> bytes:
        # Decrypt DEK
        dek = self.hsm.decrypt(
            base64decode(bundle.encrypted_key),
            bundle.key_id
        )
        
        # Decrypt plaintext
        cipher = self.ALGORITHMS[bundle.algorithm]
        return cipher.decrypt(
            dek,
            base64decode(bundle.ciphertext),
            base64decode(bundle.iv),
            base64decode(bundle.auth_tag)
        )
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Scenario: Game Save Encryption Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Player    │────▶│ Game Client │────▶│  Game API   │────▶│  Security   │
│  (browser)  │     │  (Unity)    │     │   Service   │     │   Service   │
└─────────────┘     └─────────────┘     └──────┬──────┘     └──────┬──────┘
                                                │                    │
                                                │                    │
                                                ▼                    ▼
                                         ┌─────────────┐     ┌─────────────┐
                                         │   Vault     │     │     HSM     │
                                         │   Cluster   │     │   (AWS)     │
                                         └─────────────┘     └─────────────┘
```

### 12.2 Step-by-Step Flow

**Step 1: Player Initiates Save**
```
POST /api/v1/games/{game_id}/saves
Authorization: Bearer {player_jwt}
Content-Type: application/json

{
  "save_data": "<base64-encoded-save-blob>",
  "slot": 1,
  "checksum": "sha256:abc123..."
}
```

**Step 2: API Service Authenticates**
```python
# Validate JWT
claims = jwt.decode(token, key=jwks.get_key(kid))
actor = Actor(
    type="user",
    id=claims.sub,
    roles=["player"],
    game_id=claims.game_id,
    mfa_verified=claims.amr == "mfa"
)
```

**Step 3: Authorization Check**
```python
# Verify player owns this save slot
if not policy_engine.authorize(
    actor=actor,
    action="saves:write",
    resource=f"/games/{game_id}/saves/{actor.id}/{slot}"):
    raise AccessDeniedError()
```

**Step 4: Retrieve Encryption Key**
```python
# Get game-specific encryption key
key_path = f"/games/{game_id}/encryption/save-keys"
secret = security_service.get_secret(key_path, context)
dek = secret.data["dek"]  # Data encryption key
```

**Step 5: Encrypt Save Data**
```python
# Encrypt with context binding
encryption_context = {
    "game_id": game_id,
    "player_id": actor.id,
    "slot": slot,
    "timestamp": int(time.time())
}

encrypted_bundle = encryption_service.encrypt(
    plaintext=save_data,
    context=encryption_context,
    algorithm="AES-256-GCM"
)
```

**Step 6: Store Encrypted Data**
```python
# Store in database
db.saves.insert({
    "player_id": actor.id,
    "game_id": game_id,
    "slot": slot,
    "encrypted_data": encrypted_bundle.to_json(),
    "created_at": datetime.utcnow(),
    "checksum": checksum
})
```

**Step 7: Audit Log**
```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "category": "data_access",
  "event_type": "save_game",
  "actor": {
    "type": "user",
    "id": "player-12345",
    "auth_method": "jwt",
    "ip_address": "203.0.113.42"
  },
  "target": {
    "type": "save_data",
    "id": "save-abc123",
    "classification": "confidential"
  },
  "action": {
    "operation": "write",
    "status": "success"
  },
  "context": {
    "game_id": "game-deadbeef",
    "slot": 1,
    "encryption_key_id": "kek-v2"
  }
}
```

**Step 8: Response to Client**
```json
{
  "save_id": "save-abc123",
  "slot": 1,
  "created_at": "2024-01-15T10:30:00.000Z",
  "checksum_verified": true
}
```

### 12.3 Secret Rotation Example

```bash
# Manual rotation trigger
curl -X POST https://vault.internal:8200/v1/rotate/games/production/db/password \
  -H "X-Vault-Token: $ADMIN_TOKEN" \
  -d '{"immediate": false, "grace_period": 3600}'

# Response
{
  "rotation_id": "rot-xyz789",
  "status": "in_progress",
  "old_version": 3,
  "new_version": 4,
  "affected_services": ["game-api", "matchmaker", "analytics"],
  "estimated_completion": "2024-01-15T11:30:00.000Z"
}

# Check rotation status
curl https://vault.internal:8200/v1/rotate/rot-xyz789/status \
  -H "X-Vault-Token: $ADMIN_TOKEN"

# Response
{
  "rotation_id": "rot-xyz789",
  "status": "completed",
  "old_version": 3,
  "new_version": 4,
  "completed_at": "2024-01-15T10:45:00.000Z",
  "services_migrated": 3,
  "services_failed": 0
}
```

### 12.4 Incident Response Example

```bash
# Detection: Anomaly alert
[ALERT] Unusual secret access pattern detected
  Secret: /games/production/db/password
  Actor: service-account-analytics
  Access count: 10,000 in 5 minutes (baseline: 100/hour)
  Source IP: 198.51.100.99 (unknown)

# Automated response
1. Revoke all leases for affected secret
2. Block source IP at WAF
3. Force re-authentication for service account
4. Create incident INC-2024-001

# Manual verification
vault lease revoke -prefix=true /games/production/db/password
vault token revoke -mode=path auth/kubernetes/role/analytics

# Emergency rotation
vault write -f rotate/games/production/db/password

# Post-incident verification
vault read /games/production/db/password  # Verify new version active
vault audit query -start=2024-01-15T10:00:00 -actor=service-account-analytics
```

---

## APPENDIX A: Threat Model

| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| Secret exfiltration via compromised pod | Medium | Critical | Network policies, minimal permissions, runtime security |
| Vault credential stuffing | Low | High | Rate limiting, MFA, IP restrictions |
| Insider threat (malicious admin) | Low | Critical | Dual control, audit logging, approval workflows |
| TLS interception | Low | Critical | Certificate pinning, mTLS everywhere |
| Side-channel attacks | Low | Medium | Constant-time crypto, memory sanitization |
| Supply chain compromise | Medium | Critical | SLSA compliance, signed artifacts, SBOM |

## APPENDIX B: Compliance Mapping

| Control | SOC 2 | ISO 27001 | PCI-DSS | NIST 800-53 |
|---------|-------|-----------|---------|-------------|
| Encryption at rest | CC6.1 | A.10.1.1 | 3.4 | SC-28 |
| Encryption in transit | CC6.7 | A.13.2.1 | 4.1 | SC-8 |
| Access control | CC6.2 | A.9.1.1 | 7.1 | AC-3 |
| Audit logging | CC7.2 | A.12.4.1 | 10.2 | AU-6 |
| Key management | CC6.1 | A.10.1.2 | 3.5 | SC-12 |
| Incident response | CC7.4 | A.16.1.1 | 12.10 | IR-4 |

---

*Document Version: 1.0*
*Last Updated: 2024-01-15*
*Classification: Internal*
