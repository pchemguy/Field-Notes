## Project Overview



## Code Style Guidelines

Guidelines explicitly included in this section apply to all documents in this repository, both code and Markdown-formatted documentation. This section also refers to additional documents with more specific focus.

- Strictly use ASCII when editing or creating files even for files that may violate this requirement.
    - Use English names for units and other quantities (such as, "deg" or "alpha"), instead of non-ASCII symbols.
    - Always use ASCII quotes, dash, and appropriate equivalent of any other non-ASCII characters.
    - Apply this rule to entire files, including code, docstrings, and basic comments.
- MathJAX is acceptable where appropriate.
    - The MathJAX expressions should be formatted using the dollar sign `$`.
    - Inline MathJAX expression: `$N$`
    - Block-style MathJAX expression: `$${NEW_LINE}N{NEW_LINE}$$`

External guidelines:

- `PythonStyleGuidelines.md`:  Detailed guidelines for Python modules.

## Review Guidelines

- Verify file, function, and notebook names follow the repo's naming conventions and clearly describe their purpose.
- Scan prose and markdown for typos, broken links, and inconsistent formatting before approving.
- Check that code identifiers remain descriptive (no leftover placeholder names) and that repeated values are factored into constants when practical.

## References

<!--
https://agents.md
-->