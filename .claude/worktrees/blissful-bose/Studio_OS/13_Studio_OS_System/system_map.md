---
title: System Map
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

# System Map
## AI-Native Game Studio OS - Architecture Overview

---

## Domain Index

| ID | Domain | Function | Status |
|----|--------|----------|--------|
| D01 | Claude Teams | Multi-agent orchestration | ✅ Active |
| D02 | Codex | Code generation | ✅ Active |
| D03 | Local LLM | On-premise inference | ✅ Active |
| D04 | Throughput | Performance optimization | ✅ Active |
| D05 | Autonomy Ladder | Progression management | ✅ Active |
| D06 | Risk Engine | Risk assessment | ✅ Active |
| D07 | Cost Guardrail | Budget monitoring | ✅ Active |
| D08 | OpenClaw Routing | Request routing | ✅ Active |
| D09 | Obsidian Vault | Knowledge management | ✅ Active |
| D10 | Determinism Gate | Execution validation | ✅ Active |
| D11 | CI Infrastructure | Headless simulation | ✅ Active |
| D12 | Auto-Ticket | Failure ticketing | ✅ Active |
| D13 | Security Model | Access control | ✅ Active |
| D14 | Handoff Protocol | Inter-agent comms | ✅ Active |
| D15 | Upgrade ROI | Cost optimization | ✅ Active |
| D16 | Weekly Audit | Compliance monitoring | ✅ Active |
| D17 | Decision Tree | Model selection | ✅ Active |
| D18 | Emergency Downgrade | Crisis management | ✅ Active |
| D19 | Escalation Trigger | Escalation logic | ✅ Active |
| D20 | Artifact Integrity | Hash verification | ✅ Active |

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI-NATIVE GAME STUDIO OS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   D13       │  │   D04       │  │   D16       │             │
│  │  Security   │──│ Throughput  │──│ Weekly Audit│             │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘             │
│         │                │                                      │
│         └────────────────┘                                      │
│                   │                                             │
│                   ▼                                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              D17: DECISION TREE ENGINE                   │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │D10 Det. │  │D06 Risk │  │Complex. │  │Context  │     │   │
│  │  │  Gate   │  │ Engine  │  │  Gate   │  │  Gate   │     │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘     │   │
│  └───────┼────────────┼────────────┼────────────┼──────────┘   │
│          │            │            │            │               │
│          └────────────┴────────────┴────────────┘               │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              D08: OPENCLAW ROUTING ENGINE                │   │
│  └───────────────────────────┬─────────────────────────────┘   │
│                              │                                  │
│      ┌───────────────────────┼───────────────────────┐         │
│      ▼                       ▼                       ▼         │
│  ┌─────────┐           ┌─────────┐           ┌─────────┐       │
│  │  D01    │           │  D02    │           │  D03    │       │
│  │ Claude  │           │  Codex  │           │ Local   │       │
│  │  Teams  │           │         │           │  LLM    │       │
│  └────┬────┘           └────┬────┘           └────┬────┘       │
│       │                     │                     │             │
│       └─────────────────────┴─────────────────────┘             │
│                             │                                   │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              EXECUTION & VALIDATION LAYER                │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │  D10    │  │  D11    │  │  D20    │  │  D14    │     │   │
│  │  │Determ.  │  │   CI    │  │Artifact │  │ Handoff │     │   │
│  │  │ Gate    │  │ Infra   │  │Integrity│  │Protocol │     │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
User Request → D13 (Auth) → D17 (Decision) → D08 (Route) → Executor → D10 (Validate) → Output
                  ↓              ↓              ↓              ↓
                D16          D06/D07        D04/D19       D11/D20
              (Audit)      (Risk/Cost)   (Perf/Escal)   (CI/Artifacts)
```

---

## Critical Paths

| Path | Domains | Latency Budget |
|------|---------|----------------|
| Request Handling | D17→D08→D01/D02/D03→D10 | <500ms |
| Risk Assessment | D06→D17→D07→D18 | <200ms |
| CI Pipeline | D10→D02→D11→D20 | <2s |
| Handoff | D12→D19→D14→D01 | <1s |

---

## Integration Health

```
Overall Health Score: 94/100 (EXCELLENT)

Component Health:
├─ Decision & Routing    [████████████████████░░░░] 92%
├─ Execution Layer       [█████████████████████░░░] 94%
├─ Governance Layer      [██████████████████████░░] 96%
├─ Observability Layer   [████████████████████░░░░] 92%
└─ Security Layer        [███████████████████████░] 98%
```

---

*Last Updated: 2024-01-15*
