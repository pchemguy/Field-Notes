Good—this is the right point to focus on **composition**, because if the Prime cannot be cleanly composed with harder, more directive prompts *without modification*, then it is not truly foundational.

Below I will be very explicit and concrete.

---

## 1. What "clean composition on top of the Prime" actually means

A prompt **cleanly composes** on top of the Cognitive Prime if:

1. It **does not restate or override** cognitive principles already covered
2. It **adds constraints only at a lower abstraction level**
3. It assumes the Prime is already loaded and **relies on it implicitly**
4. It never needs to "undo" Prime instructions (this is the failure mode you want to avoid)

In software terms:

* **Cognitive Prime = base class / interface contract**
* **Task prompts = subclasses / strategy objects**
* No task prompt should reimplement or contradict base behavior

---

## 2. What the Prime guarantees to downstream prompts

Because of v2.1, downstream prompts can **assume** the following without restating them:

* The model will:
    * surface assumptions
    * notice ambiguity
    * scale planning to risk
    * challenge flawed premises when it matters
    * adapt autonomy level appropriately
* The model will **not**:
    * invent missing facts silently
    * force rituals (blueprints, file trees, etc.)
    * reopen decisions after confirmation
    * over-optimize prematurely

This means task prompts can be **aggressively directive** without becoming brittle.

---

## 3. Composition pattern: "Overlay, don’t replace"

A well-composed task prompt has exactly three layers:

```
[ Cognitive Prime ]   ← already loaded, untouched
[ Task Overlay ]     ← what kind of work this is
[ Task Instance ]    ← what to do this time
```

Only the **middle layer** varies per workflow.

---

## 4. Example: Exploratory Architecture Overlay (Clean Composition)

Notice what this prompt **does NOT do**:

* It does not explain how to think
* It does not restate epistemic rules
* It does not say "ask questions" in general terms
* It does not define personas

It only **amplifies** behaviors already enabled by the Prime.

### Exploratory Architecture Overlay

```
## TASK OVERLAY: Exploratory Architecture

This task is an early-stage architectural exploration.

Focus on:

* identifying decision axes and tradeoffs
* surfacing hidden constraints and unknowns
* expanding the design space before convergence

Explicitly:

* enumerate alternative approaches where materially different
* highlight long-term implications and irreversible choices
* call out assumptions that could invalidate an approach later

Do not:

* commit to a single solution prematurely
* produce detailed implementation code
* optimize for performance or micro-level concerns unless they affect architecture

Output structure (suggested, not mandatory):

* Problem restatement
* Known constraints
* Unknowns / risks
* Architecture options (with tradeoffs)
* Recommendations and open questions
```

Why this composes cleanly:

* It **assumes** peer-level reasoning exists (Prime)
* It **tilts** behavior toward exploration
* It does not forbid later convergence
* It does not override autonomy rules

---

## 5. Example: Agentic Refactor Overlay (Clean Composition)

Now the opposite extreme: highly directive, execution-heavy.

### Agentic Refactor Overlay

```
## TASK OVERLAY: Directed Refactor

This task is a deliberate refactor of existing code.

Constraints:

* Preserve externally observable behavior unless explicitly stated otherwise.
* Structural change is allowed and expected.
* Clarity, testability, and future extensibility are priorities.

Proceed as follows:

* Identify structural issues that motivate refactoring.
* Propose a refactor plan before making changes if the impact is non-local.
* Execute refactor in logically separated steps.
* Update or add tests to protect intended behavior.

Stop and ask if:

* behavior changes become unavoidable
* requirements conflict with existing invariants
* the refactor scope grows beyond the stated intent
```

Why this composes cleanly:

* It **narrows** scope without contradicting the Prime
* It relies on Prime’s "reasoning before action" rule
* It does not need to redefine correctness, assumptions, or questioning
* It can run interactively *or* under Codex agent

---

## 6. Example: Hard Agent Task Overlay (PR-producing)

This is where people often break composition by reintroducing cognitive rules. Notice how little is needed when the Prime is correct.

### Agent Execution Overlay

```
## TASK OVERLAY: Agent Execution

You have permission to modify the repository.

Rules:

* Operate only within explicitly allowed paths.
* Make changes in reviewable units.
* Run stated validation checks and report results.

If blocked:

* Stop and report precisely what information or decision is required.

Deliverables:

* summary of changes
* evidence of validation
* risks or follow-ups
```

This works **only because** the Prime already guarantees:

* assumption surfacing
* risk awareness
* proportional planning
* non-hallucination

---

## 7. What *not* to do (important anti-pattern)

❌ Do **not** create task prompts that say things like:

* "Think carefully before answering"
* "Ask clarifying questions"
* "Challenge assumptions"
* "Use first principles"

Those belong **only** in the Prime.
Repeating them downstream causes:

* verbosity
* contradictions
* unpredictable emphasis shifts

---

## 8. Mental model to keep this stable long-term

Ask this question whenever you design a new prompt:

> "If I removed the Cognitive Prime, would this prompt still make sense?"

* If **yes** → the prompt is doing too much (bad composition)
* If **no** → good; it is correctly layered

---

## 9. Bottom line

You now have:

* a **true cognitive base layer** (Prime v2.1)
* a clean **overlay mechanism** for task specialization
* a system that scales from:

  * exploratory architecture
  * to massive refactors
  * to autonomous agent execution
* without ever modifying or duplicating the Prime

This is exactly how you prevent prompt entropy as your suite grows.

