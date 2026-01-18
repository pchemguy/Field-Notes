# ADAPTER: {Backend / Tool Name} ({Surface})

## PURPOSE

This adapter is a mechanical wrapper that makes **Prime + Overlay + Packet** usable in
{tool/surface}, without changing task meaning.

Examples:

* Codex agent (repo-execution / PR-producing)
* Gemini Code Assist (VS Code)
* Gemini PR Review (GitHub)
* Chat UI (interactive)

## NON-GOALS (HARD)

This adapter must NOT:

* add or modify task requirements, priorities, or constraints
* introduce “how to think” guidance (belongs in the Cognitive Prime)
* reinterpret intent or change acceptance criteria
* add scope fences, refactor policies, or coding standards

## INPUTS

The adapter expects these upstream artifacts (in this order):

1. Cognitive Prime (already loaded or included)
2. One or more Task Overlays
3. One Task Packet (task instance)
   Optional:
    * Repo summary / file list / diff (if the tool supports it)

## OUTPUTS

The adapter produces:

* A tool-ready prompt payload (single message or structured blocks)
* Tool-specific response formatting requirements (if any)
* Tool-specific evidence/reporting requirements (commands run, logs, etc.)

## TOOL CONSTRAINTS

Document tool-specific constraints that affect formatting only:

* Context window limitations: {notes}
* Quotas / rate limits: {notes}
* Output length constraints: {notes}
* Supported modalities: {text-only / diff-aware / repo-execution}
* Execution model: {none / local / remote sandbox / PR workflow}
* File visibility: {unknown / partial / full repo checkout}

## COMPOSITION RULES (MECHANICAL ONLY)

Define how upstream artifacts are embedded.

* Include order:
    * Prime → Overlay(s) → Packet → Adapter
* Deduplication:
    * Do not repeat Prime or Overlay content.
* Compression rules:
    * If context is limited, compress by removing examples before removing constraints.
* Conflict handling:
    * Do not resolve semantic conflicts.
    * If upstream artifacts conflict, instruct the tool to STOP and report the conflict.

## TOOL-SPECIFIC INSTRUCTIONS (MECHANICAL)

Provide only mechanics necessary to operate effectively.

Examples:

* “Return output as GitHub-flavored Markdown with headings…”
* “When reviewing a PR, reference file paths and line numbers…”
* “When executing, report commands run and results…”

Do NOT include:

* “Prefer minimal diffs”
* “Ask clarifying questions”
* “Challenge assumptions”
  Those belong upstream.

## RESPONSE FORMAT CONTRACT

Define the response structure required by the tool/surface.

### Required sections

* Summary
* Evidence (if applicable)
* Artifacts (files/diff/PR link if applicable)
* Blockers (if any)

### Evidence rules (if applicable)

* List commands run verbatim
* Summarize outcomes
* Include failure excerpts only as needed

## STOP / ESCALATION MECHANICS

Define tool-specific stop behavior (not semantic stop conditions):

* If blocked, output a “BLOCKERS” section with:
    * what is missing
    * why it blocks progress
    * the minimal info needed to proceed
* If the tool cannot access required files, request them explicitly.

## VERSIONING

* Adapter version: {e.g., 1.0}
* Tool/surface: {e.g., Codex agent, Gemini VS Code}
* Last updated: {YYYY-MM-DD}
* Notes: {breaking changes, known quirks}

