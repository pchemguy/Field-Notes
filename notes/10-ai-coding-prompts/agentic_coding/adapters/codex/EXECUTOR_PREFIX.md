# ADAPTER: Codex Agent (Repo Execution / PR-Producing)

## PURPOSE

This adapter wraps **Prime + Overlay(s) + Packet** for execution in a Codex agent environment that can modify a repository checkout and propose a branch/PR. It is mechanical only and does not change task meaning.

## NON-GOALS (HARD)

This adapter must NOT:

* add or modify task requirements, priorities, or constraints
* introduce cognitive guidance or task semantics
* resolve conflicts between Prime/Overlay/Packet
* add scope fences or acceptance checks beyond the Task Packet

## INPUTS

Upstream artifacts in order:

1. Cognitive Prime
2. One or more Task Overlays
3. One Task Packet (task instance)

Optional inputs:

* repo notes (if provided by user)
* failing logs (if provided by user)

## OUTPUTS

* A Codex-ready prompt payload
* A response format contract emphasizing PR-ready reporting and evidence

## TOOL CONSTRAINTS

* Execution model: remote/sandbox repo execution (tool-managed)
* File visibility: repository checkout (assumed), but may be partial depending on tool
* Output limits: keep final report concise; include excerpts only when blocking

## COMPOSITION RULES (MECHANICAL ONLY)

* Include order: Prime -> Overlay(s) -> Packet -> this adapter
* Do not restate Prime or Overlays.
* If context limits are encountered, compress by removing examples before constraints.
* If Prime/Overlay/Packet conflict, STOP and report the conflict; do not guess.

## TOOL-SPECIFIC INSTRUCTIONS (MECHANICAL)

* Operate directly on the repository and prepare changes as a reviewable commit series.
* Prefer a small number of commits that reflect logical steps.
* Run the Acceptance Checks specified in the Task Packet and report outcomes.
* If a command fails, include the minimal relevant excerpt and the next actionable step.
* Do not include long logs unless needed to explain a blocker.

## RESPONSE FORMAT CONTRACT

Your response must be structured exactly as:

1. **Summary**
    * 3-5 bullets describing what changed and why (task-aligned)
2. **Changes**
    * List changed files with 1-line rationale per file
3. **Validation**
    * Commands run (verbatim)
    * Outcome summary (pass/fail; key failures only)
4. **Artifacts**
    * Branch/PR status (if available in the environment)
    * Notes on commit structure (1-3 bullets)
5. **Blockers (if any)**
    * What is missing / inaccessible
    * Why it blocks progress
    * Minimal info required to proceed

## STOP / ESCALATION MECHANICS

If blocked:

* Do not continue by inventing context.
* Output the **Blockers** section and stop.

If upstream instructions conflict:

* Output a **Conflict Report** under Blockers identifying the conflicting clauses.

## VERSIONING

* Adapter version: 1.0
* Tool/surface: Codex agent (repo execution / PR-producing)
* Last updated: 2026-01-17
* Notes: Mechanical wrapper only.
