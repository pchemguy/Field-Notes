# Architectural framework for navigating "Observed Problem -> PoC/MVP"

https://chatgpt.com/c/696c7684-6cdc-832a-963e-d050655baacb
https://gemini.google.com/app/37ae3a7528f98b7e

Below is a consolidated, critically revised framework for going from an arbitrary **Observed Problem** (a real-world workflow that might benefit from automation) to an **Implemented PoC and MVP**. It is intentionally problem-agnostic: it does not assume any domain, technology, or prior project context. It is written as an architect’s operating model that you can apply repeatedly.

This framework has three design goals:

1. **Make “reality” legible to software** (capture, formalize, model).
2. **Minimize irreversible commitments** (sequence decisions so that you decide late, but not too late).
3. **Create an execution system** (artifacts, gates, baselines, tests) so iteration is measurable rather than subjective.

---

## Core distinctions you must enforce

### PoC vs MVP

* **PoC (Proof of Concept):** answers “*Can we do it at all under real constraints?*”
  Output: evidence, risk retired, a technical path, often narrow and incomplete.
* **MVP (Minimum Viable Product):** answers “*Does it reliably deliver user value end-to-end?*”
  Output: a usable product slice (the “steel thread”), instrumented, testable, deployable.

### Prototype code has three legitimate categories

1. **Throwaway prototype:** fast, disposable; used for learning or UI exploration.
2. **Tracer bullet / baseline implementation:** intentionally kept as the first end-to-end thread; minimal but structured.
3. **Spike with reusable core:** exploratory but the *kernel* is wrapped behind stable interfaces and carried forward.

“Probe” code can become the **baseline** if contained behind clean contracts.

---

## The end-to-end lifecycle

Think in two big phases - **Pre-coding** and **Coding** - but with an explicit **Bridge** (where many teams fail by mixing planning and building without gates).

### Phase 0: Orientation and guardrails (pre-coding)

**Objective:** ensure the effort is worth doing at all and that you can observe it properly.

**Blocks**

1. **Observation ethics and access**
    * Can you observe the workflow repeatedly?
    * Do you have permission, data access, and representative samples?
2. **Stakeholder map**
    * Primary user, secondary users, approvers, operators.
3. **Value hypothesis (one sentence)**
    * “We believe automating X for Y will produce Z measurable benefit.”

**Deliverables**

* Access plan (how you will collect evidence)
* Initial value hypothesis

**Gate**

* If you cannot observe or obtain representative inputs, the project is not ready.

---

## Phase 1: Workflow capture and atomization (pre-coding)

**Objective:** turn the messy workflow into a factual, stepwise description without solutioning.

**Blocks**

1. **Trigger-to-outcome trace**
    * What starts the workflow?
    * What is the “done” condition in human terms?
2. **Step decomposition to “automation-meaningful” granularity**
    * Not “open Excel,” but “import file,” “validate schema,” “compute totals,” “resolve exception.”
3. **Friction and variability catalog**
    * Where time is lost, where errors occur, where judgment is applied.
4. **Exception map**
    * The top recurring failure modes and how humans handle them.

**Deliverables**

* Process map (happy path + common exception paths)
* Step inventory (atomic actions)
* Friction/variability log

**Gate**

* If you cannot articulate the workflow as observable state transitions, you are not ready to design automation.

---

## Phase 2: Problem contract (pre-coding)

**Objective:** define what “success” means and constrain scope so you can ship something real.

**Blocks**

1. **Problem statement (tight)**
    * Who, what task, current pain, desired outcome.
2. **Success metrics**
    * Time, error rate, throughput, cost, satisfaction—must be measurable.
3. **Refusal conditions**
    * When the system must stop, escalate, or defer to a human.
4. **Non-goals / won’t-do list**
    * Explicitly exclude edge cases and adjacent tasks.
5. **Constraints**
    * Latency, privacy, offline requirements, device limits, regulatory requirements, integration limitations.

**Deliverables**

* Problem Contract document

**Gate**

* No contract, no build. This is your scope bouncer.

---

## Phase 3: Domain and data modeling (pre-coding)

**Objective:** define the “shape” of reality: the nouns, verbs, invariants, and data volumes.

This phase is frequently skipped, and the result is architectures that are “reasonable” but wrong.

**Blocks**

1. **Ubiquitous language**
    * A glossary that both domain users and developers agree on.
2. **Domain model**
    * Entities, value objects, states, events.
3. **Invariants and validation rules**
    * Rules that must always hold true.
4. **Data characterization**
    * Formats, volumes, frequency, quality issues, missingness, ambiguity, drift.
5. **Interface contracts (draft)**
    * What enters and exits the system at boundary points.

**Deliverables**

* Domain glossary
* Conceptual data model (ERD-like or event/state model)
* Draft I/O schemas (even if informal)

**Gate**

* If you cannot define inputs/outputs and invariants, architecture selection is premature.

---

## Phase 4: Automation boundary and system context (pre-coding)

**Objective:** decide what the system will own, what remains human, and what external systems are treated as unreliable.

**Blocks**

1. **Boundary decision**
    * Which steps become automation candidates, which remain manual, which become assisted (human-in-the-loop).
2. **System context diagram**
    * Actors, external systems, data stores, interfaces.
3. **Failure policy**
    * Retries, fallbacks, escalation, audit trail requirements.
4. **Trust boundaries**
    * Security and privacy assumptions; where validation must occur.

**Deliverables**

* Automation Candidate Map
* System context diagram + boundary narrative
* Initial failure and escalation policy

**Gate**

* If you cannot say what is out of scope operationally, MVP scope will explode.

---

## Phase 5: Architecture exploration and selection (pre-coding)

**Objective:** explore multiple viable architectures, then commit using explicit trade-offs.

**Blocks**

1. **Candidate architectures (at least three)**
    * Examples of *types*: local-first, client/server, batch pipeline, event-driven, embedded, etc.
2. **Trade-off matrix**
    * Latency, cost, complexity, time-to-ship, operability, security, scaling.
3. **Decision record**
    * Pick one and record why others were rejected.

**Deliverables**

* Architecture candidates + trade-off table
* ADR (Architecture Decision Record)

**Gate**

* No ADR means you will re-litigate decisions endlessly mid-build.

---

## Bridge: Risk-driven feasibility and baseline thread

This is the transition point. It is not “coding” in the product sense, but it produces code artifacts that often remain.

### Phase 6: Risk register and feasibility plan (bridge)

**Objective:** identify what can kill the project and retire those risks in the cheapest order.

**Blocks**

1. **Riskiest assumptions list**
    * Technical, operational, adoption, data quality, integration, performance, security.
2. **Risk ranking**
    * Probability × impact × cost-to-learn.
3. **Feasibility experiments**
    * Each risk gets an experiment with acceptance criteria.

**Deliverables**

* Risk register + experiment plan
* Acceptance criteria per experiment

**Gate**

* If you are “testing feasibility” without a risk list, you are burning time indiscriminately.

### Phase 7: Tracer bullet/baseline implementation (bridge into coding)

**Objective:** produce a minimal end-to-end “steel thread” that is architecturally real, even if internally crude.

**Rules**

* Interfaces are stable early; internals are expected to change.
* Every stage produces explicit artifacts (files, records, logs) or explicit typed outputs.
* Diagnostics are first-class, not an afterthought.

**Deliverables**

* Walking skeleton pipeline (input → process → output)
* Baseline metrics (runtime, accuracy proxy, error rate, manual time saved)
* Minimal run log + artifact layout

**Gate**

* If you cannot run it end-to-end repeatedly, you do not yet have a PoC you can iterate on.

---

# Coding phase: construction with controlled iteration

## Phase 8: Scaffold the product (coding)

**Objective:** establish structure, boundaries, and operability before “real” logic proliferates.

**Blocks**

1. **Project layout**
    * Modules, packages, configuration, run directories, logging.
2. **Orchestrator**
    * A single command/API call that runs the thread.
3. **Artifact conventions**
    * Naming, versioning, manifest, reproducibility.
4. **Minimal observability**
    * Structured logs, run IDs, error taxonomy.

**Deliverables**

* Runnable skeleton with placeholder stages
* Standard output layout + manifest

---

## Phase 9: Block development loop (coding)

**Objective:** implement each block with a micro-lifecycle so you can replace parts without destabilizing the system.

**Per-block micro-lifecycle**

1. **Contract first:** define I/O and acceptance tests.
2. **Diagnostics first:** overlays, counters, residuals, debug artifacts.
3. **Implement:** minimal logic that meets acceptance criteria.
4. **Harden:** handle expected variability; enforce refusal conditions.
5. **Benchmark:** compare to baseline.

**Deliverables**

* Block-level tests
* Block-level debug outputs
* Updated baseline metrics

---

## Phase 10: Integration hardening and “quality envelope” (coding)

**Objective:** ensure the system fails safely, debugs quickly, and remains reproducible.

**Blocks**

1. **Failure mode coverage**
    * Explicit handling of top exception classes; escalation paths.
2. **Regression set**
    * Curated representative inputs; run on every change.
3. **Performance envelope**
    * Define acceptable ranges; detect regressions.
4. **Operational readiness**
    * Config management, environment capture, version stamping.

**Deliverables**

* End-to-end regression suite
* Performance checks (even if coarse)
* Run reports suitable for stakeholders

---

## Phase 11: MVP packaging and usability (coding)

**Objective:** convert a technically working pipeline into a usable product slice.

**Blocks**

1. **User workflow**
    * Minimal UI/CLI/API; consistent errors; clear outputs.
2. **Documentation**
    * Setup, runbook, troubleshooting, limitations.
3. **Feedback instrumentation**
    * Capture user feedback and operational telemetry relevant to success metrics.

**Deliverables**

* MVP release candidate
* User-facing documentation
* Feedback collection mechanism

---

# Iteration model: evolving PoC → MVP without thrash

Use two nested loops:

1. **Outer loop (product learning):** validate value hypothesis against success metrics.
2. **Inner loop (engineering):** replace or improve blocks while preserving contracts and baseline comparisons.

The “Ship of Theseus” approach is correct **only if** contracts and artifacts are enforced. Without that, “incremental replacement” becomes accidental coupling.

---

## Canonical deliverables checklist (minimal but complete)

**Pre-coding**

* Observation log + process map
* Problem Contract (success, refusal, non-goals, constraints)
* Domain glossary + conceptual data model + invariants
* System context + automation boundary
* Architecture candidates + ADR
* Risk register + experiment plan

**Bridge**

* Walking skeleton / baseline thread
* Baseline metrics + artifact layout + run manifest

**Coding**

* Block contracts + block tests
* Regression set + end-to-end tests
* Operability: logs, config capture, version stamping
* MVP package + user docs + feedback loop

---

If you want the framework to be maximally operational, the next step is to convert this into a set of **templates** (one page each) for: Observation Log, Problem Contract, Domain Glossary/Data Model, System Context, ADR, Risk Register/Experiment Plan, and Baseline Run Manifest.
