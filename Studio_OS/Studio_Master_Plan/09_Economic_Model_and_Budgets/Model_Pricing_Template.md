---
title: Model Pricing Template
type: template
layer: architecture
status: active
tags:
  - pricing
  - template
  - unknown-models
  - estimation
  - cost-model
depends_on:
  - "[Economic_Model_Overview]]"
  - "[[Model_Cost_Matrix]"
used_by:
  - "[Cost_Per_Feature_Estimates]]"
  - "[[Monthly_Budget_Prototype_Tier]]"
  - "[[Monthly_Budget_Indie_Tier]]"
  - "[[Monthly_Budget_MultiProject_Tier]"
---

# Model Pricing Template

## Overview

Use this template when exact pricing is unknown for a model or provider. It provides a structured approach to cost estimation with appropriate uncertainty ranges.

## Template Structure

```yaml
model_pricing_estimate:
  # Identification
  model_name: "Model Name"
  provider: "Provider Name"
  version: "v1.0"
  estimate_date: "2024-01-15"
  
  # Pricing Information
  pricing:
    status: "unknown | estimated | confirmed"
    source: "documentation | announcement | inference"
    confidence: "low | medium | high"
    
  # Cost Components
  costs:
    input_per_1k: null  # $X.XXXX
    output_per_1k: null  # $X.XXXX
    context_window: null  # tokens
    
  # Estimation Method
  estimation:
    method: "comparison | interpolation | provider_pattern"
    basis: "similar to GPT-4o | between X and Y"
    
  # Ranges
  ranges:
    low:
      input_per_1k: null
      output_per_1k: null
    likely:
      input_per_1k: null
      output_per_1k: null
    high:
      input_per_1k: null
      output_per_1k: null
      
  # Validation Plan
  validation:
    method: "test_calls | documentation_review | provider_inquiry"
    timeline: "1 week"
    
  # Notes
  notes: "Any relevant context or assumptions"
```

## Estimation Methods

### Method 1: Comparison to Known Models

Use when the new model is positioned relative to known models.

```yaml
estimation:
  method: comparison
  comparable_models:
    - name: "claude-3.5-sonnet"
      relationship: "similar_capability"
      price_ratio: 1.0
      
    - name: "gpt-4o"
      relationship: "slightly_less_capable"
      price_ratio: 0.8
      
  calculation: |
    If Claude 3.5 Sonnet = $3/1K input
    And new model is 80% of that capability
    Then estimate = $3 × 0.8 = $2.40/1K input
```

### Method 2: Provider Pattern

Use when the provider has consistent pricing across models.

```yaml
estimation:
  method: provider_pattern
  provider: "anthropic"
  pattern: "capability_tiers"
  
  known_prices:
    haiku: "$0.25/1K input"
    sonnet: "$3.00/1K input"
    opus: "$15.00/1K input"
    
  new_model_position: "between sonnet and opus"
  
  calculation: |
    Range = $3.00 to $15.00
    Midpoint = ($3 + $15) / 2 = $9.00
    Likely estimate = $9.00/1K input
```

### Method 3: Market Position

Use when the provider's market position is known.

```yaml
estimation:
  method: market_position
  provider_position: "premium | mid-market | budget"
  
  market_reference:
    premium: "OpenAI, Anthropic"
    mid_market: "Google, Cohere"
    budget: "OpenRouter, Together"
    
  calculation: |
    Premium: 1.0x market average
    Mid-market: 0.7x market average
    Budget: 0.4x market average
```

### Method 4: Interpolation

Use when the model fits between two known models.

```yaml
estimation:
  method: interpolation
  lower_bound:
    model: "gpt-3.5-turbo"
    price: "$0.50/1K input"
    
  upper_bound:
    model: "gpt-4o"
    price: "$2.50/1K input"
    
  new_model_position: "75% of the way to GPT-4o"
  
  calculation: |
    Range = $2.50 - $0.50 = $2.00
    75% of range = $2.00 × 0.75 = $1.50
    Estimate = $0.50 + $1.50 = $2.00/1K input
```

## Range Calculation

### Uncertainty Factors

| Factor | Low Multiplier | High Multiplier |
|--------|----------------|-----------------|
| New provider | 0.5 | 2.0 |
| Known provider, new model | 0.7 | 1.5 |
| Beta/Preview | 0.3 | 3.0 |
| Similar to known model | 0.8 | 1.2 |

### Example Range Calculation

```yaml
base_estimate:
  input_per_1k: $2.00
  output_per_1k: $6.00
  
uncertainty:
  factor: "new_provider"
  low_mult: 0.5
  high_mult: 2.0
  
ranges:
  low:
    input_per_1k: $1.00  # $2.00 × 0.5
    output_per_1k: $3.00  # $6.00 × 0.5
    
  likely:
    input_per_1k: $2.00
    output_per_1k: $6.00
    
  high:
    input_per_1k: $4.00  # $2.00 × 2.0
    output_per_1k: $12.00  # $6.00 × 2.0
```

## Validation Approaches

### Approach 1: Test Calls

```yaml
validation:
  method: test_calls
  
  steps:
    - sign_up_for_api_access
    - make_10_test_calls
    - record_actual_costs
    - calculate_per_token_price
    
  sample_sizes:
    minimum: 10 calls
    recommended: 50 calls
    statistically_significant: 200 calls
    
  cost: "$10-50 for validation"
```

### Approach 2: Documentation Review

```yaml
validation:
  method: documentation_review
  
  sources:
    - official_pricing_page
    - api_documentation
    - announcement_blog_post
    - discord_slack_community
    
  reliability:
    official: high
    community: medium
    inferred: low
```

### Approach 3: Provider Inquiry

```yaml
validation:
  method: provider_inquiry
  
  channels:
    - sales_contact
    - support_ticket
    - community_forum
    - twitter_dm
    
  response_time:
    sales: "1-3 business days"
    support: "24-48 hours"
    community: "variable"
```

## Example: New Model Estimation

### Scenario: "Nova-1" from NewProvider AI

```yaml
model_pricing_estimate:
  model_name: "Nova-1"
  provider: "NewProvider AI"
  version: "v1.0"
  estimate_date: "2024-01-15"
  
  pricing:
    status: estimated
    source: inference
    confidence: low
    
  costs:
    input_per_1k: null
    output_per_1k: null
    context_window: 128000  # Announced
    
  estimation:
    method: comparison
    basis: "Positioned as GPT-4 competitor"
    
    comparable_models:
      - name: "gpt-4o"
        price_input: "$2.50/1K"
        price_output: "$10.00/1K"
        relationship: "similar_capability"
        
      - name: "claude-3.5-sonnet"
        price_input: "$3.00/1K"
        price_output: "$15.00/1K"
        relationship: "similar_capability"
        
    calculation: |
      Average of competitors:
      Input: ($2.50 + $3.00) / 2 = $2.75/1K
      Output: ($10.00 + $15.00) / 2 = $12.50/1K
      
      New provider discount (estimated 20%):
      Input: $2.75 × 0.8 = $2.20/1K
      Output: $12.50 × 0.8 = $10.00/1K
      
  ranges:
    low:
      input_per_1k: $1.50  # Aggressive pricing
      output_per_1k: $6.00
      
    likely:
      input_per_1k: $2.20
      output_per_1k: $10.00
      
    high:
      input_per_1k: $4.00  # Premium positioning
      output_per_1k: $18.00
      
  validation:
    method: test_calls
    timeline: "1 week after API access"
    budget: "$50"
    
  notes: |
    NewProvider AI is positioning as budget-friendly alternative.
    Their marketing emphasizes "50% cheaper than GPT-4" but this
    may refer to specific use cases. Wide uncertainty range due
    to lack of official pricing.
    
    UPDATE 2024-01-20: Official pricing released!
    Actual: $1.50/1K input, $6.00/1K output
    Validation: Low estimate was correct.
```

## Updating Estimates

### When to Update

| Trigger | Action |
|---------|--------|
| Official pricing released | Update to confirmed |
| Beta → GA | Narrow ranges |
| Price change announced | Update ranges |
| Validation complete | Update with actuals |
| New competitor launched | Re-evaluate positioning |

### Version Control

```yaml
pricing_history:
  - date: "2024-01-15"
    version: "estimate_v1"
    input: "$2.20 (likely)"
    confidence: low
    
  - date: "2024-01-20"
    version: "confirmed_v1"
    input: "$1.50 (actual)"
    confidence: high
    
  - date: "2024-03-01"
    version: "confirmed_v2"
    input: "$1.20 (price drop)"
    confidence: high
```

## Integration with Budgets

### Conservative Planning

When using estimated pricing:
- Use HIGH range for budget planning
- Add 20% buffer for uncertainty
- Review weekly until confirmed

### Example Budget Impact

```yaml
monthly_budget:
  base: $1000
  
  with_known_models: $1000
  
  with_one_estimated_model:
    base: $1000
    uncertainty_buffer: $200  # 20% of estimated usage
    total: $1200
    
  with_multiple_estimated_models:
    base: $1000
    uncertainty_buffer: $400  # Higher uncertainty
    total: $1400
```

---

*Unknown pricing is not an excuse for no budget. Estimate, validate, update.*
