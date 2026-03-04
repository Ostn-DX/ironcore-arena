# Domain 14: Handoff + Return Packet Protocol Specification
## AI-Native Game Studio OS - Inter-Agent Communication Protocol v1.0

---

## 1. PACKET STRUCTURE DEFINITION

### 1.1 Core HandoffPacket Schema

```haskell
data HandoffPacket = HandoffPacket {
  packet_id        :: UUID,           -- v4 UUID, collision-resistant
  timestamp        :: ISO8601,        -- UTC nanosecond precision
  source_agent     :: AgentID,        -- Fully qualified agent identifier
  target_agent     :: AgentID,        -- Destination agent identifier
  context          :: ContextPack,    -- Serialized state container
  priority         :: Priority,       -- 1-10 scale, 10=critical
  ttl              :: Seconds,        -- Time-to-live, 0=infinite
  signature        :: HMAC-SHA256,    -- Integrity verification
  hop_count        :: Int,            -- Max 16 hops, prevent loops
  trace_chain      :: [TraceNode]     -- Audit trail
}

type AgentID = String  -- Format: "domain{NN}_{agent_name}@{version}"
type Priority = Int    -- Range: [1,10], default=5
type Seconds = Int     -- Range: [0, 86400], 0=unlimited
```

### 1.2 Binary Encoding Format

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|        MAGIC (0x484F46)       |    Version    |  Encoding     |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Packet Length                         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                         Packet UUID (16 bytes)                +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                      Timestamp (8 bytes, ns)                  +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Source Agent Length  |      Source Agent (variable)          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Target Agent Length  |      Target Agent (variable)          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Priority |   TTL     | Hop Count |      Reserved (5 bytes)    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                      Signature (32 bytes)                     +
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Context Pack Length                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                    Context Pack (variable)                    |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**Total Fixed Header: 72 bytes**

---

## 2. CONTEXT SERIALIZATION FORMAT

### 2.1 ContextPack Structure

```typescript
interface ContextPack {
  schema_version: "1.0.0";
  encoding: "json" | "bson" | "msgpack" | "protobuf";
  compression: "none" | "gzip" | "zstd" | "lz4";
  encrypted: boolean;
  checksum: string;  // SHA-256 of uncompressed payload
  
  payload: {
    // Structured context data
    task_state: TaskState;
    memory_snapshot: MemorySnapshot;
    resource_handles: ResourceHandle[];
    execution_context: ExecutionContext;
    partial_results: Result[];
    metadata: ContextMetadata;
  };
}

interface TaskState {
  task_id: UUID;
  task_type: string;
  status: "pending" | "active" | "blocked" | "complete" | "failed";
  progress: number;  // 0.0 - 1.0
  checkpoint_id: UUID | null;
  dependencies: UUID[];
}

interface MemorySnapshot {
  working_memory: Record<string, unknown>;
  episodic_buffer: EpisodicEntry[];
  semantic_cache: SemanticEntry[];
  token_budget: {
    used: number;
    remaining: number;
    max: number;
  };
}

interface ResourceHandle {
  resource_id: UUID;
  resource_type: "file" | "db_connection" | "api_token" | "gpu_context";
  access_mode: "read" | "write" | "exclusive";
  lease_expiry: ISO8601 | null;
  handle_token: string;  // Opaque reference
}
```

### 2.2 Encoding Decision Matrix

| Payload Size | Encoding | Compression | Latency | Use Case |
|-------------|----------|-------------|---------|----------|
| < 1KB | JSON | none | <1ms | Control packets |
| 1KB-100KB | JSON | gzip | 1-5ms | Standard handoff |
| 100KB-10MB | MsgPack | zstd | 5-50ms | Large context |
| > 10MB | Protobuf | zstd | 50-200ms | Memory dump |

### 2.3 Base64 Binary Encoding

```python
def encode_binary_payload(data: bytes) -> str:
    """Encode binary data for JSON transport."""
    compressed = zstd.compress(data, level=3)
    encoded = base64.urlsafe_b64encode(compressed)
    return encoded.decode('ascii')

def decode_binary_payload(encoded: str) -> bytes:
    """Decode binary data from JSON transport."""
    compressed = base64.urlsafe_b64decode(encoded)
    return zstd.decompress(compressed)
```

---

## 3. HANDOFF TRIGGER CONDITIONS

### 3.1 Trigger Condition Table

| Condition ID | Metric | Threshold | Comparator | Action | Priority |
|-------------|--------|-----------|------------|--------|----------|
| CTX_OVF | context_size | 80% capacity | > | HANDOFF | 8 |
| TOK_EXH | token_remaining | 10% budget | < | HANDOFF | 9 |
| TSK_CMP | task_status | "complete" | == | RETURN | 5 |
| TSK_FAIL | task_status | "failed" | == | ESCALATE | 10 |
| TMO_EXP | elapsed_time | TTL * 0.9 | > | HANDOFF | 7 |
| DEP_BLK | blocked_deps | > 0 | > | DEFER | 4 |
| CAP_MISS | capability_match | 0.5 | < | ROUTE | 6 |
| MEM_PRS | memory_pressure | 85% | > | HANDOFF | 8 |
| ERR_RTE | error_rate | 0.3 | > | ESCALATE | 10 |
| SIG_INT | interrupt_flag | true | == | SUSPEND | 9 |

### 3.2 Trigger Evaluation Function

```python
HandoffTrigger = Callable[[AgentState], Optional[HandoffDecision]]

def evaluate_triggers(state: AgentState) -> HandoffDecision:
    """
    Evaluate all trigger conditions and return highest priority action.
    
    Returns: HandoffDecision = HANDOFF | RETURN | ESCALATE | DEFER | SUSPEND | CONTINUE
    """
    triggers = [
        (SIG_INT, lambda s: s.interrupt_flag, ESCALATE, 10),
        (ERR_RTE, lambda s: s.error_rate > 0.3, ESCALATE, 10),
        (TSK_FAIL, lambda s: s.task_status == "failed", ESCALATE, 10),
        (TOK_EXH, lambda s: s.token_remaining < 0.1 * s.token_max, HANDOFF, 9),
        (SIG_INT, lambda s: s.interrupt_flag, SUSPEND, 9),
        (CTX_OVF, lambda s: s.context_size > 0.8 * s.context_capacity, HANDOFF, 8),
        (MEM_PRS, lambda s: s.memory_pressure > 0.85, HANDOFF, 8),
        (TMO_EXP, lambda s: s.elapsed > 0.9 * s.ttl, HANDOFF, 7),
        (CAP_MISS, lambda s: s.capability_match < 0.5, ROUTE, 6),
        (TSK_CMP, lambda s: s.task_status == "complete", RETURN, 5),
        (DEP_BLK, lambda s: s.blocked_deps > 0, DEFER, 4),
    ]
    
    fired = [(action, priority) for cond, check, action, priority in triggers 
             if check(state)]
    
    if not fired:
        return CONTINUE
    
    # Return highest priority action
    return max(fired, key=lambda x: x[1])[0]
```

### 3.3 Hysteresis to Prevent Oscillation

```python
class TriggerHysteresis:
    """Prevent rapid handoff/return cycles."""
    
    def __init__(self, cooldown_seconds: float = 5.0):
        self.last_trigger_time: Dict[ConditionID, float] = {}
        self.cooldown = cooldown_seconds
    
    def can_fire(self, condition: ConditionID) -> bool:
        now = time.monotonic()
        last = self.last_trigger_time.get(condition, 0)
        if now - last > self.cooldown:
            self.last_trigger_time[condition] = now
            return True
        return False
```

---

## 4. RETURN PACKET VALIDATION

### 4.1 Validation Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    RETURN PACKET VALIDATION                      │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Syntax Validation                                      │
│    ✓ Schema conformance (JSON Schema validation)                │
│    ✓ Required fields present                                    │
│    ✓ Type correctness                                           │
│    ✓ UUID format validation                                     │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: Semantic Validation                                    │
│    ✓ Timestamp bounds (not future, not stale > TTL)            │
│    ✓ Agent ID format validation                                 │
│    ✓ Priority range [1,10]                                      │
│    ✓ Hop count < max_hops                                       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: Integrity Validation                                   │
│    ✓ HMAC-SHA256 signature verification                         │
│    ✓ Context checksum validation                                │
│    ✓ Sequence number continuity                                 │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: Context Validation                                     │
│    ✓ Task state consistency                                     │
│    ✓ Resource handle validity                                   │
│    ✓ Memory snapshot integrity                                  │
│    ✓ Dependency graph acyclicity                                │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: Business Logic Validation                              │
│    ✓ Source agent authorization                                 │
│    ✓ Task ownership verification                                │
│    ✓ Result completeness check                                  │
│    ✓ Escalation path validity                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Validation Functions

```python
class ReturnValidator:
    """Five-layer validation for return packets."""
    
    def validate(self, packet: HandoffPacket) -> ValidationResult:
        errors = []
        
        # Layer 1: Syntax
        syntax_errors = self._validate_syntax(packet)
        if syntax_errors:
            return ValidationResult(False, "SYNTAX", syntax_errors)
        
        # Layer 2: Semantic
        semantic_errors = self._validate_semantic(packet)
        if semantic_errors:
            return ValidationResult(False, "SEMANTIC", semantic_errors)
        
        # Layer 3: Integrity
        if not self._verify_signature(packet):
            return ValidationResult(False, "INTEGRITY", ["Invalid signature"])
        
        # Layer 4: Context
        context_errors = self._validate_context(packet.context)
        if context_errors:
            return ValidationResult(False, "CONTEXT", context_errors)
        
        # Layer 5: Business Logic
        logic_errors = self._validate_business_logic(packet)
        if logic_errors:
            return ValidationResult(False, "BUSINESS_LOGIC", logic_errors)
        
        return ValidationResult(True, "OK", [])
    
    def _verify_signature(self, packet: HandoffPacket) -> bool:
        """Verify HMAC-SHA256 signature."""
        computed = hmac.new(
            key=self._get_agent_key(packet.source_agent),
            msg=self._canonicalize(packet),
            digestmod=hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(computed, packet.signature)
```

### 4.3 Validation Error Codes

| Code | Description | Recovery Action |
|------|-------------|-----------------|
| E1001 | Missing required field | Reject, request retransmission |
| E1002 | Invalid UUID format | Reject, log malformed packet |
| E1003 | Schema validation failed | Reject, send schema version mismatch |
| E2001 | Timestamp in future | Reject, check clock sync |
| E2002 | Packet expired (TTL) | Reject, request fresh packet |
| E2003 | Invalid agent ID | Reject, log unauthorized source |
| E3001 | Signature mismatch | Reject, potential tampering |
| E3002 | Checksum failure | Reject, data corruption |
| E4001 | Invalid task state | Reject, request state clarification |
| E4002 | Resource handle expired | Reject, request resource refresh |
| E5001 | Unauthorized source | Reject, escalate to security |
| E5002 | Task ownership conflict | Reject, request arbitration |

---

## 5. STATE RECONSTRUCTION PROCEDURES

### 5.1 Reconstruction Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATE RECONSTRUCTION                          │
├─────────────────────────────────────────────────────────────────┤
│  Phase 1: Packet Reception                                       │
│    → Receive and buffer packet                                   │
│    → Validate packet structure                                   │
│    → Queue for processing                                        │
├─────────────────────────────────────────────────────────────────┤
│  Phase 2: Context Extraction                                     │
│    → Decompress context pack                                     │
│    → Decode based on encoding type                               │
│    → Verify checksum                                             │
├─────────────────────────────────────────────────────────────────┤
│  Phase 3: Memory Restoration                                     │
│    → Restore working memory                                      │
│    → Rebuild episodic buffer                                     │
│    → Load semantic cache                                         │
├─────────────────────────────────────────────────────────────────┤
│  Phase 4: Resource Reconnection                                  │
│    → Validate resource handles                                   │
│    → Reconnect to resources                                      │
│    → Acquire locks if needed                                     │
├─────────────────────────────────────────────────────────────────┤
│  Phase 5: Task Continuation                                      │
│    → Restore task state                                          │
│    → Rebuild dependency graph                                    │
│    → Resume execution                                            │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 State Reconstruction Algorithm

```python
class StateReconstructor:
    """Reconstruct agent state from handoff packet."""
    
    async def reconstruct(self, packet: HandoffPacket) -> AgentState:
        """Full state reconstruction from validated packet."""
        
        # Phase 1: Decode context
        context = await self._decode_context(packet.context)
        
        # Phase 2: Restore memory
        memory = self._restore_memory(context.memory_snapshot)
        
        # Phase 3: Reconnect resources
        resources = await self._reconnect_resources(
            context.resource_handles,
            packet.source_agent
        )
        
        # Phase 4: Build task context
        task_ctx = self._build_task_context(
            context.task_state,
            context.execution_context,
            context.partial_results
        )
        
        # Phase 5: Assemble final state
        return AgentState(
            agent_id=packet.target_agent,
            memory=memory,
            resources=resources,
            task_context=task_ctx,
            received_from=packet.source_agent,
            received_at=datetime.utcnow(),
            packet_id=packet.packet_id
        )
    
    async def _decode_context(self, pack: ContextPack) -> DecodedContext:
        """Decode and decompress context pack."""
        # Decompress
        if pack.compression != "none":
            decompressor = self._get_decompressor(pack.compression)
            raw = decompressor.decompress(pack.payload_bytes)
        else:
            raw = pack.payload_bytes
        
        # Verify checksum
        if hashlib.sha256(raw).hexdigest() != pack.checksum:
            raise ChecksumError("Context pack checksum mismatch")
        
        # Decode
        decoder = self._get_decoder(pack.encoding)
        return decoder.decode(raw)
    
    async def _reconnect_resources(
        self, 
        handles: List[ResourceHandle],
        source_agent: AgentID
    ) -> Dict[UUID, ResourceConnection]:
        """Reconnect to resources from handles."""
        connections = {}
        for handle in handles:
            try:
                conn = await self._resource_manager.reconnect(
                    handle,
                    source_agent
                )
                connections[handle.resource_id] = conn
            except ResourceExpiredError:
                # Mark for reacquisition
                connections[handle.resource_id] = None
        return connections
```

### 5.3 Checkpoint-Based Recovery

```python
@dataclass
class Checkpoint:
    """Immutable state checkpoint for rollback."""
    checkpoint_id: UUID
    parent_id: Optional[UUID]
    state_hash: str
    created_at: datetime
    packet_ref: Optional[UUID]

class CheckpointManager:
    """Manage state checkpoints for recovery."""
    
    def create_checkpoint(self, state: AgentState) -> Checkpoint:
        """Create immutable checkpoint of current state."""
        state_hash = self._hash_state(state)
        checkpoint = Checkpoint(
            checkpoint_id=uuid4(),
            parent_id=self._current_checkpoint_id,
            state_hash=state_hash,
            created_at=datetime.utcnow(),
            packet_ref=None
        )
        self._store_checkpoint(checkpoint, state)
        return checkpoint
    
    def rollback(self, checkpoint_id: UUID) -> AgentState:
        """Rollback to checkpoint state."""
        checkpoint = self._load_checkpoint(checkpoint_id)
        state = self._load_state(checkpoint_id)
        
        # Verify integrity
        if self._hash_state(state) != checkpoint.state_hash:
            raise IntegrityError("Checkpoint state hash mismatch")
        
        return state
```

---

## 6. ERROR HANDLING

### 6.1 Error Classification

```
Error Hierarchy:
├── ProtocolError
│   ├── PacketError
│   │   ├── MalformedPacketError
│   │   ├── InvalidSignatureError
│   │   └── ExpiredPacketError
│   ├── ContextError
│   │   ├── DecompressionError
│   │   ├── DecodingError
│   │   └── ChecksumError
│   └── RoutingError
│       ├── AgentNotFoundError
│       ├── LoopDetectedError
│       └── CapacityExceededError
├── StateError
│   ├── ReconstructionError
│   ├── ResourceError
│   │   ├── ResourceExpiredError
│   │   ├── ResourceConflictError
│   │   └── ResourceUnavailableError
│   └── TaskError
│       ├── TaskStateError
│       └── DependencyError
└── SystemError
    ├── TimeoutError
    ├── NetworkError
    └── StorageError
```

### 6.2 Error Recovery Strategies

| Error Type | Retry | Fallback | Escalate | Abort |
|-----------|-------|----------|----------|-------|
| Packet corruption | 3x exponential | Request retransmit | After retries | Never |
| Signature failure | Never | Reject packet | Immediately | Never |
| Resource expired | 1x | Reacquire resource | If reacquire fails | Never |
| State inconsistency | Never | Rollback checkpoint | Immediately | If no checkpoint |
| Agent unavailable | 5x linear | Route to alternate | After retries | Never |
| Timeout | 2x exponential | Degrade gracefully | If critical | After all retries |
| Loop detected | Never | Break loop, notify | Immediately | Never |

### 6.3 Error Handler Implementation

```python
class ErrorHandler:
    """Centralized error handling for handoff protocol."""
    
    def __init__(self):
        self.retry_policies: Dict[Type[Exception], RetryPolicy] = {
            PacketError: RetryPolicy(max_retries=3, backoff="exponential"),
            ResourceError: RetryPolicy(max_retries=1, backoff="fixed"),
            NetworkError: RetryPolicy(max_retries=5, backoff="linear"),
        }
    
    async def handle(
        self, 
        error: Exception,
        context: ErrorContext
    ) -> ErrorResolution:
        """Handle error with appropriate strategy."""
        
        error_type = type(error)
        
        # Check if retryable
        if error_type in self.retry_policies:
            policy = self.retry_policies[error_type]
            if context.retry_count < policy.max_retries:
                delay = policy.calculate_delay(context.retry_count)
                return ErrorResolution(
                    action=RETRY,
                    delay=delay,
                    updated_context=context.increment_retry()
                )
        
        # Non-retryable errors
        if isinstance(error, (InvalidSignatureError, LoopDetectedError)):
            return ErrorResolution(
                action=ESCALATE,
                escalation_target="orchestrator",
                reason=str(error)
            )
        
        if isinstance(error, StateError):
            if context.checkpoint_available:
                return ErrorResolution(
                    action=ROLLBACK,
                    checkpoint_id=context.last_checkpoint
                )
            else:
                return ErrorResolution(
                    action=ESCALATE,
                    escalation_target="orchestrator",
                    reason="State error with no checkpoint"
                )
        
        return ErrorResolution(action=ABORT, reason=str(error))
```

### 6.4 Circuit Breaker Pattern

```python
class CircuitBreaker:
    """Prevent cascade failures."""
    
    STATE_CLOSED = "closed"      # Normal operation
    STATE_OPEN = "open"          # Failing, reject requests
    STATE_HALF_OPEN = "half_open"  # Testing recovery
    
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0,
        half_open_max_calls: int = 3
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.half_open_max_calls = half_open_max_calls
        
        self.state = self.STATE_CLOSED
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
        self.half_open_calls = 0
    
    def can_execute(self) -> bool:
        if self.state == self.STATE_CLOSED:
            return True
        
        if self.state == self.STATE_OPEN:
            if time.monotonic() - self.last_failure_time > self.recovery_timeout:
                self.state = self.STATE_HALF_OPEN
                self.half_open_calls = 0
                return True
            return False
        
        if self.state == self.STATE_HALF_OPEN:
            if self.half_open_calls < self.half_open_max_calls:
                self.half_open_calls += 1
                return True
            return False
    
    def record_success(self):
        if self.state == self.STATE_HALF_OPEN:
            self.state = self.STATE_CLOSED
            self.failure_count = 0
    
    def record_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.monotonic()
        
        if self.state == self.STATE_HALF_OPEN:
            self.state = self.STATE_OPEN
        elif self.failure_count >= self.failure_threshold:
            self.state = self.STATE_OPEN
```

---

## 7. SUCCESS CRITERIA (MEASURABLE)

### 7.1 Quantitative Metrics

| Metric ID | Description | Target | Measurement |
|-----------|-------------|--------|-------------|
| S001 | Handoff latency (p50) | < 50ms | `t_receive - t_send` |
| S002 | Handoff latency (p99) | < 200ms | `t_receive - t_send` |
| S003 | State reconstruction time | < 100ms | `t_ready - t_receive` |
| S004 | Packet validation rate | > 99.9% | `valid / total` |
| S005 | Successful handoff rate | > 99.5% | `success / attempts` |
| S006 | Zero data loss | 100% | `context_integrity_check` |
| S007 | Resource reconnection rate | > 98% | `reconnected / total_handles` |
| S008 | Task continuity | 100% | `task_resumed / task_transferred` |
| S009 | Error recovery rate | > 95% | `recovered / errors` |
| S010 | End-to-end latency | < 500ms | `t_complete - t_initiate` |

### 7.2 Success Measurement Framework

```python
@dataclass
class HandoffMetrics:
    """Metrics collection for handoff operations."""
    
    # Latency metrics (milliseconds)
    latency_send_to_receive: Histogram
    latency_receive_to_ready: Histogram
    latency_end_to_end: Histogram
    
    # Success rate metrics
    validation_success: Counter
    handoff_success: Counter
    handoff_failure: Counter
    
    # Data integrity metrics
    checksum_validations: Counter
    checksum_failures: Counter
    context_corruptions: Counter
    
    # Resource metrics
    resource_reconnections: Counter
    resource_failures: Counter
    
    # Task metrics
    tasks_transferred: Counter
    tasks_resumed: Counter
    tasks_failed: Counter

class MetricsCollector:
    """Collect and report handoff metrics."""
    
    def record_handoff(
        self,
        packet: HandoffPacket,
        result: HandoffResult,
        timing: TimingData
    ):
        """Record metrics for a handoff operation."""
        
        # Latency
        self.metrics.latency_send_to_receive.observe(
            timing.received - timing.sent
        )
        self.metrics.latency_receive_to_ready.observe(
            timing.ready - timing.received
        )
        
        # Success/failure
        if result.success:
            self.metrics.handoff_success.inc()
            self.metrics.tasks_transferred.inc()
            if result.task_resumed:
                self.metrics.tasks_resumed.inc()
        else:
            self.metrics.handoff_failure.inc()
            self.metrics.tasks_failed.inc()
    
    def get_sla_compliance(self) -> Dict[str, float]:
        """Calculate SLA compliance percentages."""
        return {
            "handoff_success_rate": (
                self.metrics.handoff_success.value /
                (self.metrics.handoff_success.value + 
                 self.metrics.handoff_failure.value)
            ),
            "validation_rate": (
                self.metrics.validation_success.value /
                (self.metrics.validation_success.value +
                 self.metrics.checksum_failures.value)
            ),
            "resource_reconnection_rate": (
                self.metrics.resource_reconnections.value /
                (self.metrics.resource_reconnections.value +
                 self.metrics.resource_failures.value)
            )
        }
```

### 7.3 Success Criteria Checklist

```yaml
handoff_success_criteria:
  performance:
    - latency_p50: "< 50ms"
    - latency_p99: "< 200ms"
    - throughput: "> 1000 handoffs/sec"
  
  reliability:
    - availability: "99.99%"
    - success_rate: "> 99.5%"
    - zero_data_loss: "required"
  
  correctness:
    - state_consistency: "100%"
    - task_continuity: "100%"
    - resource_integrity: "> 98%"
  
  recoverability:
    - automatic_recovery: "> 95%"
    - max_recovery_time: "< 5s"
    - checkpoint_restore: "< 100ms"
```

---

## 8. FAILURE STATES

### 8.1 Failure State Matrix

| State ID | Description | Cause | Detection | Recovery |
|----------|-------------|-------|-----------|----------|
| F001 | Packet Loss | Network failure | Timeout | Retransmit, log |
| F002 | State Corruption | Memory/bit error | Checksum fail | Rollback checkpoint |
| F003 | Resource Deadlock | Circular wait | Timeout | Kill and restart |
| F004 | Agent Crash | Runtime error | Heartbeat loss | Restart, restore state |
| F005 | Routing Loop | Misconfiguration | Hop count exceeded | Break, notify orchestrator |
| F006 | Context Overflow | State too large | Size limit exceeded | Compress, chunk, retry |
| F007 | Signature Failure | Tampering/key error | HMAC mismatch | Reject, security alert |
| F008 | Version Mismatch | Protocol drift | Schema validation fail | Negotiate version |
| F009 | Capacity Exhausted | Resource limits | Queue full | Backpressure, queue |
| F010 | Dependency Cycle | Task graph error | Cycle detection | Break cycle, escalate |

### 8.2 Failure State Machine

```
                    ┌─────────────┐
                    │   NORMAL    │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │  DEGRADED  │  │  RECOVERY  │  │   FAILED   │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          │               │               │
          │    success    │               │
          └──────────────►│               │
                          │   success     │
                          └──────────────►│
                                          │
                          ◄───────────────┘
                              manual reset
```

### 8.3 Failure Recovery Procedures

```python
class FailureRecovery:
    """Handle failure state recovery."""
    
    async def recover_packet_loss(
        self,
        expected_packet_id: UUID,
        source_agent: AgentID
    ) -> HandoffPacket:
        """Recover from packet loss."""
        # Request retransmission
        for attempt in range(3):
            try:
                packet = await self._request_retransmit(
                    expected_packet_id,
                    source_agent,
                    timeout=5.0 * (2 ** attempt)
                )
                return packet
            except TimeoutError:
                continue
        
        # All retries failed
        raise UnrecoverableError(f"Packet {expected_packet_id} lost")
    
    async def recover_state_corruption(
        self,
        packet: HandoffPacket,
        checkpoint_manager: CheckpointManager
    ) -> AgentState:
        """Recover from state corruption."""
        # Try to find valid checkpoint
        checkpoints = checkpoint_manager.list_checkpoints(
            task_id=packet.context.payload.task_state.task_id
        )
        
        for checkpoint in sorted(checkpoints, key=lambda c: c.created_at, reverse=True):
            try:
                state = checkpoint_manager.rollback(checkpoint.checkpoint_id)
                return state
            except IntegrityError:
                continue
        
        # No valid checkpoint
        raise UnrecoverableError("No valid checkpoint for recovery")
    
    async def recover_resource_deadlock(
        self,
        resources: List[ResourceHandle]
    ) -> None:
        """Recover from resource deadlock."""
        # Detect cycle
        cycle = self._detect_deadlock_cycle(resources)
        
        if cycle:
            # Select victim (youngest transaction)
            victim = min(cycle, key=lambda r: r.acquired_at)
            
            # Abort victim
            await self._abort_resource(victim)
            
            # Notify orchestrator
            await self._notify_deadlock_resolved(cycle, victim)
```

---

## 9. INTEGRATION SURFACE

### 9.1 API Surface

```python
# Core Handoff API
class HandoffAPI:
    """Public API for handoff protocol integration."""
    
    @abstractmethod
    async def initiate_handoff(
        self,
        target_agent: AgentID,
        context: ContextPack,
        options: HandoffOptions = None
    ) -> HandoffResult:
        """Initiate handoff to target agent."""
        pass
    
    @abstractmethod
    async def receive_handoff(
        self,
        packet: HandoffPacket
    ) -> ReceiveResult:
        """Receive and process handoff packet."""
        pass
    
    @abstractmethod
    async def return_result(
        self,
        original_packet: HandoffPacket,
        result: TaskResult,
        options: ReturnOptions = None
    ) -> ReturnResult:
        """Return result to originating agent."""
        pass
    
    @abstractmethod
    async def query_status(
        self,
        packet_id: UUID
    ) -> HandoffStatus:
        """Query status of in-flight handoff."""
        pass

# Event Interface
class HandoffEventHandler:
    """Event handler interface for handoff events."""
    
    async def on_handoff_initiated(self, event: HandoffInitiatedEvent): pass
    async def on_handoff_received(self, event: HandoffReceivedEvent): pass
    async def on_handoff_completed(self, event: HandoffCompletedEvent): pass
    async def on_handoff_failed(self, event: HandoffFailedEvent): pass
    async def on_return_received(self, event: ReturnReceivedEvent): pass
```

### 9.2 Integration Points

```
┌─────────────────────────────────────────────────────────────────┐
│                    INTEGRATION SURFACE                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Agent A    │◄──►│   Handoff    │◄──►│   Agent B    │      │
│  │   (Source)   │    │   Router     │    │  (Target)    │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   │                   │                │
│         │            ┌──────┴──────┐           │                │
│         │            │             │           │                │
│         ▼            ▼             ▼           ▼                │
│  ┌──────────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐       │
│  │   State      │ │ Queue  │ │Metrics │ │   State      │       │
│  │   Manager    │ │ Manager│ │ Collector  │   Manager    │       │
│  └──────────────┘ └────────┘ └────────┘ └──────────────┘       │
│                                                                  │
│  External Interfaces:                                            │
│  ├── Message Bus (Redis/RabbitMQ/Kafka)                         │
│  ├── Service Mesh (gRPC/HTTP2)                                  │
│  ├── Storage (PostgreSQL/MongoDB/S3)                            │
│  └── Monitoring (Prometheus/Grafana)                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 9.3 Configuration Schema

```yaml
handoff_protocol:
  # Transport configuration
  transport:
    type: "grpc"  # grpc | http2 | message_bus
    grpc:
      port: 50051
      max_message_size: 16777216  # 16MB
      keepalive:
        time: 10s
        timeout: 20s
    
  # Queue configuration
  queue:
    type: "redis"
    redis:
      host: "localhost"
      port: 6379
      db: 0
      max_queue_size: 10000
    
  # State management
  state:
    storage: "postgresql"
    postgresql:
      connection_string: "postgresql://..."
      pool_size: 10
    checkpoint:
      enabled: true
      interval_seconds: 30
      retention_count: 10
    
  # Security
  security:
    signature_algorithm: "HMAC-SHA256"
    key_rotation_interval: 86400  # 24 hours
    
  # Performance tuning
  performance:
    max_concurrent_handoffs: 1000
    default_ttl_seconds: 300
    compression_threshold_bytes: 1024
    
  # Monitoring
  monitoring:
    metrics_enabled: true
    tracing_enabled: true
    log_level: "INFO"
```

---

## 10. JSON SCHEMAS

### 10.1 HandoffPacket Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.ai/schemas/handoff-packet-v1.json",
  "title": "HandoffPacket",
  "type": "object",
  "required": [
    "packet_id",
    "timestamp",
    "source_agent",
    "target_agent",
    "context",
    "priority",
    "ttl",
    "signature"
  ],
  "properties": {
    "packet_id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique identifier for this packet"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO8601 timestamp with nanosecond precision"
    },
    "source_agent": {
      "type": "string",
      "pattern": "^domain[0-9]{2}_[a-z_]+@[0-9]+\\.[0-9]+\\.[0-9]+$",
      "description": "Fully qualified source agent identifier"
    },
    "target_agent": {
      "type": "string",
      "pattern": "^domain[0-9]{2}_[a-z_]+@[0-9]+\\.[0-9]+\\.[0-9]+$",
      "description": "Fully qualified target agent identifier"
    },
    "context": {
      "$ref": "#/definitions/ContextPack"
    },
    "priority": {
      "type": "integer",
      "minimum": 1,
      "maximum": 10,
      "default": 5,
      "description": "Priority level, 10 is highest"
    },
    "ttl": {
      "type": "integer",
      "minimum": 0,
      "maximum": 86400,
      "default": 300,
      "description": "Time-to-live in seconds, 0 is infinite"
    },
    "hop_count": {
      "type": "integer",
      "minimum": 0,
      "maximum": 16,
      "default": 0,
      "description": "Number of hops this packet has traversed"
    },
    "trace_chain": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/TraceNode"
      },
      "maxItems": 16,
      "description": "Audit trail of packet routing"
    },
    "signature": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$",
      "description": "HMAC-SHA256 signature in hex"
    }
  },
  "definitions": {
    "ContextPack": {
      "type": "object",
      "required": [
        "schema_version",
        "encoding",
        "compression",
        "encrypted",
        "checksum",
        "payload"
      ],
      "properties": {
        "schema_version": {
          "type": "string",
          "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
          "description": "Schema version of context pack"
        },
        "encoding": {
          "type": "string",
          "enum": ["json", "bson", "msgpack", "protobuf"],
          "description": "Encoding format of payload"
        },
        "compression": {
          "type": "string",
          "enum": ["none", "gzip", "zstd", "lz4"],
          "description": "Compression algorithm used"
        },
        "encrypted": {
          "type": "boolean",
          "description": "Whether payload is encrypted"
        },
        "checksum": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$",
          "description": "SHA-256 checksum of uncompressed payload"
        },
        "payload": {
          "type": "object",
          "required": ["task_state", "memory_snapshot"],
          "properties": {
            "task_state": {
              "$ref": "#/definitions/TaskState"
            },
            "memory_snapshot": {
              "$ref": "#/definitions/MemorySnapshot"
            },
            "resource_handles": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/ResourceHandle"
              }
            },
            "execution_context": {
              "type": "object"
            },
            "partial_results": {
              "type": "array"
            },
            "metadata": {
              "type": "object"
            }
          }
        }
      }
    },
    "TaskState": {
      "type": "object",
      "required": ["task_id", "task_type", "status", "progress"],
      "properties": {
        "task_id": {
          "type": "string",
          "format": "uuid"
        },
        "task_type": {
          "type": "string"
        },
        "status": {
          "type": "string",
          "enum": ["pending", "active", "blocked", "complete", "failed"]
        },
        "progress": {
          "type": "number",
          "minimum": 0.0,
          "maximum": 1.0
        },
        "checkpoint_id": {
          "type": ["string", "null"],
          "format": "uuid"
        },
        "dependencies": {
          "type": "array",
          "items": {
            "type": "string",
            "format": "uuid"
          }
        }
      }
    },
    "MemorySnapshot": {
      "type": "object",
      "required": ["working_memory", "token_budget"],
      "properties": {
        "working_memory": {
          "type": "object"
        },
        "episodic_buffer": {
          "type": "array"
        },
        "semantic_cache": {
          "type": "array"
        },
        "token_budget": {
          "type": "object",
          "required": ["used", "remaining", "max"],
          "properties": {
            "used": {
              "type": "integer",
              "minimum": 0
            },
            "remaining": {
              "type": "integer",
              "minimum": 0
            },
            "max": {
              "type": "integer",
              "minimum": 1
            }
          }
        }
      }
    },
    "ResourceHandle": {
      "type": "object",
      "required": [
        "resource_id",
        "resource_type",
        "access_mode",
        "handle_token"
      ],
      "properties": {
        "resource_id": {
          "type": "string",
          "format": "uuid"
        },
        "resource_type": {
          "type": "string",
          "enum": ["file", "db_connection", "api_token", "gpu_context"]
        },
        "access_mode": {
          "type": "string",
          "enum": ["read", "write", "exclusive"]
        },
        "lease_expiry": {
          "type": ["string", "null"],
          "format": "date-time"
        },
        "handle_token": {
          "type": "string"
        }
      }
    },
    "TraceNode": {
      "type": "object",
      "required": ["agent_id", "timestamp", "action"],
      "properties": {
        "agent_id": {
          "type": "string"
        },
        "timestamp": {
          "type": "string",
          "format": "date-time"
        },
        "action": {
          "type": "string",
          "enum": ["received", "processed", "forwarded", "returned"]
        }
      }
    }
  }
}
```

### 10.2 ReturnPacket Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://gamestudio.ai/schemas/return-packet-v1.json",
  "title": "ReturnPacket",
  "type": "object",
  "required": [
    "return_packet_id",
    "original_packet_id",
    "timestamp",
    "source_agent",
    "target_agent",
    "result",
    "signature"
  ],
  "properties": {
    "return_packet_id": {
      "type": "string",
      "format": "uuid"
    },
    "original_packet_id": {
      "type": "string",
      "format": "uuid"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "source_agent": {
      "type": "string"
    },
    "target_agent": {
      "type": "string"
    },
    "result": {
      "type": "object",
      "required": ["status"],
      "properties": {
        "status": {
          "type": "string",
          "enum": ["success", "failure", "partial"]
        },
        "data": {
          "type": "object"
        },
        "error": {
          "type": "object",
          "properties": {
            "code": {
              "type": "string"
            },
            "message": {
              "type": "string"
            },
            "details": {
              "type": "object"
            }
          }
        },
        "metrics": {
          "type": "object",
          "properties": {
            "processing_time_ms": {
              "type": "number"
            },
            "tokens_used": {
              "type": "integer"
            }
          }
        }
      }
    },
    "signature": {
      "type": "string",
      "pattern": "^[a-f0-9]{64}$"
    }
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Implementation

```python
# ============================================================
# HANDOFF + RETURN PACKET PROTOCOL - PSEUDO-IMPLEMENTATION
# ============================================================

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable, Any
from enum import Enum, auto
from uuid import uuid4, UUID
from datetime import datetime
import hashlib
import hmac
import json
import asyncio

# -----------------------------------------------------------
# Type Definitions
# -----------------------------------------------------------

class HandoffAction(Enum):
    HANDOFF = auto()
    RETURN = auto()
    ESCALATE = auto()
    DEFER = auto()
    SUSPEND = auto()
    CONTINUE = auto()
    ROUTE = auto()

class Priority(Enum):
    CRITICAL = 10
    HIGH = 8
    NORMAL = 5
    LOW = 3
    BACKGROUND = 1

@dataclass(frozen=True)
class AgentID:
    domain: int
    name: str
    version: str
    
    def __str__(self) -> str:
        return f"domain{self.domain:02d}_{self.name}@{self.version}"

# -----------------------------------------------------------
# Packet Structure
# -----------------------------------------------------------

@dataclass
class HandoffPacket:
    packet_id: UUID
    timestamp: datetime
    source_agent: AgentID
    target_agent: AgentID
    context: 'ContextPack'
    priority: int = 5
    ttl: int = 300
    hop_count: int = 0
    trace_chain: List['TraceNode'] = field(default_factory=list)
    signature: Optional[str] = None
    
    def __post_init__(self):
        if self.signature is None:
            self.signature = self._compute_signature()
    
    def _compute_signature(self) -> str:
        """Compute HMAC-SHA256 signature."""
        canonical = self._canonicalize()
        key = _get_agent_key(self.source_agent)
        return hmac.new(
            key=key.encode(),
            msg=canonical.encode(),
            digestmod=hashlib.sha256
        ).hexdigest()
    
    def _canonicalize(self) -> str:
        """Create canonical representation for signing."""
        data = {
            "packet_id": str(self.packet_id),
            "timestamp": self.timestamp.isoformat(),
            "source_agent": str(self.source_agent),
            "target_agent": str(self.target_agent),
            "context_checksum": self.context.checksum,
            "priority": self.priority,
            "ttl": self.ttl,
            "hop_count": self.hop_count,
        }
        return json.dumps(data, sort_keys=True, separators=(',', ':'))
    
    def verify(self) -> bool:
        """Verify packet signature."""
        computed = self._compute_signature()
        return hmac.compare_digest(computed, self.signature or "")

@dataclass
class ContextPack:
    schema_version: str = "1.0.0"
    encoding: str = "json"
    compression: str = "none"
    encrypted: bool = False
    checksum: str = ""
    payload: Dict[str, Any] = field(default_factory=dict)
    payload_bytes: Optional[bytes] = None
    
    def __post_init__(self):
        if not self.checksum and self.payload_bytes:
            self.checksum = hashlib.sha256(self.payload_bytes).hexdigest()
    
    @classmethod
    def from_payload(
        cls,
        payload: Dict[str, Any],
        encoding: str = "json",
        compression: str = "none"
    ) -> 'ContextPack':
        """Create context pack from payload."""
        encoder = _get_encoder(encoding)
        raw = encoder.encode(payload)
        
        if compression != "none":
            compressor = _get_compressor(compression)
            raw = compressor.compress(raw)
        
        checksum = hashlib.sha256(
            encoder.encode(payload)
        ).hexdigest()
        
        return cls(
            encoding=encoding,
            compression=compression,
            checksum=checksum,
            payload=payload,
            payload_bytes=raw
        )

@dataclass
class TraceNode:
    agent_id: AgentID
    timestamp: datetime
    action: str  # received | processed | forwarded | returned

# -----------------------------------------------------------
# Handoff Manager
# -----------------------------------------------------------

class HandoffManager:
    """Central manager for handoff operations."""
    
    def __init__(
        self,
        agent_id: AgentID,
        router: 'HandoffRouter',
        state_manager: 'StateManager',
        metrics: 'MetricsCollector'
    ):
        self.agent_id = agent_id
        self.router = router
        self.state_manager = state_manager
        self.metrics = metrics
        self.pending_handoffs: Dict[UUID, HandoffPacket] = {}
        self.circuit_breakers: Dict[AgentID, 'CircuitBreaker'] = {}
    
    async def initiate_handoff(
        self,
        target_agent: AgentID,
        context: ContextPack,
        priority: int = 5,
        ttl: int = 300
    ) -> 'HandoffResult':
        """Initiate handoff to target agent."""
        
        # Check circuit breaker
        cb = self._get_circuit_breaker(target_agent)
        if not cb.can_execute():
            return HandoffResult(
                success=False,
                error="Circuit breaker open"
            )
        
        # Create packet
        packet = HandoffPacket(
            packet_id=uuid4(),
            timestamp=datetime.utcnow(),
            source_agent=self.agent_id,
            target_agent=target_agent,
            context=context,
            priority=priority,
            ttl=ttl
        )
        
        # Store pending
        self.pending_handoffs[packet.packet_id] = packet
        
        try:
            # Route packet
            result = await self.router.route(packet)
            
            if result.success:
                cb.record_success()
                self.metrics.record_handoff_success(packet)
            else:
                cb.record_failure()
                self.metrics.record_handoff_failure(packet, result.error)
            
            return result
            
        except Exception as e:
            cb.record_failure()
            self.metrics.record_handoff_failure(packet, str(e))
            return HandoffResult(success=False, error=str(e))
    
    async def receive_handoff(
        self,
        packet: HandoffPacket
    ) -> 'ReceiveResult':
        """Receive and process incoming handoff."""
        
        # Validate packet
        validator = PacketValidator()
        validation = validator.validate(packet)
        
        if not validation.valid:
            self.metrics.record_validation_failure(packet, validation.errors)
            return ReceiveResult(
                success=False,
                error=f"Validation failed: {validation.errors}"
            )
        
        # Check hop count
        if packet.hop_count >= 16:
            return ReceiveResult(
                success=False,
                error="Hop count exceeded"
            )
        
        # Add trace node
        packet.trace_chain.append(TraceNode(
            agent_id=self.agent_id,
            timestamp=datetime.utcnow(),
            action="received"
        ))
        
        # Reconstruct state
        try:
            reconstructor = StateReconstructor(self.state_manager)
            state = await reconstructor.reconstruct(packet)
            
            self.metrics.record_receive_success(packet)
            
            return ReceiveResult(
                success=True,
                state=state,
                packet=packet
            )
            
        except Exception as e:
            self.metrics.record_receive_failure(packet, str(e))
            return ReceiveResult(success=False, error=str(e))
    
    async def return_result(
        self,
        original_packet: HandoffPacket,
        result: 'TaskResult'
    ) -> 'ReturnResult':
        """Return result to originating agent."""
        
        return_packet = ReturnPacket(
            return_packet_id=uuid4(),
            original_packet_id=original_packet.packet_id,
            timestamp=datetime.utcnow(),
            source_agent=self.agent_id,
            target_agent=original_packet.source_agent,
            result=result
        )
        
        return await self.router.route_return(return_packet)
    
    def _get_circuit_breaker(self, agent_id: AgentID) -> 'CircuitBreaker':
        """Get or create circuit breaker for agent."""
        if agent_id not in self.circuit_breakers:
            self.circuit_breakers[agent_id] = CircuitBreaker()
        return self.circuit_breakers[agent_id]

# -----------------------------------------------------------
# Trigger Evaluation
# -----------------------------------------------------------

class TriggerEvaluator:
    """Evaluate handoff trigger conditions."""
    
    TRIGGERS = [
        # (condition_id, check_fn, action, priority)
        ("SIG_INT", lambda s: s.interrupt_flag, HandoffAction.ESCALATE, 10),
        ("ERR_RTE", lambda s: s.error_rate > 0.3, HandoffAction.ESCALATE, 10),
        ("TSK_FAIL", lambda s: s.task_status == "failed", HandoffAction.ESCALATE, 10),
        ("TOK_EXH", lambda s: s.token_remaining < 0.1 * s.token_max, HandoffAction.HANDOFF, 9),
        ("CTX_OVF", lambda s: s.context_size > 0.8 * s.context_capacity, HandoffAction.HANDOFF, 8),
        ("MEM_PRS", lambda s: s.memory_pressure > 0.85, HandoffAction.HANDOFF, 8),
        ("TMO_EXP", lambda s: s.elapsed > 0.9 * s.ttl, HandoffAction.HANDOFF, 7),
        ("CAP_MISS", lambda s: s.capability_match < 0.5, HandoffAction.ROUTE, 6),
        ("TSK_CMP", lambda s: s.task_status == "complete", HandoffAction.RETURN, 5),
        ("DEP_BLK", lambda s: s.blocked_deps > 0, HandoffAction.DEFER, 4),
    ]
    
    def __init__(self, hysteresis_seconds: float = 5.0):
        self.last_trigger_time: Dict[str, float] = {}
        self.cooldown = hysteresis_seconds
    
    def evaluate(self, state: 'AgentState') -> HandoffAction:
        """Evaluate triggers and return highest priority action."""
        fired = []
        
        for cond_id, check, action, priority in self.TRIGGERS:
            if check(state) and self._can_fire(cond_id):
                fired.append((action, priority))
        
        if not fired:
            return HandoffAction.CONTINUE
        
        return max(fired, key=lambda x: x[1])[0]
    
    def _can_fire(self, condition_id: str) -> bool:
        """Check if trigger can fire (hysteresis)."""
        import time
        now = time.monotonic()
        last = self.last_trigger_time.get(condition_id, 0)
        
        if now - last > self.cooldown:
            self.last_trigger_time[condition_id] = now
            return True
        return False

# -----------------------------------------------------------
# Supporting Classes (Simplified)
# -----------------------------------------------------------

@dataclass
class HandoffResult:
    success: bool
    packet_id: Optional[UUID] = None
    error: Optional[str] = None
    latency_ms: Optional[float] = None

@dataclass
class ReceiveResult:
    success: bool
    state: Optional['AgentState'] = None
    packet: Optional[HandoffPacket] = None
    error: Optional[str] = None

@dataclass
class ReturnResult:
    success: bool
    error: Optional[str] = None

@dataclass
class ReturnPacket:
    return_packet_id: UUID
    original_packet_id: UUID
    timestamp: datetime
    source_agent: AgentID
    target_agent: AgentID
    result: 'TaskResult'
    signature: Optional[str] = None

@dataclass
class TaskResult:
    status: str  # success | failure | partial
    data: Dict[str, Any] = field(default_factory=dict)
    error: Optional[Dict[str, Any]] = None
    metrics: Optional[Dict[str, Any]] = None

class CircuitBreaker:
    STATE_CLOSED = "closed"
    STATE_OPEN = "open"
    STATE_HALF_OPEN = "half_open"
    
    def __init__(self, failure_threshold: int = 5, recovery_timeout: float = 30.0):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.state = self.STATE_CLOSED
        self.failure_count = 0
        self.last_failure_time: Optional[float] = None
    
    def can_execute(self) -> bool:
        import time
        if self.state == self.STATE_CLOSED:
            return True
        if self.state == self.STATE_OPEN:
            if time.monotonic() - self.last_failure_time > self.recovery_timeout:
                self.state = self.STATE_HALF_OPEN
                return True
            return False
        return True  # HALF_OPEN
    
    def record_success(self):
        if self.state == self.STATE_HALF_OPEN:
            self.state = self.STATE_CLOSED
            self.failure_count = 0
    
    def record_failure(self):
        import time
        self.failure_count += 1
        self.last_failure_time = time.monotonic()
        if self.failure_count >= self.failure_threshold:
            self.state = self.STATE_OPEN

# Helper functions (stubs)
def _get_agent_key(agent_id: AgentID) -> str:
    """Retrieve signing key for agent."""
    # Implementation: key store lookup
    return f"key_for_{agent_id}"

def _get_encoder(encoding: str) -> 'Encoder':
    """Get encoder for encoding type."""
    encoders = {
        "json": JsonEncoder(),
        "msgpack": MsgPackEncoder(),
        "protobuf": ProtobufEncoder(),
    }
    return encoders.get(encoding, JsonEncoder())

def _get_compressor(compression: str) -> 'Compressor':
    """Get compressor for compression type."""
    compressors = {
        "gzip": GzipCompressor(),
        "zstd": ZstdCompressor(),
        "lz4": LZ4Compressor(),
    }
    return compressors.get(compression, NullCompressor())

# Encoder/Compressor stubs
class JsonEncoder:
    def encode(self, data: Dict) -> bytes:
        return json.dumps(data).encode('utf-8')

class MsgPackEncoder:
    def encode(self, data: Dict) -> bytes:
        import msgpack
        return msgpack.packb(data)

class ProtobufEncoder:
    def encode(self, data: Dict) -> bytes:
        # Protobuf serialization
        pass

class GzipCompressor:
    def compress(self, data: bytes) -> bytes:
        import gzip
        return gzip.compress(data)

class ZstdCompressor:
    def compress(self, data: bytes) -> bytes:
        import zstandard
        return zstandard.ZstdCompressor().compress(data)

class LZ4Compressor:
    def compress(self, data: bytes) -> bytes:
        import lz4.frame
        return lz4.frame.compress(data)

class NullCompressor:
    def compress(self, data: bytes) -> bytes:
        return data

# Placeholder classes
class HandoffRouter:
    async def route(self, packet: HandoffPacket) -> HandoffResult:
        pass
    async def route_return(self, packet: ReturnPacket) -> ReturnResult:
        pass

class StateManager:
    pass

class StateReconstructor:
    def __init__(self, state_manager: StateManager):
        self.state_manager = state_manager
    async def reconstruct(self, packet: HandoffPacket) -> 'AgentState':
        pass

class PacketValidator:
    def validate(self, packet: HandoffPacket) -> 'ValidationResult':
        pass

class ValidationResult:
    def __init__(self, valid: bool, errors: List[str] = None):
        self.valid = valid
        self.errors = errors or []

class MetricsCollector:
    def record_handoff_success(self, packet: HandoffPacket):
        pass
    def record_handoff_failure(self, packet: HandoffPacket, error: str):
        pass
    def record_validation_failure(self, packet: HandoffPacket, errors: List[str]):
        pass
    def record_receive_success(self, packet: HandoffPacket):
        pass
    def record_receive_failure(self, packet: HandoffPacket, error: str):
        pass

class AgentState:
    pass
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Complete Handoff Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OPERATIONAL EXAMPLE                                  │
│                    Domain 3 → Domain 7 Task Handoff                          │
└─────────────────────────────────────────────────────────────────────────────┘

SCENARIO: Domain 3 (Asset Generation) needs to handoff to Domain 7 (Asset 
Validation) after generating a 3D character model.

STEP 1: TRIGGER EVALUATION (Domain 3)
───────────────────────────────────────
Agent State:
  - task_status: "complete"
  - context_size: 45MB / 100MB (45%)
  - token_remaining: 2000 / 8000 (25%)
  - elapsed_time: 45s / 300s TTL

Trigger Evaluation:
  - CTX_OVF: 45% < 80% → NOT FIRED
  - TOK_EXH: 25% > 10% → NOT FIRED
  - TSK_CMP: status == "complete" → FIRED (priority 5)

Action: RETURN (but target is validation, so route to Domain 7)

STEP 2: CONTEXT PACK CREATION (Domain 3)
────────────────────────────────────────
Task State:
  {
    "task_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "task_type": "character_generation",
    "status": "complete",
    "progress": 1.0,
    "checkpoint_id": "chk-001",
    "dependencies": []
  }

Memory Snapshot:
  {
    "working_memory": {
      "character_params": { "height": 1.8, "style": "realistic" },
      "generation_log": [...],
      "iterations": 5
    },
    "episodic_buffer": [...],
    "semantic_cache": [...],
    "token_budget": { "used": 6000, "remaining": 2000, "max": 8000 }
  }

Resource Handles:
  [
    {
      "resource_id": "res-001",
      "resource_type": "file",
      "access_mode": "read",
      "lease_expiry": "2024-01-15T10:30:00Z",
      "handle_token": "tok_abc123"
    },
    {
      "resource_id": "res-002",
      "resource_type": "gpu_context",
      "access_mode": "exclusive",
      "lease_expiry": null,
      "handle_token": "tok_def456"
    }
  ]

Partial Results:
  {
    "model_file": "s3://assets/char_001.fbx",
    "texture_files": ["s3://assets/char_001_diffuse.png", ...],
    "metadata": { "poly_count": 15000, "bone_count": 64 }
  }

Encoding Decision:
  - Payload size: ~2.5MB
  - Selected encoding: msgpack
  - Selected compression: zstd
  - Compressed size: ~450KB

STEP 3: PACKET CONSTRUCTION (Domain 3)
──────────────────────────────────────
HandoffPacket:
  packet_id: "pkt-001-uuid"
  timestamp: "2024-01-15T10:15:30.123456789Z"
  source_agent: "domain03_asset_generator@1.2.0"
  target_agent: "domain07_asset_validator@2.0.1"
  priority: 7  (high priority - validation needed)
  ttl: 300
  hop_count: 0
  trace_chain: []
  
  context:
    schema_version: "1.0.0"
    encoding: "msgpack"
    compression: "zstd"
    encrypted: false
    checksum: "a1b2c3d4e5f6..." (SHA-256)
    payload: <base64-encoded compressed data>
  
  signature: "h1j2k3l4m5n6..." (HMAC-SHA256)

STEP 4: PACKET TRANSMISSION
───────────────────────────
Transport: gRPC over HTTP/2
Message Size: ~72 bytes header + ~450KB payload = ~450KB total
Latency: 15ms (local network)

STEP 5: PACKET RECEPTION (Domain 7)
───────────────────────────────────
Received: "2024-01-15T10:15:30.138456789Z"

Validation Layer 1 (Syntax):
  ✓ Schema conforms to handoff-packet-v1.json
  ✓ All required fields present
  ✓ UUID format valid
  ✓ Priority in range [1,10]

Validation Layer 2 (Semantic):
  ✓ Timestamp not in future
  ✓ Packet not expired (15ms < 300s)
  ✓ Agent ID format valid
  ✓ Hop count < 16

Validation Layer 3 (Integrity):
  ✓ HMAC-SHA256 signature verified
  ✓ Context checksum verified
  ✓ Sequence continuity OK

Validation Layer 4 (Context):
  ✓ Task state consistent
  ✓ Resource handles valid
  ✓ Memory snapshot integrity OK

Validation Layer 5 (Business Logic):
  ✓ Source agent authorized
  ✓ Task ownership verified
  ✓ Result completeness check passed

STEP 6: STATE RECONSTRUCTION (Domain 7)
────────────────────────────────────────
Phase 1: Decode Context
  - Decompress: zstd.decompress(payload) → 2.5MB
  - Decode: msgpack.decode(raw) → Python dict
  - Verify checksum: SHA-256 matches
  - Time: 25ms

Phase 2: Restore Memory
  - Working memory: Loaded 15 entries
  - Episodic buffer: Loaded 50 entries
  - Semantic cache: Loaded 200 entries
  - Token budget: Set to {used: 6000, remaining: 2000, max: 8000}
  - Time: 10ms

Phase 3: Reconnect Resources
  - Resource res-001 (file): ✓ Validated, read access granted
  - Resource res-002 (gpu_context): ✓ Validated, exclusive access granted
  - Time: 30ms

Phase 4: Build Task Context
  - Task state: Restored
  - Execution context: Initialized
  - Partial results: Loaded
  - Time: 5ms

Total Reconstruction Time: 70ms

STEP 7: TASK EXECUTION (Domain 7)
─────────────────────────────────
Task: Validate generated character model

Execution:
  1. Load model from s3://assets/char_001.fbx
  2. Run topology validation
  3. Check UV mapping
  4. Verify bone weights
  5. Generate validation report

Result:
  {
    "status": "success",
    "data": {
      "validation_passed": true,
      "issues": [],
      "score": 0.98,
      "report_url": "s3://reports/val_001.html"
    },
    "metrics": {
      "processing_time_ms": 2500,
      "tokens_used": 1500
    }
  }

STEP 8: RETURN PACKET (Domain 7 → Domain 3)
───────────────────────────────────────────
ReturnPacket:
  return_packet_id: "ret-001-uuid"
  original_packet_id: "pkt-001-uuid"
  timestamp: "2024-01-15T10:18:00.500000000Z"
  source_agent: "domain07_asset_validator@2.0.1"
  target_agent: "domain03_asset_generator@1.2.0"
  
  result:
    status: "success"
    data: { validation_passed: true, score: 0.98, ... }
    metrics: { processing_time_ms: 2500, tokens_used: 1500 }
  
  signature: "x1y2z3a4b5c6..." (HMAC-SHA256)

STEP 9: COMPLETION (Domain 3)
─────────────────────────────
Received: "2024-01-15T10:18:00.520000000Z"

Final Status:
  - Handoff latency: 15ms
  - Processing time: 2.5s
  - Return latency: 20ms
  - End-to-end time: 2.535s
  - Success: TRUE

Metrics Recorded:
  - handoff_success_total: +1
  - handoff_latency_seconds: 0.015
  - validation_success_total: +1
  - task_completion_total: +1
```

### 12.2 Error Scenario: Resource Expired

```
SCENARIO: Domain 7 attempts to reconnect to resource res-001, but lease expired.

Detection:
  - Resource handle lease_expiry: "2024-01-15T10:30:00Z"
  - Current time: "2024-01-15T10:35:00Z"
  - Lease EXPIRED by 5 minutes

Error Handling:
  1. ResourceExpiredError raised
  2. Error handler checks retry policy: max_retries=1
  3. Attempt reacquisition:
     - Request new lease from resource manager
     - If successful: Continue with new handle
     - If failed: ESCALATE to orchestrator

Recovery:
  - Resource manager grants new 1-hour lease
  - New handle token: "tok_ghi789"
  - Task continues normally

Metrics:
  - resource_reconnections_total: +1
  - resource_expiry_recoveries_total: +1
```

### 12.3 Metrics Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    OPERATIONAL METRICS                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Handoff Performance:                                            │
│  ├── P50 Latency:           15ms  ✓ (< 50ms target)            │
│  ├── P99 Latency:           45ms  ✓ (< 200ms target)           │
│  ├── State Reconstruction:  70ms  ✓ (< 100ms target)           │
│  └── End-to-End:            2.535s ✓ (< 500ms for simple)      │
│                                                                  │
│  Reliability:                                                    │
│  ├── Validation Rate:       100%  ✓ (> 99.9% target)           │
│  ├── Success Rate:          100%  ✓ (> 99.5% target)           │
│  └── Zero Data Loss:        YES   ✓ (required)                 │
│                                                                  │
│  Resource Management:                                            │
│  ├── Reconnection Rate:     100%  ✓ (> 98% target)             │
│  └── Handle Validity:       50%   (1/2 expired, recovered)     │
│                                                                  │
│  Task Continuity:                                                │
│  ├── Tasks Transferred:     1                                    │
│  ├── Tasks Resumed:         1     ✓ (100% target)              │
│  └── Tasks Failed:          0                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## APPENDIX A: Quick Reference

### A.1 Magic Numbers

| Constant | Value | Purpose |
|----------|-------|---------|
| MAGIC | 0x484F46 | "HOF" - Handoff packet marker |
| VERSION | 0x01 | Protocol version 1 |
| MAX_HOPS | 16 | Maximum routing hops |
| MAX_TTL | 86400 | Maximum TTL (24 hours) |
| HEADER_SIZE | 72 | Fixed header size in bytes |

### A.2 Error Code Quick Reference

| Code | Severity | Action |
|------|----------|--------|
| E1001-E1003 | ERROR | Reject packet |
| E2001-E2003 | ERROR | Reject packet |
| E3001-E3002 | CRITICAL | Reject, security alert |
| E4001-E4002 | WARNING | Request clarification |
| E5001-E5002 | CRITICAL | Escalate immediately |

### A.3 Priority Levels

| Level | Name | Use Case |
|-------|------|----------|
| 10 | CRITICAL | Security alerts, system failures |
| 9 | HIGH | Token exhaustion, interrupts |
| 8 | HIGH | Context overflow, memory pressure |
| 7 | MEDIUM | Timeout warnings |
| 6 | MEDIUM | Capability mismatch |
| 5 | NORMAL | Task completion |
| 4 | LOW | Dependency blocking |
| 3 | LOW | Background tasks |
| 1 | BACKGROUND | Logging, metrics |

---

## APPENDIX B: Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2024-01-15 | Initial specification |

---

*Document ID: domain14_handoff_protocol_spec_v1.0.0*
*Classification: Technical Specification*
*Status: FINAL*
