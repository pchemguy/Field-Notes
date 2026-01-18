## From Observed Problem to Implemented PoC / MVP 

### Conceptual stages

* exploration
* architecture
* refactors
* reviews
* greenfield development
* agent execution


## Precoding

### Observed Workflow -> Problem Formalization Prompt

This prompt converts an observed real-world human practice into a solution-agnostic, engineering-ready problem statement. It is intended for early-stage problem discovery, before feasibility analysis, architecture design, or technology selection. A core objective is to surface unknown-unknowns, overlooked constraints, and hidden decision criteria early, while changes are still cheap. This prompt deliberately suppresses solution thinking in order to reduce premature convergence and hidden assumptions.

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

### Problem Formalization -> Automation Boundary

This prompt consumes a completed `OBSERVED_PROBLEM.md` artifact and performs a structured decomposition of the observed workflow into automation candidates.

This stage sits between problem formalization and solution design.

Its purpose is to:

* identify what could be automated vs what should remain human
* expose feasibility risks without committing to solutions
* prevent premature end-to-end automation assumptions
* establish clear boundaries for later architectural work

This is the first stage where feasibility reasoning is allowed, but solution selection is still prohibited.

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

### Automation Boundary -> Architecture Space Exploration

This prompt explores possible system architectures that could satisfy the automation
candidates and constraints identified in `AUTOMATION_CANDIDATE_DECOMPOSITION.md`.

This stage intentionally does not select a solution.

Its goals are to:

* shape the solution space
* compare fundamentally different architectural approaches
* surface tradeoffs and risks early
* preserve optionality before commitment

This is the first solution-shaping step, but it remains pre-decisional.

### Architecture Selection and Justification

This document captures the final **architecture decision** for the automation system, based on the exploration conducted in `ARCHITECTURE_EXPLORATION.md`.

The goal is to:

* **select** one architecture candidate
* **justify** this selection relative to other candidates
* **explicitly document trade-offs**, assumptions, and reasons for commitment

This decision is **pre-implementation** and informs the next phase of detailed design, feasibility validation, and prototyping.

* You must **explicitly** justify your decision.
* For each candidate, you must document:
    * why it was **rejected** or **deferred**
    * why the selected architecture **outperforms** others relative to key criteria
* You **must not**:
    * select an architecture without justification
    * leave key trade-offs unaddressed
    * change or introduce new architecture candidates at this stage

### Feasibility Validation for Selected Architecture

This document outlines the **feasibility validation plan** for the selected architecture from `ARCHITECTURE_DECISION.md`.

Its goal is to:

* validate critical **assumptions**
* confirm that the selected architecture is technically and operationally feasible
* identify **showstopper risks** early
* ensure that further development is based on **solid, validated foundations**

This is a **pre-implementation** validation step and must be completed before any prototyping or full-scale implementation begins.

You are designing a **feasibility validation plan** for the selected architecture.

You must:

* reason about **core assumptions**, **risks**, and **uncertainties**
* design small, quick experiments to validate critical aspects of the architecture
* identify the **most important technical and operational uncertainties**
* propose methods to **validate or invalidate assumptions** before full implementation

You must not:

* design full-scale implementation
* define tool-specific solutions
* propose full prototyping or UI design
