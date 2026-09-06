Below is a **clean, shareable, guide-style core document** structured exactly as requested. It is written to be reusable both as a personal operating manual and as a public-facing guide for early adopters of AI-assisted coding in problem-oriented projects.

---

# AI-Assisted Development for Problem-Oriented Learning Projects

This document provides a **practical methodology** for using modern AI systems as collaborators when entering a new technical domain with limited prior experience, while still producing a real, usable tool. The emphasis is on **learning through construction**, architectural discipline, and avoiding early lock-in to suboptimal approaches.

The guide is organized into:

1. Core principles
2. A workflow checklist
3. Reusable templates

---

## 1. Principles

### 1.1 Choose “training problems” that are solvable in principle

For early experience, avoid novelty for its own sake. Instead, select problems that:

* Are **well-known classes of problems** in the target field
* Have **established solution families**, even if no turnkey tool exists
* Are constrained enough that success is plausible with modest assumptions

The objective is not invention, but **competent reimplementation, adaptation, or simplification** of known techniques in a specific context.

---

### 1.2 Separate *problem definition* from *solution architecture*

Before discussing algorithms, clearly define:

* What problem is being solved
* Under what assumptions
* For whom
* With what notion of success

AI systems are very good at proposing solutions - but only if the problem is specified. Poor problem definition almost guarantees architectural drift.

---

### 1.3 Decompose into loosely coupled, artifact-driven blocks

Complex tasks should be split into **independent subtasks** with:

* Explicit input/output artifacts
* Minimal hidden dependencies
* Clear diagnostic outputs

This enables:

* Parallel experimentation
* Algorithm substitution
* Incremental hardening of the system

Avoid tightly coupled pipelines early.

---

### 1.4 Optimize for *information gain*, not elegance

Early stages are about answering feasibility questions, not producing polished code.

Prefer:

* Fast prototypes over clean abstractions
* Manual steps over premature automation
* Diagnostic outputs over performance

Only automate or optimize steps once their value is demonstrated.

---

### 1.5 Treat AI as a peer, not an oracle

AI should be used to:

* Propose alternatives
* Recall algorithms and design patterns
* Generate scaffolding and boilerplate
* Critically evaluate your ideas *when instructed to do so*

You remain responsible for:

* Architecture
* Acceptance criteria
* Failure definitions
* Test harnesses

Avoid letting AI’s first plausible solution become the default path.

---

### 1.6 Design the end product early

Even at prototype stage, decide:

* CLI vs GUI vs batch tool
* Single image vs dataset processing
* Required outputs and formats
* Distribution constraints (standalone binary, Python-only, etc.)

These decisions impose real constraints and should inform early design.

---

## 2. Workflow Checklist

This checklist can be followed linearly or revisited iteratively.

### Phase 0 - Problem Framing

* [ ] Write a one-page **Problem Contract**
* [ ] Define explicit success and refusal conditions
* [ ] Identify realistic constraints and assumptions

---

### Phase 1 - Decomposition

* [ ] Identify major subtasks
* [ ] Define block boundaries
* [ ] Specify input/output artifacts for each block
* [ ] Ensure blocks can be tested independently

---

### Phase 2 - Feasibility Probing

* [ ] Identify the most uncertain or fragile blocks
* [ ] Prototype them using the fastest viable approach
* [ ] Use off-the-shelf tools if they provide quick signal
* [ ] Save all intermediate artifacts

---

### Phase 3 - Diagnostic Hardening

* [ ] Add confidence metrics or residuals
* [ ] Define failure modes explicitly
* [ ] Produce visual/debug artifacts for each block
* [ ] Build a small curated test set

---

### Phase 4 - Integration

* [ ] Connect blocks through explicit artifacts
* [ ] Avoid hidden state or global assumptions
* [ ] Maintain reproducibility (logs, configs, seeds)

---

### Phase 5 - Packaging & Usability

* [ ] Implement CLI or UI entry point
* [ ] Define output directory layout
* [ ] Ensure outputs are interpretable by humans
* [ ] Document assumptions and failure cases

---

## 3. Templates

The following templates are designed to be copied directly into a repository and filled in.

---

### 3.1 Problem Contract Template

**Project Name:**
**Version:**

#### Problem Statement

What real-world problem is being solved?
Who experiences this problem, and why does it matter?

#### Inputs

* Image/data types:
* Acquisition assumptions:
* Typical variations:
* Known problematic cases:

#### Outputs

* Primary outputs:
* Intermediate artifacts:
* Machine-readable outputs:
* Human-readable diagnostics:

#### Success Criteria

* Quantitative thresholds:
* Qualitative expectations:
* Acceptable error bounds:

#### Refusal / Failure Conditions

* Conditions under which the system must return “no result”
* Conditions that invalidate outputs

---

### 3.2 Block Specification Template

**Block Name:**
**Responsibility:**

#### Inputs

* Artifact type(s):
* Required fields:
* Optional metadata:

#### Outputs

* Artifact type(s):
* Required fields:
* Confidence / quality indicators:

#### Assumptions

* Preconditions on inputs
* Environmental or data assumptions

#### Failure Modes

* Known failure cases
* Expected degradation behavior

#### Debug Artifacts

* Visual overlays
* Logs or residuals
* Summary statistics

---

### 3.3 Failure Taxonomy Template

Failures should be cataloged early and expanded continuously.

| Failure ID | Block          | Description     | Trigger           | Detection Signal    | Action |
| ---------- | -------------- | --------------- | ----------------- | ------------------- | ------ |
| F-001      | Grid Detection | Heavy occlusion | Organ covers >70% | Low grid confidence | Abort  |
| F-002      | Segmentation   | Low contrast    | Poor lighting     | Boundary entropy    | Warn   |

Guidelines:

* Prefer explicit failure over silent degradation
* Each failure should have a detection mechanism
* Each failure should define an action (abort / warn / fallback)

---

### 3.4 Run Output Layout Template

Define output structure **before** writing the pipeline.

```
outputs/
└── run_YYYYMMDD_HHMMSS/
    ├── input/
    │   └── original_image.jpg
    ├── preprocess/
    │   └── normalized.png
    ├── grid/
    │   ├── grid_overlay.png
    │   └── grid_metrics.json
    ├── geometry/
    │   ├── rectified.png
    │   └── homography.json
    ├── segmentation/
    │   ├── mask.png
    │   └── overlay.png
    ├── measurements/
    │   └── measurements.csv
    ├── qc/
    │   └── qc_report.json
    └── logs/
        └── run.log
```

Principles:

* Every major block produces at least one inspectable artifact
* Outputs must be deterministic and reproducible
* Directory names encode execution context, not interpretation

---

## Closing Note

This structure is intentionally conservative and process-heavy. That is a feature, not a bug. It trades short-term speed for:

* clearer learning
* easier debugging
* safer AI collaboration
* and a much higher chance of producing a usable tool

If you want, the next logical step is to **instantiate these templates specifically for your lab-photo analysis project**, producing a concrete `VISION.md`, `ARCHITECTURE.md`, and an initial block map tailored to your domain.
