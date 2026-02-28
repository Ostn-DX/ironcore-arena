---
title: Merge and Release Workflow
type: pipeline
layer: execution
status: active
tags:
  - merge
  - release
  - workflow
  - integration
  - deployment
depends_on:
  - "[Review_Gate_Workflow]]"
  - "[[Patch_Protocol]"
used_by:
  - "[OpenClaw_Daily_Work_Loop]"
---

# Merge and Release Workflow

## Purpose

The Merge and Release Workflow defines how approved changes are integrated into the main codebase and prepared for release. It ensures safe, traceable integration with proper versioning and documentation.

## Merge Workflow

### Pre-Merge Checklist

```yaml
PreMergeChecklist:
  requirements:
    - review_approved: true
    - all_gates_passed: true
    - no_conflicts: true
    - up_to_date_with_base: true
    - tests_pass_on_branch: true
```

### Merge Execution

```python
async def execute_merge(
    merge_request: MergeRequest
) -> MergeResult:
    """Execute merge of approved changes."""
    
    # 1. Pre-merge validation
    validation = await validate_merge_request(merge_request)
    if not validation.valid:
        return MergeResult(
            status="rejected",
            errors=validation.errors
        )
    
    # 2. Create merge commit
    try:
        merge_commit = await create_merge_commit(
            source_branch=merge_request.branch,
            target_branch=merge_request.target,
            message=generate_merge_message(merge_request),
            strategy=merge_request.strategy
        )
    except MergeConflictError as e:
        return MergeResult(
            status="conflict",
            error=str(e)
        )
    
    # 3. Post-merge validation
    post_validation = await validate_post_merge(merge_commit)
    if not post_validation.valid:
        # Rollback merge
        await rollback_merge(merge_commit)
        return MergeResult(
            status="post_validation_failed",
            errors=post_validation.errors
        )
    
    # 4. Update ticket status
    await update_ticket_status(
        ticket_id=merge_request.ticket_id,
        status="merged"
    )
    
    # 5. Generate merge notification
    await notify_merge_complete(merge_request, merge_commit)
    
    return MergeResult(
        status="success",
        commit_hash=merge_commit.hash,
        merged_at=now()
    )
```

### Merge Strategies

```python
class MergeStrategies:
    @staticmethod
    async def squash_merge(
        source: str,
        target: str,
        message: str
    ) -> Commit:
        """Squash all commits into single commit."""
        # Combine all changes into one commit
        return await git.squash_merge(source, target, message)
    
    @staticmethod
    async def rebase_merge(
        source: str,
        target: str
    ) -> Commit:
        """Rebase source onto target, then fast-forward."""
        # Replay commits on top of target
        return await git.rebase_merge(source, target)
    
    @staticmethod
    async def merge_commit(
        source: str,
        target: str,
        message: str
    ) -> Commit:
        """Create merge commit preserving history."""
        # Standard merge with merge commit
        return await git.merge_commit(source, target, message)
```

### Strategy Selection

```python
def select_merge_strategy(ticket: Ticket) -> str:
    """Select appropriate merge strategy."""
    
    # Feature work: squash for clean history
    if ticket.type == "feature":
        return "squash"
    
    # Bug fixes: preserve commit history for traceability
    if ticket.type == "bugfix":
        return "merge_commit"
    
    # Refactors: rebase for linear history
    if ticket.type == "refactor":
        return "rebase"
    
    # Default: squash
    return "squash"
```

## Release Workflow

### Version Management

```python
class VersionManager:
    async def bump_version(
        self,
        bump_type: str,  # major, minor, patch
        changes: [Change]
    ) -> Version:
        """Bump version based on changes."""
        
        current = await self.get_current_version()
        
        if bump_type == "major":
            return Version(current.major + 1, 0, 0)
        
        elif bump_type == "minor":
            return Version(current.major, current.minor + 1, 0)
        
        elif bump_type == "patch":
            return Version(
                current.major,
                current.minor,
                current.patch + 1
            )
        
        # Auto-detect from changes
        return await self.auto_detect_bump(current, changes)
```

### Auto Version Bump

```python
async def auto_detect_bump(
    current: Version,
    changes: [Change]
) -> Version:
    """Auto-detect version bump from changes."""
    
    has_breaking = any(c.is_breaking for c in changes)
    has_features = any(c.type == "feature" for c in changes)
    
    if has_breaking:
        return Version(current.major + 1, 0, 0)
    
    if has_features:
        return Version(current.major, current.minor + 1, 0)
    
    return Version(
        current.major,
        current.minor,
        current.patch + 1
    )
```

### Release Creation

```python
async def create_release(
    version: Version,
    changes: [Change]
) -> Release:
    """Create new release."""
    
    # 1. Generate changelog
    changelog = await generate_changelog(version, changes)
    
    # 2. Create release branch
    release_branch = f"release/v{version}"
    await create_branch("main", release_branch)
    
    # 3. Update version files
    await update_version_files(version)
    
    # 4. Update changelog
    await update_changelog_file(changelog)
    
    # 5. Create release commit
    await commit_changes(
        message=f"Release v{version}",
        files=["CHANGELOG.md", "VERSION", "Cargo.toml"]
    )
    
    # 6. Create git tag
    tag = f"v{version}"
    await create_tag(tag, release_branch)
    
    # 7. Build release artifacts
    artifacts = await build_release_artifacts(version)
    
    # 8. Create GitHub release
    release = await create_github_release(
        tag=tag,
        changelog=changelog,
        artifacts=artifacts
    )
    
    return Release(
        version=version,
        tag=tag,
        changelog=changelog,
        artifacts=artifacts
    )
```

### Changelog Generation

```python
async def generate_changelog(
    version: Version,
    changes: [Change]
) -> Changelog:
    """Generate changelog for release."""
    
    sections = {
        "features": [],
        "bugfixes": [],
        "refactors": [],
        "docs": [],
        "other": []
    }
    
    for change in changes:
        entry = ChangelogEntry(
            ticket_id=change.ticket_id,
            description=change.description,
            author=change.author
        )
        
        if change.type == "feature":
            sections["features"].append(entry)
        elif change.type == "bugfix":
            sections["bugfixes"].append(entry)
        elif change.type == "refactor":
            sections["refactors"].append(entry)
        elif change.type == "docs":
            sections["docs"].append(entry)
        else:
            sections["other"].append(entry)
    
    return Changelog(
        version=version,
        date=date.today(),
        sections=sections
    )
```

## Post-Merge Validation

### Smoke Tests

```python
async def run_post_merge_smoke_tests() -> TestResult:
    """Run critical smoke tests after merge."""
    
    tests = [
        "build_check",
        "unit_tests_critical",
        "integration_tests_critical",
        "startup_check"
    ]
    
    results = []
    for test in tests:
        result = await run_test(test)
        results.append(result)
        
        if not result.passed:
            logger.error(f"Smoke test failed: {test}")
            break
    
    return TestResult(
        passed=all(r.passed for r in results),
        results=results
    )
```

### Rollback on Failure

```python
async def handle_post_merge_failure(
    merge_commit: Commit,
    error: Error
):
    """Handle post-merge validation failure."""
    
    logger.critical(f"Post-merge failure: {error}")
    
    # 1. Alert team
    await alert_team(
        severity="critical",
        message=f"Post-merge validation failed: {error}"
    )
    
    # 2. Rollback merge
    await rollback_merge(merge_commit)
    
    # 3. Create incident ticket
    await create_incident_ticket(
        merge_commit=merge_commit,
        error=error
    )
    
    # 4. Notify stakeholders
    await notify_stakeholders(
        event="merge_rollback",
        details={"commit": merge_commit.hash, "error": str(error)}
    )
```

## Release Channels

### Channel Strategy

```yaml
ReleaseChannels:
  development:
    branch: "main"
    auto_deploy: true
    audience: developers
    
  staging:
    branch: "staging"
    auto_deploy: false
    approval: required
    audience: qa
    
  production:
    branch: "production"
    auto_deploy: false
    approval: required
    audience: users
```

### Channel Promotion

```python
async def promote_release(
    version: Version,
    from_channel: str,
    to_channel: str
) -> PromotionResult:
    """Promote release between channels."""
    
    # 1. Verify release exists in source channel
    release = await get_release(version, from_channel)
    if not release:
        raise ReleaseNotFoundError(version, from_channel)
    
    # 2. Run promotion gates
    gate_result = await run_promotion_gates(
        release=release,
        to_channel=to_channel
    )
    
    if not gate_result.passed:
        return PromotionResult(
            status="rejected",
            errors=gate_result.errors
        )
    
    # 3. Deploy to target channel
    deployment = await deploy_to_channel(release, to_channel)
    
    # 4. Verify deployment
    verification = await verify_deployment(deployment)
    
    return PromotionResult(
        status="success",
        deployment=deployment,
        verification=verification
    )
```

## Monitoring

### Release Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Merge Success Rate | % successful merges | > 99% |
| Release Frequency | Releases per week | > 2 |
| Time to Release | Hours from merge to release | < 24 |
| Rollback Rate | % releases rolled back | < 1% |

### Release Dashboard

```yaml
ReleaseDashboard:
  current_version: "1.2.3"
  last_release: "2024-01-15T10:00:00Z"
  
  channels:
    development:
      version: "1.3.0-dev"
      status: healthy
      
    staging:
      version: "1.2.3-rc1"
      status: testing
      
    production:
      version: "1.2.2"
      status: stable
```
