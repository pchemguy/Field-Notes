# TASK PACKET: Review - {short objective}

## 0) Metadata

* Packet ID: {YYYY-MM-DD}-review-{slug}
* Owner: {name/handle}
* Status: draft | active | blocked | completed
* Created: {YYYY-MM-DD}
* Updated: {YYYY-MM-DD}

## 1) Review Objective

Describe what this review is trying to validate.

* Review type:
    * correctness | maintainability | security | performance | API stability | test adequacy
* Target:
    * PR | branch | diff | module(s) | commit range
* Success criteria:
    * {what “good to merge” means}

## 2) Inputs Provided

List exactly what the reviewer will have.

* PR title/description: {yes/no}
* Diff: {yes/no}
* CI results/logs: {yes/no}
* Reproduction steps: {yes/no}
* Related issues/spec: {links}

## 3) Review Scope Fence

### In scope

* {paths/modules/files}
* {components}

### Out of scope

* {paths/modules/files}
* {topics (e.g., performance)}

## 4) Reviewer Authority (Hard)

Pick one.

* Review-only:
    * Do not implement code changes; produce review findings only.
    OR
* Review + patch suggestions:
    * You may propose patch snippets, but do not refactor beyond what is necessary.

## 5) Review Priorities (Ordered)

1. Contract compliance (spec/packet alignment)
2. Correctness and safety (edge cases, failure modes)
3. Test adequacy
4. Maintainability and clarity
5. Performance (only if relevant)

## 6) Acceptance Evidence (What counts as proof)

* CI green: {required/optional}
* Local reproduction: {required/optional}
* Specific commands/logs required:
    * `{command}` (if applicable)

## 7) Risk Areas / Known Concerns

* {area 1}
* {area 2}

## 8) Stop Triggers

STOP and request missing info if:

* diff is not available (and required)
* CI results are required but not provided
* scope is ambiguous or conflicts with packet
* critical files are missing from the review input set

## 9) Output Contract

Review output must include:

* Contract compliance verdict: PASS/FAIL + brief justification
* Must fix (blocking) items (location + impact + minimal direction)
* Should fix items
* Nice to have items
* Questions/clarifications (only if blocking)
* Merge recommendation: APPROVE / REQUEST CHANGES / COMMENT

End of packet.
