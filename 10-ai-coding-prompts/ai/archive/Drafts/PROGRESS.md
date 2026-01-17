# PROGRESS.md

**Project Development Roadmap and Status**

---

## 1. Purpose of This Document

This file defines the **development roadmap**, **current status**, and **stage-level acceptance criteria** for the project.

It serves as:

- A **canonical progress ledger** for human contributors.
- A **navigation and grounding document** for AI agents.
- A **control mechanism** preventing uncontrolled refactoring of earlier-stage artifacts.

This is **not** a usage guide (see `README.md`) and **not** an agent instruction manual (see `AGENTS.md`).

---

## 2. Project Overview

### Objective

Develop a **user-friendly, standalone, non–machine-learning computer vision proof-of-concept (PoC)** tool that:

- Automatically analyzes **smartphone JPEG images** of a mouse spleen placed on **millimeter graph paper**
- Produces a **quantitative estimate of organ area**
- Emphasizes **reproducibility, transparency, and QC**, rather than black-box inference

The PoC is designed to support later evolution into a more robust application, but **early validation and feasibility** take priority over completeness.

---

### Inputs

- JPEG images acquired from smartphones
  (no assumptions on camera model or calibration beyond typical consumer devices)

---

### Outputs

For each processed image:

- Estimated organ area (physical units)
- Per-image artifacts:
    - Intermediate images
    - Masks
    - Image overlays
    - Statistical summaries
    - QC diagnostics

Additionally:

- A summary table mapping **input image → estimated organ area**

---

### Target Audience

- **End user:** Biologist or lab technician with no programming background
- **Deployment target:** Portable, standalone application
  (no Python runtime or external dependencies required by the end user)

---

## 4. Technology Stack (Development Phase)

- NumPy
- Matplotlib
- OpenCV
- Pillow
- SciPy
- Scikit-learn

(Note: deployment constraints are handled separately and are **not** enforced during PoC development.)

---

## 5. Project Organization and Artifact Discipline

Development is organized into **explicit roadmap stages**, each producing tangible artifacts.

Key principles:

- Each stage has **well-defined goals and deliverables**
- Stage outputs are treated as **read-only** during subsequent stages
  (refinement is allowed only with explicit justification)
- Outputs of a completed stage are placed under:

```
gridpet/src/gridpet/roadmap_stages_output/
```

Example structure:

```
GridPET/
├── AGENTS.md
├── PROGRESS.md  <- this file
├── README.md
├── docs/
├── drafts/
├── pyenv/
└── gridpet/
    ├── pytest.ini
    ├── tests/
    └── src/
        └── gridpet/
            └── roadmap_stages_output/
                ├── Stage 1 Report - Problem Positioning and High-Level Task Decomposition.md
                ├── Stage 2 Report - Feasibility Assessment.md
                ├── Stage 2 Artifacts/
                ├── Stage 3 Report - Initial Proof of Concept (PoC).md
                ├── Stage 3 Artifacts/
```

---

# Roadmap and Status

## Stage 1 - Problem Positioning and High-Level Task Decomposition

**Status:** Completed

### Scope

This stage establishes a shared conceptual foundation for the project by:

- Positioning the proposed solution within the relevant solution landscape, e.g.:
    - Automation of an existing manual or semi-manual workflow
    - Improvement or extension of existing automated approaches
    - Development of a fundamentally new analytical solution
- Defining **minimal viable objectives** versus **advanced objectives**
- Identifying evaluation dimensions relevant to early validation, such as:
    - Feasibility
    - Speed
    - Convenience
    - Accuracy
    - Reproducibility
- Decomposing the end-to-end problem into **high-level processing subtasks**
- Classifying subtasks and operations into:
    - **Essential** (required for a minimally useful PoC)
    - **Advanced** (deferrable without invalidating feasibility)

---

### Notes

- This stage is intentionally **analytical rather than implementation-focused**
- Subtask definitions should remain **technology-agnostic**
- The goal is to expose **problem-specific risk**, not to define a complete architecture
- Over-specification of generic or well-understood components should be avoided

---

### Outcome

Completion of this stage yields:

- A clear definition of what constitutes a **useful minimal PoC**
- A defensible separation between **core requirements** and **optional enhancements**
- An explicit list of **high-risk, problem-specific subtasks**
- A stable conceptual reference for subsequent feasibility and prototyping stages

---

### Deliverables

- One or more **project-specific analysis documents** (e.g., a Stage 1 Report) that:
    - Position the problem in context
    - Justify subtask prioritization
    - Identify essential versus advanced operations
- A documented high-level decomposition suitable for guiding feasibility assessment

This stage provides the conceptual inputs required for:

- **Feasibility Assessment**, where essential subtasks are validated experimentally
- **Initial Proof of Concept (PoC)** development, where validated subtasks are composed into a pipeline

No implementation artifacts are expected at this stage.

---

## Stage 2 - Feasibility Assessment

**Status:** Completed

### Scope

- Rapid implementation of **essential key operations**
- Validation that the core concept is technically viable

### Operating Principles

- Prefer the **fastest credible path to feasibility**
- Manual steps and external tools are acceptable if they:
    - Reduce implementation time
    - Do not undermine feasibility conclusions
- Advanced operations may be skipped if the truncated workflow remains meaningful

### Implementation Guidelines

- Scripts should be:
    - Standalone
    - Focused on a single subtask
    - Expect sample inputs residing alongside scripts
     - Executable via a standard:

```python
if __name__ == "__main__":
```

### Deliverable

- One or more **project-specific analysis documents** (e.g., a Stage 2 Report) that:
    - Provides a detailed implementation reference
    - Specification of produced artifacts
    - Defines specification of a PoC to be produced at Stage 3
- A directory of standalone scripts validating individual operations

This stage provides detailed inputs required for:

- **Initial Proof of Concept (PoC)** development, where validated subtasks are composed into a pipeline

---

## Stage 3 - Initial Proof of Concept (PoC)

**Status:** Queued

### Scope

- Integrate validated operations into a **semi-automatic end-to-end pipeline**
- Demonstrate a **minimal but coherent workflow**

### Deliverables

#### 1. Refined Operation Modules

- Derived from Stage 3 scripts
- Cleaned, parameterized, and reusable

#### 2. Integration Script

Responsibilities:

- Compose operations into a linear pipeline
- Create `./output/` directory if missing
- Emit **all artifacts** into that directory
- Enforce deterministic naming of intermediate outputs:
    - Source filename prefix
    - Two-digit sequential stage index
    - Short descriptive suffix

Example:

```
image01_03_grid_mask.png
```

Execution rules:

- Skip completed stages if outputs already exist and overwrite is not requested
- If a stage is re-run, all downstream artifacts must be regenerated

#### 3. Initial CLI Entry Point

- Accept:
    - A single image, or
    - A directory of images
- Invoke the integration pipeline
- Process each image independently

---
