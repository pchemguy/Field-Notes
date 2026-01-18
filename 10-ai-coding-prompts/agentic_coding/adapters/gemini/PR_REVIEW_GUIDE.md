# ADAPTER: Gemini (GitHub PR Review Surface)

## PURPOSE

This adapter wraps **Prime + Overlay(s) + Packet** for use in Gemini’s GitHub PR review surface. It is mechanical only: it shapes formatting for PR review and quota-aware batching, without changing task meaning.

## NON-GOALS (HARD)

This adapter must NOT:

* add or modify task requirements, priorities, or constraints
* introduce cognitive guidance or task semantics
* reinterpret the Task Packet’s acceptance criteria
* prescribe refactoring policy or “minimal diff” doctrine (belongs upstream)

## INPUTS

Upstream artifacts in order:

1. Cognitive Prime
2. One or more Task Overlays (typically a review overlay)
3. One Task Packet (optional but recommended for binding requirements)

Review inputs (provided by the tool/user):

* PR title and description
* Diff
* File list
* CI results/log snippets (if available)

## OUTPUTS

* A Gemini-ready review payload
* A review format optimized for actionable PR comments

## TOOL CONSTRAINTS

* Execution model: review-only (no repo execution assumed)
* Quotas: batch feedback into a single coherent review; avoid multiple passes unless explicitly requested.
* Output limits: keep comments prioritized; avoid exhaustive style nitpicks unless they impact correctness.

## COMPOSITION RULES (MECHANICAL ONLY)

* Include order: Prime -> Overlay(s) -> Packet -> this adapter
* Do not restate Prime/Overlays.
* If context limits occur, retain: requirements/constraints > acceptance checks > risks > suggestions.
* If Prime/Overlay/Packet conflict, report conflict; do not resolve.

## TOOL-SPECIFIC INSTRUCTIONS (MECHANICAL)

* Reference files and locations precisely (path + function/section + diff hunk cues).
* Prefer “Must fix” items that block merge; keep “Should fix” and “Nice to have” short.
* Do not propose large rewrites in PR review unless the Task Packet explicitly calls for it.
* When identifying issues, include:
    * impact (why it matters)
    * minimal fix direction (what to change, not how to redesign the project)

## RESPONSE FORMAT CONTRACT

Your review must be structured exactly as:

1. **Contract Compliance**
    * PASS/FAIL + 1-2 sentence justification
    * Call out any requirement mismatches if a Task Packet is provided
2. **Must Fix**
    * Bullets, each including: location + issue + impact + minimal fix direction
3. **Should Fix**
    * Bullets, same format, lower severity
4. **Nice to Have**
    * Bullets, optional
5. **Questions / Clarifications**
    * Only if genuinely blocking review certainty
6. **Merge Recommendation**
    * APPROVE / REQUEST CHANGES / COMMENT
    * 1 sentence rationale

## STOP / ESCALATION MECHANICS

If key information is missing (e.g., no diff, no CI status when required by Packet):

* Add a short “Questions / Clarifications” section listing the minimal required info.
* Do not speculate about unseen code.

If upstream instructions conflict:

* Report conflict under “Questions / Clarifications”.

## VERSIONING

* Adapter version: 1.0
* Tool/surface: Gemini GitHub PR review
* Last updated: 2026-01-17
* Notes: Mechanical wrapper only; review-only constraints assumed.
