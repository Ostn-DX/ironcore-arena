---
title: Context Pack Builder Specification
type: system
layer: architecture
status: active
tags:
  - context
  - builder
  - files
  - extraction
  - dependencies
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Message_Contracts]"
used_by:
  - "[Agent_Role_Definitions]]"
  - "[[OpenClaw_Daily_Work_Loop]"
---

# Context Pack Builder Specification

## Purpose

The Context Pack Builder constructs focused, relevant context for each agent invocation. It ensures agents receive exactly what they need—no more, no less—while respecting strict resource limits.

## Core Constraints

### Hard Limits
| Limit | Value | Rationale |
|-------|-------|-----------|
| Max Files | 50 | Token budget management |
| Max File Size | 100KB | Prevent context overflow |
| Total Pack Size | 5MB | API constraints |
| Max Dependencies | 20 levels | Avoid infinite recursion |

### Soft Limits
| Limit | Value | Action |
|-------|-------|--------|
| Target Files | 20 | Optimal for most tasks |
| Target Size | 2MB | Balance detail vs. cost |
| Relevance Threshold | 0.5 | Filter low-relevance files |

## Input Specification

```yaml
ContextBuildRequest:
  target_files: [string]  # Primary files of interest
  agent_type: AgentType   # Determines extraction strategy
  
  options:
    include_dependencies: boolean
    include_tests: boolean
    include_docs: boolean
    depth: integer  # Dependency depth
    
  filters:
    file_patterns: [glob]      # Include patterns
    exclude_patterns: [glob]   # Exclude patterns
    languages: [string]        # Language filter
```

## Extraction Strategies

### 1. Dependency-Based Extraction

For code generation tasks:

```python
def extract_dependencies(file_path, depth=3):
    """Extract files that target file depends on."""
    files = set()
    queue = [(file_path, 0)]
    
    while queue:
        current, current_depth = queue.pop(0)
        if current_depth > depth:
            continue
            
        files.add(current)
        deps = get_imports(current)
        
        for dep in deps:
            if dep not in files:
                queue.append((dep, current_depth + 1))
    
    return files
```

### 2. Relevance Scoring

Calculate relevance for each file:

```python
def score_relevance(file_path, target_files):
    score = 0.0
    
    # Direct dependency bonus
    if is_direct_dependency(file_path, target_files):
        score += 0.4
    
    # Shared imports bonus
    shared = count_shared_imports(file_path, target_files)
    score += min(shared * 0.1, 0.3)
    
    # Same directory bonus
    if same_directory(file_path, target_files):
        score += 0.1
    
    # Naming similarity
    if naming_similarity(file_path, target_files) > 0.7:
        score += 0.1
    
    # Recent modification (for bug fixes)
    if recently_modified(file_path, hours=24):
        score += 0.1
    
    return min(score, 1.0)
```

### 3. Smart Truncation

For files exceeding size limits:

```python
def smart_truncate(file_path, max_size=100000):
    """Extract most relevant sections of large files."""
    content = read_file(file_path)
    
    if len(content) <= max_size:
        return content
    
    # Extract:
    # 1. Imports/headers (always include)
    imports = extract_imports(content)
    
    # 2. Public API (functions, types)
    public_api = extract_public_api(content)
    
    # 3. Relevant implementation sections
    relevant = extract_relevant_sections(content, target_keywords)
    
    # Combine with markers
    result = f"""{imports}

# ... [truncated: {len(content) - max_size} bytes] ...

{public_api}

# ... [truncated] ...

{relevant}
"""
    return result
```

## File Allowlists

### Per-Agent Allowlists

```yaml
allowlists:
  CodeGenerator:
    include:
      - "src/**/*.rs"
      - "src/**/*.ts"
      - "Cargo.toml"
      - "package.json"
    exclude:
      - "**/test*"
      - "**/target/**"
      - "**/node_modules/**"
      
  TestWriter:
    include:
      - "src/**/*.rs"
      - "tests/**/*.rs"
      - "Cargo.toml"
    exclude:
      - "**/target/**"
      
  DocGenerator:
    include:
      - "src/**/*.rs"
      - "docs/**/*.md"
      - "README.md"
    exclude:
      - "**/target/**"
```

## Context Pack Structure

```yaml
ContextPack:
  metadata:
    pack_id: uuid
    created_at: ISO8601
    builder_version: "1.0"
    
  summary:
    total_files: integer
    total_size_bytes: integer
    languages: [string]
    
  primary_files:  # Files the agent should focus on
    - path: string
      relevance: float
      reason: string
      content: string
      
  supporting_files:  # Files for reference
    - path: string
      relevance: float
      content: string
      
  dependencies:
    direct: [FileRef]
    transitive: [FileRef]
    
  tests:
    relevant: [TestRef]
    coverage: CoverageInfo
    
  documentation:
    api_docs: [DocRef]
    examples: [ExampleRef]
```

## Building Algorithm

```python
def build_context_pack(request: ContextBuildRequest) -> ContextPack:
    # 1. Collect candidate files
    candidates = collect_files(
        patterns=request.options.file_patterns,
        exclude=request.options.exclude_patterns
    )
    
    # 2. Score relevance
    scored = [(f, score_relevance(f, request.target_files)) 
              for f in candidates]
    scored.sort(key=lambda x: x[1], reverse=True)
    
    # 3. Select top files within limits
    selected = []
    total_size = 0
    
    for file_path, score in scored:
        if len(selected) >= 50:
            break
            
        file_size = get_size(file_path)
        if total_size + file_size > 5_000_000:
            # Try truncation
            truncated = smart_truncate(file_path)
            if total_size + len(truncated) <= 5_000_000:
                selected.append((file_path, score, truncated))
                total_size += len(truncated)
        else:
            selected.append((file_path, score, read_file(file_path)))
            total_size += file_size
    
    # 4. Build dependency graph
    dependencies = build_dependency_graph([f[0] for f in selected])
    
    # 5. Assemble pack
    return ContextPack(
        primary_files=[f for f in selected if f[1] > 0.7],
        supporting_files=[f for f in selected if f[1] <= 0.7],
        dependencies=dependencies
    )
```

## Caching Strategy

### Cache Levels

1. **File Cache**: Individual file contents
2. **Dependency Cache**: Resolved dependency graphs
3. **Pack Cache**: Complete context packs

### Cache Invalidation

```python
def should_invalidate_cache(file_path, cache_entry):
    """Check if cached context is stale."""
    current_mtime = get_mtime(file_path)
    return current_mtime > cache_entry.mtime
```

## Performance Optimization

### Incremental Building
- Only rebuild changed portions
- Reuse unchanged file contexts
- Update dependency graph incrementally

### Parallel Extraction
- Read files in parallel
- Compute relevance concurrently
- Resolve dependencies asynchronously

### Pre-warming
- Build context packs for active files
- Cache likely-needed dependencies
- Predict next tasks from backlog

## Failure Modes

| Failure | Cause | Resolution |
|---------|-------|------------|
| File Not Found | Deleted/moved | Skip and log |
| Permission Denied | Access rights | Skip and warn |
| Circular Dependency | Import cycle | Break at depth limit |
| Pack Too Large | Too many files | Truncate lowest relevance |
| Parse Error | Invalid syntax | Include raw content |

## Monitoring

### Metrics
- Build time per pack
- Cache hit rate
- Average pack size
- Files per pack distribution

### Alerts
- Build time > 30 seconds
- Cache hit rate < 50%
- Pack size > 4MB (warning)
