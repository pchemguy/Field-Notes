# IPC Scheme XML Parsing Notes

## 1. Scope

This repository analyzes how the International Patent Classification (IPC) is organized in its XML scheme file and develops a relational representation for
structural inspection and later information modelling.

At a logical level, the file combines three different kinds of information:

- a **main classification hierarchy**, which contains the ordinary places used to classify inventions by their technical subject matter;
- a **secondary aspect hierarchy**, which supplies additional symbols for classifying recurring aspects of already classified subject matter, such as
  materials, uses, properties, or operating conditions;
- **auxiliary records**, which help present, explain, or search the two hierarchies. These records include headings that label ranges of symbols, notes that
  qualify or explain their use, subsection labels used for broad presentation, and subclass indexes that provide search-oriented topic paths leading to IPC symbols.

These logical types are not represented by different top-level XML elements. The source reuses `<ipcEntry>` for all of them and distinguishes their functions through attribute values and internal content. The immediate goal is therefore not to reproduce the XML mechanically, but to disentangle the different entities hidden behind this shared container.

The analysis is structural rather than an attempt to interpret the technical meaning of every IPC title. It asks:

- which XML elements represent nodes in either classification hierarchy;
- which elements are auxiliary search, presentation, or annotation records;
- when a symbol identifies the current node and when it only identifies the symbol or range to which an auxiliary record applies;
- how XML containment differs from IPC scope;
- which source structures should become separate relational tables.

Unless stated otherwise, claims in this document describe observations of the IPC 2027.01 early-release file, not timeless guarantees about every IPC edition.

## 2. The central modelling problem

The principal reusable container is `<ipcEntry>`. Four attributes are especially important:

| Attribute   | Role                                                                                                                                                    |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `kind`      | Identifies an auxiliary function for `i`, `g`, `n`, and `t`; for other values, identifies hierarchy level within one of the classification hierarchies. |
| `symbol`    | Either identifies the structural node itself or anchors an auxiliary record to another structural symbol, depending on `kind`.                          |
| `endSymbol` | Where present on an auxiliary record, marks the other boundary of the symbol range to which that record applies.                                        |
| `entryType` | For non-auxiliary entries, distinguishes nodes in the main classification hierarchy (`K`) from nodes in the secondary aspect hierarchy (`I`).           |

The source therefore does not have a single homogeneous `ipcEntry` entity. The meaning of an element must be resolved from `kind` and `entryType` together. For compactness, this document uses `ignt` as shorthand for the four auxiliary `kind` values:

```text
ignt = {"i", "g", "n", "t"}
```

This is only analytical shorthand; it is not an XML element or an additional source attribute. The high-level partition is:

| Condition                                | Logical function                                      |
| ---------------------------------------- | ----------------------------------------------------- |
| `kind` not in `ignt` and `entryType="K"` | Node in the main classification hierarchy             |
| `kind` not in `ignt` and `entryType="I"` | Node in the secondary aspect-classification hierarchy |
| `kind` in `ignt`                         | Auxiliary search, presentation, or annotation record  |

`kind="g"` is the important mixed case within the auxiliary records: a guidance heading may group either `K` nodes or `I` nodes. The heading does not state that choice directly; it must be resolved from a non-`ignt` entry with the same `symbol`, as described in Section 4.1.

Treating all `ipcEntry` elements as nodes in one tree would therefore conflate two distinct classification hierarchies with headings, notes, subsection labels, and search indexes.

## 3. Functional classes of `ipcEntry`

### 3.1 Special `ignt` records

| `kind` | Interpreted function | Internal structure                                  | Scope model                                                                                              |
| :----: | -------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
|  `i`   | Subclass index       | Hierarchical `indexEntry` tree ending in references | Anchored by the entry's `symbol`/`endSymbol`; not part of the classification hierarchy                   |
|  `g`   | Guidance heading     | Title parts, sometimes with references              | Applies to a run of core places or classified aspects; routing requires same-symbol target resolution    |
|  `n`   | Semi-structured note | A `textBody` containing one or more note structures | Applies to the symbol or symbol range stated on the note entry                                           |
|  `t`   | Subsection title     | Title parts                                         | Applies to a symbol range and provides presentation-level grouping above or across classification places |

A `kind="i"` **subclass index** is a search aid. Its terms form hierarchical topic paths that end in references to classification symbols, but the terms do
not themselves constitute IPC classification places. Its internal `indexEntry` hierarchy must therefore not be confused with either of the two
classification hierarchies represented by nested `ipcEntry` elements.

In the observed file, these variants are terminal with respect to `ipcEntry`: they can contain other XML elements, but do not contain nested `ipcEntry`
elements. This should be validated when importing a new edition rather than silently assumed.

The official rendered scheme exposes the corresponding presentation structures. For example, subclass PDFs contain subclass indexes and guidance headings, while full-section contents expose subsection titles. Useful comparison material is the [IPC 2027.01 English scheme PDF directory](https://www.wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/), including [A01B](https://www.wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/a01b.pdf) as an example and the [full Section A scheme](https://www.wipo.int/classifications/data/ipc/ITSupport_and_download_area/20270101/pdf/scheme/full_ipc/en/ipc_en_a_full_ipc_20270101.pdf).

### 3.2 Structural records

An `ipcEntry` whose `kind` is **not** one of `i`, `g`, `n`, or `t` is treated as a structural node. Its `entryType` determines which hierarchy it belongs to:

| `entryType` | Relational interpretation                             |
| :---------: | ----------------------------------------------------- |
|     `K`     | Place in the main IPC classification hierarchy        |
|     `I`     | Node in the secondary aspect-classification hierarchy |

The name `entryType="I"` can misleadingly suggest a search index like `kind="i"`. It instead identifies real nodes in a secondary classification
hierarchy used to record common additional aspects of subject matter. It is therefore described here as the **aspect-classification hierarchy**. The
`entryType="I"` hierarchy and the `kind="i"` subclass index are structurally and logically different.

Structural records form the nested `ipcEntry` hierarchies remaining after the special records are removed. XML nesting is meaningful for these records: it determines the nearest structural parent in the corresponding hierarchy.

While IPC scheme specification also defines an auxiliary `entryType="D"`, such entries are not present in the current scheme and are intentionally outside the current model.

## 4. `symbol`: node identifier versus reference

The same attribute name has two different roles.

| Context                     | Meaning of `symbol`                                                                                                                     | Logical node ID? |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | :--------------: |
| Non-`ignt`, `entryType="K"` | Symbol of the core classification place represented by the element                                                                      |       Yes        |
| Non-`ignt`, `entryType="I"` | Symbol of the classified-aspect node represented by the element                                                                         |       Yes        |
| `kind="g"`                  | Start/anchor symbol identifying the structural entry whose type also determines whether the heading belongs to the core or index scheme |        No        |
| `kind="i"`                  | Anchor or start of the range for which the subclass index is supplied                                                                   |        No        |
| `kind="n"`                  | Anchor or start of the range to which the note applies                                                                                  |        No        |
| `kind="t"`                  | Anchor or start of the range covered by the subsection title                                                                            |        No        |

For a structural record, `symbol` identifies the node encoded by that element. For an `ignt` record, it describes attachment or scope. It should not be treated as a primary key for the auxiliary record and it does not make that record a second copy of the same structural node.

`endSymbol`, where present, completes the scope range. The pair `(symbol, endSymbol)` describes applicability; it is not necessarily a unique
record identifier. Multiple auxiliary records may legitimately be anchored to the same structural symbol or range.

This distinction also explains why a special record's immediate XML parent is not stored merely to infer its IPC scope. For these records, scope is stated by `symbol` and `endSymbol`; XML placement is primarily a source-organization fact.

### 4.1 Guidance-heading resolution

`kind="g"` needs an additional resolution step because the source does not state whether the heading groups core places or classified aspects.

For each guidance entry:

1. take the guidance entry's `symbol`;
2. find an `ipcEntry` with the same `symbol`;
3. exclude all candidates whose `kind` is in `ignt`;
4. read the remaining structural target's `entryType`;
5. route `K` to `gheadings_core` and `I` to `gheadings_index`.

The target type is a routing discriminator only and is not stored. Resolution is by same-symbol structural lookup, **not** by the guidance entry's XML parent. Missing targets or conflicting eligible target types should be treated as audit failures rather than guessed.

### 4.2 References inside content

The source also contains explicit reference elements:

- `<sref ref="...">` identifies one symbol;
- `<mref ref="..." endRef="...">` identifies a symbol range.

These are references by definition and are distinct from the overloaded `ipcEntry/@symbol` issue. Their relational representation depends on context:
guidance and subclass-index references are normalized, whereas reference markup inside notes and place titles is currently preserved.

## 5. XML-model-aware parsing strategy

Parsing is a staged decomposition of one mutable XML tree. Each stage extracts one understood record class and removes the corresponding `ipcEntry` subtrees. Later stages therefore operate on a progressively simpler residual model.

```mermaid
flowchart TD
    A["Complete IPC XML tree"] --> B["Resolve same-symbol guidance targets"]
    B --> C["Extract t: subsections"]
    C --> D["Extract g: guidance headings"]
    D --> E["Extract i: subclass index paths"]
    E --> F["Extract n: note XML"]
    F --> G["Extract entryType I: classified aspects"]
    G --> H["Residual entryType K: places"]
```

Guidance target resolution must occur while the complete tree is still available. Extraction then proceeds in this order:

1. `kind="t"` — subsection titles;
2. `kind="g"` — guidance headings, routed using the precomputed target types;
3. `kind="i"` — subclass index paths;
4. `kind="n"` — notes retained as XML;
5. remaining `entryType="I"` — classified-aspect hierarchy;
6. remaining `entryType="K"` — core classification-place hierarchy.

This order is not merely an implementation convenience. It corresponds to the source model:

- the four special kinds are extracted according to their own internal grammar;
- removing them prevents presentation and annotation records from contaminating structural parentage;
- classified aspects are then separated from core classification places;
- after the earlier removals, the residual tree has a much narrower and more auditable interpretation.

### 5.1 Ownership boundaries

When collecting content owned by one `ipcEntry`, nested `ipcEntry` elements are boundaries. A parent's title, note, or index content must not accidentally absorb the content of a structural descendant.

Likewise, internal hierarchies must be followed according to their own element type:

- `indexEntry` nesting defines subclass-index paths;
- remaining `entryType="I"` nesting defines classified-aspect parents;
- remaining `entryType="K"` nesting defines classification-place parents.

### 5.2 Validation before interpretation

The parser should fail visibly when an observed structural invariant changes. At minimum, each edition should be checked for:

- nested `ipcEntry` elements inside any `ignt` record;
- unresolved or ambiguously resolved guidance symbols;
- `kind="i"` subtrees without `indexEntry` descendants;
- terminal index entries without references;
- missing required `ref` or `endRef` attributes;
- malformed or multiply owned note bodies;
- residual `ipcEntry` records that are neither modelled `I` nor `K` entries;
- duplicate structural symbols within a relational hierarchy;
- parent symbols that do not resolve within the same hierarchy.

## 6. Relational model

The relational model deliberately uses separate tables for source structures with different identity, hierarchy, and content semantics.

| Table                | Columns                                     | One row represents                                        |
| -------------------- | ------------------------------------------- | --------------------------------------------------------- |
| `subsections`        | `title_parts, symbol, endSymbol`            | One `kind="t"` auxiliary record                           |
| `gheadings_core`     | `title_parts, symbol, endSymbol, refs`      | One `kind="g"` heading applying to core places            |
| `gheadings_index`    | `title_parts, symbol, endSymbol, refs`      | One `kind="g"` heading applying to classified aspects     |
| `index_terms`        | `symbol, endSymbol, terms, refs`            | One root-to-terminal path through a `kind="i"` index tree |
| `notes`              | `symbol, endSymbol, note_xml`               | One `kind="n"` auxiliary record                           |
| `classified_aspects` | `kind, symbol, parent_symbol, terms`        | One structural non-`ignt`, `entryType="I"` node           |
| `places`             | `kind, symbol, parent_symbol, terms, notes` | One structural non-`ignt`, `entryType="K"` node           |

JSON values are stored in SQLite `TEXT` columns and constrained to the expected JSON container type. A one-item collection remains an array. Absence of an optional structured value is SQL `NULL`, not serialized JSON `null`.

### 6.1 `subsections`

```sql
subsections(title_parts, symbol, endSymbol)
```

- `title_parts`: JSON array containing the textual content of each owned `titlePart` in source order;
- `symbol`, `endSymbol`: copied scope boundaries.

Subsections are presentation-level range labels, not hierarchy nodes. Their symbols are therefore not converted into parent links or primary keys.

### 6.2 `gheadings_core` and `gheadings_index`

```sql
gheadings_core(title_parts, symbol, endSymbol, refs)
gheadings_index(title_parts, symbol, endSymbol, refs)
```

The tables are structurally identical. Separation records the resolved target domain without retaining a redundant `group_type` column.

References in a title part are replaced by zero-based `{ref[N]}` placeholders. The corresponding `refs` JSON array preserves source order:

```json
{"sref": "A01B0001000000"}
{"mref": ["A01B0003000000", "A01B0007000000"]}
```

A grammatical list may be stored as a nested array referenced by one placeholder. `refs` is SQL `NULL` when the title contains no parsed references.

Index guidance headings also receive conservative boilerplate normalization:

```text
Indexing scheme associated with group {ref[0]}, relating to CAD techniques.
→ CAD techniques - {ref[0]}

Indexing scheme associated with group {ref[0]}.
→ {ref[0]}
```

The normalization removes a leading `The`, removes one final period, and changes only the first cased character to uppercase so acronyms such as `CAD`, `AC`, and `CHP` are preserved. An unknown title beginning with `Indexing scheme` is an error rather than a candidate for approximate rewriting.

### 6.3 `index_terms`

```sql
index_terms(symbol, endSymbol, terms, refs)
```

One `kind="i"` subtree can contain a branching hierarchy of `indexEntry` elements. Each root-to-terminal path becomes one row.

- `terms`: JSON array of owned `<text>` values encountered from the path root to the terminal `indexEntry`, in logical top-to-bottom order;
- `refs`: nonempty JSON array parsed from the terminal entry's `<references>`;
- `sref`: stored as a symbol string;
- `mref`: stored as `[ref, endRef]`;
- comma and semicolon separator text: ignored because no stable distinction has been established.

The outer JSON array is retained even when a path or reference list contains one item.

The compact `refs` representation can be expanded into a uniform relational form when individual references need to be joined or filtered. The following query is the intended basis for a view that may be added to the parser later:

```sql
SELECT
    symbol,
    endSymbol,
    terms,
    CASE substr(r.value, 1, 1)
        WHEN '[' THEN
            r.value ->> '[0]'
        ELSE
            r.value
    END AS ref,
    CASE substr(r.value, 1, 1)
        WHEN '[' THEN
            r.value ->> '[1]'
        ELSE
            NULL
    END AS endRef
FROM index_terms, json_each(refs) AS r;
```

`json_each(refs)` emits one row per source reference. A scalar `sref` value becomes `ref` with `endRef` set to SQL `NULL`; a two-item `mref` array becomes its `ref` and `endRef` bounds. These names deliberately retain the source attributes used by `<sref>` and `<mref>`. The original `index_terms` row is therefore repeated once for each reference while its `symbol`, `endSymbol`, and `terms` values remain available for context. A future view can also expose `r.key` as a zero-based reference index if source order must be addressable explicitly. This query is documented for later use only; the current parser does not create the view.

### 6.4 `notes`

```sql
notes(symbol, endSymbol, note_xml)
```

Notes are not semantically flattened at this stage. The owned `<textBody>` root is renamed to `<xml>`, while its entire inner structure—including `<note>`, `<subnote>`, `<noteParagraph>`, `<sref>`, and `<mref>` — is preserved and beautified. The stored text begins with an XML declaration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xml xmlns="http://www.wipo.int/classifications/ipc/masterfiles">
  <note>
    ...
  </note>
</xml>
```

The synthetic `<xml>` root makes each database value a well-formed XML document. The declaration also allows tools such as DB Browser for SQLite to recognize the cell as XML automatically. Preserving XML is preferable to premature relational normalization because the observed note grammar is varied and only partially understood.

### 6.5 `classified_aspects`

```sql
classified_aspects(kind, symbol, parent_symbol, terms)
```

- `symbol`: logical identifier of the structural `I` node;
- `parent_symbol`: nearest enclosing `entryType="I"` node's symbol;
- `terms`: JSON array of the current node's meaningful title parts only.

Ancestor titles are not repeated in `terms`; hierarchy is represented once by `parent_symbol`. One or several title parts therefore become `["Term"]` or
`["Term A", "Term B"]` respectively.

Titles matching formulaic `Indexing scheme associated with <word>` wording are treated as unnamed grouping labels. A top-level grouping node stores SQL `NULL` in `terms`; a nested grouping node stores `[]`. The row itself remains because it still participates in the structural hierarchy.

### 6.6 `places`

```sql
places(kind, symbol, parent_symbol, terms, notes)
```

- `kind`: hierarchy level;
- `symbol`: logical identifier of the core classification place;
- `parent_symbol`: nearest enclosing `entryType="K"` place's symbol;
- `terms`: positional JSON array with one string per owned `titlePart`;
- `notes`: optional JSON object containing `entryReference` content associated with individual title-part positions.

Only `<text>` content contributes to each term. Inline `<sref>` and `<mref>` markup inside `<text>` is retained as XML rather than converted to symbol values. An empty string preserves a title-part slot when needed, preventing later `terms_N` keys from shifting.

For each title part containing `entryReference` elements, `notes` uses a zero-based positional key:

```json
{
  "terms_0": [
    "combined with apparatus performing additional operations while mowing <mref endRef=\"A01D0041000000\" ref=\"A01D0037000000\" />, <sref ref=\"A01D0043000000\" />",
    "convertible to apparatus for purposes other than mowing <sref ref=\"A01D0042000000\" />"
  ]
}
```

Each `terms_N` value is a flat array of strings, one string per `entryReference`. The prose, punctuation, and nested reference markup remain
unparsed. `notes` is SQL `NULL` when no `entryReference` occurs.

## 7. Post-processing principles

Post-processing is intentionally asymmetric because different source structures have been understood to different degrees.

1. **Normalize only where the source grammar is narrow and deterministic.** Guidance references and index-terminal references have explicit element types and required attributes, so they can be represented as JSON safely.
2. **Preserve source markup where semantics remain uncertain.** Notes and place `entryReference` content remain XML-bearing strings instead of being split into speculative relational fields.
3. **Separate hierarchy from labels.** Parent links store structural ancestry; title arrays store only node-local labels rather than denormalized paths.
4. **Retain positional information.** JSON arrays and `terms_N` keys preserve source order and association with a particular title part.
5. **Use SQL `NULL` for absence.** JSON arrays and objects represent present collections, including deliberately empty collections; SQL `NULL` means the
   optional value is absent.
6. **Reject unknown boilerplate variants.** A strict failure is safer than a plausible-looking but semantically wrong transformation.

## 8. Why the model is split into multiple tables

A single `ipc_entries` table would obscure several incompatible notions:

- node identity versus range attachment;
- classification hierarchy versus internal index hierarchy;
- core classification versus classified-aspect domains;
- normalized references versus preserved XML fragments;
- node-local titles versus path-expanded index terms.

The multi-table model makes these distinctions explicit. It also avoids manufacturing universal synthetic identifiers for auxiliary records whose
source symbols are scope anchors rather than record IDs.

The split is therefore semantic normalization, not merely a convenience for the current workflow.

## 9. Known limitations and open work

- The observations need to be repeated against later IPC editions to distinguish stable invariants from 2027.01-specific regularities.
- `entryType="D"` is deliberately not modelled here.
- Source `edition` values and global source-order fields are not retained in the current relational model.
- Notes remain semi-structured XML and require a separate structural survey before further normalization.
- References preserved inside place terms, place notes, and note XML are not yet exposed as relational edges.
- The meaning of absent `endSymbol` should be documented from authoritative IPC specifications or validated systematically before an inferred range rule is encoded.
- Candidate keys, uniqueness constraints, and foreign-key constraints should be enabled only after full-scheme audits confirm the relevant invariants.
- The relational model captures the imported edition, not cross-edition symbol continuity, renaming, creation, deletion, or transfer history.

## 10. Included scripts

The [`scripts/`](scripts/) directory contains the current relational importer and supporting utilities used to inspect or isolate parts of the XML model. `ipc_scheme_to_sqlite.py` implements the relational model documented above; the other scripts are focused audit tools, extractors, format converters, or earlier modelling experiments.

| Script | Function and use |
| --- | --- |
| [`replace.py`](scripts/replace.py) | Hard-coded byte-replacement experiment that writes an `_notext` copy of one scheme file; edit its path and byte patterns before use. |
| [`extract_entryType_I.py`](scripts/extract_entryType_I.py) | Extracts the outermost complete `entryType="I"` subtrees to a standalone XML document while retaining nested matching entries. |
| [`extract_ipc_entries.py`](scripts/extract_ipc_entries.py) | Successively extracts `kind="t"`, `kind="g"`, `kind="i"`, `entryType="I"`, and `kind="n"` subtrees into separate XML files for structural inspection. |
| [`extract_kind_n_under_entrytype_i.py`](scripts/extract_kind_n_under_entrytype_i.py) | Extracts every `kind="n"` subtree occurring below an `entryType="I"` entry. |
| [`ipc_entries_to_sqlite.py`](scripts/ipc_entries_to_sqlite.py) | Creates a flat SQLite inventory of every `ipcEntry` and its `kind`, `entryType`, `symbol`, and `endSymbol` attributes. |
| [`ipc_entries_to_sqlite_grouped.py`](scripts/ipc_entries_to_sqlite_grouped.py) | Earlier relational prototype that separates `K`, `I`, and `ignt` entries and records selected immediate relationships. |
| [`ipc_entry_stats.py`](scripts/ipc_entry_stats.py) | Reports `ipcEntry` counts by `kind`, by `entryType`, and by their combinations, as tables or JSON. |
| [`ipc_scheme_core.py`](scripts/ipc_scheme_core.py) | Produces a beautified `_core.xml` copy after removing all `ignt` and `entryType="I"` subtrees. |
| [`ipc_scheme_to_sqlite.py`](scripts/ipc_scheme_to_sqlite.py) | Implements the staged XML-aware conversion into the normalized SQLite tables documented in Section 6. |
| [`ipc_xml_to_treeline.py`](scripts/ipc_xml_to_treeline.py) | Projects every `ipcEntry` and its XML attributes into a TreeLine hierarchy for interactive exploration. |
| [`list_xml_tags.py`](scripts/list_xml_tags.py) | Inventories XML tag counts, attribute names, and immediate parent-child tag pairs in SQLite. |

## 11. Summary

The essential interpretation is:

```text
non-ignt ipcEntry  → structural node; symbol attribute identifies that node
ignt ipcEntry      → auxiliary record; symbol/endSymbol attributes describe attachment or scope
```

Parsing should therefore begin by resolving and removing the special record classes according to their own grammars. Only then should the remaining `I` and `K` entries be read as two structural hierarchies and projected into `classified_aspects` and `places`.

This distinction is the foundation of the XML-aware parsing strategy and of the relational schema derived from it.
