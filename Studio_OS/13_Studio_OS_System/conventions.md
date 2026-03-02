---
title: Coding Conventions
type: reference
layer: system
status: active
domain: studio_os
tags:
  - reference
  - studio_os
depends_on: []
used_by: []
---

# Naming Conventions
## AI-Native Game Studio OS - Standardized Naming

---

## Variable Naming

| Pattern | Use Case | Example |
|---------|----------|---------|
| snake_case | Variables, functions | `risk_score`, `burn_rate` |
| PascalCase | Classes, domains | `RiskEngine`, `BudgetGuardrail` |
| SCREAMING_SNAKE_CASE | Constants | `MAX_RETRY_COUNT` |
| camelCase | JSON keys | `riskScore`, `burnRate` |
| kebab-case | File names, URLs | `risk-config.yaml`, `/api/v1/risk-score` |

---

## Threshold Naming

| Pattern | Use Case | Example |
|---------|----------|---------|
| L1-L4 | Autonomy/Escalation levels | `L1`, `L2`, `L3`, `L4` |
| LOW/MEDIUM/HIGH/CRITICAL | Severity levels | `HIGH`, `CRITICAL` |
| lowercase | Budget states | `warning`, `critical`, `emergency` |

---

## Unit Suffixes

| Suffix | Unit | Example |
|--------|------|---------|
| `_ms` | Milliseconds | `latency_ms` |
| `_sec` | Seconds | `timeout_sec` |
| `_min` | Minutes | `window_min` |
| `_hour` | Hours | `ttl_hour` |
| `_usd` | US Dollars | `cost_usd` |
| `_pct` | Percentage (0-1) | `utilization_pct` |
| `_percent` | Percentage (0-100) | `threshold_percent` |
| `_count` | Count | `retry_count` |
| `_bytes` | Bytes | `size_bytes` |
| `_tokens` | Tokens | `context_tokens` |

---

## Domain Naming

| ID | Domain Name | Short Name | Abbreviation |
|----|-------------|------------|--------------|
| D01 | Claude Teams | claude-teams | CT |
| D02 | Codex | codex | CX |
| D03 | Local LLM | local-llm | LLM |
| D04 | Throughput | throughput | TPUT |
| D05 | Autonomy Ladder | autonomy | AUTO |
| D06 | Risk Engine | risk-engine | RISK |
| D07 | Cost Guardrail | cost-guardrail | COST |
| D08 | OpenClaw Routing | openclaw | ROUTE |
| D09 | Obsidian Vault | obsidian | VAULT |
| D10 | Determinism Gate | determinism | DET |
| D11 | CI Infrastructure | ci-infra | CI |
| D12 | Auto-Ticket | auto-ticket | TICKET |
| D13 | Security Model | security | SEC |
| D14 | Handoff Protocol | handoff | HAND |
| D15 | Upgrade ROI | upgrade-roi | ROI |
| D16 | Weekly Audit | weekly-audit | AUDIT |
| D17 | Decision Tree | decision-tree | DECIDE |
| D18 | Emergency Downgrade | emergency | EMERG |
| D19 | Escalation Trigger | escalation | ESC |
| D20 | Artifact Integrity | artifact-integ | ART |

---

## File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Domain spec | `domain{NN}_{name}_spec.md` | `domain06_risk_engine_spec.md` |
| QA report | `domain{NN}_qa_report.md` | `domain06_qa_report.md` |
| Config | `{domain}_config.yaml` | `risk_config.yaml` |
| Schema | `{domain}_schema.json` | `risk_schema.json` |
| Template | `{purpose}_template.md` | `ticket_template.md` |

---

## API Endpoint Naming

| Pattern | Method | Example |
|---------|--------|---------|
| `/v1/{domain}/{action}` | GET/POST | `/v1/risk/calculate` |
| `/v1/{domain}/{id}/{action}` | GET/PUT/DELETE | `/v1/tickets/123/resolve` |
| `/health/{check}` | GET | `/health/live` |
| `/metrics/{type}` | GET | `/metrics/prometheus` |

---

## Metric Naming

| Pattern | Example |
|---------|---------|
| `{domain}_{metric}_{unit}` | `risk_engine_score_pct` |
| `{domain}_{metric}_{aggregation}` | `cost_guardrail_burn_rate_avg` |
| `{domain}_{metric}_{time_window}` | `throughput_requests_per_sec_1m` |

---

## Event Naming

| Pattern | Example |
|---------|---------|
| `{domain}.{event}` | `risk.score_calculated` |
| `{domain}.{object}.{action}` | `ticket.created`, `ticket.resolved` |
| `{domain}.{severity}.{event}` | `cost.critical.budget_exceeded` |

---

## Environment Variable Naming

| Pattern | Example |
|---------|---------|
| `AI_STUDIO_{DOMAIN}_{SETTING}` | `AI_STUDIO_RISK_THRESHOLD_HIGH` |
| `AI_STUDIO_{DOMAIN}_{SECRET}` | `AI_STUDIO_CLAUDE_API_KEY` |

---

## Database Table Naming

| Pattern | Example |
|---------|---------|
| `{domain}_{entity}` | `risk_assessments`, `cost_transactions` |
| `{domain}_{entity}_{type}` | `risk_threshold_configs` |

---

## Log Message Format

```
[{timestamp}] [{level}] [{domain}] [{correlation_id}] {message}

Example:
[2024-01-15T10:30:00.123Z] [WARN] [risk-engine] [abc-123] Risk score 78 exceeds threshold 75
```

---

*Last Updated: 2024-01-15*
