Problem statement articulation
Primary target audience
Possibly, core workflow candidates
General constraints/restrictions

---
    * exploration
    * architecture
    * refactors
    * reviews
    * greenfield development
    * agent execution


### Problem Framing

* [ ] Write a one-page **Problem Contract**
* [ ] Define explicit success and refusal conditions
* [ ] Identify realistic constraints and assumptions

---

### Decomposition

* [ ] Identify major subtasks
* [ ] Define block boundaries
* [ ] Specify input/output artifacts for each block
* [ ] Ensure blocks can be tested independently

---

### Feasibility Probing

* [ ] Identify the most uncertain or fragile blocks
* [ ] Prototype them using the fastest viable approach
* [ ] Use off-the-shelf tools if they provide quick signal
* [ ] Save all intermediate artifacts

---

### Diagnostic Hardening

* [ ] Add confidence metrics or residuals
* [ ] Define failure modes explicitly
* [ ] Produce visual/debug artifacts for each block
* [ ] Build a small curated test set

---

### Integration

* [ ] Connect blocks through explicit artifacts
* [ ] Avoid hidden state or global assumptions
* [ ] Maintain reproducibility (logs, configs, seeds)

---

### Packaging & Usability

* [ ] Implement CLI or UI entry point
* [ ] Define output directory layout
* [ ] Ensure outputs are interpretable by humans
* [ ] Document assumptions and failure cases




### Define the Problem Contract Before Any Architecture

Before “solution approaches”, write a **problem contract** - one page maximum.

#### Inputs (what you will accept)

* image types (JPG/PNG/HEIC), resolution ranges
* capture conditions assumed vs optional
* allowed occlusions (organs cover grid heavily?)
* typical failure sources (wrinkles, glare, blood stains, shadows)

#### Outputs (what you will produce)

* final measurements (e.g., area mm², length mm, color stats)
* intermediate artifacts (rectified image, detected grid overlay, masks)
* machine-readable outputs (CSV/JSON)
* QC report (pass/warn/fail, reasons)

#### Success criteria

Define “done” in testable terms:

* grid reprojection error threshold
* segmentation boundary quality on a small labeled set
* tolerance to specified acquisition variability

This contract becomes your anchor against “AI drift” and “architecture inflation”.

---

### Decompose Into Loosely Coupled Blocks With Explicit Artifacts

Critical strategy: split into subproblems with minimal coupling and clearly defined I/O. Formalize it.


#### Artifact-driven design

Each block must have:

* input artifact type (e.g., `RectifiedImage`, `GridModel`)
* output artifact type
* minimal contract fields (including confidence / residuals)
* a debug visualization that can be saved deterministically

This single practice prevents the most common failure mode in AI-assisted projects: a fast-growing pile of “works on my one image” code with no clear seams.

---

### Feasibility Probing

Consider that some steps are important but not urgent. The correct ordering is determined by **information gain per unit time**, not by conceptual centrality.

#### Identify “gating uncertainties”

Early on, you are not optimizing; you are answering binary questions:

* Can grid detection work under real occlusion?
* Can you rectify to a stable mm scale?
* Can segmentation be reliable enough for measurement?

#### Prototype the hardest step with the least engineering

Use the fastest path to a feasibility verdict:

* manual preprocessing using off-the-shelf tools is acceptable early
* integrate an existing algorithm implementation if it gives you quick signal
* tolerate ugly scripts as long as they produce traceable artifacts

#### Avoid premature automation of supportive steps

If preprocessing is “obviously needed”, prove that it changes outcomes materially before building a full automated preprocessing pipeline.

A practical rule:

* If you cannot quantify its impact in a small test, do not automate it yet.

---

### Packaging and Deployment

- Python Packaging Approach
- CLI and GUI
- Web API
- Client / Server components

