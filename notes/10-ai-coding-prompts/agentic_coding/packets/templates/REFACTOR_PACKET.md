# TASK PACKET: Refactor - {short objective}

## 0) Metadata

* Packet ID: {YYYY-MM-DD}-refactor-{slug}
* Owner: {name/handle}
* Status: draft | active | blocked | completed
* Created: {YYYY-MM-DD}
* Updated: {YYYY-MM-DD}

## 1) Refactor Objective

Describe the structural improvement and why it matters.

* Motivation:
    * {maintainability | testability | modularity | performance | reliability}
* Target outcome:
    * {what the code should look like or enable after refactor}
* Non-goals:
    * {explicitly list what not to change}

## 2) Refactor Scope Fence (Hard)

### Allowed paths

* {e.g., src/...}
* {e.g., tests/...}

### Forbidden paths

* {e.g., docs/...}
* {e.g., build/CI config files}
* {e.g., dependency manifests}

### Components in scope

* {modules/packages/classes}

### Components out of scope

* {modules/packages/classes}

## 3) Behavior and API Contract (Hard)

Pick one and be explicit.

* Behavior:
    * Preserve externally observable behavior unless listed in §9.
* Public API:
    * No signature changes to public functions/classes unless listed in §9.
* Data formats:
    * Preserve serialized formats and filenames unless listed in §9.

## 4) Refactor Strategy Constraints

* Structural change is expected, but must remain reviewable.
* Prefer incremental steps (small commit units) over one massive rewrite.
* Avoid “drive-by” changes not required by refactor objective.

## 5) Deliverables

* Refactored code meeting the objective
* Tests updated/added to protect intended behavior
* A short refactor note:
    * what changed structurally
    * why it is safer/better now
    * any follow-ups

## 6) Acceptance Checks (Must Run)

### Static / lint / format

* `{command}`
* `{command}`

### Tests

* `{command}`
* Optional focused subset:
    * `{command}`

### Behavioral invariants (if applicable)

* {list invariants that must remain true}

## 7) Risk Areas

* Behavior drift through refactor
* API drift (signature, exceptions, return types)
* Hidden coupling (implicit module initialization, import side effects)
* Performance regressions due to abstraction layering

## 8) Autonomy Budget

* Max refactor iterations after failing checks: {1|2}
* Max reruns of failing checks: {2}
* If invariants cannot be preserved without exception: STOP and report.

## 9) Explicit Exceptions (If Any)

* Allowed behavior changes:
    * {none | list}
* Allowed API changes:
    * {none | list}
* Allowed dependency changes:
    * {none | list}

## 10) Stop Triggers

STOP and ask if:

* preserving behavior conflicts with refactor objective
* any public API change becomes necessary but is not approved in §9
* tests cannot be made to pass within the autonomy budget

## 11) Output Contract

Final report must include:

* Refactor summary ({=7 bullets)
* Structural changes (grouped by component)
* Tests added/changed and what they protect
* Checks run + outcomes
* Noted risks and follow-ups

End of packet.
