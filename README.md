<!--
https://gemini.google.com/app/37bd5b95ab983a95
https://gemini.google.com/app/cfef3eb756d8ccc6
https://gemini.google.com/app/34a93568b8cf6672
https://chatgpt.com/c/68e406d5-a274-8330-baae-5cd5e5bd795e
-->

# Field-Notes

> Practical notes and solutions from the tech trenches.

## About

This repository is my personal collection of technical notes, scripts, and solutions to the real-world problems I encounter as a tech professional. Think of it as a hybrid digital journal and personal knowledge base. Here, I document solutions for those often small but annoying IT issues that have tricky, non-obvious answers, as well as my exploration of various technical topics that spark my curiosity.

This repo serves two main purposes:
- A quick reference for my future self so I do not have to solve the same problem twice.
- A public resource in the hope that these notes might help someone else facing a similar challenge.

Each topic is contained within its own folder. Inside each folder, you will find a `README.md` file that details the problem and the step-by-step solution, along with any necessary scripts or configuration files. This repository is a living document, and its structure will evolve as I add more notes. Please consider everything a work-in-progress.

The Table of Contents below also include references to closely related standalone repositories, which can be considered as "promoted" notes.

## Table of Contents

### System

- Storage considerations for a new PC
    - [Part 1: Structuring internal storage for robust migration and failure recovery](./02-storage-new-pc/README.md)
    - [Part 2: Building a bootable USB drive](./02-storage-new-pc/BootableUSBDrive.md)
- [Setting up WSL for AI development](./08-wsl-setup/README.md)

### Downloads and Git

- [Resuming large file downloads with dynamic links](./01-improving-large-file-downloads/README.md) - A scripted `wget`/`aria2` solution for robustly downloading large files
- [Scripted downloads of latest GitHub binary releases on Windows](./04-github-release-download/README.md)
- [Resumable git clone for large code base and slow/unreliable connection](./07-resumable-git-clone/README.md)

### Python Setup and Native Building

- [Bootstrapping Python environments on Windows (via Micromamba)](./03-python-env-windows/README.md)
- [Python pip fails to detect MSVC Build Tools on Windows](./05-python-pip-msvc/README.md)
- [Building and installing FFCV on Windows](https://github.com/pchemguy/FFCVonWindows)

### Python C API Testing

- [Direct C API testing with Pytest and CFFI](https://github.com/pchemguy/CFFI_Pytest_C_Testing)

### SQLite

- [Advanced SQL/SQLite tutorial](https://pchemguy.github.io/SQLite-SQL-Tutorial)
- [Building SQLite/SQLiteODBC with ICU and other extensions using MSVC and MinGW](https://pchemguy.github.io/SQLite-ICU-MinGW)
- [Reverse engineering SQLite3 databases with ERD concepts](./09-revengdb/README.md)
- [SQLiteMP - managing hierarchical category systems in SQLite](https://github.com/pchemguy/SQLiteMP)
- [Integrating loadable extensions into SQLite amalgamation using MSVC toolchain](11-sqlite-msvc-build/README.md)
- [SQLiteExtensionTemplate](https://github.com/pchemguy/SQLiteExtensionTemplate) - establishes a template for a C SQLite extension with [integrated building](11-sqlite-msvc-build/README.md) and [CFFI-based testing](https://github.com/pchemguy/CFFI_Pytest_C_Testing)
- [SQLitePackedBlob extension for transforming arrays between JSON and packed blob formats](https://github.com/pchemguy/SQLitePackedBlob)
- [SQLiteRegexpMatches extension returning RegEx matches](https://github.com/pchemguy/SQLiteRegexpMatches)

### SQLite in VBA

- [SQLiteCforVBA library wrapping ADODB and SQLite C-language API](https://github.com/pchemguy/SQLiteC-for-VBA)
- [SecureADODB fork exploratory](https://pchemguy.github.io/SecureADODB-Fork)

### Patents

- [IPC scheme XML parsing notes](12-ipc-scheme-xml-parsing/README.md)

### Miscellaneous

- [Greenfield development - from concept / idea to MVP](./10-ai-coding-prompts/README.md) - exploration of a prompting system and framework for AI-assisted (interactive and agentic) greenfield coding problem development

## Acknowledgments

The solutions and documentation in this repository were developed with active AI assistance (mainly, Google Gemini and OpenAI ChatGPT) for brainstorming, code generation, and the refinement of code and text.
