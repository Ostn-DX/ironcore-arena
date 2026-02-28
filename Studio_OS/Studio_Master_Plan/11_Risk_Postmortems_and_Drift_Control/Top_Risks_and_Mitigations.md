---
title: Top Risks and Mitigations
type: pitfall
layer: enforcement
status: active
tags:
  - risks
  - mitigation
  - pitfalls
  - safety
  - enforcement
depends_on:
  - "[Risk_Taxonomy]]"
  - "[[Quality_Gates_Overview]]"
  - "[[Escalation_Triggers]"
used_by:
  - "[Vault_Maintenance_Guide]]"
  - "[[30_Day_Enablement_Plan]"
---

# Top Risks and Mitigations

## Risk Assessment Matrix

| Risk | Likelihood | Impact | Priority | Status |
|------|------------|--------|----------|--------|
| Cost Overrun | Medium | High | P1 | Monitored |
| Gate Bypass | Low | Critical | P0 | Controlled |
| Context Loss | Medium | High | P1 | Monitored |
| Model Drift | Medium | Medium | P2 | Monitored |
| Security Leak | Low | Critical | P0 | Controlled |
| Determinism Loss | Medium | High | P1 | Monitored |
| Autonomy Escalation | Medium | Medium | P2 | Monitored |
| Vendor Lock-in | Low | Medium | P3 | Accepted |

---

## P0: Critical Risks

### R1: Unauthorized Gate Bypass

**Description**: Human or system bypasses quality gates, shipping untested code.

**Impact**: Production bugs, player frustration, reputation damage.

**Detection**:
- Git hooks verify gate status on merge
- CI blocks merges without gate passes
- Audit log tracks all gate overrides

**Mitigation**:
1. **Technical**: Git hooks enforce gate requirements
2. **Process**: Override requires 2-person approval
3. **Monitoring**: Daily audit of all overrides
4. **Recovery**: Automatic rollback on detection

**Enforcement Layer**: [[Security_Secret_Scanning_Gate]], [[Release_Certification_Checklist]]

---

### R2: API Key / Secret Exposure

**Description**: Sensitive credentials leaked in code, logs, or artifacts.

**Impact**: Unauthorized access, data breach, financial loss.

**Detection**:
- [[Security_Secret_Scanning_Gate]] runs on every commit
- Pre-commit hooks scan for patterns
- CI scans build artifacts

**Mitigation**:
1. **Prevention**: Secrets only in environment variables
2. **Detection**: Automated scanning in 3 layers
3. **Response**: Immediate rotation if detected
4. **Training**: Quarterly security review

**Enforcement Layer**: [[Security_Secret_Scanning_Gate]], [[Known_Risk_Acceptance_Checklist]]

---

## P1: High Risks

### R3: Runaway Cost (Token/Compute)

**Description**: Uncontrolled API usage or compute consumption exceeds budget.

**Impact**: Financial loss, project cancellation.

**Detection**:
- Real-time cost tracking per ticket
- Alerts at 50%, 80%, 100% of budget
- Daily cost reports

**Mitigation**:
1. **Hard Limits**: Automatic shutdown at budget cap
2. **Soft Limits**: Alerts and require approval
3. **Routing**: Local-first model selection
4. **Caching**: Aggressive result caching

**Enforcement Layer**: [[Token_Burn_Controls]], [[Compute_Burn_Controls]], [[Economic_Model_Overview]]

**Recovery**:
```bash
# Emergency cost stop
openclaw pause --reason "budget-exceeded"

# Review costs
openclaw costs --analysis

# Adjust routing
openclaw config --downgrade-models
```

---

### R4: Context Loss / State Corruption

**Description**: OpenClaw loses track of work state, causing duplicate or lost work.

**Impact**: Rework, inconsistencies, lost progress.

**Detection**:
- Checksum validation on state files
- Periodic state consistency checks
- Mismatch alerts

**Mitigation**:
1. **Checkpoints**: Save state every 5 minutes
2. **Versioning**: All state in git
3. **Validation**: Checksums on all state
4. **Recovery**: Restore from last checkpoint

**Enforcement Layer**: [[Rollback_Protocol]], [[Quarantine_Branch_Protocol]]

---

### R5: Non-Deterministic Builds

**Description**: Same code produces different outputs on different runs.

**Impact**: Unreproducible bugs, failed certifications.

**Detection**:
- [[Determinism_Replay_Gate]] runs nightly
- Build hash comparison
- Replay testing

**Mitigation**:
1. **Version Lock**: All dependencies pinned
2. **Fixed Timestep**: Deterministic simulation
3. **Seeded RNG**: All randomness seeded
4. **Clean Builds**: No incremental cache issues

**Enforcement Layer**: [[Determinism_Replay_Gate]], [[Godot_Deterministic_Fixed_Timestep]], [[Unity_Determinism_Strategy]]

---

### R6: Regression Cascade

**Description**: Fix introduces new bugs faster than they can be caught.

**Impact**: Unstable codebase, release delays.

**Detection**:
- [[Regression_Harness_Spec]] runs continuously
- Nightly full test suite
- Metric trending

**Mitigation**:
1. **Comprehensive Tests**: High coverage requirement
2. **Fast Feedback**: Gates run in < 5 min
3. **Bisect**: Automatic regression finder
4. **Quarantine**: Isolate problematic changes

**Enforcement Layer**: [[Regression_Harness_Spec]], [[Unit_Tests_Gate]], [[Headless_Match_Batch_Gate]]

---

## P2: Medium Risks

### R7: Excessive Autonomy Escalation

**Description**: System escalates autonomy too quickly, reducing human oversight.

**Impact**: Poor decisions without human catch.

**Detection**:
- Autonomy level tracking
- Escalation rate monitoring
- Decision quality metrics

**Mitigation**:
1. **Gradual**: Minimum 10 tickets per level
2. **Validation**: Score must exceed threshold
3. **Override**: Human can force any level
4. **Review**: Weekly autonomy audit

**Enforcement Layer**: [[Autonomy_Score_Rubric]], [[Autonomy_Upgrade_Path]], [[Decision_Making_Protocols]]

---

### R8: Model Capability Degradation

**Description**: AI model quality degrades over time (updates, drift).

**Impact**: Lower code quality, more rework.

**Detection**:
- Confidence score tracking
- Gate pass rate trends
- Rework rate monitoring

**Mitigation**:
1. **Version Pin**: Models pinned to versions
2. **Test Suite**: Validation on model changes
3. **Fallback**: Multiple model options
4. **Monitoring**: Quality metrics dashboard

**Enforcement Layer**: [[Model_Catalog_Overview]], [[Calibration_Protocol]]

---

## P3: Low Risks

### R9: Vendor Lock-in

**Description**: Over-dependence on specific AI vendors or tools.

**Impact**: Price increases, service discontinuation.

**Mitigation**:
1. **Abstraction**: Vendor-agnostic interfaces
2. **Local Options**: Always have local fallback
3. **Multi-vendor**: Support multiple APIs
4. **Exit Plan**: Documented migration path

**Acceptance**: Risk accepted due to mitigation coverage.

---

## Risk Monitoring Dashboard

```yaml
risk_dashboard:
  refresh_interval_minutes: 5
  
  metrics:
    cost_burn_rate:
      warning: 80% of daily budget
      critical: 100% of daily budget
      
    gate_pass_rate:
      warning: < 85%
      critical: < 70%
      
    autonomy_escalation_rate:
      warning: > 30% of tickets
      critical: > 50% of tickets
      
    context_loss_incidents:
      warning: > 1 per day
      critical: > 3 per day
      
    secret_scan_alerts:
      warning: any detection
      critical: confirmed leak
      
    determinism_failures:
      warning: > 1 per week
      critical: > 3 per week
```

## Emergency Procedures

### Cost Emergency
```bash
# Immediate pause
openclaw pause --emergency

# Assess situation
openclaw costs --detailed

# Adjust limits
openclaw config --max-cost 0

# Resume when safe
openclaw resume --with-approval
```

### Security Emergency
```bash
# Immediate lockdown
openclaw lockdown --security

# Rotate all keys
./scripts/rotate-all-keys.sh

# Audit all changes
git log --since="24 hours ago" --name-only

# Resume with enhanced scanning
openclaw resume --security-mode strict
```

### Quality Emergency
```bash
# Halt all merges
openclaw pause --quality

# Run full regression
openclaw gates --full-suite

# Quarantine recent changes
openclaw quarantine --since="24 hours ago"

# Fix and verify
# (Manual intervention required)
```

## Risk Review Schedule

| Review | Frequency | Owner | Output |
|--------|-----------|-------|--------|
| Daily metrics | Daily | OpenClaw | Dashboard update |
| Weekly risk review | Weekly | Tech Lead | Risk report |
| Monthly deep-dive | Monthly | Team | Risk assessment |
| Quarterly audit | Quarterly | External | Audit report |

---

*This risk register is living documentation. Update as new risks emerge or mitigations evolve.*
