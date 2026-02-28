---
title: Data Balance Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - data
  - balance
  - game
  - design
  - tuning
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]"
used_by: []
---

# Data Balance Routing

## Game Data Change Classification and Routing

Game data changes (stats, costs, rewards, spawn rates) require careful routing due to their impact on game balance and player experience. These changes often need design review and simulation validation.

### Data Change Classification

| Class | Description | Impact | Routing |
|-------|-------------|--------|---------|
| A | Cosmetic data (names, descriptions) | None | Local Small |
| B | Single value tweak | Low | Local Small |
| C | Related value set | Medium | Local Medium |
| D | System-wide formula | High | Local Medium + Design Review |
| E | Economy change | Critical | Design Review + Simulation |
| F | Progression curve | Critical | Design Review + Simulation |

### Routing Decision Tree

```
Data Change Request
│
├── Class A: Cosmetic (names, descriptions, flavor text)
│   └── Route: Local Small
│       └── Update data files
│       └── Confidence >= 0.90 → ACCEPT
│
├── Class B: Single Value (one stat, one item)
│   └── Route: Local Small
│       └── Update single value
│       └── Confidence >= 0.85 → ACCEPT
│       └── Confidence < 0.85 → Design Review
│
├── Class C: Related Values (weapon stats, enemy group)
│   └── Route: Local Medium
│       └── Update related values consistently
│       └── Confidence >= 0.80 → ACCEPT
│       └── Confidence < 0.80 → Design Review
│
├── Class D: Formula Change (damage calc, XP curve)
│   └── Route: Local Medium
│       └── Update formula
│       └── Run balance simulation
│       └── Confidence >= 0.75 → Design Review
│       └── Confidence < 0.75 → Design Revision
│
├── Class E: Economy Change (currency, rewards, costs)
│   └── Route: Design Review Required
│       └── Designer creates specification
│       └── Local Medium implements
│       └── Economy simulation required
│       └── Design approval required
│
└── Class F: Progression Curve (leveling, unlocks)
    └── Route: Design Review Required
        └── Designer creates specification
        └── Local Medium implements
        └── Progression simulation required
        └── Design approval required
```

### Owner Agent: Data Agent

The Data Agent owns game data change coordination.

**Responsibilities:**
- Classify data change type
- Identify impacted systems
- Coordinate with design
- Implement data changes
- Run balance simulations
- Validate changes

### Permitted Models by Class

| Class | Implementation | Review | Simulation |
|-------|----------------|--------|------------|
| A | Local Small | - | - |
| B | Local Small | Design* | - |
| C | Local Medium | Design* | - |
| D | Local Medium | Design | Required |
| E | Local Medium | Design | Required |
| F | Local Medium | Design | Required |

*Optional based on confidence

### Context Pack Contents

**Simple Data Change (Class A/B):**
```yaml
context_pack:
  data_files: 2  # Files to modify
  schema_file: 1  # Data schema
  related_data: 2  # Referenced data
  total_tokens_budget: 4000
```

**Complex Data Change (Class D/E/F):**
```yaml
context_pack:
  # Data context
  data_files: 5  # Primary data files
  schema_files: 2  # Data schemas
  formula_files: 3  # Calculation logic
  
  # Design context
  design_doc: 1  # Design specification
  balance_guidelines: 1  # Balance rules
  
  # Impact analysis
  affected_systems: "List of impacted systems"
  related_data: 5  # Related data sets
  
  total_tokens_budget: 12000
```

### Balance Simulation

For Class D/E/F changes, simulation is required:

```yaml
balance_simulation:
  # Simulation parameters
  iterations: 10000
  player_archetypes: ["casual", "regular", "hardcore"]
  
  # Metrics to track
  metrics:
    - time_to_progress
    - resource_accumulation
    - difficulty_curve
    - economy_inflation
  
  # Acceptance criteria
  criteria:
    max_progression_variance: 0.20
    max_economy_inflation: 0.10
```

### Gates Required

**Pre-Change Gates:**
1. **Design Specification**: Documented change rationale
2. **Impact Analysis**: Affected systems identified
3. **Rollback Plan**: Can revert if needed

**Post-Change Gates:**
1. **Data Validation**: Schema compliance
2. **Reference Integrity**: No broken references
3. **Simulation Pass**: Balance criteria met
4. **Design Approval**: Designer sign-off
5. **Confidence Threshold**: Meet minimum for class

### Confidence Thresholds

| Class | Minimum Confidence | Review Required |
|-------|-------------------|-----------------|
| A | 0.90 | - |
| B | 0.85 | Spot-check |
| C | 0.80 | Design review |
| D | 0.75 | Design + simulation |
| E | 0.80 | Design + simulation |
| F | 0.80 | Design + simulation |

### Data Validation Rules

```yaml
data_validation:
  schema_compliance: required
  type_checking: required
  range_validation: required
  
  # Game-specific rules
  rules:
    - "damage >= 0"
    - "cost >= 0"
    - "probability between 0 and 1"
    - "experience_requirement increasing"
```

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Simulation fail | Local | Design | Balance criteria not met |
| Complex formula | Local Small | Local Medium | Multiple variables |
| Economy impact | Any | Design | Currency affected |
| Progression impact | Any | Design | Leveling affected |

### Cost Estimates

| Class | Local | Simulation | Design | Total Range |
|-------|-------|------------|--------|-------------|
| A | $0.001 | - | - | $0.001 |
| B | $0.002 | - | $25* | $0.002-25 |
| C | $0.005 | - | $50* | $0.005-50 |
| D | $0.010 | $0.10 | $100 | $100+ |
| E | $0.015 | $0.20 | $200 | $200+ |
| F | $0.015 | $0.20 | $200 | $200+ |

*Optional based on confidence

### Best Practices

1. Always document rationale for balance changes
2. Run simulations for significant changes
3. Get design approval for economy/progression
4. Version control all data changes
5. Monitor metrics after deployment
6. Have rollback plan ready

### Data Change Workflow

```
1. Receive change request
2. Classify change type
3. Identify impacted systems
4. For significant changes:
   a. Coordinate with design
   b. Create specification
5. Implement changes
6. Run validation
7. Run simulation (if required)
8. Get approvals
9. Deploy with monitoring
```
