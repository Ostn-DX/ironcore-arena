---
title: Decision Making Protocols
type: rule
layer: enforcement
status: active
tags:
  - decisions
  - protocols
  - escalation
  - authority
  - rules
depends_on:
  - "[Studio_OS_Overview]]"
  - "[[Autonomy_Ladder_L0_L5]]"
  - "[[Governance_and_Authority_Boundaries]"
used_by:
  - "[Intent_to_Release_Pipeline]]"
  - "[[OpenClaw_Core_System]]"
  - "[[Autonomy_Upgrade_Path]"
---

# Decision Making Protocols

## Purpose

This document defines the precise protocols for making decisions within the Studio OS. It specifies when decisions can be made autonomously, when they require human input, and the exact format for escalation when needed.

## Decision Classification

Every decision in the system is classified by two dimensions:
1. **Impact**: Local, Module, System, or Organization
2. **Reversibility**: Reversible, Reversible-with-cost, or Irreversible

### Impact Levels
| Level | Scope | Examples |
|-------|-------|----------|
| Local | Single file/function | Variable naming, implementation detail |
| Module | Multiple files in component | API changes within module |
| System | Cross-module impact | Shared library changes, data format changes |
| Organization | External impact | Public API changes, release commitments |

### Reversibility Levels
| Level | Description | Examples |
|-------|-------------|----------|
| Reversible | Can undo with no lasting effect | Code changes not yet committed |
| Reversible-with-cost | Can undo but with effort | Committed changes, data migrations |
| Irreversible | Cannot be undone | Released API changes, data deletion |

## Decision Matrix

The combination of Impact and Reversibility determines the required protocol:

|  | Reversible | Reversible-with-cost | Irreversible |
|--|------------|---------------------|--------------|
| **Local** | Auto-decide | Auto-decide | Supervised |
| **Module** | Auto-decide | Supervised | Human-required |
| **System** | Supervised | Human-required | Human-required |
| **Organization** | Human-required | Human-required | Executive |

## Protocol Definitions

### Protocol: Auto-Decide
**Applies to**: Low impact, reversible decisions

**Process**:
1. System evaluates options
2. System selects optimal option based on criteria
3. Decision logged with rationale
4. Execution proceeds without pause

**Logging Requirements**:
- Decision timestamp
- Options considered
- Selection criteria
- Chosen option
- Confidence score

**Example Decisions**:
- Variable naming within function
- Loop structure selection
- Test case ordering
- Import organization

### Protocol: Supervised
**Applies to**: Medium impact or reversible-with-cost decisions

**Process**:
1. System evaluates options
2. System generates recommendation
3. Recommendation presented to human
4. Human approves, modifies, or rejects
5. Decision logged with authority

**Time Limits**:
- Human has 24 hours to respond
- No response = auto-approve (if confidence > 0.8)
- No response = escalate (if confidence < 0.8)

**Presentation Format**:
```
DECISION REQUIRED: [Brief description]
Impact: [Local/Module/System/Organization]
Reversibility: [Reversible/Reversible-with-cost/Irreversible]

OPTIONS:
1. [Option 1] - [Pros] - [Cons]
2. [Option 2] - [Pros] - [Cons]
...

RECOMMENDATION: [Option X]
RATIONALE: [Why this option]
CONFIDENCE: [0.0-1.0]

RESPOND WITH: approve / reject / modify:[description]
```

**Example Decisions**:
- Refactoring across multiple files
- New dependency introduction
- Configuration changes
- Test coverage approach

### Protocol: Human-Required
**Applies to**: High impact or irreversible decisions

**Process**:
1. System identifies decision needed
2. System prepares context and options
3. System blocks execution
4. Human makes decision
5. Human enters decision into system
6. Execution resumes

**No Auto-Approval**: These decisions NEVER auto-approve

**Required Information**:
- Full context of decision
- All viable options
- Impact analysis for each option
- Risk assessment
- Recommended option with justification

**Example Decisions**:
- Architecture changes
- Database schema modifications
- Public API design
- Security-related changes
- Production deployments

### Protocol: Executive
**Applies to**: Organization-level irreversible decisions

**Process**:
1. System identifies executive-level decision
2. System prepares comprehensive briefing
3. System notifies designated executives
4. Executive review meeting scheduled
5. Decision made in meeting
6. Decision documented and logged
7. Execution proceeds per decision

**Required Participants**:
- Project lead or above
- Technical lead
- Any stakeholders with veto authority

**Documentation Requirements**:
- Decision record with rationale
- Dissenting opinions recorded
- Implementation plan
- Rollback plan (if applicable)
- Review date for reversible decisions

**Example Decisions**:
- Project cancellation
- Major strategic pivots
- Significant vendor changes
- Legal/compliance decisions

## Escalation Triggers

### Automatic Escalation
The system MUST escalate when:

| Trigger | From Protocol | To Protocol | Timeframe |
|---------|---------------|-------------|-----------|
| Confidence < 0.5 | Auto-decide | Supervised | Immediate |
| No human response | Supervised | Human-required | After 24h |
| Human rejects recommendation | Supervised | Human-required | Immediate |
| Multiple valid options with similar scores | Auto-decide | Supervised | Immediate |
| Novel situation (no pattern match) | Any | Human-required | Immediate |
| Conflict with existing decision | Any | Human-required | Immediate |
| Safety/security concern detected | Any | Executive | Immediate |

### Human-Initiated Escalation
Any human MAY escalate any decision by:
1. Stating escalation intent
2. Providing escalation reason
3. Specifying desired authority level

The system MUST honor escalation requests within 5 minutes.

## Decision Authority Registry

### System Authority (Auto-Decide)
- Decisions matching auto-decide criteria
- Within defined autonomy level boundaries

### Human Authority (Supervised, Human-Required)
| Role | Authority |
|------|-----------|
| Developer | Local and Module decisions |
| Tech Lead | Module and System decisions |
| Project Lead | System and Organization decisions |
| Executive | Organization and Executive decisions |

### Override Authority
- Any human MAY override a system decision
- Higher authority MAY override lower authority
- Override MUST be logged with justification
- Pattern of overrides triggers review

## Decision Logging

Every decision MUST be logged:

```yaml
decision_id: [UUID]
timestamp: [ISO8601]
protocol: [Auto-decide/Supervised/Human-required/Executive]
classification:
  impact: [Local/Module/System/Organization]
  reversibility: [Reversible/Reversible-with-cost/Irreversible]
context: [Ticket/operation that triggered decision]
options_considered: [List of options]
selected_option: [Chosen option]
decision_maker: [System/Human ID]
authority_level: [L0-L5 if system, role if human]
confidence: [0.0-1.0 for system decisions]
rationale: [Why this decision was made]
escalation_trigger: [If escalated, what triggered it]
override: [If override, original decision and authority]
```

## Enforcement

- System enforces protocol selection based on classification
- Attempts to use incorrect protocol are blocked
- All decisions logged immutably
- Regular audit of decision patterns
- Violations trigger governance review
