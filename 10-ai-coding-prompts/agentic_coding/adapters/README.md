## Purpose

Adapters are **mechanical wrappers** that make **Prime + Overlay(s) + Packet** usable in a specific tool or surface (Codex agent, Gemini PR review, VS Code assistant, Chat UI).

Adapters exist to absorb **tool churn** without contaminating the cognitive or task layers.

## Hard Rule: Mechanical Only

Adapters MUST NOT change what a task means.

Adapters MUST NOT:

* add or modify requirements, priorities, constraints, or acceptance criteria
* introduce cognitive guidance (belongs in the Cognitive Prime)
* reinterpret intent or “improve” the task
* add scope fences, refactor policies, or coding standards

Adapters MAY:

* translate upstream artifacts into tool-appropriate formatting
* specify tool-specific response structure (headings, sections)
* specify evidence formatting (commands run, logs, PR summaries)
* document tool limits (context window, quotas) and how to cope mechanically

If an adapter changes task semantics, it is incorrect.

## Composition Order

Use this order when assembling prompts:

1. Cognitive Prime
2. One or more Overlays
3. One Task Packet (task instance)
4. Adapter (surface/tool wrapper)

Authority for resolving semantic conflicts:

* Packet > Overlay > Prime
* Adapters do not resolve semantic conflicts; they report them.

## Directory Layout

* codex/   : adapters for repo-execution / PR-producing Codex agent surfaces
* gemini/  : adapters for Gemini surfaces (VS Code assistant, GitHub PR review, etc.)
* chat/    : optional adapters for chat-only workflows (formatting, long-session hygiene)

## Versioning

Each adapter file must include:

* Adapter version
* Tool/surface name
* Last updated date
* Notes about known quirks (mechanical only)
