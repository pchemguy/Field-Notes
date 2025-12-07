# Copilot Instructions for Field-Notes

## Repository Overview

**Field-Notes** is a personal technical knowledge base documenting practical solutions to real-world Windows IT challenges. It serves as both a reference archive and public resource, organized into independent topic folders with self-contained READMEs, scripts, and supporting materials.

- **Primary focus:** Windows system administration, PowerShell/batch scripting, Python environment setup, and GitHub release automation
- **Target platform:** Windows (PowerShell 5.1, cmd.exe, batch scripts)
- **Audience:** Power users and IT professionals implementing robust automation and system architecture

## Project Structure & Architecture

Each topic folder (`01-*`, `02-*`, etc.) is independent and can be understood in isolation:

- **01-improving-large-file-downloads:** Batch scripts (wget/aria2) for resumable downloads with dynamic URLs
- **02-storage-new-pc:** Multi-part series on Windows storage partitioning strategy and bootable USB creation (Ventoy-based)
- **03-python-env-windows:** Micromamba bootstrapping workflow—batch automation for creating isolated Python environments without shell initialization or registry modifications
- **04-github-release-download:** GitHubRelease.bat utility for downloading and caching latest GitHub binary releases with jq/findstr JSON parsing fallback
- **05-python-pip-msvc:** MSVC build tools detection issues with pip on Windows
- **06-genai-github-vscode:** (Current branch) Integrating AI agents with GitHub/VS Code workflows

## Critical Design Principles & Patterns

### Explicit Over Implicit (Avoid Shell Magic)

The **03-python-env-windows** folder exemplifies this philosophy. Rather than relying on Micromamba's built-in `shell init` and `shell hook` mechanisms (which modify registry and add persistent state), the approach:
- Uses **explicit batch scripts** (`.bat` files) that directly invoke `micromamba.exe` for environment creation
- Avoids AutoRun registry modifications and parent shell state assumptions
- Ensures **deterministic, transparent, and reproducible** environment setup
- Supports environment-per-script isolation with no cross-session pollution

Apply this principle broadly: prefer explicit commands and file manipulation over relying on automatic tool initialization or global configuration.

### Error Handling & Early Failure

The **04-github-release-download** project demonstrates rigorous error checking:
- **Every critical operation** checks `ERRORLEVEL` immediately (directory creation, downloads, file moves)
- **Fails loudly and early** rather than silently falling back or continuing with corrupted state
- Provides **specific, actionable error messages** at each failure point
- Example: checks for dependency availability (curl, tar, jq) before use, and gracefully falls back (jq → findstr)

### Batch Script Best Practices

Across projects (especially 03 and 04):
- Use `setlocal enabledelayedexpansion` for dynamic variable expansion in loops
- Employ `endlocal & (set "VAR=value")` to safely return variables from scope
- Use ANSI escape sequences for colored console output (error/success indication)
- Leverage native Windows tools first (`curl`, `tar`, `findstr`) before external dependencies
- Structure scripts with clear exit codes and status tracking

### Content Conventions

- **READMEs are comprehensive:** Include background, motivation, detailed walkthrough, known issues, and appendices
- **Technical tone:** Measured, objective language—avoid "powerful" or "elegant" without justification
- **Design rationale matters:** Explain *why* a choice was made, not just *how* to implement it
- **Cross-references:** Link between related parts (e.g., 02-storage Part 1 → Part 2, 03-python-env → supporting utility scripts)
- **Drafts folder:** Contains exploration notes, refinement steps, and raw discovery—reference for deeper understanding but not primary documentation

## Developer Workflows

### Adding a New Topic Folder

1. Create a numbered folder (e.g., `07-topic-name/`)
2. Write a detailed `README.md` explaining the problem, design approach, and solution
3. Include any batch scripts, config files, or supporting materials in the same folder
4. Reference in the root `README.md` table of contents
5. If multi-part, clearly link between parts

### Batch Script Development

- **Iterative testing:** Use companion test scripts (e.g., `GitHubRelease_Test.bat`) to validate across scenarios
- **Verbose output:** Use ANSI colors and clear logging for debugging
- **Portability:** Minimize external dependencies; rely on Windows native tools (curl, tar, findstr, jq where available)
- **Documentation:** Annotate scripts with inline comments explaining non-obvious logic

### Documentation Refinement

The `Drafts/` subfolders capture the evolution of ideas:
- Initial exploration and discovery notes
- Prompt iterations (if using AI assistance)
- Outline and structure refinement
- Final polishing before integration into main README

When reviewing or updating documentation, check `Drafts/` for context on design decisions.

## Integration Points & Dependencies

### External Tools & Scripts

- **Micromamba** (03): Single executable for bootstrapping Conda environments—auto-downloads if missing
- **curl & tar** (Windows native 10+): Used universally for downloads and archive extraction
- **jq** (04): Optional JSON parser; script auto-downloads or falls back to `findstr`
- **GitHub API**: Used for release metadata queries (requires no authentication for public repos)

### Batch Script Communication

Scripts use **environment variables** (not command-line arguments) for configuration:
- Enables easy composition in larger automation workflows
- Simplifies debugging (variables persist across script calls)
- Example: `GitHubRelease.bat` expects `REPO_NAME`, `RELEASE_URL_SUFFIX`, `CANONICAL_NAME` set before execution

### Testing Strategy

- Unit test scripts included within projects (e.g., `GitHubRelease_Test.bat`)
- Test suite validates success paths, expected failures, and edge cases
- Companion test scripts document expected behavior and common failure modes

## When Contributing or Extending

1. **Understand the why first:** Read background/motivation sections before diving into code
2. **Follow established patterns:** Use the explicit-over-implicit and fail-early principles from existing projects
3. **Maintain batch script conventions:** Proper scoping, error checking, verbose output
4. **Update cross-references:** If modifying structure or names, check root README and any inter-folder links
5. **Test thoroughly:** Create test cases for new scripts; validate across Windows versions (especially batch compatibility)
6. **Document design choices:** Explain *why* a solution was chosen over alternatives

## Specific File References

- **Root README:** `b:\GH\Field-Notes\README.md` — Table of contents and project overview
- **Python environments:** `03-python-env-windows\Micromamba_bootstrap.bat` — Core bootstrapping logic (exemplar of explicit design)
- **GitHub release automation:** `04-github-release-download\GitHubRelease.bat` — Exemplar of rigorous error handling and fallback strategies
- **Storage architecture:** `02-storage-new-pc\README.md` → `BootableUSBDrive.md` — Multi-part documentation with clear linking pattern
