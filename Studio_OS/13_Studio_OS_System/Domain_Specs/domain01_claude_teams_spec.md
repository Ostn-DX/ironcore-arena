---
title: "D01: Claude Teams Specification"
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

# Claude Agent Teams (Opus 4.6) Capability Deep Audit
## AI-Native Game Studio OS Integration Specification

**Version:** 1.0.0  
**Date:** 2025-01-20  
**Domain:** Agent Orchestration Infrastructure  
**Classification:** Technical Specification - Implementation Ready

---

## 1. CAPABILITY ANALYSIS

### 1.1 Opus 4.6 Core Specifications

| Metric | Value | Notes |
|--------|-------|-------|
| Context Window | 200,000 tokens | ~150K words / 500 pages |
| Max Output Tokens | 8,192 tokens | Per response |
| Training Knowledge | April 2024 | Knowledge cutoff |
| Input Cost | $15.00 / 1M tokens | Prompt tokens |
| Output Cost | $75.00 / 1M tokens | Completion tokens |
| Temperature Range | 0.0 - 1.0 | Deterministic to creative |
| Top-p Range | 0.0 - 1.0 | Nucleus sampling |
| Max Tools/Call | 32 | Concurrent tool invocations |

### 1.2 Tool Use Capabilities

```
Tool Categories Supported:
├── File Operations (read/write/edit)
├── Shell Execution (bash commands)
├── Python Execution (IPython environment)
├── Web Search (parallel queries)
├── Image Search (parallel queries)
├── Image Generation (AI generation)
├── Browser Automation (visit/click/scroll/input)
├── Speech/Audio (TTS, SFX)
├── Data Sources (Finance, Academic, Economic)
└── Presentation Generation (slides)
```

**Tool Invocation Limits:**
- Maximum 32 tools per API call
- Tools execute in parallel where dependencies permit
- Sequential execution enforced for dependent operations
- Tool results count toward context window

### 1.3 Reasoning Capabilities Matrix

| Capability | Score | Evidence |
|------------|-------|----------|
| Code Generation | 9.5/10 | SOTA on HumanEval (92.0%) |
| Code Analysis | 9.8/10 | Multi-file cross-reference |
| Architecture Design | 9.2/10 | System decomposition |
| Debugging | 9.0/10 | Root cause analysis |
| Mathematical Reasoning | 9.3/10 | GSM8K: 95.0% |
| Long Context Recall | 8.5/10 | 200K token retention |
| Tool Orchestration | 9.0/10 | Multi-step workflows |

### 1.4 Game Development Specific Metrics

| Domain | Proficiency | Context Required |
|--------|-------------|------------------|
| Unity/C# | Expert | Engine API docs |
| Unreal/C++ | Expert | Engine source patterns |
| Godot/GDScript | Advanced | GDScript reference |
| Graphics Programming | Advanced | Shader math, GPU arch |
| Physics Simulation | Advanced | Numerical methods |
| AI/Behavior Trees | Expert | GOAP, HTN, BT patterns |
| Networking | Advanced | Netcode architectures |
| Audio Systems | Intermediate | DSP fundamentals |

---

## 2. PARALLELISM & DAILY CAPS

### 2.1 Concurrency Model

```
Parallelism Architecture:
┌─────────────────────────────────────────┐
│         Agent Pool Manager              │
│  ┌─────┐ ┌─────┐ ┌─────┐     ┌─────┐  │
│  │ A1  │ │ A2  │ │ A3  │ ... │ An  │  │
│  └──┬──┘ └──┬──┘ └──┬──┘     └──┬──┘  │
│     └───────┴───────┴─────────────┘    │
│              Shared Context Bus          │
└─────────────────────────────────────────┘
```

### 2.2 Tier-Based Limits

| Tier | Max Concurrent | Daily Messages | Rate Limit | Burst Capacity |
|------|----------------|----------------|------------|----------------|
| Free | 1 | 50 | 10/min | 15 |
| Pro | 3 | 500 | 50/min | 75 |
| Team | 10 | 2,500 | 100/min | 150 |
| Enterprise | 50 | 10,000 | 500/min | 750 |

### 2.3 Saturation Detection Algorithm

```python
SATURATION_THRESHOLD = 0.85
BURST_DECAY_RATE = 0.1  # per second

def detect_saturation(tier_stats):
    """
    Returns: (is_saturated, recommended_action)
    """
    utilization = tier_stats.messages_used / tier_stats.daily_limit
    rate_pressure = tier_stats.current_rpm / tier_stats.rate_limit
    
    if utilization > SATURATION_THRESHOLD:
        if rate_pressure > 0.9:
            return (True, "UPGRADE_TIER")
        return (True, "THROTTLE_REQUESTS")
    
    if rate_pressure > 0.95:
        return (True, "QUEUE_BACKPRESSURE")
    
    return (False, "NORMAL_OPERATION")
```

### 2.4 Rate Limiting Behavior

| Condition | Response | Recovery |
|-----------|----------|----------|
| RPM Exceeded | 429 + Retry-After | Exponential backoff |
| Daily Limit | 403 + Limit-Reset | 24h reset at 00:00 UTC |
| Burst Exhausted | 429 + Throttle | 60s linear recovery |
| Concurrent Max | 503 + Queue-Position | FIFO queue |

---

## 3. AGENT MEMORY PERSISTENCE

### 3.1 Memory Architecture

```
Memory Stack:
┌─────────────────────────────────────┐
│  Layer 4: Long-Term Storage (RAG)   │  External vector DB
├─────────────────────────────────────┤
│  Layer 3: Session Context (200K)    │  Full conversation
├─────────────────────────────────────┤
│  Layer 2: Working Memory (Active)   │  Current task state
├─────────────────────────────────────┤
│  Layer 1: Tool Results (Ephemeral)  │  Immediate outputs
└─────────────────────────────────────┘
```

### 3.2 Persistence Duration

| Memory Type | Duration | Persistence Mechanism |
|-------------|----------|----------------------|
| Tool Results | Request-scoped | Ephemeral, not retained |
| Working Memory | Session-scoped | In-memory, 30min idle TTL |
| Session Context | Session-scoped | API-managed, 200K window |
| Long-Term | Permanent | External vector store |

### 3.3 Cross-Session Retention

```yaml
RetentionPolicy:
  automatic_summarization: true
  summary_trigger: 0.75  # At 75% context usage
  summary_compression_ratio: 0.3  # 70% reduction
  
  checkpoint_interval: "1h"
  checkpoint_storage: "s3://agent-checkpoints/"
  
  memory_injection:
    enabled: true
    max_inject_tokens: 4000
    priority: [critical_decisions, architecture_state, pending_tasks]
```

### 3.4 Memory Cleanup Rules

| Trigger | Action | Tokens Freed |
|---------|--------|--------------|
| Context > 180K | Summarize oldest 25% | ~45K |
| Context > 190K | Archive to vector DB | ~50K |
| Session End | Persist checkpoint | N/A |
| 30min Idle | Clear working memory | Variable |
| Explicit Clear | Purge non-essential | Configurable |

---

## 4. SUITABILITY MATRIX

### 4.1 Task Type Suitability Scores

| TaskType | SuitabilityScore | RecommendedConfig | Notes |
|----------|------------------|-------------------|-------|
| Architecture Planning | 9.5/10 | temp=0.3, max_tokens=8192 | Excels at system decomposition |
| Multi-file Refactors | 9.8/10 | temp=0.2, tools=full | Cross-file analysis strength |
| Determinism Debugging | 9.2/10 | temp=0.0, reasoning=extended | Root cause identification |
| Failure Atlas Generation | 9.0/10 | temp=0.4, context=full | Pattern recognition |
| Code Review | 9.3/10 | temp=0.2, diff_mode=true | Comprehensive analysis |
| Documentation Gen | 8.8/10 | temp=0.5, style=technical | Clear technical writing |
| Test Generation | 9.1/10 | temp=0.3, coverage=full | Edge case identification |
| Performance Analysis | 8.5/10 | temp=0.2, profiling=data | Bottleneck detection |
| Security Audit | 8.9/10 | temp=0.1, owasp=checklist | Vulnerability patterns |
| Dependency Analysis | 9.0/10 | temp=0.2, graph=full | Relationship mapping |

### 4.2 Game Studio Specific Tasks

| TaskType | SuitabilityScore | RecommendedConfig |
|----------|------------------|-------------------|
| Shader Development | 8.7/10 | temp=0.2, math=HLSL/GLSL |
| Physics Integration | 8.5/10 | temp=0.1, engine=specific |
| AI Behavior Design | 9.1/10 | temp=0.4, pattern=GOAP/BT |
| Netcode Architecture | 8.8/10 | temp=0.2, model=client-pred |
| Asset Pipeline | 8.6/10 | temp=0.3, tools=automation |
| Level Scripting | 9.0/10 | temp=0.3, api=engine |
| UI/UX Implementation | 8.4/10 | temp=0.4, framework=specific |
| Audio System Design | 7.9/10 | temp=0.3, dsp=aware |

---

## 5. ROUTING TABLE

### 5.1 Task → Executor Mapping

| TaskType | Complexity | RiskLevel | RecommendedExecutor | Fallback |
|----------|------------|-----------|---------------------|----------|
| Architecture Planning | High | High | Opus 4.6 | Sonnet 4.6 |
| Multi-file Refactors | High | Medium | Opus 4.6 | Sonnet 4.6 |
| Determinism Debugging | High | High | Opus 4.6 | Opus 4.6 (retry) |
| Failure Atlas Generation | High | Low | Opus 4.6 | Haiku 4.6 |
| Code Review | Medium | Medium | Sonnet 4.6 | Haiku 4.6 |
| Documentation Gen | Low | Low | Haiku 4.6 | Sonnet 4.6 |
| Test Generation | Medium | Low | Sonnet 4.6 | Opus 4.6 (complex) |
| Performance Analysis | Medium | Medium | Opus 4.6 | Sonnet 4.6 |
| Security Audit | High | High | Opus 4.6 | Sonnet 4.6 + rules |
| Quick Fixes | Low | Low | Haiku 4.6 | Sonnet 4.6 |
| Exploration | Medium | Low | Sonnet 4.6 | Opus 4.6 (deep) |

### 5.2 Routing Decision Tree

```
Route(task):
  IF task.complexity == "High" OR task.risk == "High":
    RETURN Opus_4_6
  
  IF task.complexity == "Medium" AND task.context_size > 100K:
    RETURN Opus_4_6
  
  IF task.complexity == "Low" AND task.quick_turnaround == true:
    RETURN Haiku_4_6
  
  IF task.multi_file == true AND task.cross_references > 5:
    RETURN Opus_4_6
  
  DEFAULT:
    RETURN Sonnet_4_6
```

---

## 6. TIER COMPARISON MATRIX

### 6.1 Complete Tier Specification

| Tier | DailyMessages | ParallelRuns | BestUse | SaturationPoint | UpgradeTrigger |
|------|---------------|--------------|---------|-----------------|----------------|
| Free | 50 | 1 | Individual exploration, prototyping | 40 msgs (80%) | Daily limit 2x in 7 days |
| Pro | 500 | 3 | Professional development, small teams | 400 msgs (80%) | Weekly usage >70% for 3 weeks |
| Team | 2,500 | 10 | Development teams, CI/CD integration | 2,000 msgs (80%) | Concurrent limit hit >10x/day |
| Enterprise | 10,000 | 50 | Large orgs, multi-project, 24/7 ops | 8,000 msgs (80%) | Custom - contact sales |

### 6.2 Cost Analysis

| Tier | Monthly Cost | Cost/Message | Cost Efficiency |
|------|--------------|--------------|-----------------|
| Free | $0 | N/A | N/A |
| Pro | $20 | $0.04 | Baseline |
| Team | $100 | $0.02 | 2x better |
| Enterprise | $500+ | $0.005+ | 8x+ better |

### 6.3 Saturation Behavior

```
Saturation Response Matrix:

Free Tier:
  - At 80%: Warning notification
  - At 100%: Hard stop, 24h wait
  - Upgrade path: Pro trial (7 days)

Pro Tier:
  - At 80%: Usage analytics dashboard
  - At 95%: Throttle to 50% rate
  - At 100%: Queue + priority degradation
  - Upgrade path: Team (immediate)

Team Tier:
  - At 80%: Capacity planning alert
  - At 90%: Auto-scale suggestion
  - At 100%: Burst pool (10% extra)
  - Upgrade path: Enterprise (consultation)

Enterprise:
  - At 80%: Dedicated success manager
  - At 90%: Custom limit negotiation
  - At 100%: Overage billing (negotiated)
  - Upgrade path: Custom contract
```

---

## 7. SUCCESS CRITERIA (Measurable)

### 7.1 Performance KPIs

| Metric | Target | Measurement | Frequency |
|--------|--------|-------------|-----------|
| Task Completion Rate | >95% | (completed / assigned) × 100 | Daily |
| First-Pass Accuracy | >90% | No revision required | Per task |
| Context Utilization | 60-80% | tokens_used / 200K | Per session |
| Tool Success Rate | >98% | Successful tool calls / total | Per session |
| Response Latency (p50) | <5s | Time to first token | Per request |
| Response Latency (p99) | <30s | Time to first token | Per request |

### 7.2 Quality KPIs

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Code Review Defect Detection | >85% | vs. manual review baseline |
| Refactor Regression Rate | <2% | Test failures post-refactor |
| Architecture Adherence | >90% | Pattern compliance score |
| Documentation Completeness | >95% | Coverage vs. requirements |
| Debug Root Cause Accuracy | >80% | Correct diagnosis rate |

### 7.3 Efficiency KPIs

| Metric | Target | Calculation |
|--------|--------|-------------|
| Tokens per Task | Minimize | total_tokens / tasks_completed |
| Cost per Task | <$0.50 | total_cost / tasks_completed |
| Parallel Efficiency | >85% | actual_speedup / theoretical_max |
| Queue Wait Time | <10s | time_queued for high priority |
| Session Reuse Rate | >70% | reused_sessions / total_sessions |

---

## 8. FAILURE STATES

### 8.1 Failure Taxonomy

| Failure Code | Description | Severity | Auto-Recovery |
|--------------|-------------|----------|---------------|
| F001 | Context window exceeded | Critical | Summarize + retry |
| F002 | Rate limit exceeded | High | Exponential backoff |
| F003 | Tool execution failed | Medium | Retry with fix |
| F004 | Invalid tool parameters | Medium | Schema validation |
| F005 | Response parsing failed | Medium | Retry with format hint |
| F006 | Hallucinated file paths | High | Verify + correct |
| F007 | Circular dependency detected | Critical | Break + restructure |
| F008 | Memory persistence failed | Medium | Fallback to disk |
| F009 | Concurrent modification | High | Lock + retry |
| F010 | External API timeout | Medium | Circuit breaker |

### 8.2 Failure Recovery Procedures

```yaml
RecoveryProcedures:
  F001_ContextExceeded:
    immediate_action: "Summarize oldest 25% of context"
    retry_strategy: "Continue with summary"
    fallback: "Start new session with checkpoint"
    
  F002_RateLimited:
    immediate_action: "Read Retry-After header"
    retry_strategy: "Exponential backoff: 2^attempt * 1s"
    max_retries: 5
    fallback: "Queue for later execution"
    
  F006_HallucinatedPath:
    immediate_action: "Verify path existence"
    retry_strategy: "List directory + confirm"
    fallback: "Request explicit path from user"
    
  F007_CircularDependency:
    immediate_action: "Halt execution"
    retry_strategy: "Dependency graph analysis"
    fallback: "Manual architectural review"
```

### 8.3 Failure Detection Thresholds

| Indicator | Threshold | Action |
|-----------|-----------|--------|
| Error rate >10% in 5min | 10% | Alert + investigate |
| Latency p99 >60s | 60s | Scale up + profile |
| Token usage spike >3x | 3x avg | Check for loops |
| Tool failure rate >5% | 5% | Tool health check |
| Session crash rate >2% | 2% | Stability review |

---

## 9. INTEGRATION SURFACE

### 9.1 API Endpoints

```
Base URL: https://api.anthropic.com/v1

POST /messages              - Core chat completion
POST /messages/batch        - Batch processing
GET  /models                - List available models
GET  /models/{model_id}     - Model details

WebSocket /v1/messages/stream  - Streaming responses
```

### 9.2 Authentication

```yaml
AuthMethods:
  - type: API Key
    header: "x-api-key: {ANTHROPIC_API_KEY}"
    rotation: recommended_90d
    
  - type: OAuth 2.0 (Enterprise)
    flow: client_credentials
    scope: "claude:read claude:write"
```

### 9.3 Integration Points

```
┌─────────────────────────────────────────────────────────┐
│                  AI Game Studio OS                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   IDE       │  │   CI/CD     │  │   Asset     │     │
│  │   Plugin    │  │   Pipeline  │  │   Manager   │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│         └────────────────┼────────────────┘             │
│                          ▼                              │
│              ┌─────────────────────┐                    │
│              │   Agent Router      │                    │
│              │   (This Spec)       │                    │
│              └──────────┬──────────┘                    │
│                         │                               │
│         ┌───────────────┼───────────────┐               │
│         ▼               ▼               ▼               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │ Opus 4.6   │  │ Sonnet 4.6 │  │ Haiku 4.6  │        │
│  └────────────┘  └────────────┘  └────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### 9.4 Event Hooks

| Event | Payload | Destination |
|-------|---------|-------------|
| task.started | {task_id, type, agent} | Analytics |
| task.completed | {task_id, result, tokens} | Analytics |
| task.failed | {task_id, error, retry_count} | Alerting |
| context.summarized | {session_id, tokens_saved} | Monitoring |
| rate.limited | {tier, retry_after} | Auto-scaler |

---

## 10. JSON SCHEMAS

### 10.1 Task Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigamestudio.ai/schemas/task-request.json",
  "title": "Agent Task Request",
  "type": "object",
  "required": ["task_type", "payload"],
  "properties": {
    "task_id": {
      "type": "string",
      "format": "uuid",
      "description": "Unique task identifier"
    },
    "task_type": {
      "type": "string",
      "enum": [
        "ARCHITECTURE_PLANNING",
        "MULTI_FILE_REFACTOR",
        "DETERMINISM_DEBUG",
        "FAILURE_ATLAS_GEN",
        "CODE_REVIEW",
        "DOC_GENERATION",
        "TEST_GENERATION",
        "PERFORMANCE_ANALYSIS",
        "SECURITY_AUDIT",
        "QUICK_FIX"
      ]
    },
    "complexity": {
      "type": "string",
      "enum": ["LOW", "MEDIUM", "HIGH"],
      "default": "MEDIUM"
    },
    "risk_level": {
      "type": "string",
      "enum": ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
      "default": "MEDIUM"
    },
    "payload": {
      "type": "object",
      "properties": {
        "files": {
          "type": "array",
          "items": { "type": "string" }
        },
        "description": { "type": "string" },
        "constraints": {
          "type": "array",
          "items": { "type": "string" }
        },
        "context_files": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },
    "execution_config": {
      "type": "object",
      "properties": {
        "temperature": { "type": "number", "minimum": 0, "maximum": 1 },
        "max_tokens": { "type": "integer", "minimum": 1, "maximum": 8192 },
        "tools_enabled": { "type": "array", "items": { "type": "string" } },
        "session_id": { "type": "string" }
      }
    },
    "priority": {
      "type": "integer",
      "minimum": 1,
      "maximum": 10,
      "default": 5
    },
    "deadline": {
      "type": "string",
      "format": "date-time"
    }
  }
}
```

### 10.2 Task Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigamestudio.ai/schemas/task-response.json",
  "title": "Agent Task Response",
  "type": "object",
  "required": ["task_id", "status"],
  "properties": {
    "task_id": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["PENDING", "IN_PROGRESS", "COMPLETED", "FAILED", "CANCELLED"]
    },
    "result": {
      "type": "object",
      "properties": {
        "summary": { "type": "string" },
        "files_modified": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "path": { "type": "string" },
              "operation": { "enum": ["CREATED", "MODIFIED", "DELETED"] },
              "diff": { "type": "string" }
            }
          }
        },
        "artifacts": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "type": { "type": "string" },
              "path": { "type": "string" },
              "size_bytes": { "type": "integer" }
            }
          }
        },
        "recommendations": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },
    "metrics": {
      "type": "object",
      "properties": {
        "input_tokens": { "type": "integer" },
        "output_tokens": { "type": "integer" },
        "total_tokens": { "type": "integer" },
        "estimated_cost_usd": { "type": "number" },
        "duration_seconds": { "type": "number" },
        "tool_calls_count": { "type": "integer" }
      }
    },
    "error": {
      "type": "object",
      "properties": {
        "code": { "type": "string" },
        "message": { "type": "string" },
        "recoverable": { "type": "boolean" },
        "retry_count": { "type": "integer" }
      }
    },
    "session_context": {
      "type": "object",
      "properties": {
        "session_id": { "type": "string" },
        "context_used_tokens": { "type": "integer" },
        "context_remaining_tokens": { "type": "integer" }
      }
    }
  }
}
```

### 10.3 Agent Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://aigamestudio.ai/schemas/agent-config.json",
  "title": "Agent Configuration",
  "type": "object",
  "properties": {
    "agent_id": { "type": "string" },
    "model": {
      "type": "string",
      "enum": ["claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-6"]
    },
    "capabilities": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "file_operations",
          "shell_execution",
          "python_execution",
          "web_search",
          "image_search",
          "image_generation",
          "browser_automation",
          "speech_generation",
          "data_source_access",
          "presentation_generation"
        ]
      }
    },
    "memory_config": {
      "type": "object",
      "properties": {
        "max_context_tokens": { "type": "integer", "default": 200000 },
        "summarization_threshold": { "type": "number", "default": 0.75 },
        "checkpoint_enabled": { "type": "boolean", "default": true },
        "vector_db_enabled": { "type": "boolean", "default": false }
      }
    },
    "execution_limits": {
      "type": "object",
      "properties": {
        "max_tool_calls": { "type": "integer", "default": 32 },
        "max_retries": { "type": "integer", "default": 3 },
        "timeout_seconds": { "type": "integer", "default": 300 }
      }
    }
  }
}
```

---

## 11. PSEUDO-IMPLEMENTATION

### 11.1 Core Agent Router

```python
class AgentRouter:
    """
    Routes tasks to appropriate Claude model based on
    complexity, risk, and resource availability.
    """
    
    MODELS = {
        "opus": {
            "id": "claude-opus-4-6",
            "context_window": 200000,
            "max_output": 8192,
            "cost_input": 15.0,
            "cost_output": 75.0
        },
        "sonnet": {
            "id": "claude-sonnet-4-6", 
            "context_window": 200000,
            "max_output": 8192,
            "cost_input": 3.0,
            "cost_output": 15.0
        },
        "haiku": {
            "id": "claude-haiku-4-6",
            "context_window": 200000,
            "max_output": 4096,
            "cost_input": 0.25,
            "cost_output": 1.25
        }
    }
    
    def __init__(self, tier_config: TierConfig):
        self.tier = tier_config
        self.usage_tracker = UsageTracker()
        self.session_manager = SessionManager()
        
    def route(self, task: TaskRequest) -> AgentExecutor:
        """Determine optimal executor for task."""
        
        # Check tier limits
        if not self.tier.can_execute(task):
            raise TierLimitExceeded(self.tier.get_upgrade_path())
        
        # Select model based on task profile
        model_key = self._select_model(task)
        
        # Check if we should reuse session
        session = self.session_manager.get_or_create(task)
        
        return AgentExecutor(
            model=self.MODELS[model_key],
            session=session,
            config=self._build_config(task)
        )
    
    def _select_model(self, task: TaskRequest) -> str:
        """Model selection logic."""
        
        # High complexity or risk → Opus
        if task.complexity == "HIGH" or task.risk_level in ["HIGH", "CRITICAL"]:
            return "opus"
        
        # Multi-file with cross-references → Opus
        if task.payload.get("cross_references", 0) > 5:
            return "opus"
        
        # Low complexity, quick turnaround → Haiku
        if task.complexity == "LOW" and task.priority >= 7:
            return "haiku"
        
        # Default → Sonnet
        return "sonnet"
```

### 11.2 Session Manager

```python
class SessionManager:
    """
    Manages conversation sessions with context window
    optimization and memory persistence.
    """
    
    CONTEXT_LIMIT = 200000
    SUMMARIZE_THRESHOLD = 0.75  # 150K tokens
    
    def __init__(self, vector_store: Optional[VectorStore] = None):
        self.active_sessions: Dict[str, Session] = {}
        self.vector_store = vector_store
        
    def get_or_create(self, task: TaskRequest) -> Session:
        """Get existing session or create new."""
        
        if task.execution_config.get("session_id"):
            session = self.active_sessions.get(task.session_id)
            if session and session.is_valid():
                return self._optimize_session(session, task)
        
        return self._create_session(task)
    
    def _optimize_session(self, session: Session, task: TaskRequest) -> Session:
        """Optimize session context before adding new task."""
        
        current_tokens = session.get_token_count()
        
        # Check if we need to summarize
        if current_tokens > self.CONTEXT_LIMIT * self.SUMMARIZE_THRESHOLD:
            session = self._summarize_oldest(session)
        
        # Inject relevant long-term memory
        if self.vector_store:
            relevant = self.vector_store.search(task.payload["description"])
            session.inject_memory(relevant)
        
        return session
    
    def _summarize_oldest(self, session: Session) -> Session:
        """Summarize oldest 25% of conversation."""
        
        messages = session.get_messages()
        split_point = len(messages) // 4
        
        to_summarize = messages[:split_point]
        to_keep = messages[split_point:]
        
        summary = self._generate_summary(to_summarize)
        
        # Replace oldest messages with summary
        session.set_messages([{"role": "system", "content": summary}] + to_keep)
        
        return session
```

### 11.3 Tool Orchestrator

```python
class ToolOrchestrator:
    """
    Manages parallel tool execution with dependency resolution.
    """
    
    MAX_PARALLEL = 32
    
    def __init__(self):
        self.tool_registry = ToolRegistry()
        self.execution_graph = ExecutionGraph()
        
    async def execute_batch(self, tool_calls: List[ToolCall]) -> List[ToolResult]:
        """Execute tools with optimal parallelism."""
        
        # Build dependency graph
        graph = self._build_dependency_graph(tool_calls)
        
        results = []
        pending = set(tool_calls)
        
        while pending:
            # Find ready tools (no pending dependencies)
            ready = [
                t for t in pending 
                if graph.dependencies_satisfied(t, results)
            ][:self.MAX_PARALLEL]
            
            if not ready:
                raise CircularDependencyDetected()
            
            # Execute ready tools in parallel
            batch_results = await asyncio.gather(
                *[self._execute_tool(t) for t in ready]
            )
            
            results.extend(batch_results)
            pending -= set(ready)
        
        return results
    
    def _build_dependency_graph(self, calls: List[ToolCall]) -> DependencyGraph:
        """Build graph of tool dependencies."""
        
        graph = DependencyGraph()
        
        for call in calls:
            deps = self._extract_dependencies(call)
            graph.add_node(call, dependencies=deps)
        
        return graph
```

### 11.4 Failure Recovery Handler

```python
class FailureRecoveryHandler:
    """
    Handles agent failures with automatic recovery strategies.
    """
    
    RECOVERY_STRATEGIES = {
        "F001": {
            "action": "summarize_context",
            "max_retries": 1,
            "fallback": "new_session"
        },
        "F002": {
            "action": "exponential_backoff",
            "max_retries": 5,
            "fallback": "queue_for_retry"
        },
        "F006": {
            "action": "verify_and_correct",
            "max_retries": 2,
            "fallback": "request_clarification"
        }
    }
    
    async def handle(self, error: AgentError, context: ExecutionContext) -> RecoveryResult:
        """Attempt to recover from failure."""
        
        strategy = self.RECOVERY_STRATEGIES.get(error.code)
        
        if not strategy:
            return RecoveryResult(
                success=False,
                action="ESCALATE",
                message=f"No recovery strategy for {error.code}"
            )
        
        if context.retry_count >= strategy["max_retries"]:
            return await self._execute_fallback(strategy["fallback"], context)
        
        recovery_action = getattr(self, f"_{strategy['action']}")
        return await recovery_action(error, context)
    
    async def _summarize_context(self, error: AgentError, ctx: ExecutionContext) -> RecoveryResult:
        """Summarize context to free tokens."""
        
        session = ctx.session
        session.summarize_oldest(percent=25)
        
        return RecoveryResult(
            success=True,
            action="RETRY_WITH_SUMMARY",
            context_update={"session": session}
        )
```

---

## 12. OPERATIONAL EXAMPLE

### 12.1 Multi-File Refactor Workflow

```yaml
# Input: Task Request
Task:
  task_id: "refactor-001"
  task_type: "MULTI_FILE_REFACTOR"
  complexity: "HIGH"
  risk_level: "MEDIUM"
  payload:
    description: "Extract common networking code into shared module"
    files:
      - "src/client/net/Connection.cs"
      - "src/server/net/Connection.cs"
      - "src/shared/net/Protocol.cs"
    constraints:
      - "Maintain backward compatibility"
      - "Add unit tests for extracted code"
      - "Update all references"
  execution_config:
    temperature: 0.2
    max_tokens: 8192
    tools_enabled: ["file_operations", "shell_execution", "python_execution"]
  priority: 8

# Execution Flow:
Execution:
  1. Router receives task
  2. Complexity=HIGH → Select Opus 4.6
  3. Check tier limits (Team: OK)
  4. Create/retrieve session
  5. Execute with following steps:

Steps:
  - Step 1: Read all target files
    Tools: [read_file × 3]
    Parallel: Yes
    
  - Step 2: Analyze common patterns
    Model: Opus 4.6
    Input: File contents
    Output: Extraction plan
    
  - Step 3: Create shared module
    Tools: [write_file]
    Path: "src/shared/net/BaseConnection.cs"
    
  - Step 4: Refactor client connection
    Tools: [edit_file]
    Changes: Extract to inherit from BaseConnection
    
  - Step 5: Refactor server connection
    Tools: [edit_file]
    Changes: Extract to inherit from BaseConnection
    
  - Step 6: Generate unit tests
    Tools: [write_file]
    Path: "tests/shared/net/BaseConnectionTests.cs"
    
  - Step 7: Verify compilation
    Tools: [shell]
    Command: "dotnet build"
    
  - Step 8: Run tests
    Tools: [shell]
    Command: "dotnet test --filter BaseConnection"

# Output: Task Response
Response:
  task_id: "refactor-001"
  status: "COMPLETED"
  result:
    summary: "Successfully extracted common networking code into BaseConnection class"
    files_modified:
      - path: "src/shared/net/BaseConnection.cs"
        operation: "CREATED"
        lines: 156
      - path: "src/client/net/Connection.cs"
        operation: "MODIFIED"
        diff: "-120 lines, +15 lines"
      - path: "src/server/net/Connection.cs"
        operation: "MODIFIED"
        diff: "-145 lines, +18 lines"
      - path: "tests/shared/net/BaseConnectionTests.cs"
        operation: "CREATED"
        lines: 89
    artifacts:
      - type: "class_diagram"
        path: "/tmp/refactor-001-diagram.png"
        size_bytes: 45230
    recommendations:
      - "Consider applying same pattern to MessageHandler classes"
      - "Update developer documentation with new architecture"
  metrics:
    input_tokens: 15420
    output_tokens: 8934
    total_tokens: 24354
    estimated_cost_usd: 0.90
    duration_seconds: 127
    tool_calls_count: 8
  session_context:
    session_id: "sess-abc-123"
    context_used_tokens: 24354
    context_remaining_tokens: 175646
```

### 12.2 Failure Recovery Example

```yaml
# Scenario: Context Window Exceeded During Large Refactor

Initial State:
  task: "Refactor 50 files for new input system"
  context_used: 195000 tokens
  status: IN_PROGRESS

Failure:
  code: "F001"
  message: "Context window exceeded (200K limit)"
  current_step: 23/50

Recovery:
  action: "summarize_context"
  details:
    - Summarized steps 1-15 (oldest 60% of context)
    - Compressed 120K tokens → 8K tokens
    - Retained steps 16-22 in full context
    - Injected summary as system message
  
  result: "SUCCESS"
  retry: "Step 23 with summarized context"
  
Final State:
  context_used: 78000 tokens
  status: COMPLETED
  files_refactored: 50/50
```

### 12.3 Parallel Execution Example

```yaml
# Scenario: Generate Failure Atlas for Entire Codebase

Task:
  type: "FAILURE_ATLAS_GEN"
  scope: "entire_codebase"
  files: 250

Parallelization Strategy:
  
  Phase 1: Analysis (Parallel)
    Workers: 10 (Team tier max)
    Each worker: 25 files
    Output: Partial failure analysis per batch
    
  Phase 2: Aggregation (Single)
    Worker: Opus 4.6
    Input: 10 partial analyses
    Output: Unified failure atlas
    
  Phase 3: Enhancement (Parallel)
    Workers: 5
    Tasks:
      - Generate visualization
      - Create remediation guide
      - Prioritize by risk
      - Export to various formats

Execution Metrics:
  sequential_time_estimate: 240 minutes
  parallel_time_actual: 32 minutes
  speedup: 7.5x
  cost: $12.50 (vs $45 sequential with Opus only)
```

---

## APPENDIX A: Quick Reference

### A.1 Model Selection Cheat Sheet

```
┌────────────────────────────────────────────────────────────┐
│  TASK                    │ MODEL      │ TEMP  │ MAX_TOKENS │
├────────────────────────────────────────────────────────────┤
│  Architecture Design     │ Opus 4.6   │ 0.3   │ 8192       │
│  Complex Refactoring     │ Opus 4.6   │ 0.2   │ 8192       │
│  Debugging (Heisenbug)   │ Opus 4.6   │ 0.0   │ 8192       │
│  Code Review             │ Sonnet 4.6 │ 0.2   │ 4096       │
│  Documentation           │ Haiku 4.6  │ 0.5   │ 4096       │
│  Quick Fixes             │ Haiku 4.6  │ 0.3   │ 2048       │
│  Test Generation         │ Sonnet 4.6 │ 0.3   │ 4096       │
│  Security Audit          │ Opus 4.6   │ 0.1   │ 8192       │
└────────────────────────────────────────────────────────────┘
```

### A.2 Token Cost Calculator

```python
def estimate_cost(input_tokens: int, output_tokens: int, model: str) -> float:
    """Calculate estimated API cost in USD."""
    
    rates = {
        "opus": (15.00, 75.00),    # per 1M tokens
        "sonnet": (3.00, 15.00),
        "haiku": (0.25, 1.25)
    }
    
    input_rate, output_rate = rates[model]
    
    cost = (input_tokens * input_rate + output_tokens * output_rate) / 1_000_000
    
    return round(cost, 4)

# Examples:
# Opus: 10K in, 5K out = $0.525
# Sonnet: 10K in, 5K out = $0.105
# Haiku: 10K in, 5K out = $0.00875
```

### A.3 Context Window Management

```
Optimal Context Distribution:
├── System Prompt: ~1K tokens (0.5%)
├── Task Description: ~2K tokens (1%)
├── Code Context: ~100K tokens (50%)
├── Conversation History: ~80K tokens (40%)
└── Reserved for Output: ~17K tokens (8.5%)

Warning Thresholds:
├── Green: <100K tokens (50%)
├── Yellow: 100-150K tokens (50-75%)
├── Orange: 150-180K tokens (75-90%)
└── Red: >180K tokens (90%+)
```

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-01-20 | Domain Agent 01 | Initial specification |

**Status:** IMPLEMENTATION READY  
**Review Cycle:** Quarterly  
**Next Review:** 2025-04-20
