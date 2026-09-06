# TASK PACKET: {short objective}

## 0) Metadata

* Packet ID: {YYYY-MM-DD}-{slug}
* Owner: {name/handle}
* Status: draft | active | blocked | completed
* Created: {YYYY-MM-DD}
* Updated: {YYYY-MM-DD}

## 1) Objective

State the goal in 1–3 sentences. Focus on outcomes, not implementation.

* Primary objective:
    * {what success means}
* Success criteria:
    * {observable outcomes}

## 2) Context

Minimal background needed to avoid misinterpretation.

* Problem context:
    * {1–5 bullets}
* Relevant references:
    * {links, doc paths, issue IDs, prior PRs}

## 3) Scope Fence (Hard)

Define where changes are allowed. Be explicit.

### Allowed paths

* {e.g., src/...}
* {e.g., tests/...}

### Forbidden paths

* {e.g., docs/...}
* {e.g., build/CI config files}
* {e.g., dependency manifests}

### Explicit inclusions / exclusions

* Include:
    * {file(s) that must be touched}
* Exclude:
    * {file(s) that must not be touched}

## 4) Constraints (Hard)

Non-negotiable rules.

* Behavior:
    * {preserve behavior | behavior change allowed as specified in §9}
* Compatibility:
    * {OS, Python versions, runtime environments}
* Dependencies:
    * {no new deps | allowed deps list}
* Performance / memory:
    * {constraints if relevant}
* Security posture:
    * {public-facing vs internal; specific constraints}

## 5) Deliverables

What must be produced.

* Code changes:
    * {what kind}
* Tests:
    * {required test additions/updates}
* Docs:
    * {required doc updates, if any}
* Reports:
    * {change log, risk notes, etc.}

## 6) Acceptance Checks (Must Run)

Define the commands or checks that constitute “done”.

### Static / format / lint (if applicable)

* `{command}`
* `{command}`

### Tests

* `{command}`
* Optional subset:
    * `{command}`

### Runtime / manual checks (if applicable)

* {step-by-step manual check}
* {expected observable result}

## 7) Edge Cases / Risk Areas

List the most likely failure modes relevant to this task.

* {edge case 1}
* {edge case 2}

## 8) Autonomy Budget

Bounded autonomy rules (especially for agentic execution).

* Max implementation iterations after a failed acceptance check: {0|1|2}
* Max targeted reruns of failing checks: {1|2|3}
* If blocked by missing context: STOP and report per §10.

## 9) Explicit Exceptions (If Any)

Only include exceptions when you truly intend them.

* Allowed behavior change(s):
    * {describe precisely, or “none”}
* Allowed new dependency(ies):
    * {list, or “none”}
* Allowed breaking change(s):
    * {describe, or “none”}

## 10) Stop Triggers (Blocking Conditions)

The agent must STOP and ask if:

* {requirement ambiguity that materially affects outcome}
* {conflicting constraints}
* {cannot access required files/tests}
* {acceptance checks fail after the allowed iteration budget}

## 11) Output Contract (for final response/report)

The final response must include:

* Summary ({=5 bullets)
* Files changed (with rationale)
* Acceptance checks run + outcomes
* Risks / edge cases considered
* Blockers (if any) + minimal info required

End of packet.
