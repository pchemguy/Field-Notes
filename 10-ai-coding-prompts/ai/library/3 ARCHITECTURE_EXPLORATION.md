# ARCHITECTURE_EXPLORATION.md

## Automation Boundary -> Architecture Space Exploration

---

## Purpose

This prompt explores possible system architectures that could satisfy the automation
candidates and constraints identified in `AUTOMATION_CANDIDATE_DECOMPOSITION.md`.

This stage intentionally does not select a solution.

Its goals are to:

* shape the solution space
* compare fundamentally different architectural approaches
* surface tradeoffs and risks early
* preserve optionality before commitment

This is the first solution-shaping step, but it remains pre-decisional.

---

## Preconditions

* A completed and reviewed `AUTOMATION_CANDIDATE_DECOMPOSITION.md` is available.
* Automation candidates and non-candidates are explicitly identified.

If these conditions are not met, STOP and request what is missing.

---

## Instructions to the AI

You are exploring **architecture classes**, not implementations.

You must:

* reason at the system and subsystem level
* respect all constraints and boundaries from prior artifacts
* compare alternatives fairly and explicitly
* make **implicit architectural commitments explicit**

You must not:

* commit to a single architecture
* propose specific algorithms, models, or frameworks
* design detailed data structures or APIs
* estimate implementation effort or timelines

---

## Required Inputs

Treat the following as authoritative inputs:

* `OBSERVED_PROBLEM.md`
* `AUTOMATION_CANDIDATE_DECOMPOSITION.md`

All reasoning must trace back to these documents.

---

## Required Output Structure

Produce the following sections in order.

---

## 1. Problem Restatement (Architecture-Relevant)

Restate the problem only in terms relevant to architecture.

Include:

* scope of automation
* human-in-the-loop boundaries
* non-negotiable constraints
* dominant risk drivers

Do not restate observational details unless they affect architecture.

---

## 2. System Boundary Definition

Define the conceptual boundaries of the system.

Clarify:

* what is inside the system
* what remains external (humans, existing tools, environments)
* what the system is explicitly *not* responsible for

This defines the architectural “box.”

---

## 3. Architecture Axes (Mandatory)

Before proposing architecture candidates, explicitly enumerate the **primary axes**
along which viable architectures may differ.

These axes define the **solution space dimensions** and must be considered even if
some options are later rejected.

If an axis is irrelevant, explicitly state why.

### 3.1 Execution Environment

* Operating system(s): Windows, Linux, macOS, mobile OS
* Hardware class: desktop, laptop, smartphone, server
* Resource assumptions: CPU/GPU, memory, storage

### 3.2 Compute Topology

* On-device compute
* Remote compute (server)
* Desktop-local compute
* Hybrid (split compute)

### 3.3 Workflow Timing

* Real-time / uninterrupted
* Near-real-time (capture → immediate processing)
* Asynchronous / batch

### 3.4 Deployment Model

* Local-only
* Client–server
* Hybrid

### 3.5 Device Responsibility Split

* Single-device end-to-end
* Multi-device (capture vs processing)
* Automatic vs manual handoff

### 3.6 Interaction Model

* Fully offline
* Interactive
* Semi-interactive (human checkpoints)

### 3.7 Application Form

* Library / SDK
* CLI
* Desktop GUI
* Mobile app
* Web app
* Thin client vs thick client

### 3.8 UI Technology

* Native
* Browser-based
* Headless

### 3.9 Trust and Verification Model

* Fully automated
* Automated with mandatory human validation
* Assistive tooling

### 3.10 Data Lifecycle

* Ephemeral
* Persistent with audit trail
* Export-only vs managed dataset

Do **not** select options yet.
This section exists to prevent implicit commitments.

---

## 4. Architecture Candidate Coverage Check (Mandatory)

Before listing candidates, ensure that the candidate set **collectively covers**
the major combinations implied by §§3.2 and 3.3.

At minimum, address whether candidates exist for:

* on-device compute
* remote/server-side compute
* desktop-local compute (if relevant)
* real-time or uninterrupted workflows
* capture-then-process workflows

If any combination is missing, explicitly state:

* whether it is intentionally excluded
* why it is out of scope or infeasible

Failure to justify exclusions is an error.

---

## 5. Architecture Candidate Overview

Identify **2–5 distinct architecture classes** that could plausibly satisfy the
problem definition.

Architecture candidates must differ along **fundamental axes**, not just UI or
packaging.

For each candidate, provide:

* **Formal descriptor**:
  `(workflow timing + compute topology + deployment model)`
* **Short descriptive name**
* **One-paragraph summary**

Avoid names that obscure topology (e.g., “desktop assistant” without clarifying
whether compute is local or remote).

Do not rank yet.

---

## 6. Architecture Candidates (Detailed)

For each architecture candidate, provide the following subsections.

### 6.X Architecture {Name}

#### a) Core Components

List major components and responsibilities.

#### b) Conceptual Data Flow

Describe how information flows between components and humans.

#### c) Human-in-the-Loop Placement

Explain:

* where human input is required
* where validation occurs
* what decisions remain manual

#### d) Strengths

What this architecture does well *relative to the problem*.

#### e) Weaknesses

Structural limitations or tradeoffs.

#### f) Axis Positioning

Explicitly position this architecture along the axes in §3.

For each relevant axis:

* state the chosen position
* justify it
* note excluded alternatives

#### g) Risk Alignment

Explain how this architecture:

* mitigates key risks
* exacerbates key risks

---

## 7. Cross-Architecture Comparison

Compare candidates across:

* constraint alignment
* flexibility vs rigidity
* workflow scalability
* auditability and traceability
* tolerance for variability
* user trust and adoption risk

Make tradeoffs explicit.

---

## 8. Coupled Axes and Lock-In Risks

Identify axes that appear **coupled**.

For each coupling:

* describe the linkage
* state whether it is inherent or incidental
* assess lock-in risk

Highlight candidates that prematurely fix multiple axes.

---

## 9. Open Questions and Assumptions

List assumptions architecture selection would force.

For each:

* describe the assumption
* identify evidence needed to validate it

---

## 10. Architecture Decision Readiness

Assess readiness to select an architecture.

Answer:

* Are there clear leading candidates?
* What information is missing?
* Would selection now force premature commitments?

Explicitly state whether:

* selection is appropriate now, or
* further investigation is required.

---

## Stopping Condition

Stop after completing the above sections.

Do not:

* choose an architecture
* propose implementation details
* suggest technologies or tools

---

## Intended Use

This artifact is meant to:

* inform architecture decision records
* guide feasibility validation
* prevent accidental lock-in
* justify decisions retrospectively

Freeze once architecture selection begins.

---

End of prompt.
