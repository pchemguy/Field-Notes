https://chatgpt.com/c/69373bd1-b290-8326-80e3-48ca3f89790d

---

# **Meta-Prompt**

## **Purpose of This Meta-Prompt**

You (the AI) must design a **comprehensive, multi-stage workflow** for generating consolidated documentation, analysis, and derivative Python re-implementations of a complex Java ImageJ plugin codebase (TrakEM2).
This workflow must leverage human–AI collaboration and a combination of ChatGPT Plus, OpenAI Codex (VSCode), Gemini Pro, and Gemini Code Assist.

The output from this task should be a **guide** describing proposed pipelines, workflows, stages, and artifacts, including well-formed generalized prompts, templates, and file structures that can be reused for other repositories.

---

# **1. Source Context**

The target repository is a Java-based ImageJ plugin:

**Primary Repository:**
[https://github.com/trakem2/TrakEM2](https://github.com/trakem2/TrakEM2)

**Documentation Sources:**

1. ImageJ plugin page – [https://imagej.net/plugins/trakem2](https://imagej.net/plugins/trakem2)
2. GitHub wiki – [https://github.com/trakem2/TrakEM2/wiki](https://github.com/trakem2/TrakEM2/wiki)
3. Outdated manual – [https://syn.mrc-lmb.cam.ac.uk/acardona/INI-2008-2011/trakem2_manual.html](https://syn.mrc-lmb.cam.ac.uk/acardona/INI-2008-2011/trakem2_manual.html)
4. Fiji Javadoc (needs filtering for TrakEM2 classes) – [https://javadoc.scijava.org/Fiji](https://javadoc.scijava.org/Fiji)

The documentation is incomplete, fragmented, partially outdated, and inconsistent in format.
Your (the AI’s) job is to propose a workflow that consolidates, updates, restructures, and integrates all available information.

---

# **2. Objectives**

## **Stage 1 — Documentation & Repository Augmentation**

Develop a **fully consolidated and comprehensive documentation set** within a forked repository.
This documentation must be suitable for:

* **AI agents** (primary target)
* **Human engineers and researchers**

The documentation must be designed so that LLMs can understand the architecture, data flows, algorithms, and module interactions robustly and efficiently.
Required outputs include, but are not limited to:

* **DESIGN.md**
* **ARCHITECTURE.md**
* **COMPONENTS.md**
* **ALGORITHMS.md**
* **API_MAPPING.md** (Java → conceptual → Python)
* **AGENTS.md** (LLM guidance for interactive repo exploration)
* **DOCUMENTATION_PLAN.md**
* **CONTRIBUTING_GUIDE_FOR_LLMs.md**

## **Stage 2 — AI-Assisted Interactive Exploration & Re-implementation**

Enable workflows where the user interacts conversationally with ChatGPT, Codex, Gemini, or Code Assist to:

* Explore the repo interactively
* Ask about code structure, method behavior, data models
* Request Python re-implementations of selected features
* Generate tests, adapters, wrappers
* Produce modernized pipelines based on classical algorithms

The documentation produced in Stage 1 must be optimized for these interactive workflows.

---

# **3. Available Tools**

You (AI) must design workflows that leverage:

### **LLMs**

* ChatGPT Plus
* Gemini Pro

### **Editor Integrations**

* OpenAI Codex Extension for VSCode
* Gemini Code Assist Extension for VSCode

### **Agent Systems**

* VSCode "Build with Agent" sidebar
* Any agentic features supporting code refactoring, exploration, symbol indexing, or documentation synthesis

### **Deep Research Mode**

You may assume the ability to issue multi-step research queries to gather and synthesize:

* Information from the repository
* Information from external documentation
* Architectural patterns
* Missing API details

---

# **4. Task for the AI**

Develop a **comprehensive guide** that proposes **pipelines and workflows** for achieving **Stage 1**, using the available tools.

The guide must include:

1. **A high-level blueprint**
   Structured overview of the multi-phase pipeline.
2. **A detailed procedural workflow**
   Step-by-step operational plan with human-AI collaboration loops.
3. **AI prompt templates**
   Generalized prompts reusable across other repositories and languages.
4. **Documentation structure**
   List and description of repo files to be created (e.g., DESIGN.md, ARCHITECTURE.md).
5. **Methods for integrating multiple sources**
   (repo code + wiki + external manuals + Fiji Javadoc).
6. **Quality and completeness criteria**
   What "adequate documentation for AI agents" actually means.
7. **Operational guidance for using VSCode agents**
   When to use Code Assist vs Codex vs ChatGPT web.
8. **Methods for incremental refinement**
   Iterative documentation cycles with version control.
9. **AI guardrails**
   Handling hallucinations, missing information, incorrect assumptions.
10. **A generic pipeline applicable to other projects**
    The prompt must generalize beyond TrakEM2.

The output must be **self-contained**, allowing any LLM to generate a complete actionable guide.

---

# **5. Required Deliverables in the Guide**

The guide produced by the AI must include:

## **5.1. Pipeline Breakdown**

* Discovery phase
* Documentation harvesting phase
* Architecture reconstruction phase
* Code-to-document alignment
* Cross-linking across Java sources and legacy docs
* LLM-based consolidation
* Repo augmentation and commit plan
* Cycles of refinement and verification

## **5.2. Example Deep Research Prompts**

Include generalized templates such as:

* “Consolidate all available documentation into a canonical spec.”
* “Generate an architecture diagram textual description from source code.”
* “Build a function-level map of responsibilities and interactions.”
* “Extract all algorithms and data models; summarize inputs and outputs.”
* “Explain the execution flow for feature X with cross-references to source files.”

## **5.3. Templates for Documentation Artifacts**

Provide canonical structures for:

### DESIGN.md

High-level conceptual design, goals, constraints.

### ARCHITECTURE.md

Subsystems, modules, threading model, data flow, API boundaries.

### API_MAPPING.md

Mapping between Java APIs and conceptual Python equivalents.

### COMPONENTS.md

Component-level responsibilities.

### AGENTS.md

Guidelines for LLM agents:
How to explore, what conventions to expect, how to interpret folder structure.

### DOCUMENTATION_PLAN.md

Work plan for incremental updates.

### LEGACY_REFERENCES.md

Links and notes on outdated manuals.

## **5.4. Agent Prompts for VSCode Codex / Code Assist**

Templates such as:

* “Scan this directory and produce a symbolic map of classes and dependencies.”
* “Extract the execution flow of class X and express it as structured pseudocode.”
* “Translate Java class Y into idiomatic Python while preserving algorithmic behavior.”

## **5.5. Versioning & Repository Integration Plan**

Recommendations for commit structure, e.g.:

* docs/
* docs/_sources
* docs/_ai_guidance
* docs/_research
* docs/_legacy
* etc.

---

# **6. Expected Output Format**

The response from the AI to this meta-prompt must be:
1. **A complete guide**
   (detailed, procedural, and structured)
2. **Multi-section**
   Including pipelines, prompts, templates, file definitions, operational instructions.
3. **Applicable beyond TrakEM2**
   Generalizable patterns and methods.
4. **Executable**
   Something I can apply immediately to start Stage 1.

---

# **7. Tone & Style Requirements**

* Professional, technical, and explicit.
* Zero ambiguity about steps or expectations.
* No unnecessary verbosity.
* No casual explanations.
* Every workflow step must state **who acts** (human or AI) and **how**.

---
