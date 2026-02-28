---
title: Review Gate Workflow
type: pipeline
layer: execution
status: active
tags:
  - review
  - gate
  - workflow
  - validation
  - approval
depends_on:
  - "[Implementation_Workflow]]"
  - "[[Gate_Protocol]"
used_by:
  - "[Merge_Release_Workflow]]"
  - "[[OpenClaw_Daily_Work_Loop]"
---

# Review Gate Workflow

## Purpose

The Review Gate Workflow defines how changes are reviewed—both by automated systems and humans—before being approved for merge. It ensures quality, correctness, and alignment with project standards.

## Review Types

### 1. Automated Review

Performed by Reviewer agent:

```yaml
AutomatedReview:
  checks:
    - static_analysis
    - logic_verification
    - security_scan
    - performance_check
    - style_compliance
```

### 2. Human Review

Required for certain change types:

```yaml
HumanReview:
  triggers:
    - complexity: very_complex
    - files_changed: "> 20"
    - security_related: true
    - api_changes: true
    - database_migration: true
```

## Review Workflow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Submit    │───▶│  Automated  │───▶│   Human     │
│   Changes   │    │   Review    │    │   Review    │
└─────────────┘    └──────┬──────┘    └──────┬──────┘
                          │                    │
                    ┌─────┴─────┐        ┌─────┴─────┐
                    ▼           ▼        ▼           ▼
              ┌─────────┐  ┌────────┐ ┌────────┐ ┌────────┐
              │  Pass   │  │  Fail  │ │  Pass  │ │ Request│
              │ (Auto)  │  │ (Fix)  │ │ (Merge)│ │ Changes│
              └─────────┘  └────────┘ └────────┘ └────────┘
```

## Phase 1: Submission

### Submit for Review

```python
async def submit_for_review(
    ticket: Ticket,
    normalized_output: NormalizedOutput,
    gate_result: GateResult
) -> ReviewSubmission:
    """Submit changes for review."""
    
    # 1. Create review package
    review_package = ReviewPackage(
        ticket=ticket,
        changes=normalized_output,
        gate_result=gate_result,
        submitted_at=now()
    )
    
    # 2. Determine review type
    review_type = determine_review_type(review_package)
    
    # 3. Queue for review
    if review_type == "automated_only":
        await automated_review_queue.submit(review_package)
    else:
        await human_review_queue.submit(review_package)
    
    return ReviewSubmission(
        submission_id=generate_id(),
        review_type=review_type,
        estimated_review_time=estimate_review_time(review_package)
    )
```

### Review Type Determination

```python
def determine_review_type(package: ReviewPackage) -> str:
    """Determine if human review is required."""
    
    changes = package.changes
    
    # Always require human review for:
    if package.ticket.complexity == "very_complex":
        return "human_required"
    
    if len(changes.MODIFICATIONS) > 20:
        return "human_required"
    
    if changes.has_security_changes():
        return "human_required"
    
    if changes.has_api_changes():
        return "human_required"
    
    if changes.has_database_changes():
        return "human_required"
    
    # Auto-approve simple changes
    if package.gate_result.status == "passed":
        if len(changes.MODIFICATIONS) <= 3:
            if not changes.has_new_dependencies():
                return "automated_only"
    
    # Default: human review
    return "human_required"
```

## Phase 2: Automated Review

### Execute Automated Review

```python
async def execute_automated_review(
    package: ReviewPackage
) -> AutomatedReviewResult:
    """Execute automated review checks."""
    
    results = {}
    
    # 1. Static Analysis
    results["static"] = await run_static_analysis(package.changes)
    
    # 2. Logic Verification
    results["logic"] = await verify_logic(package.changes)
    
    # 3. Security Scan
    results["security"] = await security_scan(package.changes)
    
    # 4. Performance Check
    results["performance"] = await performance_check(package.changes)
    
    # 5. Style Compliance
    results["style"] = await style_check(package.changes)
    
    # Aggregate results
    all_passed = all(r.passed for r in results.values())
    
    return AutomatedReviewResult(
        passed=all_passed,
        results=results,
        issues=collect_issues(results)
    )
```

### Static Analysis

```python
async def run_static_analysis(changes: NormalizedOutput) -> CheckResult:
    """Run static analysis on changes."""
    
    issues = []
    
    for file in changes.all_files():
        # Run language-specific linter
        linter_result = await run_linter(file)
        issues.extend(linter_result.issues)
        
        # Check for code smells
        smell_result = await detect_code_smells(file)
        issues.extend(smell_result.issues)
        
        # Check complexity
        complexity = calculate_complexity(file)
        if complexity > COMPLEXITY_THRESHOLD:
            issues.append(Issue(
                type="complexity",
                severity="warning",
                message=f"High complexity: {complexity}"
            ))
    
    return CheckResult(
        passed=len([i for i in issues if i.severity == "error"]) == 0,
        issues=issues
    )
```

### Security Scan

```python
async def security_scan(changes: NormalizedOutput) -> CheckResult:
    """Scan changes for security issues."""
    
    issues = []
    
    for file in changes.all_files():
        content = file.content
        
        # Check for secrets
        secrets = detect_secrets(content)
        issues.extend(secrets)
        
        # Check for SQL injection
        sql_issues = detect_sql_injection(content)
        issues.extend(sql_issues)
        
        # Check for unsafe patterns
        unsafe = detect_unsafe_patterns(content)
        issues.extend(unsafe)
    
    return CheckResult(
        passed=len([i for i in issues if i.severity == "critical"]) == 0,
        issues=issues
    )
```

## Phase 3: Human Review

### Human Review Assignment

```python
async def assign_human_reviewer(package: ReviewPackage) -> Reviewer:
    """Assign appropriate human reviewer."""
    
    # Find reviewers for affected areas
    file_owners = await find_file_owners(package.changes.affected_files())
    
    # Filter by availability
    available = [r for r in file_owners if r.is_available()]
    
    # Sort by expertise match
    ranked = sorted(
        available,
        key=lambda r: calculate_expertise_match(r, package),
        reverse=True
    )
    
    # Assign top reviewer
    reviewer = ranked[0]
    
    # Notify
    await notify_reviewer(reviewer, package)
    
    return reviewer
```

### Review Interface

```yaml
HumanReviewInterface:
  review_package:
    ticket: Ticket
    changes: DiffView
    gate_result: GateResult
    auto_review: AutomatedReviewResult
    
  actions:
    - approve
    - request_changes
    - comment
    - escalate
    
  checklist:
    - "Code is readable and maintainable"
    - "Tests are comprehensive"
    - "No security concerns"
    - "Performance is acceptable"
    - "Documentation is updated"
```

### Review Response Handling

```python
async def handle_review_response(
    review_id: str,
    response: ReviewResponse
) -> ReviewResult:
    """Handle human review response."""
    
    if response.action == "approve":
        # Mark approved
        await mark_approved(review_id, response.reviewer)
        
        return ReviewResult(
            status="approved",
            can_merge=True
        )
    
    elif response.action == "request_changes":
        # Create fix tickets
        for issue in response.issues:
            await create_fix_ticket(
                original_ticket=response.ticket,
                issue=issue
            )
        
        return ReviewResult(
            status="changes_requested",
            can_merge=False,
            issues=response.issues
        )
    
    elif response.action == "escalate":
        # Escalate to senior reviewer
        await escalate_review(review_id, response.reason)
        
        return ReviewResult(
            status="escalated",
            can_merge=False
        )
```

## Review Decision Matrix

| Automated | Human | Decision |
|-----------|-------|----------|
| Pass | Approve | Merge |
| Pass | Request Changes | Fix & Resubmit |
| Fail | - | Auto-fix or Escalate |
| Pass | Escalate | Senior Review |

## Review Metrics

### Tracking

| Metric | Description | Target |
|--------|-------------|--------|
| Review Time | Avg time to complete review | < 4 hours |
| Approval Rate | % approved without changes | > 70% |
| Iterations | Avg iterations per change | < 1.5 |
| Escalation Rate | % escalated to senior | < 10% |

### Review Quality

```python
def calculate_review_quality(reviews: [Review]) -> QualityScore:
    """Calculate quality metrics for reviews."""
    
    # Post-merge defect rate
    defects_found = count_post_merge_defects(reviews)
    
    # Review thoroughness
    thoroughness = avg(len(r.comments) for r in reviews)
    
    # Response time
    response_time = avg(r.completion_time for r in reviews)
    
    return QualityScore(
        defect_rate=defects_found / len(reviews),
        thoroughness=thoroughness,
        response_time=response_time
    )
```

## Integration with Merge

### Approval to Merge

```python
async def transition_to_merge(review_result: ReviewResult):
    """Transition approved changes to merge workflow."""
    
    if review_result.status != "approved":
        raise NotApprovedError()
    
    # Queue for merge
    await merge_queue.submit(
        ticket=review_result.ticket,
        changes=review_result.changes,
        approvals=review_result.approvals
    )
```

## Fast-Track Review

### Auto-Approval Criteria

```python
def can_auto_approve(package: ReviewPackage) -> bool:
    """Determine if changes can be auto-approved."""
    
    # Must pass all gates
    if package.gate_result.status != "passed":
        return False
    
    # Must pass automated review
    auto_review = package.automated_review
    if not auto_review.passed:
        return False
    
    # Small, safe changes only
    changes = package.changes
    
    if len(changes.MODIFICATIONS) > 5:
        return False
    
    if changes.has_security_changes():
        return False
    
    if changes.has_api_changes():
        return False
    
    # Only certain file types
    allowed_extensions = [".md", ".txt", ".yaml", ".json"]
    for file in changes.all_files():
        if not any(file.path.endswith(ext) for ext in allowed_extensions):
            return False
    
    return True
```
