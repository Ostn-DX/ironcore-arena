---
title: Glossary
type: system
layer: architecture
status: active
tags:
  - glossary
  - definitions
  - terminology
  - reference
depends_on:
  - "[System_Map]"
used_by:
  - "[Quickstart_OpenClaw]]"
  - "[[How_to_Run_OpenClaw_With_This_Vault]"
---

# Glossary

## A

**Agent** - An AI-powered component that performs complex tasks. Agents have specialized roles (CodeGen, Asset, Test, Build, Review) and operate within the OpenClaw orchestration system. See [[Agent_Role_Definitions]].

**Autonomy Level** - The degree of independence granted to OpenClaw for task execution. Levels range from L0 (Manual) to L5 (Full Autonomy). See [[Autonomy_Ladder_L0_L5]].

**Autonomy Score** - A numerical rating (0-100) that determines the appropriate autonomy level for a task based on complexity, risk, and historical success. See [[Autonomy_Score_Rubric]].

**Acceptance Criteria** - Specific, testable conditions that must be met for a ticket to be considered complete. Written in the ticket's YAML frontmatter.

## B

**Backlog** - The queue of pending, in-progress, and blocked tickets awaiting execution by OpenClaw.

**Build Gate** - The first quality gate that verifies code compiles without errors. See [[Build_Gate]].

**Burn Rate** - The rate at which budget (tokens, compute, money) is consumed. Monitored to prevent overruns. See [[Token_Burn_Controls]], [[Compute_Burn_Controls]].

## C

**Checkpoint** - A saved state of work that can be restored in case of failure. Used for recovery and rollback. See [[Rollback_Protocol]].

**Command Graph** - The directed graph that defines agent invocation sequences, dependencies, and execution order. See [[Command_Graph_Specification]].

**Confidence Score** - A rating (0.0-1.0) indicating an AI model's certainty in its output. Used to determine escalation needs. See [[Task_Routing_Overview]].

**Context Pack** - A curated set of files and information sent to an agent for a specific task. Limited to 50 files, 100KB each. See [[Context_Pack_Builder_Spec]].

**Cost-First** - The design principle that prioritizes minimizing expenses through local execution, caching, and efficient routing.

## D

**Decision Protocol** - Rules governing when OpenClaw can make decisions independently versus requiring human approval. See [[Decision_Making_Protocols]].

**Dependency Graph** - The network of relationships between notes, tickets, and code components showing what depends on what.

**Determinism** - The property of producing identical outputs given identical inputs. Critical for reproducible builds. See [[Determinism_Replay_Gate]].

**Drift** - The gradual deviation of system behavior from specified norms over time. Monitored and corrected. See [[Vault_Maintenance_Guide]].

## E

**Escalation** - The process of transferring control from OpenClaw to a human when autonomy limits are exceeded or failures occur. See [[Escalation_Triggers]].

**Execution Engine** - The component of OpenClaw that runs agents and tools to complete planned work. See [[OpenClaw_Core_System]].

**Economic Model** - The framework for tracking, controlling, and optimizing costs across the Studio OS. See [[Economic_Model_Overview]].

## F

**Fail Fast** - The principle that errors should be detected and reported as early as possible in the pipeline.

**Frontier Model** - A high-capability paid API model (GPT-4, Claude, etc.) used for complex reasoning tasks. See [[Frontier_Reasoning_Model]].

## G

**Gate** - A mandatory quality checkpoint with explicit pass/fail criteria. Gates block progression on failure. See [[Quality_Gates_Overview]].

**Gate Protocol** - The standardized process for executing gates and handling results. See [[Gate_Protocol]].

**GDScript** - Godot's scripting language. See [[Godot_GDScript_Style_Guide]].

## H

**Headless Mode** - Running the game engine without UI for automated testing. See [[Godot_Headless_Sim_Runner_Spec]].

**Human-in-the-Loop** - A workflow design that keeps humans involved at critical decision points while automating routine work.

## I

**Intent** - A human's high-level goal or requirement, expressed in natural language and captured in Obsidian.

**Intent-to-Release Pipeline** - The complete flow from human intent through tickets, code, gates, to shipped build. See [[Intent_to_Release_Pipeline]].

## L

**L0-L5** - The six autonomy levels: Manual (L0), Assisted (L1), Supervised (L2), Conditional (L3), High (L4), Full (L5). See [[Autonomy_Ladder_L0_L5]].

**Lint Gate** - Static analysis gate checking code style, patterns, and potential issues. See [[Lint_Static_Analysis_Gate]].

**Local-First** - The principle of defaulting to local execution and models before considering paid APIs.

## M

**Master Index** - The collection of navigation and overview notes in `00_Master_Index/`.

**Merge Gate** - Final validation before merging code to main branch.

**Message Contract** - Standardized format for communication between agents. See [[Message_Contracts]].

**Model Catalog** - The registry of available AI models with capabilities, costs, and selection rules. See [[Model_Catalog_Overview]].

## N

**Normalized Output** - Standardized format for agent results including files, modifications, tests, and integration guides. See [[Output_Normalizer_Spec]].

## O

**OpenClaw** - The autonomous build and execution engine at the heart of the Studio OS. See [[OpenClaw_Core_System]].

**Obsidian** - The knowledge management tool used as the human interface to the Studio OS.

**Orphan Note** - A note with no inbound or outbound links. Forbidden by vault rules.

## P

**Parser** - The OpenClaw component that interprets tickets and intent into executable plans. See [[OpenClaw_Core_System]].

**Performance Gate** - Validates FPS, memory usage, and load time budgets. See [[Performance_Gate]].

**Performance Budget** - Pre-defined limits on resource consumption (FPS, memory, CPU). See [[Godot_Performance_Budgets]].

**Postmortem** - Structured analysis of failures to prevent recurrence. See [[Postmortem_Process]].

**Progressive Escalation** - Starting with cheaper models and escalating only when necessary. See [[Task_Routing_Overview]].

## Q

**Quality Gates Overview** - The philosophy and architecture of the gate system. See [[Quality_Gates_Overview]].

**Quarantine Branch** - Isolated branch for unstable changes requiring review before merge. See [[Quarantine_Branch_Protocol]].

## R

**Regression** - The reintroduction of previously fixed bugs. Prevented by regression harness. See [[Regression_Harness_Spec]].

**Remediation** - The process of fixing issues identified by failed gates.

**Retry Policy** - Rules for automatic retry of failed tasks with backoff. See [[Retry_Policy_Specification]].

**Risk Acceptance** - Documented approval to bypass a gate in exceptional circumstances. See [[Known_Risk_Acceptance_Checklist]].

**Rollback** - Reverting to a previous known-good state. See [[Rollback_Protocol]].

**Routing** - The process of selecting the appropriate model/agent for a task. See [[Task_Routing_Overview]].

## S

**Safe Mode** - Restricted operation mode activated on critical failures. See [[Safe_Mode_Behavior]].

**Scheduler** - The OpenClaw component that sequences work items and allocates resources. See [[OpenClaw_Core_System]].

**Spec** - Specification document defining requirements, interfaces, or behavior.

**Spec Decomposition** - Breaking high-level intent into atomic tickets. See [[Spec_Decomposition_Rules]].

**Static Analysis** - Automated code examination without execution. See [[Lint_Static_Analysis_Gate]].

**Studio OS** - The complete AI-Native Game Studio Operating System. See [[Studio_OS_Overview]].

## T

**Ticket** - An atomic unit of work with acceptance criteria, tracked through the pipeline. See [[Ticket_Template_Spec]].

**Token Burn** - Rate of API token consumption. Monitored and controlled. See [[Token_Burn_Controls]].

**Tool** - A deterministic utility for specific operations (Git, Godot CLI, etc.).

## U

**Unit Tests Gate** - Validates core logic through automated tests. See [[Unit_Tests_Gate]].

**Used By** - YAML field listing notes that depend on this note. Creates outbound links.

## V

**Vault** - The complete Obsidian knowledge base containing all Studio OS documentation.

**Vision Model** - AI model specialized in image understanding and generation. See [[Vision_UI_Interpreter]].

## W

**Work Loop** - The continuous cycle of checking backlog, prioritizing, and executing tickets. See [[OpenClaw_Daily_Work_Loop]].

## Y

**YAML Frontmatter** - Metadata block at the start of each note defining title, type, tags, dependencies, etc.

---

*This glossary is living documentation. Add terms as the system evolves.*
