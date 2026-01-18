Understood. I will **formalize a repo-ready directory structure** specifically for **Cognitive Prime + overlays**, optimized for:

* composability
* long-term evolution
* mixed interactive + agentic use
* Codex / Gemini / Chat UI coexistence
* avoidance of prompt sprawl and duplication

No fluff, no theory—this is an **engineering artifact**.

---

## 1. Design Goals (Explicit)

The structure must:

1. Clearly separate **cognitive base**, **task overlays**, and **task instances**
2. Allow overlays to evolve independently
3. Be readable and usable by:
    * humans
    * AI agents
    * future collaborators
4. Avoid tight coupling to:
    * a specific LLM
    * a specific IDE
    * a specific execution backend
5. Make it obvious **what can override what**

---

## 2. Top-Level Directory: `agentic_coding/`

Place everything under a single, unambiguous namespace:

```
agentic_coding/
├── README.md
├── AGENTS.md
├── prime/
├── overlays/
├── packets/
├── adapters/
└── archive/
```

This keeps AI-related artifacts **explicit and contained**, not scattered across `docs/`.

---

## 3. `agentic_coding/prime/` — Foundational Cognitive Layer

This directory must be **small, stable, and boring**.

```
agentic_coding/prime/
├── COGNITIVE_PRIME.md
└── CHANGELOG.md
```

### `COGNITIVE_PRIME.md`

* Contains **exactly one thing**: the Cognitive Prime (v2.1, v2.2, etc.)
* No task rules
* No coding standards
* No formatting conventions

Think of this as the **constitution**.

### `CHANGELOG.md`

* Tracks semantic changes to the Prime
* Important for agent reproducibility

---

## 4. `agentic_coding/overlays/` — Task-Type Modulators (Most Important)

This is where **behavior is shaped**.

```
agentic_coding/overlays/
├── README.md
├── exploratory/
│   ├── ARCHITECTURE.md
│   ├── FEASIBILITY.md
│   └── RESEARCH.md
├── execution/
│   ├── IMPLEMENTATION.md
│   ├── REFACTOR.md
│   └── HOTFIX.md
├── review/
│   ├── CODE_REVIEW.md
│   ├── SECURITY_REVIEW.md
│   └── PERFORMANCE_REVIEW.md
├── testing/
│   ├── TEST_GENERATION.md
│   └── REGRESSION_ANALYSIS.md
└── docs/
    ├── DOCUMENTATION.md
    └── SPEC_ALIGNMENT.md
```

### Key rules for overlays

* Overlays:
    * **assume the Prime is loaded**
    * never restate cognitive rules
    * never contradict the Prime
* Overlays may:
    * bias toward exploration vs execution
    * introduce constraints
    * define stop conditions
* Overlays must be:
    * backend-agnostic
    * language-agnostic unless explicitly stated

Each overlay file should answer:

> “What kind of task is this, and what should be emphasized or avoided?”

---

## 5. `agentic_coding/packets/` — Task Instances (Ephemeral, Concrete)

This is where **agentic execution actually happens**.

```
agentic_coding/packets/
├── README.md
├── active/
│   ├── 2026-01-refactor-logging.md
│   ├── 2026-02-grid-detection-spike.md
│   └── bugfix-null-path-windows.md
├── templates/
│   ├── TASK_PACKET_BASE.md
│   ├── REFACTOR_PACKET.md
│   └── REVIEW_PACKET.md
└── completed/
    ├── 2025-12-api-hardening.md
    └── 2025-11-test-stabilization.md
```

### Characteristics

* **Packets are concrete**
* They bind:
    * scope
    * paths
    * checks
    * deliverables
* They are:
    * short-lived
    * archivable
    * reproducibility artifacts

This mirrors how you already think in *runs*, *stages*, and *artifacts*.

---

## 6. `agentic_coding/adapters/` — Backend-Specific Wrappers (Optional but Powerful)

Adapters translate **generic prompts** into **tool-specific execution contexts**.

```
agentic_coding/adapters/
├── README.md
├── codex/
│   ├── EXECUTOR_PREFIX.md
│   └── PR_REPORT_TEMPLATE.md
├── gemini/
│   ├── VSCODE_CONTEXT.md
│   └── PR_REVIEW_GUIDE.md
└── chat/
    ├── INTERACTIVE_PREFIX.md
    └── LONG_SESSION_GUIDE.md
```

### Purpose

* No cognitive rules here
* No task logic
* Only:
    * how to inject context
    * how to format output
    * how to comply with quotas / UI limits

This prevents you from contaminating overlays with backend trivia.

---

## 7. `agentic_coding/AGENTS.md` — Entry Point for Agents

This file ties everything together.

```
agentic_coding/AGENTS.md
```

Recommended contents:

1. Load order:

```
1) Cognitive Prime
2) One or more Overlays
3) One Task Packet
4) Optional Adapter
```

2. Authority hierarchy
3. Conflict resolution rule:
    - `> Packet > Overlay > Prime`
4. Explicit instruction:
    * “If conflicts exist, stop and report.”

This is the **bootloader** for Codex-style agents.

---

## 8. `agentic_coding/README.md` — Human Orientation

Explain briefly:

* what each directory is for
* how to create a new packet
* how to run an agent task
* how to use prompts interactively

Keep it short. Engineers should understand it in under 2 minutes.

---

## 9. `agentic_coding/archive/` — Prompt Fossils (Optional but Wise)

```
agentic_coding/archive/
├── old_primes/
├── deprecated_overlays/
└── experiments/
```

This avoids deletion while preventing accidental reuse.

---

## 10. Why This Structure Will Scale

This layout:

* prevents duplication of reasoning rules
* allows aggressive agentic execution without risk of cognitive drift
* supports iterative refinement of overlays
* cleanly separates:
    * **how to think**
    * **what kind of task this is**
    * **what exactly to do**
    * **how to run it on a tool**

It also mirrors your existing **stage-based, artifact-driven** way of working, which is why it fits naturally.

---

## 11. Next Logical Step (Optional)

If you want to push this further, the next concrete step would be:

* define a **canonical overlay template**
* define a **lint/checklist** for overlays (“does this violate the Prime?”)
* or map one of your existing workflows (e.g. GridPET refactor) into:
    * overlay + packet + adapter

But the directory structure itself is now **complete, defensible, and production-ready**.
