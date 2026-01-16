## Code Review Instructions (Module-by-Module, Drop-in Rewrites + Tests)

### Objective

AI-assisted expert code review of one or more Python modules (single module, a package, or a small set of related modules) **one module at a time**. The goal is to produce **drop-in improved code** plus a **comprehensive pytest suite**, while preserving intended behavior and clarifying semantics.

### Inputs I will provide

1. **Initial batch (once):**
    - The full source code for all modules in scope (or, if too large, the subset to be reviewed now).
    - Any project constraints that materially affect decisions (Python version, supported OSes, required deps, style tools, etc.).
    - Any non-obvious invariants or "must not change" behaviors.
2. **Module-by-module (iterative):**
    - I will paste the next module to be reviewed when you request it.

### Process and review order

1. After receiving the initial batch, you will:
    - Perform a quick high-level dependency and risk analysis.
    - Proactively assess whether I should provide any additional modules or code documentation to make sure you have sufficient context, and ask me what might be helpful, if appropriate.
    - Propose an **optimal review order** (highest risk/most foundational first), with a short rationale.
2. Then we iterate module-by-module:
    - After finishing a module, you will state **exactly which module to provide next**.

### Your responsibilities (for each module)

For each module, you will:

1. **Correctness and edge cases**
    - Identify impactful edge cases (prioritize likely/high-severity): Windows path behavior, atomicity/partial writes, concurrency, file locking realities, time zones, encoding, error propagation, resource cleanup, and boundary conditions.
    - Validate assumptions explicitly (what inputs are accepted/rejected; what is guaranteed on success/failure).
2. **API semantics and style**
    - Tighten public API semantics: argument validation, return types, exceptions, and backward-compatible defaults.
    - Normalize language and patterns to "expert-grade" Python norms (clarity, consistency, naming, typing).
    - Avoid unnecessary complexity; prefer small, testable helpers.
3. **Documentation quality**
    - Ensure module/class/function docstrings align with actual behavior.
    - Document invariants, side effects, I/O formats, failure modes, and any cross-platform concerns.
4. **Implement improvements (not just suggestions)**
    - Provide a **drop-in replacement** of the module, incorporating sensible improvements directly.
    - If a change is behavior-affecting, clearly label it and justify it. Default bias: preserve behavior unless unsafe/incorrect/underspecified.
5. **Comprehensive tests**
    - Produce a **pytest suite** that covers:
        - Success paths + failure paths
        - Edge cases and regression scenarios
        - Platform-sensitive behavior (especially Windows) where relevant
        - Deterministic tests (no flaky time/network dependence)
    - Use fixtures in `conftest.py` **only** when truly shared across multiple test files.
    - When reviewing multiple modules, suggest sensible integration tests.

### Deliverables (per module)

For each reviewed module you will return, in this order:

1. **Revised module code** (complete, drop-in replacement)
2. **`tests/test_<parent_package>_<module>.py`** (and `conftest.py` only if needed)
3. **Notes (brief)**:
    - Key fixes and semantics clarified
    - Edge cases covered by tests
    - Any behavior changes (explicitly flagged)

### Package Review

- Propose updating or generating sensible (from expert point of view) `__init__.py` after all modules have been revised and updated.
- Propose creating module-level `README.md`, possibly, `ARCHITECTURE.md`, Mermaid diagrams, etc. to provide professional documentation of package architecture, important considerations, and usage, so that a potential contributor or user could quickly orient themselves before going into the source code.

### Consistency and multi-round policy

- After all modules have been reviewed once, you will:
    - Re-scan the updated set for cross-module consistency issues (APIs, naming, error handling, logging, file layout, typing).
    - Recommend whether a **second review pass** is warranted.
- If any module underwent changes that are likely to affect other modules (public API changes, shared utility behavior, I/O schema changes), you should generally recommend a repeat review cycle for impacted modules.

### Guardrails (what not to do)

- Do not introduce new dependencies unless explicitly justified and consistent with project constraints.
- Do not change public APIs without:
    - documenting the reason,
    - providing compatibility shims when feasible,
    - adding tests proving the behavior.
- Do not "hand-wave" with suggestions only; implement the best version you can within scope.

---

```
## Optional add-ons (useful in practice)

If you want even more deterministic outcomes, add these two clauses:

### Patch discipline

- Prefer minimal diffs that improve safety and clarity.
- When refactoring, keep commits logically separable: "semantic fixes" vs. "mechanical cleanup."

### Definition of done

A module is "done" when:

- The revised code is internally consistent, typed, and documented,
- Tests cover normal + edge + failure cases,
- The module can be imported and tests can run in isolation,
- Cross-platform considerations are explicitly handled or documented.
```
