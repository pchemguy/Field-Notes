# **Git Commit Plan for Stage 1 Documentation**

*TrakEM2 Architecture Reconstruction & Documentation Consolidation*

This document defines recommended commit granularity and commit messages for maintaining clear history while collaborating with VSCode AI agents.

---

# **1. Principles**

* **Small, atomic commits.**
  Each commit should correspond to a discrete agent operation or documentation unit.

* **Group by conceptual change, not file count.**
  For example:

  * “Added initial symbol map”
  * “Drafted subsystem architecture”
  * “Added algorithm summaries for XYZ”

* **Avoid mixing planning with documentation changes.**
  `agent_plan.md` updates may be included with the tasks they describe, but not with unrelated edits.

* **Commit after every successful phase or sub-phase.**

* **Never commit hallucinated content without review.**
  Human must validate agent-generated text.

---

# **2. Recommended Commit Sequence (Stage 1)**

Below is the recommended commit progression.

### **Commit 1 — Create Analysis Framework**

* Create `docs/_analysis/agent_plan.md`
* Create `docs/_analysis/symbol_map.md` skeleton
* Create all other empty documentation skeletons in `docs/`

**Recommended commit message:**

```
Initialize documentation framework and analysis skeletons for Stage 1
```

---

### **Commit 2 — Workspace Reconnaissance**

* Add Phase 0 output to `agent_plan.md`
* Populate initial directory/package overview

**Commit message:**

```
Add Phase 0 repository reconnaissance summary
```

---

### **Commit 3 — Initial Symbol Map**

* Populate symbol_map.md with initial package+class enumeration
* Add open questions to agent_plan.md

**Commit message:**

```
Add initial Java package and class enumeration to symbol_map.md
```

---

### **Commit 4 — Subsystem Identification**

* Update symbol_map.md with subsystem groupings
* Create/update COMPONENTS.md skeleton with discovered components

**Commit message:**

```
Identify preliminary subsystems and update COMPONENTS.md structure
```

---

### **Commit 5 — Architecture Draft**

* Generate first draft of ARCHITECTURE.md
* Add execution flow notes in `_analysis/execution_flows.md`

**Commit message:**

```
Add initial architecture reconstruction and execution flow outlines
```

---

### **Commit 6 — Component Documentation Pass**

* Populate COMPONENTS.md with component blocks
* Add dependencies, interactions, and data structures

**Commit message:**

```
Add component-level documentation and interaction notes
```

---

### **Commit 7 — Algorithm Documentation Pass**

* Populate ALGORITHMS.md
* Cross-link algorithms to components

**Commit message:**

```
Add algorithm inventory and structured algorithm documentation
```

---

### **Commit 8 — API Mapping**

* Create or expand API_MAPPING.md
* Add Java → Conceptual → Python mapping entries

**Commit message:**

```
Add Java-to-Python conceptual API mapping and translation notes
```

---

### **Commit 9 — Agent Navigation Guide**

* Populate AGENTS.md with prompt templates and exploration strategy

**Commit message:**

```
Add AI agent navigation guidance and prompt templates
```

---

### **Commit 10 — External Documentation Integration**

* Add LEGACY_REFERENCES.md
* Insert human-provided excerpts and cross-links

**Commit message:**

```
Integrate external documentation sources and cross-link references
```

---

### **Commit 11 — Refinement Cycle 1**

* Update architecture and components with clarifications
* Resolve uncertainties noted in agent_plan.md

**Commit message:**

```
Refine architecture, components, and algorithm sections; resolve initial gaps
```

---

### **Commit 12 — Refinement Cycle N**

Repeat as needed.
Changes typically include:

* Clarifying ambiguous behavior
* Improving cross-document consistency
* Adding new insights from code review

**Commit message template:**

```
Refine documentation (Cycle N): <brief items>
```

---

# **3. Commit Boundaries for Agent Mode**

When using the VSCode AI agent, commits should ideally be performed:

* After each major file update or set of related updates
* After each phase’s completion
* After resolving major uncertainties
* Before switching tasks (to avoid merging unrelated work)

---

# **4. Tagging & Branching Suggestions**

Optional enhancements:

* **Branch `stage-1-docs`** for the entire tracing effort.
* Tag major milestones:

  * `stage-1-phase-1-complete`
  * `stage-1-architecture-draft`
  * `stage-1-ready-for-stage-2`

---

