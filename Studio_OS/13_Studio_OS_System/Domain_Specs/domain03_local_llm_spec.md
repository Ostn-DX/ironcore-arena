---
title: "D03: Local LLM Specification"
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

# Domain 03: Local LLM Cost-Efficiency Strategy Modeling
## Technical Specification v1.0 - AI-Native Game Studio OS

---

## 1. COST-EFFICIENCY MATHEMATICAL MODELS

### 1.1 Core Cost Equations

```
LocalCostPerToken = (HardwareDepreciation + ElectricityCost + Maintenance) / TotalTokensProcessed

Where:
- HardwareDepreciation = (PurchasePrice - ResidualValue) / UsefulLifeMonths
- ElectricityCost = PowerDraw_kW × HoursOperated × $/kWh
- Maintenance = HardwareDepreciation × 0.10 (10% annual maintenance)

BreakEvenPoint(Cloud→Local) = CloudAnnualCost / LocalSetupCost

ROI_Months = LocalSetupCost / (CloudMonthlyCost - LocalMonthlyOpEx)
```

### 1.2 Token Processing Capacity Model

```
MaxTokensPerMonth = TokensPerSecond × 3600 × HoursPerDay × DaysPerMonth

UtilizationRate = ActualTokensProcessed / MaxTokensPerMonth

EffectiveCostPerToken = LocalCostPerToken / UtilizationRate
```

### 1.3 Hybrid Routing Cost Optimization

```
TotalCost = Σ(CloudTokens × CloudCostPerToken) + Σ(LocalTokens × LocalCostPerToken) + SwitchingOverhead

OptimalRouting = argmin_TotalCost(RoutingStrategy)

Where RoutingStrategy ∈ {CloudOnly, LocalOnly, HybridAdaptive}
```

### 1.4 Latency-Adjusted Cost Model

```
ValueAdjustedCost = BaseCost × (1 + LatencyPenalty) × (1 - QualityBonus)

LatencyPenalty = max(0, (ActualLatency - TargetLatency) / TargetLatency)
QualityBonus = (LocalQualityScore - CloudQualityScore) / CloudQualityScore
```

---

## 2. HARDWARE REQUIREMENTS MATRIX

### 2.1 Minimum Viable Hardware Configurations

| ModelSize | VRAMRequired | RAMRequired | CPUCores | GPUModel | EstCost | PowerDraw |
|-----------|--------------|-------------|----------|----------|---------|-----------|
| 7B (Q4) | 6 GB | 16 GB | 4+ | RTX 3060 12GB | $350 | 170W |
| 7B (Q8) | 10 GB | 32 GB | 6+ | RTX 3080 12GB | $650 | 320W |
| 13B (Q4) | 10 GB | 32 GB | 6+ | RTX 3090 24GB | $1,200 | 350W |
| 13B (Q8) | 18 GB | 64 GB | 8+ | RTX 4090 24GB | $1,600 | 450W |
| 34B (Q4) | 22 GB | 64 GB | 8+ | 2×RTX 3090 | $2,400 | 700W |
| 34B (Q8) | 40 GB | 128 GB | 12+ | A100 40GB | $8,000 | 400W |
| 70B (Q4) | 44 GB | 128 GB | 16+ | 2×A100 40GB | $16,000 | 800W |
| 70B (Q8) | 80 GB | 256 GB | 24+ | A100 80GB | $15,000 | 400W |

### 2.2 Recommended Studio Configurations

| StudioTier | Config | ModelsSupported | ConcurrentUsers | EstCost |
|------------|--------|-----------------|-----------------|---------|
| Indie (1-3 devs) | RTX 4090 + 64GB RAM | 7B-13B Q8 | 2-4 | $2,500 |
| Mid-size (5-15) | 2×RTX 4090 + 128GB RAM | 7B-34B Q4 | 8-12 | $6,000 |
| Large (20-50) | 4×A100 40GB + 512GB RAM | 7B-70B Q8 | 20-40 | $35,000 |
| Enterprise (100+) | 8×A100 80GB + 1TB RAM | Full range | 100+ | $120,000 |

### 2.3 Quantization Impact Matrix

| Model | Q4_K_M | Q5_K_M | Q6_K | Q8_0 | FP16 |
|-------|--------|--------|------|------|------|
| 7B | 4.1GB | 4.7GB | 5.5GB | 7.6GB | 14GB |
| 13B | 7.9GB | 9.2GB | 10.6GB | 14.8GB | 26GB |
| 34B | 20.2GB | 23.4GB | 27.1GB | 37.6GB | 68GB |
| 70B | 41.3GB | 47.9GB | 55.6GB | 77.3GB | 140GB |

---

## 3. PERFORMANCE BENCHMARKS

### 3.1 Throughput Comparison (tokens/sec)

| Model | Hardware | Prefill | Decode | Context | QualityScore |
|-------|----------|---------|--------|---------|--------------|
| Local-7B-Q4 | RTX 4090 | 4,200 | 85 | 4K | 72/100 |
| Local-7B-Q8 | RTX 4090 | 3,800 | 78 | 8K | 78/100 |
| Local-13B-Q4 | RTX 4090 | 2,400 | 52 | 4K | 78/100 |
| Local-13B-Q8 | 2×RTX 4090 | 2,100 | 45 | 8K | 84/100 |
| Local-34B-Q4 | 2×A100 | 1,800 | 38 | 8K | 86/100 |
| Local-70B-Q4 | 2×A100 | 950 | 22 | 8K | 89/100 |
| Claude-3.5-Sonnet | API | N/A | 45 | 200K | 94/100 |
| Claude-3-Opus | API | N/A | 28 | 200K | 97/100 |
| GPT-4o | API | N/A | 55 | 128K | 95/100 |
| GPT-4-Turbo | API | N/A | 22 | 128K | 96/100 |

### 3.2 Cost Per 1M Tokens

| Model | InputCost | OutputCost | AvgCost/1M | Notes |
|-------|-----------|------------|------------|-------|
| Local-7B-Q4 | $0.0003 | $0.0003 | $0.30 | At 50% utilization |
| Local-13B-Q4 | $0.0005 | $0.0005 | $0.50 | At 50% utilization |
| Local-34B-Q4 | $0.0012 | $0.0012 | $1.20 | At 50% utilization |
| Local-70B-Q4 | $0.0025 | $0.0025 | $2.50 | At 50% utilization |
| Claude-3.5-Sonnet | $3.00 | $15.00 | $9.00 | 70/30 split |
| Claude-3-Opus | $15.00 | $75.00 | $45.00 | 70/30 split |
| GPT-4o | $5.00 | $15.00 | $8.50 | 70/30 split |
| GPT-4-Turbo | $10.00 | $30.00 | $17.00 | 70/30 split |

### 3.3 Latency Benchmarks (p50/p95/p99)

| Model | TTFT (p50) | TTFT (p95) | TPS (p50) | TPS (p95) |
|-------|------------|------------|-----------|-----------|
| Local-7B | 50ms | 120ms | 85 | 78 |
| Local-13B | 85ms | 200ms | 52 | 48 |
| Local-34B | 150ms | 350ms | 38 | 34 |
| Claude-API | 800ms | 2,500ms | 45 | 38 |
| GPT-4-API | 600ms | 2,000ms | 55 | 48 |

---

## 4. FALLBACK TRIGGER CONDITIONS

### 4.1 Local→Cloud Fallback Triggers

```python
TRIGGER_CLOUD_IF:
    local_queue_depth > MAX_QUEUE_DEPTH (10 requests)
    OR local_vram_utilization > 0.95
    OR local_temperature > THERMAL_LIMIT (85°C)
    OR estimated_local_latency > MAX_ACCEPTABLE_LATENCY (2s)
    OR request_context_length > LOCAL_MAX_CONTEXT
    OR model_not_available_locally(requested_model)
    OR local_error_rate > 0.05 (5% in last 5 min)
```

### 4.2 Cloud→Local Promotion Triggers

```python
TRIGGER_LOCAL_IF:
    cloud_cost_projected > DAILY_BUDGET_THRESHOLD
    OR cloud_latency_p95 > 3000ms
    OR privacy_required(request.data_classification)
    OR offline_mode_enabled
    OR cloud_rate_limit_hit
    OR request_pattern_matches_local_optimization(request_type)
    AND local_capacity_available > request_estimated_tokens
```

### 4.3 Hybrid Decision Matrix

| Condition | Primary | Fallback | Trigger |
|-----------|---------|----------|---------|
| High token volume (>100K/day) | Local | Cloud (overflow) | Queue depth > 5 |
| Privacy-sensitive data | Local | None | Always local |
| Complex reasoning | Cloud (Claude/GPT-4) | Local (70B) | Quality score < 85 |
| Real-time generation | Local | Cloud | Latency > 500ms |
| Batch processing | Local | Cloud | Time constraints |
| Creative writing | Cloud | Local | User preference |

---

## 5. COST COMPARISON TABLES

### 5.1 Monthly Cost by Usage Tier (USD)

| MonthlyTokens | CloudOnly | LocalOnly | HybridOptimal | Savings |
|---------------|-----------|-----------|---------------|---------|
| 1M | $9.00 | $85.00 | $9.00 | 0% |
| 5M | $45.00 | $85.00 | $45.00 | 0% |
| 10M | $90.00 | $85.00 | $75.00 | 17% |
| 25M | $225.00 | $85.00 | $95.00 | 58% |
| 50M | $450.00 | $85.00 | $110.00 | 76% |
| 100M | $900.00 | $85.00 | $140.00 | 84% |
| 250M | $2,250.00 | $85.00 | $200.00 | 91% |
| 500M | $4,500.00 | $85.00 | $280.00 | 94% |

### 5.2 TCO Analysis (3-Year)

| Configuration | Initial | Year1 | Year2 | Year3 | 3-YearTCO |
|---------------|---------|-------|-------|-------|-----------|
| Cloud-Only (50M/mo) | $0 | $5,400 | $5,400 | $5,400 | $16,200 |
| Local-7B Setup | $2,500 | $1,020 | $1,020 | $1,020 | $5,560 |
| Local-13B Setup | $6,000 | $1,020 | $1,020 | $1,020 | $9,060 |
| Local-34B Setup | $35,000 | $2,400 | $2,400 | $2,400 | $42,200 |
| Hybrid (13B+Cloud) | $6,000 | $2,700 | $2,700 | $2,700 | $14,100 |

### 5.3 Break-Even Analysis

| Setup | MonthlyCloudCost | BreakEvenMonths | 3-YearSavings |
|-------|------------------|-----------------|---------------|
| RTX 4090 (7B-13B) | $450 (50M tokens) | 13 months | $10,640 |
| 2×RTX 4090 (34B) | $900 (100M tokens) | 16 months | $20,880 |
| 4×A100 (70B) | $2,250 (250M tokens) | 19 months | $46,800 |

---

## 6. SUCCESS CRITERIA (MEASURABLE)

### 6.1 Primary KPIs

| Metric | Target | Measurement | Frequency |
|--------|--------|-------------|-----------|
| CostPer1MTokens | <$2.00 | (Hardware+Electricity)/Tokens | Daily |
| LocalUtilizationRate | >60% | LocalTokens/TotalTokens | Daily |
| AvgResponseLatency | <500ms p95 | End-to-end request time | Real-time |
| FallbackRate | <15% | CloudFallbacks/TotalRequests | Hourly |
| TokenThroughput | >50 tok/sec | Decode tokens per second | Continuous |
| QualityScore | >80/100 | Human evaluation + benchmarks | Weekly |
| SystemUptime | >99.5% | (TotalTime-Downtime)/TotalTime | Daily |
| PowerEfficiency | <50W/1K tokens | PowerDraw/Throughput | Continuous |

### 6.2 Secondary KPIs

| Metric | Target | Purpose |
|--------|--------|---------|
| ModelLoadTime | <30s | Fast model switching |
| ContextSwitchOverhead | <100ms | Seamless routing |
| CacheHitRate | >40% | Repeated prompt optimization |
| VRAMEfficiency | >85% | Optimal resource usage |
| ErrorRate | <0.1% | Reliability |

### 6.3 Business KPIs

| Metric | Target | Calculation |
|--------|--------|-------------|
| MonthlyCostReduction | >50% | (Previous-Current)/Previous |
| ROI Achievement | <18 months | Break-even timeline |
| DeveloperProductivity | +20% | Tasks completed per sprint |
| CloudDependency | <30% | CloudTokens/TotalTokens |

---

## 7. FAILURE STATES

### 7.1 Critical Failures (Require Immediate Action)

| FailureMode | Detection | Impact | Recovery |
|-------------|-----------|--------|----------|
| GPU OOM | vram_monitor | Request failure | Auto-fallback to cloud |
| Thermal Throttle | temp_sensor | 50% perf drop | Reduce batch size |
| Model Corruption | checksum_fail | Complete failure | Reload from backup |
| Network Partition | health_check | Isolation | Queue + retry |
| Power Loss | UPS_alert | Downtime | Graceful shutdown |

### 7.2 Degraded Performance States

| State | Condition | Action |
|-------|-----------|--------|
| Yellow | Latency > 1s p95 | Increase cloud ratio |
| Orange | Queue depth > 5 | Reject non-critical requests |
| Red | Error rate > 5% | Full cloud fallback |
| Black | Hardware failure | Maintenance mode |

### 7.3 Failure Recovery Procedures

```
DETECT_FAILURE:
    IF gpu_temperature > 85°C:
        THROTTLE_BATCH_SIZE(50%)
        ALERT_OPS_TEAM()
    
    IF vram_utilization > 0.95:
        EVICT_OLDEST_CACHE()
        FALLBACK_TO_CLOUD(new_requests)
    
    IF request_latency_p99 > 5000ms:
        SCALE_CLOUD_ALLOCATION(200%)
        INVESTIGATE_LOCAL_PERF()
    
    IF error_rate_5min > 0.10:
        ACTIVATE_FULL_FALLBACK()
        PAGE_ONCALL()
```

---

## 8. INTEGRATION SURFACE

### 8.1 API Endpoints

```
POST /v1/chat/completions          # OpenAI-compatible
POST /v1/completions               # Legacy completion
POST /v1/embeddings                # Embedding generation
GET  /v1/models                    # List available models
GET  /v1/health                    # Health check
GET  /v1/metrics                   # Prometheus metrics
POST /v1/admin/switch-model        # Runtime model switch
POST /v1/admin/update-config       # Configuration update
```

### 8.2 Configuration Interface

```yaml
llm_router:
  default_backend: "auto"  # auto, local, cloud
  
  local:
    enabled: true
    default_model: "llama-3.1-70b-q4"
    max_context: 8192
    batch_size: 512
    quantization: "Q4_K_M"
    gpu_layers: -1  # all
    
  cloud:
    enabled: true
    providers:
      - name: "anthropic"
        model: "claude-3-5-sonnet-20241022"
        priority: 1
      - name: "openai"
        model: "gpt-4o"
        priority: 2
    
  routing:
    cost_threshold: 100.0  # $/day
    latency_threshold_ms: 2000
    quality_threshold: 80
    privacy_patterns:
      - "password"
      - "secret_key"
      - "ssn"
      - "credit_card"
```

### 8.3 Event Hooks

| Event | Payload | Trigger |
|-------|---------|---------|
| `llm.request.started` | request_id, model, tokens_est | Every request |
| `llm.request.completed` | request_id, tokens_in, tokens_out, latency | Success |
| `llm.request.failed` | request_id, error, fallback_triggered | Failure |
| `llm.fallback.activated` | reason, from_backend, to_backend | Fallback |
| `llm.model.loaded` | model_name, load_time, vram_used | Model load |
| `llm.cost.threshold_exceeded` | projected_cost, threshold | Budget alert |

### 8.4 SDK Integration Points

```python
# Python SDK Example
from studio_os.llm import LLMRouter

router = LLMRouter(
    default_backend="auto",
    cost_budget=100.0,  # $/day
    latency_target=500  # ms
)

response = await router.complete(
    prompt="Generate game dialogue...",
    context=game_context,
    privacy_level="internal",  # triggers local routing
    quality_requirement=85     # may trigger cloud for complex tasks
)
```

---

## 9. JSON SCHEMAS

### 9.1 Request Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "LLMRequest",
  "type": "object",
  "required": ["messages"],
  "properties": {
    "messages": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Message"
      }
    },
    "model": {
      "type": "string",
      "default": "auto"
    },
    "temperature": {
      "type": "number",
      "minimum": 0,
      "maximum": 2,
      "default": 0.7
    },
    "max_tokens": {
      "type": "integer",
      "minimum": 1,
      "maximum": 32768,
      "default": 1024
    },
    "routing_hint": {
      "type": "string",
      "enum": ["auto", "local", "cloud", "cost_optimal", "latency_optimal", "quality_optimal"],
      "default": "auto"
    },
    "privacy_level": {
      "type": "string",
      "enum": ["public", "internal", "confidential", "restricted"],
      "default": "internal"
    },
    "context_id": {
      "type": "string",
      "description": "For conversation continuity"
    }
  },
  "definitions": {
    "Message": {
      "type": "object",
      "required": ["role", "content"],
      "properties": {
        "role": {
          "type": "string",
          "enum": ["system", "user", "assistant"]
        },
        "content": {
          "type": "string"
        }
      }
    }
  }
}
```

### 9.2 Response Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "LLMResponse",
  "type": "object",
  "required": ["id", "choices", "usage"],
  "properties": {
    "id": {
      "type": "string"
    },
    "choices": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/Choice"
      }
    },
    "usage": {
      "$ref": "#/definitions/Usage"
    },
    "routing_info": {
      "$ref": "#/definitions/RoutingInfo"
    }
  },
  "definitions": {
    "Choice": {
      "type": "object",
      "properties": {
        "index": {"type": "integer"},
        "message": {"$ref": "#/definitions/Message"},
        "finish_reason": {
          "type": "string",
          "enum": ["stop", "length", "content_filter"]
        }
      }
    },
    "Usage": {
      "type": "object",
      "properties": {
        "prompt_tokens": {"type": "integer"},
        "completion_tokens": {"type": "integer"},
        "total_tokens": {"type": "integer"},
        "estimated_cost_usd": {"type": "number"}
      }
    },
    "RoutingInfo": {
      "type": "object",
      "properties": {
        "backend": {"type": "string"},
        "model_used": {"type": "string"},
        "latency_ms": {"type": "number"},
        "cache_hit": {"type": "boolean"}
      }
    }
  }
}
```

### 9.3 Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "LLMRouterConfig",
  "type": "object",
  "properties": {
    "version": {"type": "string"},
    "default_backend": {
      "type": "string",
      "enum": ["auto", "local", "cloud"]
    },
    "local": {
      "type": "object",
      "properties": {
        "enabled": {"type": "boolean"},
        "models": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "path": {"type": "string"},
              "quantization": {"type": "string"},
              "context_length": {"type": "integer"},
              "gpu_layers": {"type": "integer"}
            }
          }
        },
        "hardware": {
          "type": "object",
          "properties": {
            "gpu_devices": {"type": "array", "items": {"type": "integer"}},
            "vram_limit_mb": {"type": "integer"},
            "cpu_threads": {"type": "integer"}
          }
        }
      }
    },
    "cloud": {
      "type": "object",
      "properties": {
        "enabled": {"type": "boolean"},
        "providers": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "api_key_env": {"type": "string"},
              "models": {"type": "array", "items": {"type": "string"}},
              "priority": {"type": "integer"}
            }
          }
        }
      }
    },
    "routing_rules": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "condition": {"type": "string"},
          "action": {"type": "string"},
          "priority": {"type": "integer"}
        }
      }
    }
  }
}
```

---

## 10. PSEUDO-IMPLEMENTATION

### 10.1 Core Router Implementation

```python
class LLMRouter:
    def __init__(self, config: RouterConfig):
        self.local_backend = LocalBackend(config.local)
        self.cloud_backend = CloudBackend(config.cloud)
        self.metrics = MetricsCollector()
        self.cache = ResponseCache()
        
    async def complete(self, request: LLMRequest) -> LLMResponse:
        # Check cache first
        cached = self.cache.get(request)
        if cached:
            return cached.with_cache_hit()
        
        # Determine routing
        backend = self._select_backend(request)
        
        # Execute with fallback
        try:
            response = await self._execute_with_fallback(request, backend)
            self.cache.store(request, response)
            return response
        except Exception as e:
            self.metrics.record_error(e)
            raise
    
    def _select_backend(self, request: LLMRequest) -> Backend:
        # Priority 1: Privacy requirements
        if request.privacy_level in ["confidential", "restricted"]:
            return self.local_backend
        
        # Priority 2: Explicit routing hint
        if request.routing_hint == "local":
            return self.local_backend
        if request.routing_hint == "cloud":
            return self.cloud_backend
        
        # Priority 3: Cost optimization
        if self._should_use_local_for_cost(request):
            return self.local_backend
        
        # Priority 4: Latency optimization
        if self._should_use_local_for_latency(request):
            return self.local_backend
        
        # Default: Cloud for quality
        return self.cloud_backend
    
    def _should_use_local_for_cost(self, request: LLMRequest) -> bool:
        projected_daily = self.metrics.project_daily_cost()
        if projected_daily > self.config.cost_threshold:
            return self.local_backend.is_available()
        return False
    
    async def _execute_with_fallback(
        self, 
        request: LLMRequest, 
        primary: Backend
    ) -> LLMResponse:
        try:
            return await primary.complete(request)
        except (ResourceExhausted, TimeoutError) as e:
            fallback = self._get_fallback(primary)
            self.metrics.record_fallback(primary, fallback, e)
            return await fallback.complete(request)
```

### 10.2 Local Backend Implementation

```python
class LocalBackend:
    def __init__(self, config: LocalConfig):
        self.model_manager = ModelManager(config.models)
        self.gpu_monitor = GPUMonitor()
        self.inference_engine = LlamaCppEngine()
        
    async def complete(self, request: LLMRequest) -> LLMResponse:
        # Check capacity
        if not self._has_capacity(request):
            raise ResourceExhausted("Local capacity exceeded")
        
        # Load model if needed
        model = await self.model_manager.load(request.model)
        
        # Execute inference
        start_time = time.monotonic()
        result = await self.inference_engine.generate(
            model=model,
            prompt=request.messages,
            max_tokens=request.max_tokens,
            temperature=request.temperature
        )
        latency = (time.monotonic() - start_time) * 1000
        
        return LLMResponse(
            content=result.text,
            tokens_in=result.prompt_tokens,
            tokens_out=result.completion_tokens,
            latency_ms=latency,
            backend="local",
            model=model.name
        )
    
    def _has_capacity(self, request: LLMRequest) -> bool:
        vram_available = self.gpu_monitor.get_free_vram()
        vram_required = self._estimate_vram(request)
        return vram_available > vram_required * 1.2  # 20% buffer
```

### 10.3 Cloud Backend Implementation

```python
class CloudBackend:
    def __init__(self, config: CloudConfig):
        self.providers = [
            AnthropicProvider(p) for p in config.providers if p.name == "anthropic"
        ] + [
            OpenAIProvider(p) for p in config.providers if p.name == "openai"
        ]
        self.cost_tracker = CostTracker()
        
    async def complete(self, request: LLMRequest) -> LLMResponse:
        provider = self._select_provider(request)
        
        start_time = time.monotonic()
        result = await provider.complete(request)
        latency = (time.monotonic() - start_time) * 1000
        
        self.cost_tracker.record(result.cost_usd)
        
        return LLMResponse(
            content=result.text,
            tokens_in=result.prompt_tokens,
            tokens_out=result.completion_tokens,
            latency_ms=latency,
            backend="cloud",
            model=result.model,
            cost_usd=result.cost_usd
        )
    
    def _select_provider(self, request: LLMRequest) -> Provider:
        # Select based on quality requirements and provider priority
        for provider in sorted(self.providers, key=lambda p: p.priority):
            if provider.quality_score >= request.quality_requirement:
                return provider
        return self.providers[0]  # Fallback to highest priority
```

### 10.4 Deployment Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  llm-router:
    image: studio-os/llm-router:latest
    ports:
      - "8080:8080"
    volumes:
      - ./models:/models:ro
      - ./config:/config:ro
    environment:
      - LLM_CONFIG_PATH=/config/router.yaml
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - ./grafana-dashboards:/var/lib/grafana/dashboards
```

---

## 11. OPERATIONAL EXAMPLE

### 11.1 Game Dialogue Generation Workflow

```python
# Example: AI-Native Game Studio OS Integration

from studio_os.llm import LLMRouter
from studio_os.game import DialogueContext, NPCProfile

class DialogueGenerator:
    def __init__(self):
        self.router = LLMRouter(
            default_backend="auto",
            cost_budget=500.0,  # $500/day budget
            latency_target=300   # 300ms target
        )
    
    async def generate_npc_dialogue(
        self,
        npc: NPCProfile,
        context: DialogueContext,
        player_input: str
    ) -> str:
        """
        Generate context-aware NPC dialogue.
        Routes based on complexity and privacy.
        """
        # Build prompt
        system_prompt = f"""You are {npc.name}, a {npc.role} in {context.location}.
Personality: {npc.personality_traits}
Background: {npc.backstory}
Current emotional state: {npc.current_mood}"""
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": player_input}
        ]
        
        # Determine routing based on NPC importance
        routing_hint = self._get_routing_hint(npc.importance)
        
        response = await self.router.complete(
            messages=messages,
            max_tokens=150,
            temperature=0.8,
            routing_hint=routing_hint,
            privacy_level="internal"
        )
        
        return response.content
    
    def _get_routing_hint(self, importance: str) -> str:
        """Route minor NPCs to local, major NPCs to cloud for quality."""
        routing_map = {
            "minor": "local",      # Cost optimization
            "supporting": "auto",  # Let router decide
            "major": "cloud",      # Quality priority
            "protagonist": "cloud" # Best quality
        }
        return routing_map.get(importance, "auto")

# Usage in game loop
async def handle_player_interaction(game_state, npc, player_input):
    generator = DialogueGenerator()
    
    dialogue = await generator.generate_npc_dialogue(
        npc=npc,
        context=game_state.current_context,
        player_input=player_input
    )
    
    # Display dialogue with metadata
    display_dialogue(
        text=dialogue,
        speaker=npc.name,
        routing_info=dialogue.routing_info  # Show backend used
    )
```

### 11.2 Batch Content Generation

```python
class ContentPipeline:
    """Batch process game content with cost optimization."""
    
    def __init__(self):
        self.router = LLMRouter(
            default_backend="local",  # Prefer local for batch
            cost_budget=1000.0
        )
    
    async def generate_quest_descriptions(
        self,
        quests: List[QuestTemplate]
    ) -> List[QuestDescription]:
        """Generate descriptions for multiple quests."""
        
        # Process in batches for efficiency
        batch_size = 10
        results = []
        
        for i in range(0, len(quests), batch_size):
            batch = quests[i:i + batch_size]
            batch_tasks = [
                self._generate_single_quest(q) for q in batch
            ]
            batch_results = await asyncio.gather(*batch_tasks)
            results.extend(batch_results)
        
        return results
    
    async def _generate_single_quest(
        self,
        quest: QuestTemplate
    ) -> QuestDescription:
        prompt = f"""Generate an engaging quest description:
Title: {quest.title}
Type: {quest.quest_type}
Difficulty: {quest.difficulty}
Setting: {quest.setting}"""
        
        response = await self.router.complete(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
            temperature=0.7,
            routing_hint="local"  # Force local for batch cost savings
        )
        
        return QuestDescription(
            quest_id=quest.id,
            description=response.content,
            cost=response.usage.estimated_cost_usd
        )
```

### 11.3 Monitoring Dashboard Queries

```promql
# Cost per hour
sum(rate(llm_request_cost_usd[1h]))

# Local vs Cloud ratio
sum(rate(llm_requests_total{backend="local"}[5m])) 
/ 
sum(rate(llm_requests_total[5m]))

# P95 latency by backend
histogram_quantile(0.95, 
  sum(rate(llm_request_duration_seconds_bucket[5m])) by (backend, le)
)

# Daily cost projection
sum(increase(llm_request_cost_usd[1d])) 
/ 
days_in_month() * 30

# Cache hit rate
sum(rate(llm_cache_hits_total[5m]))
/
sum(rate(llm_requests_total[5m]))
```

### 11.4 Cost Alert Configuration

```yaml
# alerts.yml
groups:
  - name: llm_cost_alerts
    rules:
      - alert: DailyCostThresholdExceeded
        expr: |
          sum(increase(llm_request_cost_usd[1d])) > 500
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Daily LLM cost exceeded $500"
          
      - alert: LocalUtilizationLow
        expr: |
          sum(rate(llm_requests_total{backend="local"}[1h])) 
          / 
          sum(rate(llm_requests_total[1h])) < 0.5
        for: 30m
        labels:
          severity: info
        annotations:
          summary: "Local backend underutilized"
          
      - alert: FallbackRateHigh
        expr: |
          sum(rate(llm_fallback_total[5m])) 
          / 
          sum(rate(llm_requests_total[5m])) > 0.2
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Fallback rate exceeds 20%"
```

---

## APPENDIX A: Model Recommendations

| Use Case | Recommended Model | Quantization | Hardware |
|----------|-------------------|--------------|----------|
| Code generation | CodeLlama-34B | Q4 | 2×RTX 4090 |
| Creative writing | Llama-3.1-70B | Q4 | 2×A100 |
| Dialogue/NPC | Llama-3.1-13B | Q8 | RTX 4090 |
| Summarization | Mistral-7B | Q8 | RTX 4070 |
| Embedding | nomic-embed-text | N/A | CPU/GPU |
| Classification | Phi-3-mini | Q8 | RTX 3060 |

## APPENDIX B: Power Consumption Estimates

| Configuration | Idle | Load | Monthly kWh | Cost @ $0.12/kWh |
|---------------|------|------|-------------|------------------|
| RTX 4090 Single | 25W | 450W | 180 | $21.60 |
| 2×RTX 4090 | 40W | 900W | 360 | $43.20 |
| 4×A100 | 200W | 1600W | 720 | $86.40 |

---

*Document Version: 1.0*
*Last Updated: 2024*
*Owner: Domain 03 - Local LLM Cost-Efficiency Strategy Modeling*
