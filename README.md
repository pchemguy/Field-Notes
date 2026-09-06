---
urls:
  - https://gemini.google.com/app/37bd5b95ab983a95
  - https://gemini.google.com/app/cfef3eb756d8ccc6
  - https://gemini.google.com/app/34a93568b8cf6672
  - https://chatgpt.com/c/68e406d5-a274-8330-baae-5cd5e5bd795e
  - https://chatgpt.com/c/6a9d3d05-2d1c-83eb-af3a-16bb0c644d0f
  - https://chatgpt.com/c/6a9d3d05-2d1c-83eb-af3a-16bb0c644d0f
---

# Field-Notes

> Practical notes and solutions from the tech trenches.

This repository is a living collection of technical notes, scripts, and solutions to non-obvious real-world problems - kept as a reference for myself and shared in case others find it useful.

Each topic has its own folder containing a `README.md` and any supporting files. The table of contents also links to related standalone repositories - effectively "promoted" notes.

## Contents

### Windows Systems and Storage

- New PC setup
    - [Part 1: Structuring workstation storage for maintenance, migration, and failure recovery](./notes/02-storage-new-pc/README.md)
    - [Part 2: Building a dual-purpose multiboot USB drive](./notes/02-storage-new-pc/BootableUSBDrive.md)
- [Setting up WSL 2 for AI development with controlled storage](./notes/08-wsl-setup/README.md)

### Downloads and Git

- [Resuming downloads from dynamic or expiring links with `wget` or `aria2`](./notes/01-improving-large-file-downloads/README.md)
- [Downloading and caching the latest GitHub release assets on Windows](./notes/04-github-release-download/README.md)
- [Proof of concept: resumable Git clone through sparse checkout](./notes/07-resumable-git-clone/README.md)

### Python and Native-Code Development

- [Bootstrapping reproducible Python environments on Windows with Micromamba](./notes/03-python-env-windows/README.md)
- [Working around pip failure to detect MSVC Build Tools](./notes/05-python-pip-msvc/README.md)
- [Building and installing FFCV on Windows](https://github.com/pchemguy/FFCVonWindows)
- [Testing C APIs directly with Pytest and CFFI](https://github.com/pchemguy/CFFI_Pytest_C_Testing)

### SQLite

#### SQL and Data Modelling

- [Practical advanced SQL and SQLite notes](https://pchemguy.github.io/SQLite-SQL-Tutorial)
- [Reverse engineering SQLite schemas with ERD Concepts](./notes/09-revengdb/README.md)
- [SQLiteMP: materialized-path hierarchies in SQLite](https://github.com/pchemguy/SQLiteMP)

#### Builds and Extensions

- [Building SQLite and SQLiteODBC with ICU and additional extensions on Windows](https://pchemguy.github.io/SQLite-ICU-MinGW)
- [Integrating loadable extensions into the SQLite amalgamation as auto-extensions](./notes/11-sqlite-msvc-build/README.md)
- [SQLiteExtensionTemplate: C extension development and testing](https://github.com/pchemguy/SQLiteExtensionTemplate)
- [SQLitePackedBlob: compact storage for numeric arrays and embeddings](https://github.com/pchemguy/SQLitePackedBlob)
- [SQLiteRegexpMatches: JSON arrays of regular-expression matches](https://github.com/pchemguy/SQLiteRegexpMatches)

#### VBA Database Access and OOP Design

- [SecureADODB fork: exploring OOP-centric designs for database access](https://pchemguy.github.io/SecureADODB-Fork)
- [SQLiteC for VBA: designing OOP interfaces for SQLite access via ADODB and directly through the C API](https://github.com/pchemguy/SQLiteC-for-VBA)

### Patents

- [Parsing and relationally modelling the IPC scheme XML](./notes/12-ipc-scheme-xml-parsing/README.md)

### AI-Assisted Development

- [Exploratory prompting with ChatGPT](https://github.com/pchemguy/ChatGPTExploratoryPrompting)
- [Greenfield development: from problem or idea to MVP](./notes/10-ai-coding-prompts/README.md)

## Acknowledgments

The solutions and documentation in this repository were developed with active AI assistance (mainly, Google Gemini and OpenAI ChatGPT) for brainstorming, code generation, and the refinement of code and text.
