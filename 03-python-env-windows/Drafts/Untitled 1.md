Bootstrapping Python Environments on Windows with Micromamba

This post outlines a method for creating self-contained Python environments on Windows. It uses Micromamba as a minimal, dependency-free tool for the initial setup, allowing you to build reproducible environments without a system-wide Python installation or shell modifications.

The Approach
- Use Micromamba only for bootstrapping. Its sole job is to create a new environment containing Python, Mamba, and Conda.
- Use Mamba/Conda for management. Once the environment exists, use the Mamba and Conda tools inside it for all package management and activation.
- Avoid system-wide changes. This method bypasses Micromamba's shell initialization to prevent modifications to your registry or user profile.

https://github.com/pchemguy/Field-Notes/blob/main/03-python-env-windows/README.md