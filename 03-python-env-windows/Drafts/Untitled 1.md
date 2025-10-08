Bootstrapping Python Environments on Windows (via Micromamba)

This post documents an experimental workflow for initializing and managing isolated Python environments on Windows using Micromamba as a lightweight, dependency-free bootstrapper. It consolidates findings, implementation notes, and practical scripts developed to establish a fully self-contained, reproducible environment model without system-wide dependencies or shell-level initialization.

Key points
- Do's
    - Use Micromamba solely for creation of a new basic environment (Python, Mamba, and Conda).
    - After creation, switch to Mamba/Conda installed in the new environment
- Don'ts
    - Do not use system-wide Python installation.
    - Do not use Micromamba-based shell initialization.
