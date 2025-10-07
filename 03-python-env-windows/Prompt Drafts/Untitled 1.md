Help me revise this draft. Present text is a collection of narrated notes documenting exploration/discovery of the described topic, including important technical details, such as code snippets and discussions. The draft narrates including technical insights, experiments, and dead ends. I have also developed two shell scripts implementing the desired objective. I want to transform this text into technical guide/reference primarily for my future self (but also for anyone else) that would provide relevant detailed information present in the draft, without the need for rediscovery. The primary focus is on the workflow summarized in the following points

Bootstrapping Python envs on Windows
- Do not use a system-wide Python installation (root environment)
- Instead, each environment should be standalone, with at most one environment ever present in any given shell ancestry line (Path and other key environment variables)
- Each environment is bootstrapped using a standalone simple tool with no Python dependencies.
- Primary responsibility of the bootstrapping tool - creation of a basic environment in an empty directory, including a particular version of Python plus one of the standard mature package managers, integrated within the Python environment (a Python-package-based).
- Once minimalistic environment is created, it should be possible to activate it in any shell using a standard script.
- After environment is activated, it is managed by the installed package managers, the bootstrapping tool should no longer be used.
- For the Conda-based ecosystem, Micromamba is an example of such a bootstrapping tool meeting specified requirements: it should be used to install Python/Conda/Mamba. Conda/Mamba (and, pip, if necessary) can then be used for managing this environment.
- Unfortunately, Conda/Mamba scripts are not completely portable and some absolute paths are getting hardcoded during environment bootstrapping process. 

---

