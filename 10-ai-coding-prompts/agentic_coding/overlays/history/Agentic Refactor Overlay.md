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
