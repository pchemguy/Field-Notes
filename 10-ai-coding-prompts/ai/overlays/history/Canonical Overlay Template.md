Below are the two artifacts you requested: a **canonical overlay template** and a **lint/checklist** to verify overlays do not violate the Cognitive Prime (and remain composable, backend-agnostic, and task-appropriate).

---

## 1) Canonical Overlay Template

Use this as the standard skeleton for every file in `ai/overlays/**`.

```
# TASK OVERLAY: <Overlay Name>

## PURPOSE

Describe what this overlay is for in 1–3 sentences.

* Intended task type(s):
    * <e.g., exploratory architecture, directed refactor, PR review, test generation>
* Typical outputs:
    * <e.g., decision memo, plan + patch, review comments, test suite>

## WHEN TO USE

Use this overlay when:

* <condition 1>
* <condition 2>

Do not use this overlay when:

* <condition 1>
* <condition 2>

## PRIORITIES

Rank what matters most for this task type (ordered list).

1. <Priority 1>
2. <Priority 2>
3. <Priority 3>

## SCOPE AND AUTHORITY

Define what the model is allowed to do in this task type.

* Allowed:
    * <e.g., propose alternatives, modify code, restructure modules, add tests>
* Not allowed:
    * <e.g., change public API, add dependencies, change behavior>
* Requires explicit approval:
    * <e.g., breaking changes, schema changes, performance tradeoffs>

## OPERATING RULES

Concrete rules specific to this task type. Keep these actionable and testable.

* <Rule 1>
* <Rule 2>
* <Rule 3>

Notes:

* Do not restate Cognitive Prime principles (assumptions, uncertainty, etc.).
* Rules should refine behavior for this task category, not define cognition.

## WORKFLOW

Provide an ordered process. Keep it short (5–10 steps).

1. <Step 1>
2. <Step 2>
3. <Step 3>

## STOP CONDITIONS

Define when the model must pause and ask for input.

Stop and ask if:

* <blocking ambiguity>
* <conflicting requirements>
* <risk threshold exceeded>

## OUTPUT CONTRACT

Define the expected response structure for this overlay (headings or bullets).

Recommended structure:

* <Section 1>
* <Section 2>
* <Section 3>

## COMPATIBILITY NOTES

State any constraints the overlay assumes.

* Language assumptions (if any): <none by default>
* Backend/tool assumptions (if any): <none by default>
* Repo assumptions (if any): <none by default>

## VERSION

* Overlay version: <e.g., 1.0>
* Last updated: <YYYY-MM-DD>
```

### Guidance for using the template

* Overlays should be **short** (typically 1–2 pages).
* If you need heavy detail, move it into:
    * a task packet template in `ai/packets/templates/`, or
    * a backend adapter in `ai/adapters/`.

---

## 2) Overlay Lint Checklist

This is a concrete checklist you can apply manually, or later automate as a simple markdown linter.

### A) Prime Compatibility: Non-Contradiction

An overlay **fails** if it:

* ☐ Re-instructs “how to think” in generic terms (e.g., “think carefully,” “use first principles,” “ask clarifying questions”) instead of task-specific rules
* ☐ Forces a universal ritual (e.g., “always produce a blueprint/file tree”) rather than conditioning it on scope/complexity
* ☐ Requires the model to invent missing details (“assume X/Y/Z without labeling assumptions”)
* ☐ Demands premature optimization as a general rule
* ☐ Makes the assistant adversarial by default (“challenge everything,” “always propose alternatives”)
* ☐ Reopens settled decisions without new information (contradicts “suspend once chosen”)

### B) Abstraction Level: Overlay vs Packet vs Adapter

An overlay **fails** if it includes:

* ☐ Backend/UI operational instructions (belongs in `ai/adapters/`)
    Examples: “click X,” “open PR,” “use tool Y,” quota handling, IDE keystrokes
* ☐ Task-instance specifics (belongs in a task packet)
    Examples: exact file paths, exact commands for a specific repo task, specific bug context
* ☐ Language-specific style rules in a general overlay (unless overlay is explicitly language-scoped)

### C) Composability and Override Hierarchy

Overlay **passes** only if:

* ☐ It explicitly defines what it is modulating (purpose / when to use)
* ☐ Its constraints are compatible with both:
    * interactive use, and
    * agent execution (unless it explicitly says otherwise)
* ☐ It does not introduce conflicting authority with packets
    (overlay should not hardcode scope fences; packets own concrete scope)
* ☐ It uses “Requires explicit approval” for things that often vary by task

### D) Task Fitness: Does it Produce the Intended Behavior?

Overlay **fails** if:

* ☐ Priorities are not ordered (so the model cannot trade off under constraints)
* ☐ Stop conditions are missing or vague
* ☐ Output contract is missing (leads to inconsistent responses)
* ☐ Rules are untestable (“be robust,” “write clean code”) without operational definition
* ☐ It mandates contradictory goals (e.g., “maximal refactor” + “minimal diffs”)

### E) Minimal Duplication / Prompt Entropy Controls

Overlay **passes** only if:

* ☐ It is under ~500–800 lines (practically: under ~2 pages)
* ☐ It contains no repeated boilerplate that should live in the Prime
* ☐ It includes a version tag and update date
* ☐ It does not include deprecated “brand phrases” that trigger verbosity (“elite,” “chain-of-thought,” etc.)

---

## 3) Optional: A Simple “Overlay Lint Score”

If you want a quick quantitative rubric:

* Prime compatibility (0–5)
* Abstraction correctness (0–5)
* Composability (0–5)
* Task fitness (0–5)
* Entropy control (0–5)

Any overlay scoring **<20/25** should be revised before reuse.

---

## 4) Next Practical Step

If you paste **one overlay draft** (even rough), I will:

* rewrite it into the canonical template
* run the lint checklist on it
* propose revisions that improve composability and reduce prompt entropy
