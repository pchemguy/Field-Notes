# ARCHITECTURE_EXPLORATION.md

## Automation Boundary -> Architecture Space Exploration

---

## Purpose

This prompt explores possible system architectures that could satisfy the automation candidates and constraints identified in `AUTOMATION_CANDIDATE_DECOMPOSITION.md`.

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

You are exploring architecture classes, not implementations.

You must:

* reason at the system and subsystem level
* respect all constraints and boundaries from prior artifacts
* compare alternatives fairly and explicitly

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
* risk drivers

Do not restate observational details unless they affect architecture.

---

## 2. System Boundary Definition

Define the conceptual boundaries of the system.

Clarify:

* what is inside the system
* what remains external (humans, existing tools, environments)
* what the system is explicitly not responsible for

This defines the architectural "box".

---

## 3. Architecture Axes (Mandatory)

Before proposing architecture candidates, explicitly enumerate the primary axes along which viable architectures may differ. These axes define the solution space dimensions and must be considered even if some options are later rejected. At minimum, consider whether each of the following axes is relevant to this problem. If an axis is irrelevant, state why.

Typical axes include (non-exhaustive):

### Execution Environment

* Operating system(s): e.g., Windows, Linux, macOS, mobile OS
* Hardware class: desktop, laptop, smartphone, server
* Resource assumptions: CPU/GPU availability, memory, storage

### Deployment Model

* Local-only
* Client–server
* Hybrid (local capture, remote processing, local review)

### Device Responsibility Split

* Single-device end-to-end workflow
* Multi-device workflow (e.g., capture on one device, processing on another)
* Synchronous vs asynchronous handoff between devices

### Interaction Model

* Fully offline / batch
* Interactive / real-time
* Semi-interactive (human-in-the-loop checkpoints)

### Application Form

* Library / SDK
* CLI tool
* Desktop GUI application
* Mobile application
* Web-based application (browser client)
* Thin client vs thick client

### User Interface Technology

* Native UI
* Browser-based UI
* Headless (no UI)

### Trust and Verification Model

* Fully automated results
* Automated with mandatory human validation
* Assistive tooling with manual decision authority

### Data Lifecycle

* Ephemeral processing
* Persistent storage with audit trail
* Export-only vs managed dataset

Do not select options yet.
This section exists to prevent implicit commitments.

---

## 4. Architecture Candidate Overview

Identify 2-5 distinct architecture classes that could plausibly satisfy the
problem definition.

Architecture classes should differ along fundamental axes, such as:

* deployment model (local, client-server, hybrid)
* degree of automation (assistive vs supervisory vs autonomous)
* coupling to existing workflows
* responsibility split between components

For each candidate, provide:

* short descriptive name
* one-paragraph summary

Do not rank yet.

---

## 5. Architecture Candidates (Detailed)

For each architecture candidate, provide the following subsections.

### 5.X. Architecture {Name}

#### a) Core Components

List major components and their responsibilities.

#### b) Conceptual Data Flow

Describe how information flows between components and humans.

Use prose or bullet points, not diagrams or APIs.

#### c) Human-in-the-Loop Placement

Explain:

* where human input is required
* where human validation occurs
* what decisions remain manual

#### d) Strengths

What this architecture does well *relative to the problem*.

#### e) Weaknesses

Structural limitations or tradeoffs.

#### f) Axis Positioning

Explicitly position this architecture along the axes identified in §3.

For each relevant axis:

* state where this architecture sits
* explain why this positioning is natural or necessary
* note which alternatives this choice excludes

If an axis is intentionally deferred or left flexible, state how and why.

This section must make implicit assumptions explicit.

#### g) Risk Alignment

How this architecture interacts with previously identified risks:

* which risks it mitigates
* which risks it exacerbates

---

## 6. Cross-Architecture Comparison

Compare candidates across key dimensions:

* alignment with constraints
* flexibility vs rigidity
* scalability of workflow
* transparency and auditability
* tolerance for variability
* user trust and adoption risk

This section should make tradeoffs explicit.

---

## 7. Coupled Axes and Lock-In Risks

Identify axes that appear **coupled** in the proposed architecture candidates.

For each coupling:

* describe which axes are linked
* explain whether the coupling is inherent or incidental
* assess whether it introduces early lock-in or loss of optionality

Highlight any architecture candidates that:

* prematurely fix multiple axes
* reduce future flexibility without clear justification

This section is critical for long-lived or evolving systems.

---

## 8. Open Questions and Assumptions

List assumptions that architecture selection would force at this stage.

For each assumption:

* describe what is being assumed
* identify what evidence would be needed to validate it

These assumptions should drive the next stage.

---

## 9. Architecture Decision Readiness

Assess readiness to move to architecture selection.

Answer:

* Are there clear leading candidates?
* What information is still missing?
* Would choosing now force premature commitments?

Explicitly state whether:

* architecture selection is appropriate now, or
* further investigation is required first

---

## Stopping Condition

Stop after completing the above sections.

Do not:

* choose an architecture
* propose implementation details
* design APIs or pipelines
* suggest technologies or tools

This document defines the architecture option space, not the decision.

---

## Intended Use

This artifact is meant to:

* inform a later architecture decision record
* guide feasibility validation planning
* prevent accidental lock-in
* justify architectural choices retrospectively

It should be frozen once architecture selection begins.

---

End of prompt.
