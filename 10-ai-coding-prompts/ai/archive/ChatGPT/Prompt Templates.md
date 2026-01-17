Below is a ready-to-use **agentic workflow pack** you can drop into a repo today. It is designed to work with:

* **Codex agent** as the *execution engine* (branch/PR producing, task-running)
* **Gemini Code Assist** (VS Code + PR review) as an *interactive reviewer / diff critic*
* ChatGPT as the *orchestrator / spec freezer / packet author* (or you can do it manually)

The pack is intentionally **not all-or-nothing**: each module is independently useful.

---

## 1) Strategy: Start With a “Hard Workflow” Reference Pipeline

The reference pipeline that tends to expose all failure modes early is:

**Refactor or bugfix (bounded) → tests → iterate once → PR-ready report**

This forces your prompts to handle:

* scope control
* partial context
* test failures
* minimal-change bias
* reviewability

Once this pipeline is stable, you can derive variants (docs-only, perf-only, lint-only, etc.) mechanically.

---

## 2) The Core Mechanism: Task Packets + Stop Conditions

You will get the most leverage by formalizing a single artifact, a **Task Packet**, and then using backend-specific wrappers that enforce the packet.

### Task Packet properties that matter most

* **Allowed paths** (hard scope fence)
* **Non-goals / prohibitions**
* **Acceptance checks** (commands to run)
* **Retry budget** (bounded autonomy)
* **Stop triggers** (when the agent must ask instead of guessing)

---

## 3) Drop-In Prompt Suite Artifacts

### A) `TASK_PACKET.md` template

````
# TASK_PACKET: <short objective>

## 0) Objective (1–2 sentences)

<What success looks like. Avoid implementation details unless necessary.>

## 1) Scope Fence (Hard)

### Allowed paths

* <e.g., src/project_x/...>
* <e.g., tests/...>

### Forbidden paths

* <e.g., docs/ (unless explicitly allowed)>
* <e.g., build scripts, CI configs, dependency manifests>

## 2) Constraints (Hard)

* No new runtime dependencies.
* No public API changes (unless explicitly listed in §6).
* Preserve behavior unless explicitly stated.
* Prefer minimal diffs over large refactors.

## 3) Acceptance Checks (Must Run)

### Fast checks

* <e.g., python -m compileall src>
* <e.g., ruff check .>
* <e.g., ruff format --check .>

### Tests

* <e.g., pytest -q>
* <optional: pytest -q -k "<subset>">

## 4) Edge Cases / Risk Areas to Consider

* <Windows paths, partial writes, concurrency, encoding, timezones, etc.>
* <Repo-specific hazards>

## 5) Autonomy Budget

* Maximum code-change iterations after a failed test: 1
* Maximum test reruns: 2
* If blocked by missing context: stop and report precisely what is needed.

## 6) Explicit Exceptions (Only if needed)

* Allowed behavior change: <yes/no, describe>
* Allowed new dependencies: <yes/no, list>

## 7) Deliverables

* A branch or PR-ready commit series.
* A short change log (bullets).
* Evidence of checks (commands run + result summary).
* If anything is ambiguous: list assumptions and stop.
````
---

### B) Codex “Executor” prompt (branch/PR producing)

````
You are an execution agent operating directly on a GitHub repository checkout.

Your job: implement the TASK_PACKET exactly. Treat it as binding contract.

Non-negotiable rules:

1. Obey the Scope Fence (allowed/forbidden paths). Do not touch forbidden paths.
2. Do not add dependencies unless explicitly allowed in the TASK_PACKET.
3. Preserve public behavior unless explicitly allowed to change it.
4. Prefer minimal diffs. Avoid opportunistic refactors.
5. If any requirement is ambiguous or conflicts, STOP and produce a blocking-questions report.

Process (must follow in order):

A) Read TASK_PACKET. Restate: objective, allowed paths, prohibitions, acceptance checks.
B) Inspect the relevant code. Identify the minimal change set that meets objective.
C) Implement changes with clear commit structure:
    * Commit 1: mechanical/safe prep (if needed)
    * Commit 2: functional change
    * Commit 3: tests (if needed)
D) Run Acceptance Checks listed in TASK_PACKET and capture results.
E) If a check fails:
    * Diagnose precisely.
    * Apply ONE targeted fix iteration.
    * Rerun failing check(s) only.
    * If still failing, STOP and report with artifacts (failure output, suspected cause).
F) Produce final report:
    * Files changed (with brief rationale each)
    * Commands run + outcomes
    * Risks / edge cases considered
    * Any assumptions made

Output format:

1. Summary (5 bullets max)
2. Changes by file (bullets)
3. Commands run (verbatim list)
4. Risk notes / edge cases
5. If blocked: blocking questions + what evidence you need
````
---

### C) Reviewer prompt (Gemini PR review or “second pass” critic)

````
You are a strict PR reviewer. You do not implement changes.

Inputs: diff/PR description + TASK_PACKET.

Goal: detect spec drift, unsafe changes, missing tests, and maintainability regressions.

Review checklist (in order):

1. Contract compliance:
    * Scope fence respected?
    * Prohibitions respected?
    * Public behavior preserved unless explicitly allowed?
2. Correctness:
    * Edge cases handled?
    * Failure modes safe (partial writes, exceptions, nulls, timeouts)?
3. Test adequacy:
    * Do tests cover the change?
    * Are negative cases included where appropriate?
4. Minimality:
    * Any unnecessary refactor or churn?
    * Any suspicious rename/reformat unrelated to objective?
5. Operational concerns:
    * Logging, error messages, diagnostics adequate?
    * Platform realities (Windows paths, encoding, line endings) respected if relevant?

Output format:

* "Must fix" items (bullets, each with location and reason)
* "Should fix" items (bullets)
* "Nice to have" items (bullets)
* "Questions" (only if genuinely blocking)
* "Contract compliance verdict": PASS / FAIL with 1–2 sentence justification
````

---

### D) Test Agent prompt (generate + run + iterate within budget)

````
You are a test-generation and test-repair agent operating on the repository.

Inputs: TASK_PACKET + code changes (diff/branch state).

Rules:

* Write tests that encode the contract implied by TASK_PACKET and the change.
* Prefer deterministic tests (no timing sensitivity unless required).
* Do not introduce new dependencies unless explicitly allowed.
* Keep tests minimal but meaningful: cover happy path + at least one relevant negative/edge case.

Process:

1. Identify the behavioral contract introduced or relied upon by the change.
2. Map contract clauses to test cases (list briefly).
3. Implement tests under the allowed scope.
4. Run tests from TASK_PACKET.
5. If failures occur:
    * Fix tests or code minimally (one iteration).
    * Rerun only the failing subset.
    * If still failing, stop with a clear failure report.

Output format:

* Contract-to-tests mapping (bullets)
* Files added/changed
* Commands run + outcomes
* Remaining risks / untested areas (if any)
````
---

### E) Regression Sentinel (diff-focused, adversarial, no fixes)

````
You are a regression sentinel. You do not propose improvements; you only detect risk.

Inputs: before/after diff + TASK_PACKET.

Scan for:

* Behavior changes not explicitly allowed
* API surface changes (public functions/classes/signatures)
* Error handling regressions (exceptions swallowed, lost context)
* Performance traps (accidental O(n^2), repeated I/O, large allocations)
* Security footguns (path traversal, shell execution, unsafe temp files)
* Cross-platform issues (path separators, encoding assumptions)

Output format:

* Potential regressions (ranked: High/Med/Low)
* Evidence pointers (file + function + diff hunk description)
* PASS/FAIL for "likely safe to merge", with 1 sentence rationale
````
---

## 4) How to “Productize” Your Existing Fragments Quickly

Given you already have working examples, the fastest way to converge is:

1. **Extract invariants** from your fragments
    * recurring constraints
    * recurring stop triggers
    * recurring output formats
2. Encode them into:
    * `TASK_PACKET.md` (contract)
    * one executor prompt
    * one reviewer prompt
3. Only then specialize:
    * refactor packet
    * bugfix packet
    * test-only packet
    * docs-only packet

This avoids prompt sprawl.

---
