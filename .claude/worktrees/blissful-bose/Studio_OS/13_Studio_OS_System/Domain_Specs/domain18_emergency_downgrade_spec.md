---
title: "D18: Emergency Downgrade Specification"
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

# Domain 18: Emergency Downgrade Mode (Budget Crisis Mode)
## Complete Technical Specification v1.0

---

## 1. CRISIS TRIGGER CONDITIONS

### 1.1 Budget Threshold Matrix

| Level | Condition Formula | Threshold | Action | Latency |
|-------|-------------------|-----------|--------|---------|
| L0-Normal | B/B_max < 0.75 | <75% | Monitor | 60s |
| L1-Warning | 0.75 ≤ B/B_max < 0.90 | ≥75% | Alert | 30s |
| L2-Restrict | 0.90 ≤ B/B_max < 0.95 | ≥90% | Restrict | 15s |
| L3-Degrade | 0.95 ≤ B/B_max < 1.00 | ≥95% | Degrade | 5s |
| L4-Emergency | B/B_max ≥ 1.00 | ≥100% | Emergency | 0s |

### 1.2 Secondary Triggers

```
T_rate = dB/dt  (burn rate $/min)
T_velocity = T_rate / B_remaining  (time to exhaustion)

IF T_velocity < 30min → Escalate +1 level
IF T_velocity < 5min → Immediate L4
IF concurrent_requests > R_max * 0.8 → Pre-escalate
```

### 1.3 Trigger Evaluation Function

```python
def evaluate_crisis_level(budget_pct, burn_rate, time_horizon):
    base_level = floor(budget_pct / 0.25)  # 0-4
    velocity_penalty = 1 if time_horizon < 30 else 0
    load_penalty = 1 if load_factor > 0.8 else 0
    return min(4, base_level + velocity_penalty + load_penalty)
```

---

## 2. DOWNGRADE ESCALATION LADDER

### 2.1 State Transition Graph

```
                    ┌─────────────────────────────────────────┐
                    │           STATE MACHINE                 │
                    └─────────────────────────────────────────┘

    NORMAL ──[B≥75%]──► RESTRICTED ──[B≥95%]──► MINIMAL ──[B≥100%]──► EMERGENCY
       ▲                   │                       │                      │
       │                   │                       │                      │
       └───────────────────┴───────────────────────┴──────────────────────┘
                    [Recovery: B < threshold - 10% hysteresis]
```

### 2.2 Transition Rules

| From | To | Condition | Hysteresis | Max Transition Time |
|------|-----|-----------|------------|---------------------|
| Normal → Restricted | B ≥ 75% | -5% | 30s |
| Restricted → Minimal | B ≥ 90% | -5% | 15s |
| Minimal → Emergency | B ≥ 100% | N/A | 5s |
| Emergency → Minimal | B < 90% | +5% | 60s |
| Minimal → Restricted | B < 80% | +5% | 30s |
| Restricted → Normal | B < 65% | +5% | 30s |

### 2.3 Escalation Velocity Limits

```
V_escalation_max = 1 level per 5 seconds (prevent thrashing)
V_deescalation_max = 1 level per 60 seconds (ensure stability)
```

---

## 3. SERVICE DEGRADATION MATRIX

### 3.1 Complete Capability Mapping

| Capability | Normal | Restricted | Minimal | Emergency |
|------------|--------|------------|---------|-----------|
| **Executors** | | | | |
| Cloud GPU (A100/H100) | ✓ Full | ✓ Limited | ✗ | ✗ |
| Cloud GPU (T4/L4) | ✓ Full | ✓ Full | ✗ | ✗ |
| Local GPU | ✓ Full | ✓ Full | ✓ Essential | ✗ |
| Local CPU | ✓ Full | ✓ Full | ✓ Full | ✓ Human-only |
| **Features** | | | | |
| Asset Generation (4K) | ✓ | ✗ | ✗ | ✗ |
| Asset Generation (1K) | ✓ | ✓ | ✗ | ✗ |
| Code Generation | ✓ Full | ✓ Limited | ✓ Core only | ✗ |
| Testing (Full Suite) | ✓ | ✓ Limited | ✗ | ✗ |
| Testing (Unit Only) | ✓ | ✓ | ✓ | ✗ |
| Documentation | ✓ | ✓ | ✗ | ✗ |
| Analytics | ✓ Full | ✓ Essential | ✗ | ✗ |
| **Queues** | | | | |
| Priority Queue | ✓ | ✓ Priority | ✓ Critical | ✗ |
| Standard Queue | ✓ | ✓ Limited | ✗ | ✗ |
| Batch Queue | ✓ | ✗ | ✗ | ✗ |
| **Storage** | | | | |
| Hot Cache | ✓ Full | ✓ 75% | ✓ 50% | ✓ 25% |
| Warm Cache | ✓ Full | ✓ 50% | ✗ | ✗ |
| Cold Archive | ✓ | ✓ | ✓ Read-only | ✓ Read-only |

### 3.2 Resource Allocation Formula

```
R_allocated(mode) = R_max × degradation_factor(mode)

degradation_factor = {
    NORMAL:      1.00,
    RESTRICTED:  0.60,
    MINIMAL:     0.25,
    EMERGENCY:   0.05  # Human coordination only
}
```

### 3.3 Request Routing Matrix

| Request Type | Normal | Restricted | Minimal | Emergency |
|--------------|--------|------------|---------|-----------|
| Asset Gen (High) | Cloud GPU | Local GPU | Local CPU | Reject |
| Asset Gen (Low) | Cloud GPU | Queue | Reject | Reject |
| Code Gen | Cloud GPU | Local GPU | Local CPU | Reject |
| Test Execution | Distributed | Local | Local | Reject |
| Analytics | Real-time | Batch | Reject | Reject |

---

## 4. RECOVERY PROCEDURES

### 4.1 Recovery State Machine

```
EMERGENCY ──[Budget < 90%]──► MINIMAL ──[Budget < 80%]──► RESTRICTED ──[Budget < 65%]──► NORMAL
     │                            │                            │                        │
     │                            │                            │                        │
     └─────[Budget ≥ 100%]───────┴─────[Budget ≥ 95%]────────┴─────[Budget ≥ 90%]───────┘
                    (RE-ESCALATION PATH)
```

### 4.2 Recovery Checklist

#### Phase 1: Budget Stabilization (L4→L3)
- [ ] Confirm budget < 90% for 5 consecutive minutes
- [ ] Halt all non-essential spend
- [ ] Activate cost monitoring dashboard
- [ ] Notify operations team

#### Phase 2: Service Restoration (L3→L2)
- [ ] Verify budget < 80% for 10 consecutive minutes
- [ ] Enable local GPU executors
- [ ] Restore critical queue processing
- [ ] Validate service health checks

#### Phase 3: Feature Restoration (L2→L1)
- [ ] Confirm budget < 65% for 15 consecutive minutes
- [ ] Enable limited cloud resources
- [ ] Restore priority queue
- [ ] Run smoke tests

#### Phase 4: Full Restoration (L1→L0)
- [ ] Confirm budget < 50% for 30 consecutive minutes
- [ ] Restore full service capability
- [ ] Clear all degradation flags
- [ ] Generate recovery report

### 4.3 Recovery Time Objectives (RTO)

| Transition | RTO | RPO | Validation Required |
|------------|-----|-----|---------------------|
| Emergency → Minimal | 5 min | 0 | Budget + Health |
| Minimal → Restricted | 10 min | 0 | Budget + Queue |
| Restricted → Normal | 15 min | 0 | Budget + Load |

---

## 5. COMMUNICATION PROTOCOLS

### 5.1 Notification Matrix

| Level | Channels | Recipients | Frequency | Content |
|-------|----------|------------|-----------|---------|
| L1 | Slack #alerts | Team | Immediate | Budget warning |
| L2 | Slack + Email | Team + Lead | Immediate + 5min | Restriction active |
| L3 | Slack + Email + SMS | Team + Lead + Manager | Immediate + 2min | Degradation active |
| L4 | All + PagerDuty | All + On-call | Immediate + 1min | EMERGENCY |

### 5.2 Message Schema

```json
{
  "event_type": "BUDGET_CRISIS",
  "level": "L3",
  "severity": "HIGH",
  "timestamp": "2024-01-15T10:30:00Z",
  "budget": {
    "current": 950.00,
    "max": 1000.00,
    "percentage": 95.0,
    "burn_rate": 45.50,
    "projected_exhaustion": "2024-01-15T10:41:00Z"
  },
  "actions_taken": [
    "DISABLED_CLOUD_GPU",
    "LIMITED_QUEUE_DEPTH",
    "ACTIVATED_LOCAL_FALLBACK"
  ],
  "recovery_requirement": "Budget < 850.00 for 10 minutes"
}
```

### 5.3 Status Dashboard Endpoints

| Endpoint | Purpose | Update Frequency |
|----------|---------|------------------|
| /status/budget | Current budget state | 5s |
| /status/mode | Current operating mode | 1s |
| /status/queues | Queue depths | 10s |
| /status/executors | Executor availability | 10s |

---

## 6. COST FLOOR ENFORCEMENT

### 6.1 Absolute Minimum Costs

```
C_floor = C_monitoring + C_coordination + C_storage_critical

Where:
  C_monitoring = $0.50/day (metrics, logging)
  C_coordination = $1.00/day (orchestrator, queue)
  C_storage_critical = $2.00/day (essential assets)
  
C_floor_total = $3.50/day = $0.146/hour
```

### 6.2 Cost Floor Enforcement Rules

```python
def enforce_cost_floor(projected_spend, time_horizon):
    min_required = C_floor * time_horizon
    
    if projected_spend < min_required:
        # Cannot operate - enter emergency mode
        return EMERGENCY_MODE
    
    available_for_ops = projected_spend - min_required
    return allocate_budget(available_for_ops)
```

### 6.3 Hard Stops

| Condition | Action | Override |
|-----------|--------|----------|
| Budget < $5.00 | Immediate L4 | Requires CFO approval |
| Daily spend > 2× average | Auto-restrict | Requires lead approval |
| Single request > $10.00 | Require approval | Auto-reject in L2+ |

---

## 7. SUCCESS CRITERIA (MEASURABLE)

### 7.1 Key Performance Indicators

| Metric | Target | Measurement |
|--------|--------|-------------|
| Detection Latency | < 5s | Time from threshold breach to alert |
| Escalation Time | < 30s | Time from L1 to L4 if needed |
| False Positive Rate | < 2% | Incorrect escalations per month |
| Recovery Time | < 30min | L4 to Normal restoration |
| Cost Savings | > 40% | Actual vs projected spend in crisis |
| Service Availability | > 95% | Uptime during degraded modes |

### 7.2 Success Thresholds

```
S_overall = Σ(w_i × s_i) where Σw_i = 1

s_detection = 1 if t_detect ≤ 5s else 0
s_escalation = 1 if t_escalate ≤ 30s else max(0, 1 - (t-30)/60)
s_recovery = 1 if t_recovery ≤ 30min else max(0, 1 - (t-30)/30)
s_savings = min(1, savings_pct / 40%)
s_availability = availability_pct / 95%

SUCCESS if S_overall ≥ 0.85
```

### 7.3 Validation Tests

| Test | Frequency | Pass Criteria |
|------|-----------|---------------|
| Threshold Detection | Daily | 100% accuracy |
| Escalation Speed | Weekly | < 30s |
| Recovery Procedure | Monthly | < 30min |
| Cost Calculation | Continuous | < 1% error |

---

## 8. FAILURE STATES

### 8.1 Failure Mode Classification

| Code | Failure | Cause | Impact | Response |
|------|---------|-------|--------|----------|
| F001 | Threshold Miss | Monitoring lag | Delayed response | Fallback to conservative mode |
| F002 | Escalation Loop | Rapid threshold crossing | System thrashing | Implement cooldown (60s) |
| F003 | Recovery Stall | Budget not decreasing | Stuck in degraded mode | Manual intervention required |
| F004 | Cost Underestimation | Pricing changes | Budget exceeded | Emergency stop + audit |
| F005 | Communication Failure | Network issues | Silent degradation | Local alerting + logs |
| F006 | State Corruption | Race condition | Incorrect mode | Reset to safe state (L4) |

### 8.2 Failure Detection

```python
def detect_failure_state():
    failures = []
    
    # F001: Check detection latency
    if time_since_threshold > 10:
        failures.append("F001")
    
    # F002: Check for rapid transitions
    if transitions_in_60s > 3:
        failures.append("F002")
    
    # F003: Check recovery progress
    if mode != NORMAL and time_in_mode > 120:
        failures.append("F003")
    
    # F004: Check budget accuracy
    if actual_spend > projected_spend * 1.1:
        failures.append("F004")
    
    return failures
```

### 8.3 Failure Recovery Procedures

| Failure | Automatic Action | Manual Action |
|---------|-----------------|---------------|
| F001 | Enter Restricted mode | Review monitoring config |
| F002 | Lock mode for 60s | Investigate root cause |
| F003 | Alert operations team | Manual budget review |
| F004 | Emergency stop all spend | Cost audit required |
| F005 | Local logging + retry | Check network connectivity |
| F006 | Reset to L4, alert team | State verification |

---

## 9. INTEGRATION SURFACE

### 9.1 API Endpoints

```
GET    /api/v1/budget/status          → Current budget state
POST   /api/v1/budget/set-limit       → Update budget limit
GET    /api/v1/mode/current           → Current operating mode
POST   /api/v1/mode/force             → Force mode (admin only)
GET    /api/v1/degradation/matrix     → Current degradation state
POST   /api/v1/degradation/configure  → Update degradation rules
GET    /api/v1/alerts/history         → Alert history
POST   /api/v1/recovery/initiate      → Manual recovery
```

### 9.2 Event Stream

```
Topic: budget.crisis.events
Events:
  - budget.threshold.crossed
  - mode.escalated
  - mode.deescalated
  - service.degraded
  - service.restored
  - recovery.initiated
  - recovery.completed
```

### 9.3 Integration Points

| System | Interface | Purpose |
|--------|-----------|---------|
| Cost Monitor | Webhook | Budget updates |
| Task Scheduler | API | Queue management |
| Executor Pool | API | Resource allocation |
| Notification Service | Events | Alerts |
| Dashboard | WebSocket | Real-time status |
| Audit Log | API | Compliance |

### 9.4 Authentication

```
All administrative endpoints require:
  - Bearer token with scope: budget:admin
  
Read endpoints require:
  - Bearer token with scope: budget:read
  
Force mode changes require:
  - Bearer token with scope: budget:emergency
  - Additional MFA verification
```

---

## 10. JSON SCHEMAS

### 10.1 Budget State Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BudgetState",
  "type": "object",
  "required": ["current", "maximum", "currency", "period"],
  "properties": {
    "current": {
      "type": "number",
      "minimum": 0,
      "description": "Current spend amount"
    },
    "maximum": {
      "type": "number",
      "minimum": 0,
      "description": "Budget limit"
    },
    "currency": {
      "type": "string",
      "enum": ["USD", "EUR", "GBP"],
      "default": "USD"
    },
    "period": {
      "type": "string",
      "enum": ["daily", "weekly", "monthly"],
      "default": "monthly"
    },
    "percentage": {
      "type": "number",
      "minimum": 0,
      "maximum": 1000
    },
    "burn_rate": {
      "type": "number",
      "minimum": 0,
      "description": "Spend rate per hour"
    },
    "projected_exhaustion": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

### 10.2 Operating Mode Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "OperatingMode",
  "type": "object",
  "required": ["mode", "level", "timestamp"],
  "properties": {
    "mode": {
      "type": "string",
      "enum": ["NORMAL", "RESTRICTED", "MINIMAL", "EMERGENCY"]
    },
    "level": {
      "type": "integer",
      "minimum": 0,
      "maximum": 4
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "entered_by": {
      "type": "string",
      "enum": ["SYSTEM", "ADMIN", "AUTOMATED"]
    },
    "reason": {
      "type": "string"
    },
    "active_restrictions": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "NO_CLOUD_GPU",
          "LIMITED_QUEUE",
          "NO_BATCH",
          "LOCAL_ONLY",
          "HUMAN_ONLY"
        ]
      }
    }
  }
}
```

### 10.3 Degradation Rule Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "DegradationRules",
  "type": "object",
  "properties": {
    "rules": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["mode", "threshold", "actions"],
        "properties": {
          "mode": {
            "type": "string",
            "enum": ["RESTRICTED", "MINIMAL", "EMERGENCY"]
          },
          "threshold": {
            "type": "number",
            "minimum": 0,
            "maximum": 100
          },
          "hysteresis": {
            "type": "number",
            "minimum": 0,
            "maximum": 20,
            "default": 5
          },
          "actions": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["type", "target"],
              "properties": {
                "type": {
                  "type": "string",
                  "enum": ["DISABLE", "LIMIT", "QUEUE", "NOTIFY"]
                },
                "target": {
                  "type": "string"
                },
                "value": {
                  "type": ["string", "number", "boolean"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### 10.4 Alert Event Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BudgetAlert",
  "type": "object",
  "required": ["event_type", "level", "timestamp", "budget"],
  "properties": {
    "event_type": {
      "type": "string",
      "const": "BUDGET_CRISIS"
    },
    "level": {
      "type": "string",
      "enum": ["L1", "L2", "L3", "L4"]
    },
    "severity": {
      "type": "string",
      "enum": ["INFO", "WARNING", "HIGH", "CRITICAL"]
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "budget": {
      "$ref": "#/definitions/BudgetState"
    },
    "actions_taken": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "recovery_requirement": {
      "type": "string"
    }
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core State Manager

```python
class BudgetCrisisManager:
    def __init__(self, config):
        self.budget_limit = config.budget_limit
        self.current_spend = 0
        self.mode = OperatingMode.NORMAL
        self.thresholds = {
            'L1': 0.75,
            'L2': 0.90,
            'L3': 0.95,
            'L4': 1.00
        }
        self.hysteresis = 0.05
        self.last_transition = time.now()
        self.cooldown = 60  # seconds
        
    def update_budget(self, new_spend):
        """Update current spend and evaluate crisis level"""
        self.current_spend = new_spend
        percentage = new_spend / self.budget_limit
        
        new_level = self._evaluate_level(percentage)
        
        if new_level != self.mode.level:
            if self._can_transition():
                self._transition(new_level, percentage)
                
    def _evaluate_level(self, percentage):
        """Determine crisis level from budget percentage"""
        if percentage >= self.thresholds['L4']:
            return 4
        elif percentage >= self.thresholds['L3']:
            return 3
        elif percentage >= self.thresholds['L2']:
            return 2
        elif percentage >= self.thresholds['L1']:
            return 1
        else:
            # Apply hysteresis for de-escalation
            if self.mode.level == 1 and percentage > self.thresholds['L1'] - self.hysteresis:
                return 1
            return 0
            
    def _can_transition(self):
        """Check if enough time has passed since last transition"""
        return (time.now() - self.last_transition) >= self.cooldown
        
    def _transition(self, new_level, percentage):
        """Execute mode transition"""
        old_mode = self.mode
        self.mode = OperatingMode.from_level(new_level)
        self.last_transition = time.now()
        
        # Apply degradation rules
        self._apply_degradation(self.mode)
        
        # Emit event
        self._emit_transition_event(old_mode, self.mode, percentage)
        
    def _apply_degradation(self, mode):
        """Apply service degradation based on mode"""
        rules = DEGRADATION_RULES[mode.name]
        
        for action in rules.actions:
            if action.type == 'DISABLE':
                self.executor_pool.disable(action.target)
            elif action.type == 'LIMIT':
                self.queue_manager.set_limit(action.target, action.value)
            elif action.type == 'NOTIFY':
                self.notifier.send_alert(mode, action.target)
```

### 11.2 Budget Monitor

```python
class BudgetMonitor:
    def __init__(self, crisis_manager, poll_interval=5):
        self.crisis_manager = crisis_manager
        self.poll_interval = poll_interval
        self.running = False
        
    async def start(self):
        """Start budget monitoring loop"""
        self.running = True
        while self.running:
            spend = await self._fetch_current_spend()
            self.crisis_manager.update_budget(spend)
            await asyncio.sleep(self.poll_interval)
            
    async def _fetch_current_spend(self):
        """Fetch current spend from cost provider"""
        # Integration with cloud cost APIs
        return await cost_provider.get_current_spend()
```

### 11.3 Request Router

```python
class DegradedRequestRouter:
    def __init__(self, crisis_manager, executor_pool):
        self.crisis_manager = crisis_manager
        self.executor_pool = executor_pool
        
    def route_request(self, request):
        """Route request based on current operating mode"""
        mode = self.crisis_manager.mode
        
        # Check if request type is allowed
        if not self._is_request_allowed(request.type, mode):
            raise RequestRejectedError(f"Request type {request.type} not allowed in {mode}")
            
        # Select appropriate executor
        executor = self._select_executor(request, mode)
        
        # Apply rate limiting
        if not self._check_rate_limit(request.type, mode):
            raise RateLimitExceededError()
            
        return executor.execute(request)
        
    def _is_request_allowed(self, request_type, mode):
        """Check if request type is allowed in current mode"""
        allowed = DEGRADATION_MATRIX[mode.name]['allowed_requests']
        return request_type in allowed
        
    def _select_executor(self, request, mode):
        """Select best available executor for request"""
        preferences = EXECUTOR_PREFERENCES[request.type][mode.name]
        
        for executor_type in preferences:
            executor = self.executor_pool.get_available(executor_type)
            if executor:
                return executor
                
        raise NoExecutorAvailableError()
```

### 11.4 Recovery Manager

```python
class RecoveryManager:
    def __init__(self, crisis_manager):
        self.crisis_manager = crisis_manager
        self.recovery_checks = {}
        
    async def monitor_recovery(self):
        """Monitor for recovery conditions"""
        while True:
            mode = self.crisis_manager.mode
            
            if mode != OperatingMode.NORMAL:
                if self._check_recovery_condition(mode):
                    await self._initiate_recovery(mode)
                    
            await asyncio.sleep(10)
            
    def _check_recovery_condition(self, mode):
        """Check if recovery conditions are met"""
        percentage = self.crisis_manager.current_percentage
        
        recovery_thresholds = {
            OperatingMode.EMERGENCY: 0.90,
            OperatingMode.MINIMAL: 0.80,
            OperatingMode.RESTRICTED: 0.65
        }
        
        threshold = recovery_thresholds.get(mode, 0)
        
        # Must be below threshold for sustained period
        if percentage < threshold:
            key = f"recovery_{mode.name}"
            if key not in self.recovery_checks:
                self.recovery_checks[key] = time.now()
            elif (time.now() - self.recovery_checks[key]) >= 600:  # 10 min
                return True
        else:
            # Reset if goes back above
            key = f"recovery_{mode.name}"
            if key in self.recovery_checks:
                del self.recovery_checks[key]
                
        return False
        
    async def _initiate_recovery(self, from_mode):
        """Initiate recovery to next lower level"""
        recovery_chain = {
            OperatingMode.EMERGENCY: OperatingMode.MINIMAL,
            OperatingMode.MINIMAL: OperatingMode.RESTRICTED,
            OperatingMode.RESTRICTED: OperatingMode.NORMAL
        }
        
        to_mode = recovery_chain.get(from_mode)
        if to_mode:
            await self.crisis_manager.force_transition(to_mode, reason="RECOVERY")
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Scenario: Monthly Budget Exhaustion

**Initial State:**
- Budget Limit: $1,000/month
- Current Spend: $700 (70%)
- Mode: NORMAL
- Date: January 20, 2024

**Timeline:**

```
T+0:00  [NORMAL]  Budget: $700 (70%)
        └─> Monitoring active, all services enabled

T+2:30  [NORMAL]  Budget: $751 (75.1%) 
        └─> L1 THRESHOLD CROSSED
        └─> Alert sent to #alerts channel
        └─> Mode remains NORMAL (hysteresis buffer)

T+5:00  [NORMAL]  Budget: $755 (75.5%)
        └─> Sustained above L1, escalation triggered
        └─> TRANSITION: NORMAL → RESTRICTED
        └─> Actions:
            • Cloud GPU limited to 50% capacity
            • Batch queue disabled
            • Analytics switched to batch mode

T+8:00  [RESTRICTED]  Budget: $902 (90.2%)
        └─> L2 THRESHOLD CROSSED
        └─> TRANSITION: RESTRICTED → MINIMAL
        └─> Actions:
            • All cloud GPU disabled
            • Local GPU only for critical tasks
            • Standard queue disabled
            • Only priority queue active
            • SMS alert sent to on-call

T+9:30  [MINIMAL]  Budget: $951 (95.1%)
        └─> L3 THRESHOLD CROSSED
        └─> TRANSITION: MINIMAL → EMERGENCY
        └─> Actions:
            • All automated execution halted
            • Human approval required for all operations
            • PagerDuty incident created
            • Emergency notification to all stakeholders

T+10:00 [EMERGENCY] Budget: $1000 (100%)
        └─> HARD STOP: All spend blocked
        └─> Only monitoring and coordination active
```

### 12.2 Recovery Scenario

```
T+0:00  [EMERGENCY] Budget: $1000 (100%)
        └─> Emergency budget increase approved: +$500
        └─> New limit: $1500

T+0:30  [EMERGENCY] Budget: $1000 (66.7% of new limit)
        └─> Below 90% threshold
        └─> Sustained for 5 minutes
        └─> TRANSITION: EMERGENCY → MINIMAL
        └─> Local GPU executors restored

T+15:00 [MINIMAL] Budget: $1100 (73.3%)
        └─> Below 80% threshold for 10 minutes
        └─> TRANSITION: MINIMAL → RESTRICTED
        └─> Limited cloud GPU restored
        └─> Standard queue enabled

T+45:00 [RESTRICTED] Budget: $1150 (76.7%)
        └─> Below 65% threshold for 15 minutes
        └─> TRANSITION: RESTRICTED → NORMAL
        └─> Full service restoration
        └─> Recovery report generated
```

### 12.3 API Usage Example

```bash
# Check current budget status
curl -H "Authorization: Bearer $TOKEN" \
  https://api.studio.os/v1/budget/status

# Response:
{
  "current": 950.00,
  "maximum": 1000.00,
  "percentage": 95.0,
  "currency": "USD",
  "burn_rate": 45.50,
  "projected_exhaustion": "2024-01-15T10:41:00Z"
}

# Check current operating mode
curl -H "Authorization: Bearer $TOKEN" \
  https://api.studio.os/v1/mode/current

# Response:
{
  "mode": "MINIMAL",
  "level": 3,
  "timestamp": "2024-01-15T10:30:00Z",
  "entered_by": "SYSTEM",
  "reason": "BUDGET_THRESHOLD_L3",
  "active_restrictions": [
    "NO_CLOUD_GPU",
    "LIMITED_QUEUE",
    "LOCAL_ONLY"
  ]
}

# Force emergency mode (admin only)
curl -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "X-MFA-Code: 123456" \
  -d '{"mode": "EMERGENCY", "reason": "MANUAL_OVERRIDE"}' \
  https://api.studio.os/v1/mode/force
```

---

## APPENDIX A: Configuration Reference

```yaml
budget_crisis:
  limits:
    monthly: 1000.00
    daily: 50.00
    hourly: 10.00
    
  thresholds:
    L1_warning: 0.75
    L2_restrict: 0.90
    L3_degrade: 0.95
    L4_emergency: 1.00
    
  hysteresis: 0.05
  
  timing:
    poll_interval_seconds: 5
    escalation_cooldown_seconds: 60
    recovery_confirmation_seconds: 600
    
  notifications:
    L1: ["slack:#alerts"]
    L2: ["slack:#alerts", "email:team@studio.os"]
    L3: ["slack:#alerts", "email:team@studio.os", "sms:+1234567890"]
    L4: ["all", "pagerduty:studio-oncall"]
    
  cost_floor:
    daily_minimum: 3.50
    enforcement: strict
```

---

## APPENDIX B: Glossary

| Term | Definition |
|------|------------|
| Budget | Maximum authorized spend for a period |
| Burn Rate | Rate of spend per unit time ($/hour) |
| Degradation | Reduction in service capability |
| Escalation | Movement to higher crisis level |
| Hysteresis | Buffer zone to prevent rapid transitions |
| Mode | Operating state (Normal/Restricted/Minimal/Emergency) |
| Recovery | Return to lower crisis level |
| Threshold | Budget percentage triggering action |

---

*Document Version: 1.0*
*Last Updated: 2024-01-15*
*Owner: Domain 18 - Emergency Downgrade Mode*
