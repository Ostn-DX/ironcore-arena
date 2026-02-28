---
title: Safe_Mode_Protocol
type: rule
layer: enforcement
status: active
tags:
  - safety
  - safe-mode
  - emergency
  - protection
depends_on:
  - "[Autonomy_Ladder_L0_to_L5]"
used_by:
  - "[Daily_Operator_Protocol]"
---

# Safe Mode Protocol

## Purpose
Protect production when automation fails. Graceful degradation to manual mode.

## Safe Mode Triggers

### Automatic Entry
Safe mode activates when:
- 3 consecutive gate failures
- Budget exceeded by 2x
- Determinism break in production
- Security incident
- Human override command

### Manual Entry
```bash
# Emergency stop
./tools/safe_mode.sh --activate

# Or via API
curl -X POST /api/safe-mode/activate
```

## Safe Mode Behavior

### Disabled
- ❌ Auto-integration
- ❌ Auto-commit
- ❌ Multi-ticket execution
- ❌ Costly model usage (Claude)
- ❌ Experimental features

### Enabled
- ✅ Ticket creation (human-approved)
- ✅ Context pack building
- ✅ Validation (vault, normalizer)
- ✅ Gate execution
- ✅ Logging and reporting

### Required Human Steps
1. Review all pending tickets
2. Approve each integration manually
3. Run gate before every commit
4. Verify determinism
5. Monitor costs hourly

## Safe Mode Exit Criteria

Exit safe mode when:
- [ ] 5 consecutive successful manual integrations
- [ ] All gate passes for 48 hours
- [ ] Cost under budget for 1 week
- [ ] Human approves exit

```bash
# Request exit
./tools/safe_mode.sh --request-exit

# Auto-approved if criteria met
# Otherwise manual review required
```

## Protection Mechanisms

### Cost Protection
```python
if daily_cost > 2 * daily_average:
    enter_safe_mode(reason="cost_spike")
```

### Quality Protection
```python
if gate_failures >= 3:
    enter_safe_mode(reason="quality_degradation")
```

### Safety Protection
```python
if determinism_check_fails:
    enter_safe_mode(reason="determinism_break")
    notify_human(urgent=True)
```

## Safe Mode Dashboard

```
╔══════════════════════════════════╗
║      ⚠ SAFE MODE ACTIVE ⚠        ║
╠══════════════════════════════════╣
║ Reason: Quality degradation      ║
║ Activated: 2024-02-27 14:30      ║
║                                  ║
║ Criteria for exit:               ║
║ [✓] 5 successful integrations    ║
║ [✓] 48hr gate passes             ║
║ [ ] Budget compliance (2 days)   ║
║ [ ] Human approval               ║
║                                  ║
║ Current Status:                  ║
║ - Auto-integration: DISABLED     ║
║ - Model: GPT-4o-mini only        ║
║ - Daily limit: $10               ║
╚══════════════════════════════════╝
```

## Recovery Process

1. **Diagnose:** Root cause analysis
2. **Fix:** Address underlying issue
3. **Test:** Verify fix in isolation
4. **Monitor:** Extended observation
5. **Exit:** Gradual return to normal

## Related
[[Autonomy_Ladder_L0_to_L5]]
[[Escalation_Policy]]
