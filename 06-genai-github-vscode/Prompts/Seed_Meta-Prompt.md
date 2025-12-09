# Meta-Prompt

Develop a comprehensive guide proposing pipelines/workflows for the following task and providing detailed description and considerations.

## Source

I have a GitHub repository containing ImageJ plugin TrakEM2 https://github.com/trakem2/TrakEM2. The plugin is in JAVA. The documentation is distributed across multiple sources:
- ImageJ website section - https://imagej.net/plugins/trakem2
- Repo wiki - https://github.com/trakem2/TrakEM2/wiki
- Outdated manual - https://syn.mrc-lmb.cam.ac.uk/acardona/INI-2008-2011/trakem2_manual.html
- Fiji reference (would need to filter items with "trakem2") - https://javadoc.scijava.org/Fiji

## Objective

### Stage 1

My immediate objective is development of consolidated comprehensive documentation within a forked repository for
- AI agents (primary target)
- human
I need to complement the source code with extensive and comprehensive documentation to aid AI in a robust and efficient way.

### Stage 2

The ultimate objective is being able to interactively explore the repo from an AI chat and have AI (ChatGPT Plus / OpenAI Codex / Gemini Pro / Gemini Code Assist) develop Python implementation of selected features.

## Tools

I have at my disposal
- **LLMs**
    - **ChatGPT Plus**
    - **Gemini Pro**
- **Deep Research Prompts:** Within either chatbot, I can execute conventional or Deep Research queries aimed at developing documentation (`Stage 1`). Between the two, I probably need to use Deep Research variants so that both LLMs would explore the source repo and other documentation.
- **OpenAI Codex Extension in VSCode**
- **Gemini Code Assist Extension in VSCode**
- **Generate Agents Instructions:** A VSCode sidebar "Build with Agent", which appears to be OpenAI Codex feature, as it opens settings with OpenAI logo.

## Task

Given the `Source`, `Objective`, and `Tools` develop a comprehensive guide proposing pipelines/workflows for achieving `Stage 1` `Objective`.  The pipeline/workflows must be based on AI with human dispatching up AI prompts, overseeing AI, committing docs to repo as necessary. The guide must include well-developed AI prompts that should designed in a generalized manner (I might have similar tasks with different repos/languages). The guide should propose specific files to be generated, such as DESIGN.md, ARCHITECTURE.md, AGENTS.md, and so on, and incorporate associated instructions within proposed prompts.

