---
title: Autonomous_Execution_Loop
type: system
layer: execution
status: active
tags:
  - autonomy
  - execution
  - loop
depends_on:
  - "[OpenClaw_Ingestion_Rules]"
used_by: []
---

# Autonomous Execution Loop

## Purpose

Define a closed-loop execution system so OpenClaw can complete tasks without human intervention.

## Execution Steps

1. Ticket Intake
   - Validate ticket format
   - Extract allowlisted directories/files
   - Extract required gates

2. Context Assembly
   - Build context pack per [[OpenClaw_Ingestion_Rules]]

3. Model Selection
   - Use [[Model_Routing_Decision_Tree]]

4. Prompt Template Selection
   - Select appropriate template from Prompt Library

5. Implementation
   - Generate patch
   - Normalize output

6. Gate Execution
   - Run dev_gate script
   - Run required test suites

7. Repair Loop
   - If gate fails:
       - Analyze failure
       - Attempt fix
       - Re-run gate
   - Max retries: 3

8. Completion
   - If all gates pass:
       - Generate diff summary
       - Notify human: “Task complete.”

9. Escalation
   - If retries exhausted:
       - Generate structured escalation report
       - Enter Safe Mode

## Failure Modes

- Infinite retry loop
- Gate bypass
- Cross-directory drift

## Enforcement

- Retry counter hard-limited
- Gate must pass before completion allowed
- Escalation mandatory after retry ceiling