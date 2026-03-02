# Constraints: TICKET-0003

The external executor MUST NOT modify any file outside the allowlist.
Violations will be rejected by the enforcement pipeline.

---

## Allowed Files (only these may be modified)

- `agents/context/conventions.md`
- `agents/context/invariants.md`
- `agents/context/project_summary.md`

## Hard Boundaries

- `Studio_OS/` — vault is READ-ONLY. Never write to it.
- `project/`   — game engine code. NEVER touch unless explicitly in allowlist.
- Any file not listed above is FORBIDDEN.

## Enforcement

After completion, the following gates will run:
- `require_context_pack` — verifies pack integrity
- `verify_manifest` — SHA-256 hash check on all pack files
- `dev_gate` — vault frontmatter validation

---
_Generated: 2026-02-28T01:22:20Z_