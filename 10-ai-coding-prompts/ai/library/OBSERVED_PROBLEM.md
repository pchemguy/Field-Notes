# OBSERVED_PROBLEM.md

## Observed Workflow -> Problem Formalization Prompt

---

## Purpose

This prompt converts an observed real-world human practice into a solution-agnostic, engineering-ready problem statement. It is intended for early-stage problem discovery, before feasibility analysis, architecture design, or technology selection. A core objective is to surface unknown-unknowns, overlooked constraints, and hidden decision criteria early, while changes are still cheap. This prompt deliberately suppresses solution thinking in order to reduce premature convergence and hidden assumptions.

---

## Instructions to the User

1. Paste your **raw observation** into **Section 1** below.
2. Describe only what you observed.
3. Do not propose solutions or interpretations.
4. Imperfect or partial observations are acceptable.

---

## Instructions to the AI

You are analyzing a user-provided observation of a human workflow.

* Treat Section 1 as ground truth.
* Do not rewrite, "clean up", or reinterpret the observation.
* Do not invent missing details.
* Interrogate the observation to surface ambiguity and risk.
* Remain strictly solution-agnostic.

---

## Required Output Structure

Produce the following sections in order.

---

## 1. User-Provided Observation (Ground Truth - VERBATIM)

> **USER INPUT START**
>
> *(The user pastes their observation here.
> This content is treated as immutable ground truth.)*
>
> **USER INPUT END**

* Do not modify this content.
* Do not summarize it.
* Do not infer intent beyond what is written.

All subsequent sections must explicitly trace back to this input.

---

## 2. Observed Workflow (As-Is Interpretation)

Based strictly on the observation in §1, describe the workflow as it appears to operate.

Include:

* step-by-step actions taken by the human
* inputs at each step
* intermediate artifacts created
* final outputs
* points where judgment, approximation, or discretion appears to be applied

If something is unclear or missing, mark it explicitly as uncertain.

---

## 3. Clarifying Questions (Mandatory)

Identify critical unknowns that prevent confident problem definition.

Ask targeted, high-leverage questions whose answers would materially affect:

* understanding of the workflow
* identification of constraints
* definition of success or failure

Guidelines:

* Ask only questions that meaningfully reduce ambiguity.
* Prefer questions that expose hidden constraints or variability.
* Group questions by theme (e.g., variability, accuracy, scale, verification).

Examples of acceptable categories:

* workflow variability
* measurement tolerance
* error handling
* frequency and scale
* trust and verification

Do not ask about solutions, tools, or implementations.

---

## 4. Implicit Goals (Hypotheses)

Based on §§1-2 and explicitly acknowledging unanswered questions, infer what the human operator may be optimizing for.

Consider:

* accuracy vs speed
* convenience vs rigor
* reproducibility vs flexibility
* expert judgment vs standardization

State all goals as hypotheses, not facts.

---

## 5. Pain Points and Friction

Identify where the observed workflow appears to incur cost, risk, or inefficiency.

Include:

* time-consuming steps
* error-prone or inconsistent steps
* steps sensitive to operator skill or judgment
* aspects that scale poorly with repetition or volume

Do not propose remedies.

---

## 6. Constraints (Non-Negotiable)

List constraints implied or stated by the observation.

Consider:

* environmental constraints (devices, lighting, physical setup)
* human constraints (training, habits, tolerance for change)
* scientific or regulatory constraints (traceability, auditability, reproducibility)
* organizational constraints (workflow integration, documentation)

Treat constraints as binding unless explicitly contradicted.

---

## 7. Success Definition (Solution-Agnostic)

Define what would make automation or tooling useful versus unacceptable, without describing how it would be achieved.

Include:

* minimum acceptable outcomes
* failure conditions
* what aspects of the manual workflow must be preserved
* what losses (accuracy, trust, explainability) would be unacceptable

Frame success strictly in terms of observable outcomes and guarantees.

---

## Stopping Condition

Stop after completing the above sections.

Do not:

* answer the clarifying questions
* suggest solutions or feasibility conclusions
* transition into architecture or design

This artifact must remain problem-only.

---

## Intended Use

This document is meant to be:

* frozen and referenced during later stages
* used as an input to feasibility and architecture prompts
* used to detect scope drift and premature solution bias
* reusable across domains where a manual practice is observed

---
