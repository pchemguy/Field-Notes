# 2 AUTOMATION_CANDIDATE_DECOMPOSITION.md

## Problem Formalization -> Automation Feasibility Boundary

---

## Purpose

This prompt consumes a completed `OBSERVED_PROBLEM.md` artifact and performs a structured decomposition of the observed workflow into automation candidates.

This stage sits between problem formalization and solution design.

Its purpose is to:

* identify what could be automated vs what should remain human
* expose feasibility risks without committing to solutions
* prevent premature end-to-end automation assumptions
* establish clear boundaries for later architectural work

This is the first stage where feasibility reasoning is allowed, but solution selection is still prohibited.

---

## Preconditions

* A completed `OBSERVED_PROBLEM.md` is available.
* Clarifying questions from that document have been answered or explicitly deferred.

If these conditions are not met, STOP and request what is missing.

---

## Instructions to the AI

You are analyzing a formalized problem description, not a raw observation.

Your task is to:

* decompose the workflow into logical sub-tasks
* reason about automation suitability, not implementation
* surface risks, variability, and dependency chains
* remain agnostic to specific algorithms, tools, or technologies

You must not:

* propose architectures, pipelines, or algorithms
* discuss ML vs non-ML, CV methods, or frameworks
* design user interfaces
* estimate cost, effort, or timelines

---

## Required Input

The following artifact must be treated as authoritative input:

* `OBSERVED_PROBLEM.md` (completed)

All reasoning must trace back to it explicitly.

---

## Required Output Structure

Produce the following sections in order.

---

## 1. Workflow Decomposition

Break the observed workflow into discrete functional steps.

For each step, include:

* brief description
* input(s)
* output(s)
* degree of human judgment involved:
    * none | low | medium | high

Do not yet judge feasibility.

---

## 2. Automation Suitability Assessment

For each workflow step identified in §1, assess:

* **Automation suitability**
    * high | medium | low | unsuitable
* **Primary limiting factors**
    * variability
    * ambiguity
    * data quality
    * trust / verification requirements
    * dependency on tacit human knowledge

Justify each assessment briefly.

---

## 3. Human-in-the-Loop Boundaries

Identify steps where:

* full automation is risky or undesirable
* partial automation with human confirmation may be appropriate
* human judgment is likely to remain essential

Explain *why* these boundaries exist, based on constraints and goals from `OBSERVED_PROBLEM.md`.

---

## 4. Degrees of Freedom

List dimensions along which future solutions could vary without violating the problem definition.

Examples (generic categories, adapt as needed):

* level of automation (assistive -> supervisory -> autonomous)
* tolerance for manual correction
* strictness of validation and audit trails
* latency vs accuracy tradeoffs
* reproducibility vs flexibility

Do not rank or choose yet.

---

## 5. Feasibility Risk Map

Identify risk clusters that could block or complicate automation.

For each risk, include:

* description
* affected workflow steps
* risk type:
    * technical
    * human factors
    * organizational
    * scientific / regulatory

Do not propose mitigations yet.

---

## 6. Automation Candidates (Preliminary)

List candidate automation units that appear plausible *in principle*.

For each candidate:

* scope (which workflow steps it covers)
* expected role (assistive / validating / replacing)
* critical assumptions that must hold true

These are *hypotheses*, not commitments.

---

## 7. Non-Candidates (Explicit)

Explicitly list:

* workflow elements that should **not** be automated at this stage
* elements that are unclear or too risky given current information

Explain why they are excluded.

---

## 8. Readiness for Architecture

Conclude with a short assessment:

* Is the problem sufficiently decomposed to begin architecture exploration?
* What unanswered questions still block design decisions?
* What assumptions would architecture be forced to make prematurely?

This section gates the transition to solution design.

---

## Stopping Condition

Stop after completing the above sections.

Do not:

* propose specific technical solutions
* design system architecture
* recommend algorithms, models, or tools

This document defines the automation boundary, not the solution.

---

## Intended Use

This artifact is meant to:

* serve as the bridge between problem definition and architecture
* constrain later design space
* justify human-in-the-loop decisions
* reduce the risk of over-automation

It should be frozen and referenced during all subsequent design and implementation
stages.

---

End of prompt.
