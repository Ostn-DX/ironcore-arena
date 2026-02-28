---
title: Repo-Aware Code Editor
type: agent
layer: execution
status: active
tags:
  - repo-aware
  - cursor
  - windsurf
  - editor
  - ide
  - context
  - indexing
depends_on:
  - "[Model_Catalog_Overview]]"
  - "[[Local_LLM_Coder_Medium]"
used_by:
  - "[Code_Implementation_Routing]]"
  - "[[Refactor_Routing]"
---

# Repo-Aware Code Editor

## Model Class: Cursor/Windsurf-Class Tools

Repo-aware code editors combine traditional IDE functionality with AI capabilities, maintaining persistent codebase understanding through indexing and embeddings. These tools bridge the gap between local LLMs and frontier models by providing superior context management.

### Supported Tools

| Tool | Base IDE | AI Backend | Indexing | Best For |
|------|----------|------------|----------|----------|
| Cursor | VS Code | GPT-4/Claude | Full codebase | Daily development |
| Windsurf | VS Code | Claude/GPT-4 | Full codebase | Complex refactoring |
| GitHub Copilot | VS Code | GPT-4 | Limited | Inline suggestions |
| Codeium | VS Code | Proprietary | File-level | Free alternative |
| Continue.dev | Any | Configurable | Custom | Flexibility |

### Capability Profile

**Strengths:**
- Persistent codebase indexing and embeddings
- Automatic symbol resolution across files
- Natural language codebase queries
- Multi-file edit suggestions
- Chat interface with codebase context
- Inline completions with context awareness
- Integration with version control
- Customizable with local models

**Weaknesses:**
- Requires editor lock-in (usually VS Code)
- Indexing overhead for large codebases
- Privacy concerns with cloud-based indexing
- Cost for premium features
- Limited CI/CD integration
- Not designed for automated workflows

### Optimal Task Types

1. **Exploratory development** with codebase queries
2. **Cross-file refactoring** with symbol tracking
3. **Codebase understanding** for new developers
4. **Natural language to code** translation
5. **Documentation generation** with context
6. **Test generation** with coverage awareness
7. **Bug investigation** with codebase search
8. **API migration** across multiple files

### Context Management

**Indexing Strategy:**
- AST-based symbol extraction
- Embeddings for semantic search
- File relationship graphs
- Import/dependency tracking
- Git history integration

**Query Capabilities:**
- "Find all usages of X"
- "Where is Y defined?"
- "Show me the data flow for Z"
- "What functions call W?"

### Configuration

```json
{
  "cursor": {
    "indexing": {
      "enabled": true,
      "exclude": ["node_modules", "*.min.js", "build/"]
    },
    "ai": {
      "defaultModel": "claude-3.5-sonnet",
      "temperature": 0.0
    },
    "privacy": {
      "codebaseIndexing": "local-only"
    }
  }
}
```

### Cost Profile

| Tier | Cost | Features |
|------|------|----------|
| Free | $0 | Limited requests, basic completions |
| Pro | $20/mo | Unlimited fast requests, GPT-4 |
| Business | $40/user/mo | Team features, admin controls |

### Comparison with Standalone Models

| Feature | Standalone LLM | Repo-Aware Editor |
|---------|----------------|-------------------|
| Context management | Manual | Automatic |
| Symbol resolution | Limited | Excellent |
| Multi-file edits | Difficult | Native |
| Codebase queries | Impossible | Natural language |
| CI/CD integration | Possible | Limited |
| Automation | Scriptable | Manual |
| Cost control | Predictable | Subscription |

### Integration with Studio OS

**Recommended Usage:**
- Developer workstations: Primary IDE
- Automated workflows: Use standalone models
- Complex refactoring: Editor-assisted, then automated
- Code review: Export suggestions to review system

**Workflow Integration:**
```
1. Developer uses editor for exploration
2. Identifies needed changes
3. Exports context to automated system
4. Automated system implements with local models
5. Editor used for final review
```

### Context Budget

- **Indexed files**: Unlimited (with exclusions)
- **Chat context**: 100K-200K tokens
- **Completion context**: 8K-32K tokens
- **Query response time**: 2-10 seconds

### Failure Patterns

1. **Stale Index**: Code changed since last index
   - *Detection*: Missing symbols, wrong locations
   - *Remediation*: Force re-index

2. **Privacy Leak**: Sensitive code sent to cloud
   - *Detection*: Privacy settings audit
   - *Remediation*: Enable local-only mode

3. **Over-Reliance**: Accepting suggestions without review
   - *Detection*: Code review findings
   - *Remediation*: Mandatory review gates

### When to Use

| Scenario | Recommendation |
|----------|----------------|
| Daily development | Yes - primary IDE |
| Automated CI/CD | No - use standalone |
| Security-sensitive | Maybe - check privacy |
| Large refactoring | Yes - with export |
| Quick fixes | Yes - inline |
| Production automation | No - not designed |

### Best Practices

1. Configure privacy settings before first use
2. Set up exclusions for generated files
3. Use explicit commands for complex operations
4. Export significant changes to version control
5. Combine with local models for cost control

### Integration

Used primarily by:
- [[Code_Implementation_Routing]]: Developer workstation tier
- [[Refactor_Routing]]: Complex refactoring exploration
