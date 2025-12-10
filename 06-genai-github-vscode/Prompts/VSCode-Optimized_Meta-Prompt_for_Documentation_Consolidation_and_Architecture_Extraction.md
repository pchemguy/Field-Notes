https://chatgpt.com/c/69373bd1-b290-8326-80e3-48ca3f89790d

---

# **VSCode-Optimized Meta-Prompt for Documentation Consolidation and Architecture Extraction**

## **Purpose**

You must plan and execute a multi-stage workflow for consolidating documentation and reconstructing the architecture of the Java-based project, located in the current workspace.

You will propose workflows, generate documentation files, analyze source code, summarize components, and prepare the repository for downstream AI-assisted Python re-implementation.

All outputs must be created as files inside the repo, using VSCode agent abilities to write, update, and refine content.

---

# **1. Source Material Available to You**

### **Local Workspace (Primary Source):**

The repository contents, including:
* Java source code under `src/`
* Existing docs (if present)
* Any notes or partial documentation currently in the repo

### **External Documentation (Secondary Source):**

* ImageJ TrakEM2 plugin page - https://imagej.net/plugins/trakem2
* GitHub wiki - https://github.com/trakem2/TrakEM2/wiki
* Outdated manual - https://syn.mrc-lmb.cam.ac.uk/acardona/INI-2008-2011/trakem2_manual.html
* Fiji Javadoc (must filter by TrakEM2 classes) - https://javadoc.scijava.org/Fiji

You must fetch and analyze these autonomously.

---

# **2. Objectives (Agent-Facing)**

Your tasks are:

## **Stage 1 - Documentation Construction**

Create a coherent internal documentation corpus optimized for both:
* LLM agents, and
* Human engineers.

Documentation must be written to maximize downstream **code comprehension**, **architecture inference**, and **Python translation**.

Deliverables include:
* `docs/DESIGN.md`
* `docs/ARCHITECTURE.md`
* `docs/COMPONENTS.md`
* `docs/ALGORITHMS.md`
* `docs/API_MAPPING.md` (Java → conceptual → Python)
* `docs/AGENTS.md` (how LLMs should navigate the repo)
* `docs/DOCUMENTATION_PLAN.md`
* `docs/LEGACY_REFERENCES.md`

## **Stage 2 (Future): Interactive Exploration for Python Re-implementation**

Your documentation must prepare the repo so future VSCode agent workflows can:
* Answer architectural questions
* Generate Python equivalents of selected algorithms
* Produce wrappers, adapters, tests
* Explore code flow interactively

Stage 2 is not performed now; *prepare for it through Stage 1 outputs*.

---

# **3. Agent Constraints and Operating Mode**

* Use **file-level actions**: create, update, restructure, extract.
* Always propose a file-generation plan before writing.
* Use **minimal hallucination**; if information is missing, request clarification or source excerpts from the user.
* Use **incremental commits** (human-executed, but you propose the commit granularity).
* At every step, you must remain **repo-aware**: refer to directories, classes, and file paths accurately.

---

# **4. Core Tasks You Must Execute**

You must develop:

## **4.1. A Repo Documentation Pipeline**

You will generate a pipeline with explicit steps:
1. Workspace scan
2. Symbol extraction (packages, classes, interfaces)
3. High-level architecture reconstruction
4. Per-component summaries
5. Algorithm extraction
6. Cross-link Java classes with external docs
7. Documentation synthesis into canonical files
8. AI-targeted navigation guidance
9. Validation, refinement, and linking

## **4.2. A File Tree for Documentation**

You must propose and create:

```
docs/
    DESIGN.md
    ARCHITECTURE.md
    COMPONENTS.md
    ALGORITHMS.md
    API_MAPPING.md
    AGENTS.md
    DOCUMENTATION_PLAN.md
    LEGACY_REFERENCES.md
    _generated/         # optional scratch output
    _analysis/          # optional symbol maps, dependency graphs
```

## **4.3. Agent-Powered Code Analysis**

Perform tasks such as:
* Enumerate all packages and their responsibilities.
* Extract class-level summaries.
* Describe interactions between subsystems.
* Identify key algorithms and data structures.
* Write cross-references (class → file → role).

## **4.4. Prompt Templates for Reuse**

Generate generalized prompts that can be applied to any repo:
* “Scan workspace and generate subsystem map”
* “Extract execution flow for class X”
* “Generate algorithm summary for method Y”
* “Create architecture diagram description”
* “Generate a Python equivalent of subsystem Z (but do not implement now)”
* “Align repo content with external documentation”

These will be written into `docs/AGENTS.md`.

---

# **5. Required Output from the Agent in This Task**

Your output (as the agent) must be a **complete guide** that includes:

1. **A multi-phase workflow** for documentation synthesis
2. **A concrete set of steps the user should follow inside VSCode**
3. **When to use Agent Mode vs ChatGPT/Gemini in the browser**
4. **Prompts that the user should issue to the VSCode agent**
5. **The documentation structure and file definitions**
6. **A plan for iterative refinement and verification**
7. **A standard pattern applicable to other repositories**

This guide must instruct explicitly:
* what the agent does,
* what the user does,
* how files evolve across iterations.

The deliverable should be written as a structured technical document inside VSCode (usually as `docs/VSCODE_AGENT_WORKFLOW.md`).

---

# **6. How You Must Format Your Guide**

Your generated guide must include:

### **Section A — Workflow Overview**

A concise blueprint.

### **Section B — Step-by-Step Agent Workflow**

Precise actionable instructions.

### **Section C — File Generation Plan**

Exact file names and intended contents.

### **Section D — Agent Prompt Templates**

General-purpose prompts for multi-repo use.

### **Section E — Human-AI Collaboration Model**

Responsibilities by stage.

### **Section F — Refinement Pipeline**

How to iteratively improve docs through commits.

---

# **7. Tone & Style Requirements**

* Use **concise professional technical writing**.
* Reference agent operations explicitly (e.g., “Create file at path X”).
* Avoid speculative content.
* Use accurate references to workspace paths.
* Propose improvements, but do not unilaterally reorganize code.

---

# **8. Final Instruction to the Agent**

**Generate the complete documentation-creation guide described above, formatted as a standalone file (`docs/VSCODE_AGENT_WORKFLOW.md`).
Include multi-phase workflows, prompts, templates, file structures, and operating instructions.
Ensure that all workflows are directly runnable inside VSCode agent mode.**

---
