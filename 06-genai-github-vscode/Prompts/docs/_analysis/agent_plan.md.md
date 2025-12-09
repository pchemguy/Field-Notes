# **agent_plan.md**

```
docs/_analysis/agent_plan.md
```

# **AI Agent Planning File**

*Stage 1 Documentation & Architecture Reconstruction — TrakEM2 Fork*

This file maintains the agent’s **explicit planning state**, **task lists**, **phase statuses**, and **open questions**.
It is the central coordination document for all VSCode AI agent operations on this repository.

Human and AI agents should review and update this file continuously.

---

# **0. Repository Overview (To Be Filled After Phase 0 Scan)**

**Workspace Summary:**

* Project root:
* Identified source directories:
* Existing documentation directories:
* Observed major modules:
* Notes / uncertainties:

(These fields will be filled by the agent after Phase 0 initial reconnaissance.)

---

# **1. Workflow Phases & Completion Status**

This project follows a structured 8-phase workflow.
Check off phases as they are executed.

## **Phase 0 — Repository Reconnaissance**

* [ ] Scan directory structure
* [ ] Identify Java source roots
* [ ] Locate any existing documentation
* [ ] Summarize findings into this file

**Notes:**
(Agent will populate.)

---

## **Phase 1 — Symbol Extraction & Package Map**

* [ ] Enumerate all Java packages
* [ ] List classes, interfaces, enums
* [ ] Add short responsibility notes
* [ ] Identify candidate subsystems
* [ ] Write results to `symbol_map.md`
* [ ] Update status & open questions here

## **Phase 1 Open Questions:**

*

---

## **Phase 2 — Architecture Reconstruction**

* [ ] Identify subsystems and major functional blocks
* [ ] Describe subsystem responsibilities
* [ ] Document data flows & entry points
* [ ] Build execution flows for core classes
* [ ] Write initial `ARCHITECTURE.md`
* [ ] Record knowledge gaps

## **Phase 2 Open Questions:**

*

---

## **Phase 3 — Component Documentation**

* [ ] Summarize key components in `COMPONENTS.md`
* [ ] Document inputs/outputs
* [ ] Describe cross-component interactions
* [ ] Identify unclear or highly coupled areas

## **Phase 3 Open Questions:**

*

---

## **Phase 4 — Algorithm Documentation**

* [ ] Identify algorithm-heavy classes
* [ ] Document each algorithm: purpose, inputs, outputs, invariants
* [ ] Organize findings in `ALGORITHMS.md`
* [ ] Mark potential Python-translation candidates

## **Phase 4 Open Questions:**

*

---

## **Phase 5 — API Mapping (Java → Conceptual → Python)**

* [ ] Enumerate major Java API surfaces
* [ ] Provide conceptual descriptions
* [ ] Propose Python abstractions
* [ ] Document in `API_MAPPING.md`

## **Phase 5 Open Questions:**

*

---

## **Phase 6 — Agent Navigation & Interaction Guidance**

* [ ] Create AI guidance in `AGENTS.md`
* [ ] Add prompt templates for future agents
* [ ] Describe documentation map
* [ ] Provide instructions for Python re-implementation workflows

## **Phase 6 Open Questions:**

*

---

## **Phase 7 — External Documentation Integration**

* [ ] Integrate ImageJ plugin page excerpts
* [ ] Integrate GitHub wiki excerpts
* [ ] Integrate legacy manual content
* [ ] Integrate Fiji Javadoc excerpts
* [ ] Create `LEGACY_REFERENCES.md`
* [ ] Cross-link internal & external docs

## **Phase 7 Open Questions:**

*

---

## **Phase 8 — Refinement Cycles**

Repeat until documentation is complete and consistent.

* [ ] Re-scan code for missing elements
* [ ] Refine architecture and component docs
* [ ] Expand algorithm descriptions
* [ ] Align API mapping with architecture
* [ ] Suggest commit boundaries & repository improvements

## **Pending Refinements:**

*

---

# **2. Current Active Goals**

(Agent fills this dynamically as tasks progress.)

* **Active Phase:**
* **Short-term focus:**
* **Blocking dependencies:**
* **Tasks awaiting user input:**

---

# **3. High-Priority Questions for User**

(Add questions agent needs answered, e.g., external doc excerpts.)

*
*

---

# **4. Running Task List (Actionable Items)**

### Immediate Tasks (Next 1–3 Agent Actions)

*
*

### Medium-Term Tasks

*
*

### Long-Term Tasks

*
*

---

# **5. Knowledge Gaps Identified**

(Cross-link with symbol_map, components, algorithms, architecture.)

*
*

---

# **6. Risk Areas & Uncertainty Notes**

Document locations where behavior or architecture is unclear.

* `[UNCERTAIN]`
* `[NEEDS VERIFICATION]`
*

---

# **7. Revision History**

| Date | Agent | Action Summary           |
| ---- | ----- | ------------------------ |
|      |       | Created initial skeleton |

---

# **End of agent_plan.md**

---
