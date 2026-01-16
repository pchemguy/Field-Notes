https://chatgpt.com/g/g-p-6969f25c67888191aa1e0805a42dcf1e-meta-ai-coding/c/6969f2a3-f6f4-8328-ba6b-a5e40fccb533

# Meta AI Coding / Meta-Prompting for Coding

You are to act as a highly qualified prompt engineering (PE) expert and a peer PE developer. My/our objective is development of a suite of prompts (meta-prompts, context setting prompts, AI agent prompts, etc.) for AI-assisted (both interactive and agentic) software development.

## ChatGPT

Understood. I will operate as a **peer prompt-engineering (PE) architect** focused on **meta-prompt systems for AI-assisted software development**, spanning interactive use (chat, IDE copilots) and constrained agentic workflows (subscription-only, repo-aware, no autonomous API loops).

Below is a **foundational framework** we can use to design, evaluate, and iterate a **suite of prompts** in a disciplined, engineering-grade manner.

---

## 1. Define the Prompt System, Not Individual Prompts

Treat prompts as **first-class system artifacts**, analogous to code modules.

### 1.1 Prompt Taxonomy (Canonical Set)

We should explicitly distinguish:

1. **Context-setting prompts**
    * Establish role, constraints, scope, non-goals
    * Loaded once per session or per repo
2. **Meta-prompts**
    * Define *how* the model should reason, review, or interact
    * Often persistent (e.g., “review protocol”, “architecture gate”)
3. **Task prompts**
    * Concrete, local objectives (write code, review module, draft spec)
4. **Control prompts**
    * Enforce process steps (order of actions, checkpoints, stop criteria)
5. **Evaluator / critic prompts**
    * Independent scoring, regression detection, or sanity checks
6. **Recovery / correction prompts**
    * Handle drift, hallucination, or partial context loss

A mature system will include **all six**, even if some are implicit initially.

---

## 2. Core Design Principles for Coding Meta-Prompts

### 2.1 Determinism Over Creativity (Unless Explicitly Requested)

For software engineering prompts:

* Bias toward:
    * Explicit procedures
    * Ordered steps
    * Termination conditions
* Minimize:
    * Open-ended phrasing
    * Vague “improve” or “optimize” language

**Rule of thumb:**
If two competent models could interpret the prompt differently, it is under-specified.

---

### 2.2 Separation of Concerns (So Prompts Don’t Collapse)

Avoid “do everything” prompts.

Instead, isolate:

* **Analysis** (what exists, what matters)
* **Decision** (what to change, what not to touch)
* **Execution** (code / docs / tests)
* **Evaluation** (did we meet objectives?)

This mirrors clean architecture and prevents reasoning collapse under long contexts.

---

### 2.3 Explicit Non-Goals and Guardrails

High-value coding prompts always specify:

* What **must not** be done
* What **is out of scope**
* What **requires explicit approval**

Example categories:

* No refactors unless justified
* No new dependencies
* No behavior changes without tests
* No stylistic edits unless correctness-related

This dramatically reduces prompt drift.

---

## 3. Canonical Meta-Prompt Skeleton (Reusable)

This is a **structural template**, not a finished prompt:

```
ROLE
You are acting as <role> with <seniority>.

OBJECTIVE
Your objective is <single primary objective>.

SCOPE
You are working within:
- Codebase: <path / module>
- Constraints: <language, platform, style guides>

NON-GOALS
You must not:
- <explicit exclusions>

PROCESS
You shall proceed in the following order:
1. <analysis step>
2. <decision step>
3. <execution step>
4. <verification step>

QUALITY BAR
Your output must satisfy:
- <measurable criteria>

STOP CONDITION
Stop immediately after <condition>.
```

Every specialized prompt we create should be traceable back to this skeleton.

---

## 4. Prompt Classes Specifically for Coding Workflows

### 4.1 Code Review Meta-Prompt (Protocol-Level)

Characteristics:

* Multi-pass
* Edge-case driven
* Test-first bias
* Change justification required

Key pattern:

> “Identify → Classify → Prioritize → Act → Re-evaluate”

---

### 4.2 Architecture & Design Prompts

Must:

* Separate **problem framing** from **solution selection**
* Force articulation of alternatives and tradeoffs
* Explicitly tag future-work vs MVP

Anti-pattern to avoid:

* Jumping to frameworks/tools before constraints are enumerated

---

### 4.3 Agent-Compatible Prompts (No API Autonomy)

For subscription-only tools (Chat UI, IDE copilots):

* Assume **no persistent memory**
* Assume **partial repo visibility**
* Require **explicit re-hydration steps**

Include instructions like:

* “Request missing files explicitly”
* “Summarize state before proceeding”
* “Confirm assumptions before modifying code”

---

## 5. Evaluation: How We Know a Prompt Is “Good”

A prompt is successful if it:

1. Produces **repeatable outputs** across sessions
2. Degrades gracefully when context is missing
3. Prevents unauthorized scope expansion
4. Encourages clarification instead of guessing
5. Scales from small tasks to multi-module workflows

We can formalize this into a **prompt QA checklist** later.

---

## 6. Proposed Next Steps (Concrete)

I recommend we proceed in this order:

1. **Define your target workflows**
    * Code review
    * Greenfield design
    * Incremental refactor
    * Test generation
    * Documentation alignment
2. For one workflow, we:
    * Design a **context prompt**
    * Add a **meta-prompt (process rules)**
    * Add a **task prompt**
    * Add an **evaluator prompt**
3. Iterate until it is:
    * Stable
    * Reusable
    * Repo-agnostic

---
