# Task Packets

Task packets are **concrete, binding task-instance artifacts**.
They define *what exactly is to be done*, under what constraints, and how completion
is verified.

Packets are the **only layer allowed to be task-specific**.

---

## 1. Role of Task Packets in the Stack

The full prompt stack is:

1. **Cognitive Prime** — how to reason
2. **Overlay(s)** — what kind of task this is
3. **Task Packet** — what to do *this time*
4. **Adapter** — how to run it on a specific tool/surface

**Authority order (highest wins):**

```
Task Packet > Overlay > Cognitive Prime
```

Adapters never override packets.

---

## 2. What Belongs in a Task Packet (and What Does Not)

### A task packet MUST define:

* the concrete objective
* the allowed and forbidden scope (paths, components)
* hard constraints (behavior, API, dependencies)
* deliverables
* acceptance checks
* stop conditions
* autonomy limits (for agentic execution)

### A task packet MUST NOT:

* restate cognitive rules (“think carefully”, “challenge assumptions”)
* describe how to reason in general terms
* contain tool/UI mechanics (Codex, Gemini, VS Code, Chat UI)
* include speculative requirements (“nice to have unless easy”)
* act as a policy document

If it is not specific to *this* task instance, it does not belong in a packet.

---

## 3. Packet Lifecycle

### 3.1 Creation

Packets are created in:

```
ai/packets/active/
```

using a template from:

```
ai/packets/templates/
```

Choose the narrowest appropriate template:

* `TASK_PACKET_BASE.md` — generic tasks
* `REFACTOR_PACKET.md` — structural refactors
* `REVIEW_PACKET.md` — review-only work

Copy, rename, and fill in all required sections.

---

### 3.2 Activation

A packet is **active** when:

* it has a clear objective
* scope fences are defined
* acceptance checks are specified
* stop triggers are explicit

An active packet can be used:

* interactively (human-in-the-loop)
* by an agent (Codex, Gemini, etc.)

---

### 3.3 Blocking

If execution cannot proceed due to missing or conflicting information:

* update packet status to `blocked`
* record the blocker explicitly in the packet or execution report
* do not silently weaken constraints to proceed

---

### 3.4 Completion

When a task is complete:

* update packet status to `completed`
* move it to:

```
ai/packets/completed/
```

Completed packets are **artifacts**, not trash:

* they document decisions
* they enable reproducibility
* they are valuable training examples for future tasks

---

## 4. Packets and Agentic Execution

For agent-driven execution (e.g. Codex):

* The packet is treated as a **binding contract**
* Autonomy is explicitly bounded by:
    * acceptance checks
    * iteration limits
    * stop triggers
* If the agent hits a stop trigger, it must stop and report

Agents must not:

* reinterpret packet intent
* relax scope fences
* invent missing requirements

---

## 5. Multiple Overlays with One Packet

A single packet may be combined with multiple overlays, for example:

* Exploratory overlay + base packet (early investigation)
* Refactor overlay + refactor packet (structural work)
* Review overlay + review packet (PR review)

Overlays **modulate behavior**, but the packet always defines:

* *what* is in scope
* *what* must be delivered
* *how* success is judged

---

## 6. Versioning and Naming Conventions

Recommended filename pattern:

```
YYYY-MM-DD-<task-type>-<short-slug>.md
```

Examples:

* `2026-01-logging-refactor.md`
* `2026-02-grid-detection-review.md`

Packets should include:

* creation date
* last update date
* current status

---

## 7. Sanity Checklist (Before Using a Packet)

Before running a packet, verify:

* ☐ Objective is concrete and testable
* ☐ Scope fence is explicit (allowed + forbidden)
* ☐ Acceptance checks are listed and runnable
* ☐ Stop triggers are defined
* ☐ Exceptions (if any) are explicit
* ☐ No cognitive or tool-specific instructions leaked in

If any item is missing, fix the packet before proceeding.

---

## 8. Design Principle (Non-Negotiable)

> **If two competent engineers could interpret the packet differently, the packet is incomplete.**

Packets exist to eliminate ambiguity at execution time.

End of document.
