---
title: Security Secret Scanning Gate
type: gate
layer: enforcement
status: active
tags:
  - security
  - secrets
  - scanning
  - gate
  - api-keys
  - tokens
  - credentials
depends_on:
  - "[Quality_Gates_Overview]]"
  - "[[Build_Gate]"
used_by:
  - "[Release_Certification_Checklist]]"
  - "[[Lint_Static_Analysis_Gate]"
---

# Security Secret Scanning Gate

## Purpose

The Security Secret Scanning Gate prevents sensitive credentials (API keys, tokens, passwords) from being committed to the repository. It scans all changes for patterns that match known secret formats and blocks commits containing potential secrets.

## Tool/Script

**Primary**: `scripts/gates/secret_scan_gate.py`
**Pre-commit Hook**: `.git/hooks/pre-commit`
**CI Scanner**: `truffleHog` or `git-secrets`
**GitHub Integration**: GitHub secret scanning

## Local Run

```bash
# Scan working directory
python scripts/gates/secret_scan_gate.py

# Scan specific file
python scripts/gates/secret_scan_gate.py --file Assets/Scripts/Network/Config.cs

# Scan commit range
python scripts/gates/secret_scan_gate.py --since HEAD~5

# Update secret patterns
python scripts/gates/secret_scan_gate.py --update-patterns

# Install pre-commit hook
python scripts/gates/secret_scan_gate.py --install-hook
```

## CI Run

```yaml
# .github/workflows/secret-scan-gate.yml
name: Security Secret Scanning Gate
on: [push, pull_request]
jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Secret Scan Gate
        run: python scripts/gates/secret_scan_gate.py --since origin/main
      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: main
          head: HEAD
```

## Pass/Fail Thresholds

### Pass Criteria (ALL must be true)

| Check | Threshold | Measurement |
|-------|-----------|-------------|
| No Secrets in Commit | 0 | Secrets detected in changes |
| No High Entropy Strings | 0 | Suspicious high-entropy strings |
| No Private Keys | 0 | RSA/EC private key patterns |
| No AWS Keys | 0 | AWS access key patterns |
| No Database URLs | 0 | Connection strings with credentials |

### Fail Criteria (ANY triggers failure)

| Check | Threshold | Failure Mode |
|-------|-----------|--------------|
| Secret Detected | >= 1 | HARD FAIL - immediate block |
| High Entropy String | >= 1 | SOFT FAIL - manual review |
| Private Key | >= 1 | HARD FAIL - security risk |
| Known Pattern Match | >= 1 | HARD FAIL - credential leak |

## Secret Patterns Detected

| Pattern | Example | Severity |
|---------|---------|----------|
| AWS Access Key | `AKIAIOSFODNN7EXAMPLE` | Critical |
| AWS Secret Key | Long base64 string | Critical |
| GitHub Token | `ghp_xxxxxxxxxxxx` | Critical |
| Unity Cloud Token | `uc_xxxxxxxxxxxx` | Critical |
| Database Password | `password=secret123` | Critical |
| Private Key | `-----BEGIN RSA PRIVATE KEY-----` | Critical |
| API Key Generic | `api_key: xxxxxxxx` | High |
| Bearer Token | `Bearer eyJ...` | High |
| Connection String | `Server=...;Password=...` | High |

## Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Secret scanning pre-commit hook

STAGED_FILES=$(git diff --cached --name-only)

if [ -n "$STAGED_FILES" ]; then
    echo "Scanning for secrets..."
    python scripts/gates/secret_scan_gate.py --files $STAGED_FILES
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Potential secrets detected in commit!"
        echo "Remove secrets and try again."
        exit 1
    fi
fi

exit 0
```

## Failure Modes

### Secret Detected in Commit

**Symptoms**: Scanner reports secret pattern match
**Immediate Action**: HARD FAIL - commit blocked

### High Entropy String

**Symptoms**: String with high randomness detected
**Analysis Required**: May be false positive (hash, GUID)

### Private Key Detected

**Symptoms**: Private key pattern found
**Immediate Action**: HARD FAIL - key must be revoked

## Remediation Steps

### Remove Committed Secret

**WARNING**: Secret is already in git history!

1. **Revoke the secret immediately** at provider
2. Do NOT just delete the line - it's in history
3. Use `git filter-repo` or BFG to remove from history:

```bash
# Install git-filter-repo
pip install git-filter-repo

# Remove secret from all history
git filter-repo --replace-text <(echo 'SECRET_TO_REMOVE==>REPLACEMENT')

# Force push (coordinate with team!)
git push origin --force --all
```

4. Rotate all affected credentials
5. Audit access logs for compromised secret

### Use Secrets Manager

```csharp
// ❌ WRONG - hardcoded secret
string apiKey = "sk_live_xxxxxxxxxxxx";

// ✅ CORRECT - use secrets manager
string apiKey = SecretsManager.Get("payment_api_key");
```

### Environment Variables for Local Dev

```csharp
// Local development only - never commit
string apiKey = Environment.GetEnvironmentVariable("GAME_API_KEY");
if (string.IsNullOrEmpty(apiKey))
{
    Debug.LogError("GAME_API_KEY environment variable not set");
}
```

### Unity Cloud Secrets

```csharp
// Use Unity Cloud Build environment variables
string apiKey = CloudBuildConfig.GetEnvironmentVariable("API_KEY");
```

## False Positive Handling

```csharp
// If a string is flagged but is not a secret:
// Add comment to suppress (use sparingly!)

// secret-scan:ignore (This is a public test key)
const string TestApiKey = "test_key_12345";
```

## Secret Scanner Configuration

```yaml
# config/secret_scanner.yml
patterns:
  - name: AWS Access Key
    regex: 'AKIA[0-9A-Z]{16}'
    severity: critical
  
  - name: GitHub Token
    regex: 'gh[pousr]_[A-Za-z0-9_]{36}'
    severity: critical
  
  - name: Unity Cloud Token
    regex: 'uc_[A-Za-z0-9]{32}'
    severity: critical

exclude_paths:
  - '*.md'
  - 'Documentation/**'
  - 'Tests/**'
  - '**/Test*.cs'

exclude_patterns:
  - 'example_*'
  - 'test_*'
  - 'dummy_*'
```

## Integration with Other Gates

- **Runs with**: [[Lint_Static_Analysis_Gate]]
- **Blocks**: All downstream gates if secret detected
- **Required by**: [[Release_Certification_Checklist]]
- **Alerts**: Security team on detection

## Incident Response

If a secret is committed:

1. **IMMEDIATE**: Revoke secret at provider
2. **Within 1 hour**: Remove from git history
3. **Within 4 hours**: Rotate all related credentials
4. **Within 24 hours**: Complete access audit
5. **Document**: Incident in security log

## Known Issues

| Issue | Workaround | Ticket |
|-------|------------|--------|
| False positives on GUIDs | Add to exclude_patterns | SEC-123 |
| Binary files not scanned | Scan decompiled text | SEC-456 |
| History scan slow on large repos | Incremental scanning | SEC-789 |
