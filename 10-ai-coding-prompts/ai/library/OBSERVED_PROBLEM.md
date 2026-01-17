# OBSERVED_PROBLEM.md

## Observed Workflow -> Problem Formalization Prompt

### Purpose

This prompt is used to convert an **observed real-world practice** into a **solution-agnostic, engineering-ready problem statement**.

It is intended for **early-stage problem discovery**, *before* feasibility analysis, architecture design, or technology selection.

This prompt deliberately suppresses solution thinking in order to reduce premature convergence and hidden assumptions.

---

## Instructions to the AI

You are analyzing an **observed human workflow** to determine whether automation or tooling is appropriate.

Your task is to **formalize the problem only**.

### Hard Rules

* Do **not** propose solutions, algorithms, architectures, or tools.
* Do **not** discuss ML vs non-ML, CV techniques, UI frameworks, or implementation feasibility.
* Do **not** evaluate cost, schedule, or staffing.
* Do **not** optimize or redesign the workflow.

Focus strictly on **what exists**, **why it exists**, and **what constraints it operates under**.

---

## Required Output Structure

Produce the following sections in order.

---

### 1. Observed Workflow (As-Is)

Describe the workflow exactly as it is performed today.

Include:

* Step-by-step actions taken by the human
* Inputs used at each step
* Intermediate artifacts created (notes, measurements, photos, annotations)
* Final outputs
* Points where judgment, estimation, or subjective decisions are applied

Do **not** interpret intent or propose improvements.

---

### 2. Implicit Goals

Infer what the human operator is actually optimizing for.

Consider:

* Accuracy vs speed
* Convenience vs rigor
* Reproducibility vs flexibility
* Personal judgment vs standardization

State these as **hypotheses**, not facts.

---

### 3. Pain Points and Friction

Identify where the workflow experiences friction.

Include:

* Time-consuming steps
* Error-prone or inconsistent steps
* Steps that require repeated attention or rework
* Aspects that do not scale with workload or sample count

Avoid proposing fixes.

---

### 4. Constraints (Non-Negotiable)

List constraints that any future solution must respect.

Consider:

* Environmental constraints (lighting, devices, physical setup)
* Human constraints (training level, habits, tolerance for change)
* Scientific or regulatory constraints (traceability, auditability, reproducibility)
* Organizational constraints (workflow integration, record-keeping)

Assume these constraints are **real unless explicitly contradicted**.

---

### 5. Success Definition (Solution-Agnostic)

Define what would make an automation or tool **useful** versus **unacceptable**, without describing how it would be achieved.

Include:

* Minimum acceptable outcomes
* Failure conditions
* What aspects of the manual workflow must be preserved
* What losses (if any) would be unacceptable

Frame success in terms of **observable behavior and outcomes**, not internal mechanisms.

---

## Stopping Condition

Stop after completing the above sections.

Do **not**:

* Suggest next steps
* Transition into feasibility or design
* Recommend technologies or approaches

---

## Intended Use

This artifact is meant to be:

* Frozen and referenced during later stages
* Used as an input to feasibility analysis
* Used to detect scope drift and solution bias
* Reused across different domains where a manual practice is observed

---
