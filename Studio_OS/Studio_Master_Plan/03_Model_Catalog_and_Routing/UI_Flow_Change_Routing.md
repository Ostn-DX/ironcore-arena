---
title: UI Flow Change Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - ui
  - flow
  - layout
  - changes
  - vision
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Vision_UI_Interpreter]]"
  - "[[Local_LLM_Coder_Small]]"
  - "[[Local_LLM_Coder_Medium]"
used_by: []
---

# UI Flow Change Routing

## UI Modification Classification and Routing

UI flow changes require coordination between vision models (for design analysis) and code models (for implementation). Routing depends on whether design assets are provided and the complexity of the interaction flow.

### UI Change Classification

| Class | Description | Complexity | Routing |
|-------|-------------|------------|---------|
| A | Style change only (colors, fonts) | Low | Local Small |
| B | Layout adjustment | Medium | Local Medium |
| C | Component addition | Medium | Local Medium |
| D | Flow modification | High | Vision + Local Medium |
| E | New screen/page | High | Vision + Local Medium |
| F | Complex interaction | Very High | Vision + Frontier |

### Routing Decision Tree

```
UI Change Request
│
├── Class A: Style Only (colors, spacing, fonts)
│   └── Route: Local Small
│       └── Update CSS/styles
│       └── Confidence >= 0.85 → ACCEPT
│       └── Confidence < 0.85 → Local Medium Review
│
├── Class B: Layout Adjustment (reposition elements)
│   └── Route: Local Medium
│       └── Modify layout code
│       └── Confidence >= 0.80 → ACCEPT
│       └── Confidence < 0.80 → Vision Review
│
├── Class C: Component Addition (new button, field)
│   └── Route: Local Medium
│       └── Create component
│       └── Integrate into existing
│       └── Confidence >= 0.75 → ACCEPT
│       └── Confidence < 0.75 → Vision + Review
│
├── Class D: Flow Modification (change navigation)
│   └── Route: Vision + Local Medium
│       └── Vision analyzes current flow
│       └── Local Medium implements changes
│       └── Confidence >= 0.75 → ACCEPT
│       └── Confidence < 0.75 → Human Review
│
├── Class E: New Screen/Page
│   └── Route: Vision (if mockup) + Local Medium
│       └── If mockup provided:
│           └── Vision extracts layout
│       └── Local Medium implements
│       └── Confidence >= 0.70 → ACCEPT
│       └── Confidence < 0.70 → Human Review
│
└── Class F: Complex Interaction (animation, state)
    └── Route: Vision + Frontier
        └── Vision analyzes requirements
        └── Frontier designs interaction
        └── Local Medium implements
        └── Human Review MANDATORY
```

### Owner Agent: UI Agent

The UI Agent owns UI change coordination.

**Responsibilities:**
- Classify UI change type
- Coordinate vision analysis (if needed)
- Generate implementation plan
- Execute code changes
- Validate visual output
- Handle responsive behavior

### Permitted Models by Class

| Class | Vision | Code | Review |
|-------|--------|------|--------|
| A | - | Local Small | Local Medium |
| B | Optional | Local Medium | Vision |
| C | Optional | Local Medium | Vision |
| D | Required | Local Medium | Human |
| E | Required | Local Medium | Human |
| F | Required | Frontier | Human |

### Context Pack Contents

**Simple UI Change (Class A/B):**
```yaml
context_pack:
  component_files: 3  # UI components to modify
  style_files: 2  # CSS/styling
  parent_components: 2  # Parent containers
  design_tokens: 1  # Color/font definitions
  total_tokens_budget: 6000
```

**Complex UI Change (Class D/E/F):**
```yaml
context_pack:
  # Design assets
  mockup_images: 2  # Screenshot/mockup
  design_system: 1  # Component library
  
  # Code context
  component_files: 5  # Related components
  flow_files: 3  # Navigation/routing
  state_files: 2  # State management
  style_files: 3  # Styling
  
  # Analysis output
  vision_analysis: "Extracted layout data"
  
  total_tokens_budget: 16000
```

### Vision Analysis Integration

When design mockups are provided:

```
1. Vision model analyzes mockup
2. Extracts:
   - Layout structure
   - Component hierarchy
   - Style properties
   - Responsive breakpoints
3. Passes structured data to code model
4. Code model implements from specification
```

### Gates Required

**Pre-Implementation Gates:**
1. **Design Review**: Mockup approved (if provided)
2. **Accessibility Check**: WCAG compliance considered
3. **Responsive Plan**: Mobile/desktop behavior defined

**Post-Implementation Gates:**
1. **Visual Match**: Matches design (if provided)
2. **Responsive Test**: Works on target viewports
3. **Interaction Test**: All interactions work
4. **Accessibility Test**: Screen reader compatible
5. **Cross-Browser**: Works on target browsers
6. **Confidence Threshold**: Meet minimum for class

### Confidence Thresholds

| Class | Minimum Confidence | Review Required |
|-------|-------------------|-----------------|
| A | 0.85 | Automated |
| B | 0.80 | Automated |
| C | 0.75 | Spot-check |
| D | 0.75 | Human review |
| E | 0.70 | Human review |
| F | 0.80 | Human mandatory |

### Responsive Behavior Requirements

```yaml
responsive_requirements:
  breakpoints:
    mobile: "< 768px"
    tablet: "768px - 1024px"
    desktop: "> 1024px"
  
  testing:
    - viewport_resizing
    - device_emulation
    - actual_device_testing
```

### Escalation Triggers

| Trigger | From | To | Condition |
|---------|------|-----|-----------|
| Visual mismatch | Local | Vision | Design not matching |
| Complex animation | Local | Frontier | Animation required |
| State management | Local Medium | Frontier | Complex state |
| Accessibility fail | Any | Human | WCAG violation |
| Cross-browser issue | Any | Human | Browser-specific |

### Cost Estimates

| Class | Local | Vision | Frontier | Total Range |
|-------|-------|--------|----------|-------------|
| A | $0.001 | - | - | $0.001 |
| B | $0.003 | $0.01* | - | $0.003-0.01 |
| C | $0.005 | $0.01* | - | $0.005-0.01 |
| D | $0.010 | $0.02 | - | $0.03 |
| E | $0.015 | $0.02 | - | $0.035 |
| F | $0.020 | $0.02 | $0.30 | $0.34 |

*If vision analysis used

### Best Practices

1. Always test responsive behavior
2. Verify accessibility (keyboard navigation, screen readers)
3. Test on actual devices, not just emulators
4. Maintain design system consistency
5. Document component usage
6. Include interaction states (hover, focus, disabled)

### Integration

Uses:
- [[Vision_UI_Interpreter]]: For design analysis
