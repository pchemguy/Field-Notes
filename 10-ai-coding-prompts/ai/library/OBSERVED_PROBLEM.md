# OBSERVED_PROBLEM.md

## Observed Workflow -> Problem Formalization Prompt

---

## Purpose

This prompt converts an observed real-world human practice into a solution-agnostic, engineering-ready problem statement. It is intended for early-stage problem discovery, *before* feasibility analysis, architecture design, or technology selection. A core objective is to surface unknown-unknowns, overlooked constraints, and hidden decision criteria early, while changes are still cheap. This prompt deliberately suppresses solution thinking in order to reduce premature convergence and hidden assumptions.

---

## Instructions to the AI

You are analyzing an observed human workflow to determine whether automation or tooling might be appropriate. Your responsibility is not only to summarize, but to interrogate the observation in order to reduce ambiguity and premature assumptions.

### Hard Rules

You must not:

* propose solutions, algorithms, architectures, or tools
* discuss ML vs non-ML, CV techniques, or implementation feasibility
* recommend next steps beyond problem formalization
* optimize or redesign the workflow

You must:

* identify missing information that materially affects understanding
* ask clarifying questions where observation alone is insufficient
* keep all outputs solution-agnostic

---

## Required Output Structure

Produce the following sections in order.

---

### 1. Observed Workflow (As-Is)

Describe the workflow exactly as it is performed today.

Include:

* step-by-step actions taken by the human
* inputs used at each step
* intermediate artifacts created (photos, notes, measurements, annotations)
* final outputs
* points where judgment, approximation, or discretion is applied

If any step is unclear from the observation, note the uncertainty explicitly.

---

### 2. Clarifying Questions (Mandatory)

Before drawing conclusions, identify critical unknowns.

List targeted, high-leverage questions whose answers would materially affect:

* interpretation of the workflow
* identification of constraints
* definition of success or failure

Guidelines:

* Ask only questions that matter for understanding the problem.
* Prefer questions that expose hidden constraints, not preferences.
* Group questions by theme where possible.

Examples of acceptable categories:

* workflow variability
* measurement tolerance
* error handling
* frequency and scale
* trust and verification

Do not ask about solutions or tools.

---

### 3. Implicit Goals (Hypotheses)

Based on the observation and acknowledging unanswered questions, infer what the human operator is likely optimizing for.

Consider:

* accuracy vs speed
* convenience vs rigor
* reproducibility vs flexibility
* expert judgment vs standardization

State these explicitly as hypotheses, not facts.

---

### 4. Pain Points and Friction

Identify where the workflow experiences friction or risk.

Include:

* time-consuming steps
* error-prone or inconsistent steps
* steps sensitive to operator skill or judgment
* aspects that scale poorly with workload or sample count

Do not propose remedies.

---

### 5. Constraints (Non-Negotiable)

List constraints that any future solution must respect.

Consider:

* environmental constraints (lighting, devices, physical setup)
* human constraints (training level, habits, tolerance for change)
* scientific or regulatory constraints (traceability, auditability, reproducibility)
* organizational constraints (workflow integration, documentation requirements)

Treat constraints as binding unless explicitly stated otherwise.

---

### 6. Success Definition (Solution-Agnostic)

Define what would make automation or tooling useful versus unacceptable, without describing how it would be achieved.

Include:

* minimum acceptable outcomes
* failure conditions
* what aspects of the manual workflow must be preserved
* what losses (accuracy, trust, explainability) would be unacceptable

Frame success in terms of observable outcomes and guarantees, not mechanisms.

---

## Stopping Condition

Stop after completing the above sections.

Do **not**:

* answer the clarifying questions yourself
* suggest solutions or feasibility conclusions
* transition into architecture or design

This artifact must remain **problem-only**.

---

## Intended Use

This document is meant to be:

* frozen and referenced during later stages
* used as an input to feasibility and architecture prompts
* used to detect scope drift and premature solution bias
* reusable across domains where a manual practice is observed

---
