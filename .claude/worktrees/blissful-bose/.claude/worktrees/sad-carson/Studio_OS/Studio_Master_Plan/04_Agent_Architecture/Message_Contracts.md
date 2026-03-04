---
title: Message Contracts
type: system
layer: architecture
status: active
tags:
  - messages
  - contracts
  - api
  - schema
  - communication
depends_on:
  - "[Orchestration_Architecture_Overview]]"
  - "[[Command_Graph_Specification]"
used_by:
  - "[Context_Pack_Builder_Spec]]"
  - "[[Output_Normalizer_Spec]"
---

# Message Contracts

## Purpose

Message Contracts define the standardized formats for all communication between OpenClaw and agents. These contracts ensure type safety, version compatibility, and clear semantics across the orchestration system.

## Design Principles

1. **Schema-First**: All messages have validated schemas
2. **Versioned**: Contracts include version for compatibility
3. **Self-Describing**: Messages include metadata about their content
4. **Fail-Fast**: Invalid messages rejected immediately

## Core Message Types

### 1. Task Invocation Message

Sent from OpenClaw to agent to initiate work:

```yaml
TaskInvocation:
  version: "1.0"
  message_id: uuid
  trace_id: uuid
  timestamp: ISO8601
  
  task:
    task_id: string
    agent_type: AgentType
    ticket: TicketRef
    
  context:
    context_pack: ContextPack
    files: [FileContext]
    dependencies: [DependencyRef]
    
  constraints:
    max_tokens: integer
    timeout_seconds: integer
    allowed_operations: [OperationType]
```

### 2. Task Result Message

Sent from agent to OpenClaw on completion:

```yaml
TaskResult:
  version: "1.0"
  message_id: uuid
  trace_id: uuid
  task_id: string
  timestamp: ISO8601
  
  status: success|failure|partial|timeout
  
  output:
    new_files: [NewFile]
    modifications: [FileModification]
    tests: [TestCase]
    integration_guide: string
    
  metrics:
    duration_ms: integer
    tokens_used: integer
    files_accessed: integer
    
  errors: [ErrorDetail]  # Empty if success
```

### 3. Context Pack Message

Encapsulates all context for an agent:

```yaml
ContextPack:
  version: "1.0"
  pack_id: uuid
  created_at: ISO8601
  
  metadata:
    source_intent: string
    target_agent: AgentType
    file_count: integer
    total_size_bytes: integer
    
  files: [FileContext]
  
  dependencies:
    direct: [FileRef]
    transitive: [FileRef]
    
  tests:
    relevant: [TestRef]
    coverage_target: float
```

### 4. File Context Message

Represents a single file in context:

```yaml
FileContext:
  path: string  # Relative to project root
  content: string
  language: string
  
  metadata:
    size_bytes: integer
    line_count: integer
    last_modified: ISO8601
    
  relevance:
    score: float  # 0.0 - 1.0
    reason: string
    
  extraction:  # If partial content
    start_line: integer
    end_line: integer
    is_partial: boolean
```

### 5. File Modification Message

Represents a change to an existing file:

```yaml
FileModification:
  path: string
  operation: modify|delete|rename
  
  original:
    hash: sha256
    content: string  # For verification
    
  modified:
    hash: sha256
    content: string
    diff: unified_diff
    
  metadata:
    lines_changed: integer
    lines_added: integer
    lines_removed: integer
```

### 6. New File Message

Represents a newly created file:

```yaml
NewFile:
  path: string
  content: string
  language: string
  
  metadata:
    size_bytes: integer
    line_count: integer
    
  purpose:
    description: string
    related_to: [FileRef]  # Related existing files
```

### 7. Test Case Message

Represents a test specification:

```yaml
TestCase:
  name: string
  type: unit|integration|e2e
  
  target:
    file: FileRef
    function: string  # Optional
    
  code:
    content: string
    language: string
    
  expectations:
    assertions: [Assertion]
    coverage_target: float
    
  metadata:
    priority: critical|high|medium|low
    tags: [string]
```

### 8. Error Detail Message

Structured error information:

```yaml
ErrorDetail:
  code: string  # Machine-readable error code
  severity: fatal|error|warning|info
  
  message:
    summary: string
    detail: string
    suggestion: string  # Optional
    
  context:
    file: string  # Optional
    line: integer  # Optional
    snippet: string  # Optional
    
  recovery:
    is_retryable: boolean
    retry_strategy: immediate|backoff|none
```

## Message Validation

### Schema Validation
```python
def validate_message(message: dict, schema: dict) -> ValidationResult:
    validator = jsonschema.Draft7Validator(schema)
    errors = list(validator.iter_errors(message))
    return ValidationResult(valid=len(errors) == 0, errors=errors)
```

### Version Compatibility
```python
def check_version_compatibility(
    message_version: str,
    supported_versions: [str]
) -> bool:
    return message_version in supported_versions
```

### Size Limits
| Message Type | Max Size | Max Files |
|--------------|----------|-----------|
| TaskInvocation | 1MB | 50 |
| TaskResult | 2MB | 100 |
| ContextPack | 5MB | 50 |
| FileContext | 100KB | - |

## Error Codes

### System Errors (SYSxxx)
- `SYS001`: Message parse error
- `SYS002`: Schema validation failed
- `SYS003`: Version mismatch
- `SYS004`: Message too large

### Agent Errors (AGTxxx)
- `AGT001`: Agent initialization failed
- `AGT002`: Context pack invalid
- `AGT003`: Output generation failed
- `AGT004`: Timeout exceeded

### Context Errors (CTXxxx)
- `CTX001`: File not found
- `CTX002`: Dependency resolution failed
- `CTX003`: Context pack too large
- `CTX004`: Circular dependency detected

### Execution Errors (EXCxxx)
- `EXC001`: Operation not allowed
- `EXC002`: File locked by other task
- `EXC003`: Resource exhausted
- `EXC004`: Concurrent modification

## Message Flow Example

```
OpenClaw          Agent
   │                │
   │── TaskInvocation ──▶│
   │                │
   │                │ (process)
   │                │
   │◀── TaskResult ─────│
   │                │
```

## Serialization

### Default Format: JSON
```json
{
  "version": "1.0",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "trace_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "task_id": "task_123",
  "status": "success",
  "output": {
    "new_files": [],
    "modifications": [
      {
        "path": "src/main.rs",
        "operation": "modify",
        "diff": "@@ -1,5 +1,5 @@..."
      }
    ]
  }
}
```

### Alternative: MessagePack
For binary efficiency when needed.

## Security Considerations

1. **Input Sanitization**: All content validated before processing
2. **Path Traversal Prevention**: File paths normalized and validated
3. **Size Limits**: Enforced at message boundary
4. **Audit Logging**: All messages logged with trace ID
