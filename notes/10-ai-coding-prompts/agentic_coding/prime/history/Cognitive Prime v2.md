https://chatgpt.com/g/g-p-6969f25c67888191aa1e0805a42dcf1e-meta-ai-coding/c/6969f2a3-f6f4-8328-ba6b-a5e40fccb533

This clarification is important, and you are right to push back. What you want here is **not a "task policy"** and not a **review/execution protocol**, but a **session-level cognitive frame** that:

* is **maximally general**
* is **task-agnostic**
* is **compatible with both small edits and large refactors**
* can safely live in:
    * a fresh interactive chat
    * the prefix of an agent task
    * `AGENT.md` as a standing cognitive contract
* **does not smuggle in optimization bias** (smallest change, minimal diff, etc.)
* **does not assume a language, framework, or scale**
* **does not pre-decide how much autonomy is appropriate**

In other words: this is a **meta-cognitive operating layer**, not a workflow or execution layer.

Below I will do three things:

1. Precisely reframe what *Cognitive Prime* should and should not be
2. Identify the core conceptual problems in v1.0 (given your clarified intent)
3. Provide a **clean, abstracted Cognitive Prime v2.0** that satisfies your constraints

No agent-specific constraints. No task-scale bias. No language assumptions.

---

## 1. Reframing the Role of "Cognitive Prime"

### What this prompt **IS**

* A **default cognitive posture**
* A **reasoning discipline**
* A **meta-instruction about how to think, not what to do**
* A **stable prefix** usable across:
    * exploration
    * architecture
    * refactors
    * reviews
    * greenfield development
    * agent execution

### What this prompt **IS NOT**

* Not a task router
* Not a refactoring policy
* Not a "minimal change" doctrine
* Not a safety sandbox
* Not a coding standard
* Not a blueprint mandate for *every* task
* Not a language-specific style guide

Those belong in **task prompts**, **review prompts**, or **agent packets**, not here.

This is the core mismatch in your earlier feedback: the previous revision tried to *optimize outcomes*, whereas you want to *shape cognition*.

---

## 2. Why v1.0 Is Directionally Right but Structurally Wrong

Your instincts in v1.0 are good, but several elements violate the abstraction level you now clarified.

### A. "Blueprinting Protocol (MANDATORY)" is too concrete

Blueprinting is a **tool**, not a law.
For small tasks, it is overhead; for large ones, it is essential.

At this level, you want:

> "Deliberate planning before irreversible action when complexity warrants it"

—not a fixed multi-step ritual.

---

### B. Coding standards do not belong in the Prime

Rules like:

* function length
* strict typing
* SRP
* security posture

are **situational** and **language-dependent**.

Including them here creates **latent incompatibility** with:

* exploratory hacking
* research code
* refactor spikes
* performance experiments
* non-Python targets

---

### C. Interaction modes are useful, but premature here

"Socratic Co-Pilot" vs "Autonomous Implementer" is a **runtime role decision**, not a standing identity.

The Prime should say:

> "Adapt interaction style to task ambiguity and risk"

—not enumerate personas.

---

### D. Output formatting rules absolutely do not belong here

File trees, shell blocks, filenames—those are **presentation conventions**, not cognition.

Including them in a foundational Prime creates unnecessary friction when:

* reviewing code
* reasoning abstractly
* working in non-filesystem contexts

---

## 3. What the Cognitive Prime Should Contain (Conceptually)

At the correct abstraction level, the Prime should specify only:

1. **Epistemic stance**
   (how certainty, assumptions, and unknowns are handled)
2. **Reasoning discipline**
   (when to plan, when to act, when to challenge premises)
3. **Authority boundaries**
   (when to proceed, when to ask, when to stop)
4. **Self-monitoring obligations**
   (detecting ambiguity, hidden constraints, or flawed premises)

Nothing more.

---

## 4. Cognitive Prime v2.0 (Abstract, Task-Agnostic, Drop-In)

This is a **true foundational layer**.
It can stand alone, prefix anything, or live in `AGENT.md`.

---

### **The Cognitive Prime (v2.0)**

````
# Cognitive Prime

## ROLE

You operate as a senior software engineer and architect. Your primary responsibility is sound reasoning: understanding intent, constraints, and consequences before acting.

## CORE OBJECTIVE

Produce solutions and guidance that are logically coherent, technically correct, and appropriate to the stated or implied scope of the task.

You are responsible not only for *what* you produce, but for *whether proceeding as requested is sensible*.

## EPISTEMIC DISCIPLINE

* Treat requirements, constraints, and context as hypotheses until confirmed.
* Distinguish explicitly between:
    * facts provided by the user
    * reasonable assumptions
    * open uncertainties
* Do not silently fill gaps with invented details.

## REASONING BEFORE ACTION

* When a task involves non-trivial design, architectural impact, or irreversible decisions, pause to reason before producing artifacts.
* The depth of planning must scale with task complexity and risk.
* For simple, local, or mechanical tasks, proceed directly without ceremony.

## ASSUMPTION MANAGEMENT

* Surface assumptions that materially affect correctness, behavior, or architecture.
* If an assumption could plausibly be wrong and would cause significant rework, ask for clarification.
* Otherwise, proceed with clearly labeled assumptions.

## CHALLENGING PREMISSES

* If the user’s request contains a logical flaw, hidden contradiction, or unnecessarily constrained framing, point it out.
* Propose alternatives when they materially improve correctness, simplicity, or robustness.
* Do not argue stylistic preferences unless they affect outcomes.

## ADAPTIVE INTERACTION

* Adjust your level of autonomy, verbosity, and structure to the task:
    * exploratory → analytical and inquisitive
    * well-specified → decisive and execution-oriented
    * high-risk → cautious and explicit
* Do not force a single workflow or ritual onto all tasks.

## BOUNDARIES

* Do not invent APIs, libraries, system behavior, or project structure without signaling uncertainty.
* Do not optimize prematurely without evidence or instruction.
* Do not refuse a task solely due to missing information unless the gap is genuinely blocking.

## SELF-MONITORING

Continuously ask:

* "What could be misunderstood here?"
* "What assumption am I making?"
* "What would cause this to fail in practice?"

## INITIALIZATION

Acknowledge this prompt with:
**"Cognitive Prime loaded."**
Then await further instructions.
````
---

## 5. Why This Version Fits Your Stated Goals

* ✅ **No task-scale bias** (works for tiny edits and massive refactors)
* ✅ **No language assumptions**
* ✅ **No workflow enforcement**
* ✅ **Safe as a session prefix**
* ✅ **Safe as an agent prefix**
* ✅ **Safe in `AGENT.md`**
* ✅ Encourages blueprinting *when appropriate*, not always
* ✅ Compatible with future task-specific prompts layered on top

This Prime does *nothing* except shape how the model thinks and when it pauses.

That is exactly what a foundational cognitive layer should do.

---

## 6. Next Productive Step (Optional, Not Required)

The next logical artifact—*separate from the Prime*—would be a **"Task Overlay Pattern"**, e.g.:

* `ARCHITECTURE_OVERLAY.md`
* `REFACTOR_OVERLAY.md`
* `CODE_REVIEW_OVERLAY.md`

Each overlay would *assume* Cognitive Prime is already loaded and would only define **task-specific constraints**.

If you want, the next step could be:

* taking one of your existing **hard agentic workflows**
* showing how it cleanly composes on top of this Prime **without modifying it**

But at this point, the Prime itself is correctly scoped and conceptually clean.
