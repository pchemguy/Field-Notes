#!/usr/bin/env python3
"""Convert the structural content of a WIPO IPC scheme to relational SQLite.

Purpose and source of truth
---------------------------
The input IPC XML document is the sole source of imported records, ordering,
symbols, ranges, hierarchy, title text, and reference markup. The importer does
not supplement the source from external taxonomies or infer omitted symbols.
Its only semantic transformations are the deterministic reference and
boilerplate rules documented below.

Processing model
----------------
The complete document is parsed into a mutable :mod:`xml.etree.ElementTree`.
Stages run sequentially in source order and remove their processed
``ipcEntry`` subtrees before the next stage observes the residual tree:

1. ``kind="t"`` entries become ``subsections``.
2. ``kind="g"`` entries become core or indexing guidance headings.
3. ``kind="i"`` subtrees become root-to-terminal index-term paths.
4. ``kind="n"`` entries become declared, well-formed XML note fragments.
5. remaining ``entryType="I"`` nodes become ``classified_aspects``.
6. remaining ``entryType="K"`` nodes become the ``places`` hierarchy.

The whole-tree representation deliberately favors a clear extraction model
over bounded memory use. Large future editions should be measured before this
prototype is treated as a streaming or production-scale importer.

Owned tables and column contracts
---------------------------------
The script owns and may rebuild these tables:

* ``subsections(title_parts, symbol, endSymbol)``;
* ``gheadings_core(title_parts, symbol, endSymbol)``;
* ``gheadings_index(title_parts, symbol, endSymbol, refs)``;
* ``gheading_index_exclusions(target_list, exclusion_list)``;
* ``index_terms(symbol, endSymbol, terms, refs)``;
* ``notes(symbol, endSymbol, note_xml)``;
* ``classified_aspects(kind, symbol, parent_symbol, terms)``; and
* ``places(kind, symbol, parent_symbol, terms, notes)``.

JSON columns are stored as UTF-8-capable SQLite ``TEXT`` and constrained with
SQLite JSON functions. Arrays remain arrays even when they contain one item.
Optional structured values use SQL ``NULL``, not a serialized JSON ``null``.

Subsections
-----------
``title_parts`` is a JSON array containing the complete textual content of
each owned ``titlePart``. No ``sref`` or ``mref`` parsing is performed for this
table; ``symbol`` and ``endSymbol`` are copied from the source entry.

Guidance headings
-----------------
A guidance heading is routed by the ``entryType`` of the non-special
``ipcEntry`` having the same symbol: ``K`` goes to ``gheadings_core`` and ``I``
to ``gheadings_index``. The routing type is not stored. Core and indexing
guidance deliberately use different reference representations.

``gheadings_core`` does not parse references and has no ``refs`` column. Its
``title_parts`` strings retain inline ``sref`` and ``mref`` XML markup inside
the source ``text`` elements. ``gheadings_index`` uses temporary zero-based
``{ref[N]}`` pointers only while parsing. Stored titles contain only the cleaned
subject and no pointers. Its optional ``refs`` value is one target JSON list in
source order: ``sref`` becomes a symbol string and ``mref`` becomes
``[ref, endRef]``. Thus the former ``{"sref": ref}`` and
``{"mref": [ref, endRef]}`` object wrappers are not stored.

An indexing title may include a clause beginning with ``, with the exception
of``. The clause must then contain one or more punctuation-free words followed
by one reference-list pointer. Its reference list is removed from
``gheadings_index.refs`` and written with the main target list to
``gheading_index_exclusions(target_list, exclusion_list)``. Both columns use
the same flat-list convention as ``gheadings_index.refs``.

Indexing guidance headings also receive strict boilerplate cleanup. Recognized
association and exclusion forms retain only their subject. Pure associations
have no meaningful subject and are omitted from the stored ``title_parts``
array. If filtering leaves the complete array empty, the
``gheadings_index`` row is not stored. A leading ``the`` and one terminal
period are removed from an extracted subject, whose first cased character is
uppercased without lowercasing acronyms. Reference-free headings retain SQL
``NULL`` in ``refs``. An unrecognized title beginning with ``Indexing scheme``
is rejected rather than partially rewritten.

Index terms
-----------
Each terminal ``indexEntry`` under a ``kind="i"`` subtree produces one row.
``terms`` is a JSON array of all owned ``text`` values encountered along that
root-to-terminal path. Terminal ``references`` must produce a nonempty ``refs``
array: ``sref`` is a symbol string and ``mref`` is ``[ref, endRef]``. Separator
punctuation is ignored and reference order is preserved.

Notes
-----
Each ``kind="n"`` entry must own exactly one ``textBody``. The wrapper is
renamed to ``xml`` without changing the enclosed note elements, indented, and
stored in ``note_xml`` with an XML 1.0 UTF-8 declaration at byte zero.

Classified aspects
------------------
Remaining ``entryType="I"`` nodes retain ``kind``, ``symbol``, and the nearest
enclosing I node's symbol. ``terms`` contains only the current node's meaningful
title parts; it does not accumulate ancestor terms. Recognized
``Indexing scheme associated with <word>`` grouping titles are omitted.
Grouping-only top-level nodes use SQL ``NULL`` and grouping-only nested nodes
use ``[]``. Flexible comma/``and``/``or`` noise before ``relating to`` is
removed from recognized boilerplate.

Places
------
Remaining ``entryType="K"`` nodes are stored as
``places(kind, symbol, parent_symbol, terms, notes)``. ``parent_symbol`` is the
nearest enclosing K node's symbol. ``terms`` has one positional string per
owned ``titlePart`` and is built only from its ``text`` elements. Inline XML,
including ``sref`` and ``mref``, remains markup rather than becoming reference
values. A title part without text retains an empty-string slot so ``terms_N``
indexes do not shift.

Each owned ``entryReference`` contributes one inner-XML string containing its
prose, separators, and unchanged inline tags. For every affected title part,
``notes`` maps its zero-based ``terms_N`` key to a flat JSON array of those
strings. ``notes`` is SQL ``NULL`` when no entry reference occurs.

Database lifecycle and safety
-----------------------------
The output path is the XML path with its suffix replaced by ``.db``. Existing
database files are reused. By default, every owned table is dropped and rebuilt
inside one transaction; unrelated tables are untouched. The obsolete owned
table ``gheadings`` is also removed in default mode.

With ``--preserve-existing-tables``, each existing owned table is independently
left untouched and reported as skipped, while missing owned tables are created.
All XML extraction still runs so later stages always see the same residual tree.
XML parsing and row construction finish before ``BEGIN IMMEDIATE``. A parsing,
validation, or SQLite failure therefore cannot partially replace owned tables;
the database transaction is rolled back. Rerunning default mode is deterministic
for a fixed input document and SQLite JSON implementation.

Command line and exit status
----------------------------
The XML path is optional. When absent, exactly one regular file matching
``EN_ipc_scheme_YYYYMMDD.xml`` must exist in the current directory; the eight-
digit edition date is discovered and never hardcoded. Exit status ``0`` means
success, ``1`` means XML/import/database failure, and ``2`` means input
selection or command-line usage failure. Diagnostics are written to stderr;
per-table results are written to stdout.

Runtime requirements
--------------------
The implementation uses only the Python standard library and requires SQLite
JSON scalar functions such as ``json_valid`` and ``json_type``. This revision
was exercised with Python 3.12.13 and SQLite 3.53.1.
"""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import TypedDict
from xml.sax.saxutils import escape


DEFAULT_SCHEME_PATTERN = re.compile(r"^EN_ipc_scheme_\d{8}\.xml$")
REFERENCE_LIST_SEPARATOR = re.compile(
    r"(?:\s*,\s*(?:and\s+)?|\s+and\s+)",
    re.IGNORECASE,
)
REFERENCE_POINTER_PATTERN = r"\{ref\[\d+\]\}"
REFERENCE_POINTER_INDEX_PATTERN = re.compile(r"\{ref\[(\d+)\]\}")
EXCLUSION_DESCRIPTOR_WORD_PATTERN = r"[^\W\d_]+"
INDEX_EXCEPTION_PATTERN = re.compile(
    rf"^Indexing scheme\s*,?\s*associated with groups?\s+"
    rf"(?P<scope>{REFERENCE_POINTER_PATTERN})\s*,\s*"
    rf"with the exception of\s+"
    rf"(?P<exclusion_descriptor>{EXCLUSION_DESCRIPTOR_WORD_PATTERN}"
    rf"(?:\s+{EXCLUSION_DESCRIPTOR_WORD_PATTERN})*)\s+"
    rf"(?P<excluded>{REFERENCE_POINTER_PATTERN})\s*,?\s*"
    rf"(?:and\s+)?relating to\s+(?P<subject>.+)$",
    re.IGNORECASE,
)
INDEX_ASSOCIATED_SUBJECT_PATTERN = re.compile(
    rf"^Indexing scheme\s*,?\s*associated with groups?\s+"
    rf"(?P<scope>{REFERENCE_POINTER_PATTERN})\s*,?\s*"
    rf"(?:and\s+)?relating to\s+(?P<subject>.+)$",
    re.IGNORECASE,
)
INDEX_PURE_ASSOCIATION_PATTERN = re.compile(
    rf"^Indexing scheme\s*,?\s*associated with groups?\s+"
    rf"(?P<scope>{REFERENCE_POINTER_PATTERN})$",
    re.IGNORECASE,
)
INDEX_ASSOCIATED_WITHOUT_REFERENCE_PATTERN = re.compile(
    r"^Indexing scheme\s*,?\s*associated with groups?\s+"
    r"(?:and\s+)?relating to\s+(?P<subject>.+)$",
    re.IGNORECASE,
)
INDEX_RELATED_SUBJECT_PATTERN = re.compile(
    r"^Indexing scheme\s+(?:relating|related) to\s+(?P<subject>.+)$",
    re.IGNORECASE,
)
CLASSIFIED_SCOPE_WORD_PATTERN = r"[^\W\d_]+"
CLASSIFIED_GROUPING_TITLE_PATTERN = re.compile(
    rf"^Indexing\s+scheme\s*,?\s*associated\s+with\s+"
    rf"{CLASSIFIED_SCOPE_WORD_PATTERN}\s*[,;:]?\s*$",
    re.IGNORECASE,
)
CLASSIFIED_RELATING_TITLE_PATTERN = re.compile(
    rf"^Indexing\s+scheme\s*,?\s*associated\s+with\s+"
    rf"{CLASSIFIED_SCOPE_WORD_PATTERN}"
    r"(?:(?:\s*[,;]\s*)|(?:\s+(?:and|or)\s+))*"
    r"\s*relating\s+to\s*(?P<subject>.*)$",
    re.IGNORECASE,
)


class SrefDefinition(TypedDict):
    """Represent one temporary guidance-heading ``sref`` definition.

    Attributes:
        sref: Required IPC symbol copied from the XML element's ``ref``
            attribute.
    """

    sref: str


class MrefDefinition(TypedDict):
    """Represent one temporary guidance-heading ``mref`` definition.

    Attributes:
        mref: Two-item list containing ``ref`` and ``endRef`` in that order.
    """

    mref: list[str]


ReferenceDefinition = SrefDefinition | MrefDefinition
ReferenceEntry = ReferenceDefinition | list[ReferenceDefinition]
TitleToken = str | ReferenceDefinition
SubsectionRow = tuple[str, str | None, str | None]
GuidanceHeadingRow = tuple[
    str,
    str | None,
    str | None,
    str | None,
    str | None,
]
CoreGuidanceHeadingRow = tuple[
    str,
    str | None,
    str | None,
]
IndexGuidanceHeadingRow = tuple[
    str,
    str | None,
    str | None,
    str | None,
]
GuidanceExclusionRow = tuple[str, str]
IndexReference = str | list[str]
IndexTermRow = tuple[str | None, str | None, str, str]
NoteRow = tuple[str | None, str | None, str]
ClassifiedAspectRow = tuple[str | None, str | None, str | None, str | None]
PlaceNotes = dict[str, list[str]]
PlaceRow = tuple[
    str | None,
    str | None,
    str | None,
    str,
    str | None,
]
HeadingRow = SubsectionRow | GuidanceHeadingRow


def normalized_subject(subject: str) -> str:
    """Normalize one extracted index subject without damaging capitalization.

    Whitespace is collapsed, one final period and a leading definite article
    ``the`` are removed, and only the first cased character is uppercased.
    Unlike ``str.capitalize()``, this preserves later uppercase characters in
    terms such as ``CAD``, ``AC``, and ``CHP``.

    Args:
        subject: Subject text captured after an indexing boilerplate phrase.

    Returns:
        Normalized subject suitable for a guidance-heading title part.

    Raises:
        ValueError: If normalization leaves no subject text.
    """

    result = " ".join(subject.split())
    if result.endswith("."):
        result = result[:-1].rstrip()
    if result[:4].casefold() == "the ":
        result = result[4:]
    if not result:
        raise ValueError("indexing boilerplate has an empty subject")
    for index, character in enumerate(result):
        if character.isalpha():
            return result[:index] + character.upper() + result[index + 1 :]
    return result


def reference_pointer_index(pointer: str) -> int:
    """Extract the zero-based integer from one complete reference pointer.

    Args:
        pointer: String expected to have the exact form ``{ref[N]}``.

    Returns:
        Nonnegative pointer index ``N``.

    Raises:
        ValueError: If ``pointer`` does not have the required complete form.
    """

    match = REFERENCE_POINTER_INDEX_PATTERN.fullmatch(pointer)
    if match is None:
        raise ValueError(f"invalid guidance reference pointer: {pointer!r}")
    return int(match.group(1))


def parse_index_title_part(
    title_part: str,
) -> tuple[str | None, int | None, int | None]:
    """Parse one index-guidance title into subject and reference roles.

    Non-boilerplate values are returned exactly as supplied. A title beginning
    with ``Indexing scheme`` must match one supported complete formulation;
    otherwise it is rejected so a new source phrase cannot be silently
    misinterpreted by a partial match.

    Args:
        title_part: Rendered title part containing temporary ``{ref[N]}``
            pointers where source reference lists occurred.

    Returns:
        Tuple of cleaned subject (or ``None`` for a pure association), target
        pointer index, and exclusion pointer index. Reference-free forms use
        ``None`` for both indexes.

    Raises:
        ValueError: If indexing boilerplate has an unknown formulation.
    """

    if not title_part.casefold().startswith("indexing scheme"):
        return title_part, None, None

    candidate = " ".join(title_part.split())
    if candidate.endswith("."):
        candidate = candidate[:-1].rstrip()

    match = INDEX_EXCEPTION_PATTERN.fullmatch(candidate)
    if match:
        return (
            normalized_subject(match.group("subject")),
            reference_pointer_index(match.group("scope")),
            reference_pointer_index(match.group("excluded")),
        )

    match = INDEX_ASSOCIATED_SUBJECT_PATTERN.fullmatch(candidate)
    if match:
        return (
            normalized_subject(match.group("subject")),
            reference_pointer_index(match.group("scope")),
            None,
        )

    match = INDEX_PURE_ASSOCIATION_PATTERN.fullmatch(candidate)
    if match:
        return None, reference_pointer_index(match.group("scope")), None

    match = INDEX_ASSOCIATED_WITHOUT_REFERENCE_PATTERN.fullmatch(candidate)
    if match:
        return normalized_subject(match.group("subject")), None, None

    match = INDEX_RELATED_SUBJECT_PATTERN.fullmatch(candidate)
    if match:
        return normalized_subject(match.group("subject")), None, None

    raise ValueError(f"unsupported indexing title boilerplate: {title_part!r}")


def clean_index_title_part(title_part: str) -> str | None:
    """Return only the pointer-free subject parsed from one title part.

    Args:
        title_part: Rendered title part containing any temporary pointers.

    Returns:
        Cleaned subject, unchanged non-boilerplate content, or ``None`` when a
        pure association has no meaningful title beyond its target list.

    Raises:
        ValueError: If indexing boilerplate has an unknown formulation.
    """

    cleaned, _, _ = parse_index_title_part(title_part)
    return cleaned


def clean_index_title_parts(title_parts_json: str) -> str:
    """Clean every title part in a serialized indexing-heading JSON array.

    Args:
        title_parts_json: JSON array produced by guidance-title extraction.

    Returns:
        A JSON array serialized using the importer's standard settings.

    Raises:
        ValueError: If the JSON value is not an array of strings or a title
            contains unsupported indexing boilerplate.
    """

    title_parts = json.loads(title_parts_json)
    if not isinstance(title_parts, list) or not all(
        isinstance(part, str) for part in title_parts
    ):
        raise ValueError("index guidance title_parts must be an array of strings")
    cleaned_title_parts = [
        cleaned
        for part in title_parts
        if (cleaned := clean_index_title_part(part)) is not None
    ]
    if cleaned_title_parts == title_parts:
        return title_parts_json
    return json.dumps(cleaned_title_parts, ensure_ascii=False)


def flatten_guidance_reference_entry(entry: object) -> list[IndexReference]:
    """Remove temporary object wrappers from one guidance reference list.

    Args:
        entry: Parsed JSON value produced for one temporary ``{ref[N]}``
            pointer. It must be one reference-definition object or a
            grammatical list of such objects.

    Returns:
        Flat list in source order where ``sref`` is a string and ``mref`` is a
        two-string ``[ref, endRef]`` range.

    Raises:
        ValueError: If the temporary entry has an unexpected JSON shape.
    """

    definitions = [entry] if isinstance(entry, dict) else entry
    if not isinstance(definitions, list) or not definitions:
        raise ValueError("guidance reference entry must be a nonempty list")

    flattened: list[IndexReference] = []
    for definition in definitions:
        if not isinstance(definition, dict) or len(definition) != 1:
            raise ValueError("guidance reference definition must be one object")
        if "sref" in definition:
            ref = definition["sref"]
            if not isinstance(ref, str) or not ref:
                raise ValueError("guidance sref definition must contain a symbol")
            flattened.append(ref)
            continue
        if "mref" in definition:
            ref_range = definition["mref"]
            if (
                not isinstance(ref_range, list)
                or len(ref_range) != 2
                or not all(isinstance(value, str) and value for value in ref_range)
            ):
                raise ValueError(
                    "guidance mref definition must contain ref and endRef"
                )
            flattened.append(ref_range)
            continue
        raise ValueError("unsupported guidance reference definition")
    return flattened


def normalize_index_guidance(
    title_parts_json: str,
    refs_json: str | None,
) -> tuple[str, str | None, GuidanceExclusionRow | None]:
    """Normalize one indexing heading's titles and reference-list roles.

    Temporary object-encoded reference entries are selected by pointers in the
    recognized title boilerplate. The main pointer becomes the heading's sole
    flat target list. An optional exclusion pointer becomes a separate row and
    is not retained in ``gheadings_index.refs``.

    Args:
        title_parts_json: JSON array of rendered title strings containing
            temporary reference pointers.
        refs_json: Temporary object-encoded reference-entry array, or ``None``
            for a reference-free heading.

    Returns:
        Pointer-free title-parts JSON, normalized target-list JSON or ``None``,
        and an optional ``(target_list, exclusion_list)`` row.

    Raises:
        ValueError: If JSON shapes, pointer roles, pointer indexes, or reference
            definitions are inconsistent.
    """

    title_parts = json.loads(title_parts_json)
    if not isinstance(title_parts, list) or not all(
        isinstance(part, str) for part in title_parts
    ):
        raise ValueError("index guidance title_parts must be an array of strings")

    cleaned_parts: list[str] = []
    target_indexes: set[int] = set()
    exclusion_indexes: set[int] = set()
    all_pointer_indexes: set[int] = set()
    for part in title_parts:
        all_pointer_indexes.update(
            int(value) for value in REFERENCE_POINTER_INDEX_PATTERN.findall(part)
        )
        cleaned, target_index, exclusion_index = parse_index_title_part(part)
        if cleaned is not None:
            cleaned_parts.append(cleaned)
        if target_index is not None:
            target_indexes.add(target_index)
        if exclusion_index is not None:
            exclusion_indexes.add(exclusion_index)

    normalized_titles = json.dumps(cleaned_parts, ensure_ascii=False)
    classified_indexes = target_indexes | exclusion_indexes
    if all_pointer_indexes != classified_indexes:
        raise ValueError(
            "index guidance contains a reference pointer without a recognized role"
        )

    if refs_json is None:
        if classified_indexes:
            raise ValueError("index guidance pointers have no refs array")
        return normalized_titles, None, None

    raw_entries = json.loads(refs_json)
    if not isinstance(raw_entries, list) or not raw_entries:
        raise ValueError("index guidance refs must be a nonempty array")
    if len(target_indexes) != 1:
        raise ValueError("index guidance must identify exactly one target list")
    if len(exclusion_indexes) > 1:
        raise ValueError("index guidance must identify at most one exclusion list")

    used_indexes = target_indexes | exclusion_indexes
    expected_indexes = set(range(len(raw_entries)))
    if used_indexes != expected_indexes:
        raise ValueError(
            "index guidance refs contain an unclassified or missing list"
        )

    target_index = next(iter(target_indexes))
    target_list = flatten_guidance_reference_entry(raw_entries[target_index])
    target_json = json.dumps(target_list, ensure_ascii=False)

    if not exclusion_indexes:
        return normalized_titles, target_json, None
    exclusion_index = next(iter(exclusion_indexes))
    exclusion_list = flatten_guidance_reference_entry(raw_entries[exclusion_index])
    exclusion_json = json.dumps(exclusion_list, ensure_ascii=False)
    return normalized_titles, target_json, (target_json, exclusion_json)


def local_name(name: str) -> str:
    """Remove an ElementTree namespace expansion from one XML name.

    Args:
        name: Plain name or ElementTree ``{namespace}local`` expanded name.

    Returns:
        The local portion after the final closing brace, or ``name`` unchanged
        when it is not namespace-expanded.
    """

    return name.rsplit("}", 1)[-1]


def element_text(element: ET.Element) -> str:
    """Collect all descendant character data from one XML element.

    Args:
        element: Element whose complete textual content is required.

    Returns:
        Concatenated :meth:`Element.itertext` content with outer whitespace
        removed. Internal source whitespace is otherwise retained.
    """

    return "".join(element.itertext()).strip()


def reference_definition(element: ET.Element) -> ReferenceDefinition:
    """Convert a reference element to its temporary pointer definition.

    ``sref`` maps to ``{"sref": ref}``; ``mref`` maps distinctly to
    ``{"mref": [ref, endRef]}``. These objects support temporary pointer-role
    parsing and are flattened before indexing guidance is stored.

    Args:
        element: ``sref`` or ``mref`` element to convert.

    Returns:
        JSON-ready mapping whose key preserves the reference element type.

    Raises:
        ValueError: If a required reference attribute is absent or empty.
            Also raised when ``element`` is neither ``sref`` nor ``mref``.
    """

    element_name = local_name(element.tag)
    ref = element.get("ref")
    if not ref:
        raise ValueError(f"{element_name} is missing its required ref attribute")
    if element_name == "sref":
        return {"sref": ref}
    if element_name == "mref":
        end_ref = element.get("endRef")
        if not end_ref:
            raise ValueError("mref is missing its required endRef attribute")
        return {"mref": [ref, end_ref]}
    raise ValueError(f"unsupported reference element: {element_name}")


def inline_title_part(
    element: ET.Element,
    references: list[ReferenceEntry],
) -> str:
    """Render a title part and append its reference entries separately.

    A single reference becomes one entry. Adjacent references separated only
    by comma/``and`` list grammar become one nested-list entry. Each entry is
    replaced inline by ``{ref[N]}``, using its zero-based index in
    ``references``.

    Args:
        element: ``titlePart`` element whose mixed content should be rendered.
        references: Mutable destination list. New reference definitions are
            appended and pointer indexes are based on its existing length.

    Returns:
        Trimmed title string containing zero-based reference pointers.

    Raises:
        ValueError: If an encountered ``sref`` or ``mref`` lacks a required
            attribute.

    Notes:
        Separator text consumed as grammatical list syntax is not emitted in
        the rendered title because the complete list has one pointer.
    """

    tokens: list[TitleToken] = []

    def append_text(text: str | None) -> None:
        """Append character data while coalescing adjacent string tokens.

        Args:
            text: Optional XML text or tail content.

        Returns:
            ``None``.
        """

        if not text:
            return
        if tokens and isinstance(tokens[-1], str):
            tokens[-1] += text
        else:
            tokens.append(text)

    def visit(parent: ET.Element) -> None:
        """Tokenize mixed title content recursively in document order.

        Args:
            parent: Element whose text, children, and child tails to visit.

        Returns:
            ``None``.
        """

        append_text(parent.text)
        for child in parent:
            child_name = local_name(child.tag)
            if child_name in {"sref", "mref"}:
                tokens.append(reference_definition(child))
            else:
                visit(child)
            append_text(child.tail)

    visit(element)
    rendered: list[str] = []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if isinstance(token, str):
            rendered.append(token)
            index += 1
            continue

        list_members = [token]
        next_index = index + 1
        while (
            next_index + 1 < len(tokens)
            and isinstance(tokens[next_index], str)
            and REFERENCE_LIST_SEPARATOR.fullmatch(tokens[next_index])
            and isinstance(tokens[next_index + 1], dict)
        ):
            list_members.append(tokens[next_index + 1])
            next_index += 2

        if len(list_members) == 1:
            reference_entry: ReferenceEntry = list_members[0]
        else:
            reference_entry = list_members
        reference_index = len(references)
        references.append(reference_entry)
        rendered.append(f"{{ref[{reference_index}]}}")
        index = next_index

    return "".join(rendered).strip()


def own_title_content(
    entry: ET.Element,
) -> tuple[list[str], list[ReferenceEntry]]:
    """Collect title parts and their ordered references for one ``ipcEntry``.

    Traversal stops at nested ``ipcEntry`` boundaries so a defensive or future
    source variant cannot accidentally assign a descendant entry's title to
    the enclosing subsection.

    Args:
        entry: Guidance ``ipcEntry`` whose owned title content is required.

    Returns:
        A pair containing rendered title-part strings and their shared ordered
        reference-entry list.

    Raises:
        ValueError: If reference parsing encounters an invalid ``sref`` or
            ``mref``.
    """

    title_parts: list[str] = []
    references: list[ReferenceEntry] = []

    def visit(element: ET.Element) -> None:
        """Collect owned title parts without crossing an IPC-entry boundary.

        Args:
            element: Current traversal element.

        Returns:
            ``None``.
        """

        for child in element:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "titlePart":
                title_parts.append(inline_title_part(child, references))
            else:
                visit(child)

    visit(entry)
    return title_parts, references


def own_plain_title_parts(entry: ET.Element) -> list[str]:
    """Collect owned title parts without parsing reference elements.

    Args:
        entry: Subsection ``ipcEntry`` whose title parts are required.

    Returns:
        Complete textual content of each owned ``titlePart`` in source order.

    Notes:
        Nested ``ipcEntry`` elements are ownership boundaries. Reference tags
        contribute only their character data, if any; their attributes are not
        inspected and no ``refs`` structure is produced.
    """

    title_parts: list[str] = []

    def visit(element: ET.Element) -> None:
        """Collect plain title parts owned by the requested IPC entry.

        Args:
            element: Current traversal element.

        Returns:
            ``None``.
        """

        for child in element:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "titlePart":
                title_parts.append(element_text(child))
            else:
                visit(child)

    visit(entry)
    return title_parts


def own_embedded_reference_title_parts(entry: ET.Element) -> list[str]:
    """Collect core-guidance title text while preserving inline XML tags.

    Only the contents of owned ``text`` elements contribute to each title-part
    string. The ``text`` wrapper itself is omitted, while child markup such as
    ``sref`` and ``mref`` is serialized unchanged instead of being converted
    into pointers or separate reference definitions.

    Args:
        entry: K-routed guidance ``ipcEntry`` whose title parts are required.

    Returns:
        One markup-preserving string per owned ``titlePart`` in source order.

    Notes:
        Nested ``ipcEntry`` elements are ownership boundaries. Multiple
        ``text`` elements within one title part are joined with one space.
    """

    title_parts: list[str] = []

    def visit(element: ET.Element) -> None:
        """Collect core title parts without entering nested IPC entries.

        Args:
            element: Current traversal element.

        Returns:
            ``None``.
        """

        for child in element:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "titlePart":
                text_values = [
                    inner_xml(text_element)
                    for text_element in child.iter()
                    if local_name(text_element.tag) == "text"
                ]
                title_parts.append(" ".join(text_values))
            else:
                visit(child)

    visit(entry)
    return title_parts


def collect_group_types(root: ET.Element) -> dict[str, str | None]:
    """Map symbols to entry types of corresponding non-``ignt`` entries.

    Same-symbol entries whose kind is ``i``, ``g``, ``n``, or ``t`` are
    deliberately ignored. Repeated eligible entries may agree on ``entryType``;
    conflicting non-null types are rejected as ambiguous.

    Args:
        root: Complete IPC tree before special-kind extraction.

    Returns:
        Mapping from every resolvable guidance-heading symbol to the sole
        matching non-special ``entryType`` or ``None`` when only untyped
        matching entries exist.

    Raises:
        ValueError: If eligible entries give one symbol conflicting entry types.
    """

    guidance_symbols = {
        element.get("symbol")
        for element in root.iter()
        if local_name(element.tag) == "ipcEntry"
        and element.get("kind") == "g"
        and element.get("symbol")
    }
    candidates: dict[str, set[str]] = {}
    symbols_with_untyped_entries: set[str] = set()
    for element in root.iter():
        if local_name(element.tag) != "ipcEntry":
            continue
        if element.get("kind") in {"i", "g", "n", "t"}:
            continue
        symbol = element.get("symbol")
        if not symbol or symbol not in guidance_symbols:
            continue
        entry_type = element.get("entryType")
        if entry_type is None:
            symbols_with_untyped_entries.add(symbol)
        else:
            candidates.setdefault(symbol, set()).add(entry_type)

    group_types: dict[str, str | None] = {}
    for symbol in candidates.keys() | symbols_with_untyped_entries:
        entry_types = candidates.get(symbol, set())
        if len(entry_types) > 1:
            values = ", ".join(sorted(entry_types))
            raise ValueError(
                f"ambiguous non-ignt entryType values for {symbol}: {values}"
            )
        group_types[symbol] = next(iter(entry_types), None)
    return group_types


def extract_entries(
    root: ET.Element,
    kind: str,
    parse_references: bool,
    group_types: dict[str, str | None] | None = None,
) -> list[HeadingRow]:
    """Extract rows of one ``kind`` and remove their entries from ``root``.

    All matches are collected before mutation. Consequently, even an unexpected
    nested matching entry is represented in the output, while removing an
    outer match still removes its complete subtree from the residual tree.

    Args:
        root: Mutable residual IPC tree.
        kind: Exact ``kind`` attribute to extract.
        parse_references: Whether to apply guidance-heading routing behavior.
            K-routed rows preserve inline markup; other rows render references
            into a separate ``refs`` value for subsequent index routing.
        group_types: Optional symbol-to-entryType routing map. It is consulted
            only when ``parse_references`` is true.

    Returns:
        Subsection-shaped rows when reference parsing is disabled, otherwise
        guidance-heading rows including the temporary routing value.

    Raises:
        ValueError: If indexing-guidance reference parsing encounters malformed
            data.

    Notes:
        Rows are fully constructed before any matching element is removed. The
        caller therefore never observes a partially extracted stage.
    """

    parents = {child: parent for parent in root.iter() for child in parent}
    entries = [
        element
        for element in root.iter()
        if local_name(element.tag) == "ipcEntry" and element.get("kind") == kind
    ]
    rows: list[HeadingRow] = []
    for entry in entries:
        if parse_references:
            symbol = entry.get("symbol")
            group_type = (
                group_types.get(symbol)
                if group_types is not None and symbol
                else None
            )
            if group_type == "K":
                title_parts = own_embedded_reference_title_parts(entry)
                serialized_references = None
            else:
                title_parts, references = own_title_content(entry)
                serialized_references = (
                    json.dumps(references, ensure_ascii=False)
                    if references
                    else None
                )
            rows.append(
                (
                    json.dumps(title_parts, ensure_ascii=False),
                    symbol,
                    entry.get("endSymbol"),
                    group_type,
                    serialized_references,
                )
            )
        else:
            rows.append(
                (
                    json.dumps(own_plain_title_parts(entry), ensure_ascii=False),
                    entry.get("symbol"),
                    entry.get("endSymbol"),
                )
            )

    for entry in entries:
        parent = parents.get(entry)
        if parent is not None and entry in parent:
            parent.remove(entry)

    return rows


def nearest_index_entries(element: ET.Element) -> list[ET.Element]:
    """Return the nearest descendant ``indexEntry`` elements in source order.

    Traversal stops at each discovered ``indexEntry`` boundary. This supports
    harmless wrapper elements without flattening deeper index hierarchy levels.

    Args:
        element: Element whose immediate logical index children are required.

    Returns:
        Nearest descendant ``indexEntry`` elements in document order.
    """

    entries: list[ET.Element] = []

    def visit(parent: ET.Element) -> None:
        """Find nearest logical index children through harmless wrappers.

        Args:
            parent: Current element whose children should be inspected.

        Returns:
            ``None``.
        """

        for child in parent:
            child_name = local_name(child.tag)
            if child_name == "indexEntry":
                entries.append(child)
            elif child_name == "ipcEntry":
                continue
            else:
                visit(child)

    visit(element)
    return entries


def own_index_texts(entry: ET.Element) -> list[str]:
    """Collect one ``indexEntry`` level's own ``text`` values in source order.

    Nested ``indexEntry`` subtrees are boundaries and therefore contribute
    their text only when their own path level is visited.

    Args:
        entry: Index entry whose own text values should be collected.

    Returns:
        Complete textual contents of matching ``text`` elements.
    """

    texts: list[str] = []

    def visit(parent: ET.Element) -> None:
        """Collect text owned by one index level.

        Args:
            parent: Current element below the selected ``indexEntry``.

        Returns:
            ``None``.
        """

        for child in parent:
            child_name = local_name(child.tag)
            if child_name == "indexEntry":
                continue
            if child_name == "text":
                texts.append(element_text(child))
            else:
                visit(child)

    visit(entry)
    return texts


def terminal_index_references(entry: ET.Element) -> list[IndexReference]:
    """Parse references belonging to one terminal ``indexEntry``.

    Only ``sref`` and ``mref`` elements beneath ``references`` containers are
    significant. Separator text and punctuation between them are ignored.

    Args:
        entry: Terminal index entry containing its reference targets.

    Returns:
        Reference strings and two-string ranges in XML source order.

    Raises:
        ValueError: If a reference omits a required attribute.
    """

    references: list[IndexReference] = []
    for container in entry.iter():
        if local_name(container.tag) != "references":
            continue
        for element in container.iter():
            element_name = local_name(element.tag)
            if element_name not in {"sref", "mref"}:
                continue
            ref = element.get("ref")
            if not ref:
                raise ValueError(
                    f"terminal index {element_name} is missing its required "
                    "ref attribute"
                )
            if element_name == "sref":
                references.append(ref)
                continue
            end_ref = element.get("endRef")
            if not end_ref:
                raise ValueError(
                    "terminal index mref is missing its required endRef attribute"
                )
            references.append([ref, end_ref])
    return references


def extract_index_terms(root: ET.Element) -> list[IndexTermRow]:
    """Extract root-to-leaf paths from every ``kind="i"`` subtree.

    Each terminal ``indexEntry`` produces one row. Terms accumulate from the
    logical root toward that terminal entry, while references come only from
    the terminal entry. All processed ``kind="i"`` entries are removed from the
    mutable residual tree after successful extraction.

    Args:
        root: Mutable IPC scheme root after earlier extraction stages.

    Returns:
        Index-term rows in subtree and terminal-path source order.

    Raises:
        ValueError: If a ``kind="i"`` subtree has no index entries or a terminal
            index entry has no parsed references.
    """

    parents = {child: parent for parent in root.iter() for child in parent}
    ipc_entries = [
        element
        for element in root.iter()
        if local_name(element.tag) == "ipcEntry" and element.get("kind") == "i"
    ]
    rows: list[IndexTermRow] = []

    for ipc_entry in ipc_entries:
        symbol = ipc_entry.get("symbol")
        end_symbol = ipc_entry.get("endSymbol")
        path_roots = nearest_index_entries(ipc_entry)
        if not path_roots:
            raise ValueError(
                f"kind='i' entry {symbol or '<missing symbol>'} has no indexEntry"
            )

        def descend(entry: ET.Element, inherited_terms: list[str]) -> None:
            """Emit rows for every terminal path below one index entry.

            Args:
                entry: Current logical index-path node.
                inherited_terms: Text values collected from higher path nodes.

            Returns:
                ``None``.

            Raises:
                ValueError: If a terminal entry has no parsed references or a
                    reference lacks a required attribute.
            """

            terms = inherited_terms + own_index_texts(entry)
            children = nearest_index_entries(entry)
            if children:
                for child in children:
                    descend(child, terms)
                return

            references = terminal_index_references(entry)
            if not references:
                raise ValueError(
                    "terminal indexEntry for "
                    f"{symbol or '<missing symbol>'} has no references"
                )
            rows.append(
                (
                    symbol,
                    end_symbol,
                    json.dumps(terms, ensure_ascii=False),
                    json.dumps(references, ensure_ascii=False),
                )
            )

        for path_root in path_roots:
            descend(path_root, [])

    for ipc_entry in ipc_entries:
        parent = parents.get(ipc_entry)
        if parent is not None and ipc_entry in parent:
            parent.remove(ipc_entry)

    return rows


def own_text_bodies(entry: ET.Element) -> list[ET.Element]:
    """Return ``textBody`` elements belonging directly to one ``ipcEntry``.

    Nested ``ipcEntry`` elements are treated as ownership boundaries even
    though current note entries are expected to be terminal IPC structures.

    Args:
        entry: IPC entry whose note body should be located.

    Returns:
        Owned ``textBody`` elements in source order.
    """

    bodies: list[ET.Element] = []

    def visit(parent: ET.Element) -> None:
        """Collect owned text bodies without entering nested IPC entries.

        Args:
            parent: Current traversal element.

        Returns:
            ``None``.
        """

        for child in parent:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "textBody":
                bodies.append(child)
            else:
                visit(child)

    visit(entry)
    return bodies


def namespace_uri(name: str) -> str | None:
    """Return an expanded XML name's namespace URI when present.

    Args:
        name: ElementTree tag name in local or ``{URI}local`` form.

    Returns:
        Namespace URI, or ``None`` for an unqualified name.
    """

    if name.startswith("{") and "}" in name:
        return name[1:].split("}", 1)[0]
    return None


def beautified_note_xml(text_body: ET.Element) -> str:
    """Replace ``textBody`` with ``xml`` and serialize the complete subtree.

    The body is deep-copied before its outer tag is renamed and indented,
    keeping the mutable source tree unchanged. When the source is namespaced,
    the replacement wrapper remains in that namespace so one declaration on
    ``xml`` covers every unchanged descendant tag.

    Args:
        text_body: Note body whose outer element should be replaced.

    Returns:
        One declared, well-formed, indented XML value rooted at ``xml``.
    """

    body = deepcopy(text_body)
    body.tail = None
    default_namespace = namespace_uri(text_body.tag)
    if default_namespace is None:
        body.tag = "xml"
    else:
        ET.register_namespace("", default_namespace)
        body.tag = f"{{{default_namespace}}}xml"
    ET.indent(body, space="  ")
    serialized_body = ET.tostring(
        body,
        encoding="unicode",
        short_empty_elements=True,
    )
    return '<?xml version="1.0" encoding="UTF-8"?>\n' + serialized_body


def extract_notes(root: ET.Element) -> list[NoteRow]:
    """Extract ``kind="n"`` bodies as unparsed, beautified XML fragments.

    One row is emitted for each note IPC entry in source order. The processed
    entries are then removed from the mutable residual tree.

    Args:
        root: Mutable IPC scheme root after earlier extraction stages.

    Returns:
        Note rows containing symbol, end symbol, and body XML.

    Raises:
        ValueError: If a note entry does not contain exactly one owned
            ``textBody`` element.
    """

    parents = {child: parent for parent in root.iter() for child in parent}
    entries = [
        element
        for element in root.iter()
        if local_name(element.tag) == "ipcEntry" and element.get("kind") == "n"
    ]
    rows: list[NoteRow] = []
    for entry in entries:
        symbol = entry.get("symbol")
        text_bodies = own_text_bodies(entry)
        if len(text_bodies) != 1:
            raise ValueError(
                f"kind='n' entry {symbol or '<missing symbol>'} has "
                f"{len(text_bodies)} textBody elements; expected exactly one"
            )
        rows.append(
            (
                symbol,
                entry.get("endSymbol"),
                beautified_note_xml(text_bodies[0]),
            )
        )

    for entry in entries:
        parent = parents.get(entry)
        if parent is not None and entry in parent:
            parent.remove(entry)

    return rows


def clean_classified_aspect_title(title: str) -> str | None:
    """Remove recognized indexing boilerplate from one I-node title.

    A complete ``Indexing scheme associated with <word>`` title is a nameless
    grouping component. When ``relating to`` follows that introduction, noisy
    commas and conjunctions are accepted and the remaining subject is retained.

    Args:
        title: Text extracted from one or more ``text`` elements.

    Returns:
        Meaningful title text, or ``None`` for a grouping-only title.
    """

    candidate = " ".join(title.split())
    if not candidate:
        return None
    match = CLASSIFIED_RELATING_TITLE_PATTERN.fullmatch(candidate)
    if match:
        subject = match.group("subject").strip()
        return subject or None
    if CLASSIFIED_GROUPING_TITLE_PATTERN.fullmatch(candidate):
        return None
    return title


def own_classified_title_texts(entry: ET.Element) -> list[str]:
    """Collect meaningful owned title-part text for one I node.

    Only ``text`` elements beneath owned ``titlePart`` elements contribute.
    Nested ``ipcEntry`` elements are ownership boundaries. Empty title parts
    and recognized grouping-only boilerplate are omitted.

    Args:
        entry: I entry whose title text should be collected.

    Returns:
        Cleaned meaningful title-part strings in source order.
    """

    title_parts: list[ET.Element] = []

    def find_title_parts(parent: ET.Element) -> None:
        """Locate title parts owned by one classified-aspect node.

        Args:
            parent: Current traversal element.

        Returns:
            ``None``.
        """

        for child in parent:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "titlePart":
                title_parts.append(child)
            else:
                find_title_parts(child)

    find_title_parts(entry)
    meaningful_parts: list[str] = []
    for title_part in title_parts:
        text_values: list[str] = []
        for element in title_part.iter():
            if local_name(element.tag) != "text":
                continue
            value = element_text(element)
            if value:
                text_values.append(value)
        cleaned = clean_classified_aspect_title(" ".join(text_values))
        if cleaned is not None:
            meaningful_parts.append(cleaned)
    return meaningful_parts


def classified_aspect_terms(entry: ET.Element) -> list[str] | None:
    """Build one I node's optional flat title-part array.

    Args:
        entry: ``entryType="I"`` IPC entry whose owned title parts are needed.

    Returns:
        Meaningful title-part strings, or ``None`` for an unnamed grouping node.
    """

    title_parts = own_classified_title_texts(entry)
    if not title_parts:
        return None
    return title_parts


def extract_classified_aspects(root: ET.Element) -> list[ClassifiedAspectRow]:
    """Extract remaining ``entryType="I"`` nodes and node-local terms.

    Each row stores the nearest enclosing I node's symbol and only the current
    node's flat title-part array. Unnamed top-level rows store SQL ``NULL``;
    unnamed nested rows store ``[]``. Outermost I subtrees are removed after
    all rows have been constructed.

    Args:
        root: Mutable IPC scheme root after all special-kind stages.

    Returns:
        Classified-aspect rows in deterministic XML source order.

    """

    parents = {child: parent for parent in root.iter() for child in parent}
    entries: list[ET.Element] = []
    rows: list[ClassifiedAspectRow] = []

    def visit(
        element: ET.Element,
        parent_i_entry: ET.Element | None,
    ) -> None:
        """Build I rows recursively while carrying the nearest I parent.

        Args:
            element: Current tree element.
            parent_i_entry: Nearest enclosing ``entryType="I"`` node, if any.

        Returns:
            ``None``.
        """

        current_parent = parent_i_entry
        if (
            local_name(element.tag) == "ipcEntry"
            and element.get("entryType") == "I"
        ):
            terms = classified_aspect_terms(element)
            if terms is None:
                serialized_terms = None if parent_i_entry is None else "[]"
            else:
                serialized_terms = json.dumps(terms, ensure_ascii=False)
            rows.append(
                (
                    element.get("kind"),
                    element.get("symbol"),
                    (
                        parent_i_entry.get("symbol")
                        if parent_i_entry is not None
                        else None
                    ),
                    serialized_terms,
                )
            )
            entries.append(element)
            current_parent = element

        for child in element:
            visit(child, current_parent)

    visit(root, None)

    entry_set = set(entries)
    for entry in entries:
        ancestor = parents.get(entry)
        has_i_ancestor = False
        while ancestor is not None:
            if ancestor in entry_set:
                has_i_ancestor = True
                break
            ancestor = parents.get(ancestor)
        if has_i_ancestor:
            continue
        parent = parents.get(entry)
        if parent is not None and entry in parent:
            parent.remove(entry)

    return rows


def inner_xml(element: ET.Element) -> str:
    """Serialize an element's content while retaining inline XML markup.

    ElementTree expands namespaced tags internally. Copies of child elements
    are converted back to local tag and attribute names before serialization,
    avoiding synthetic ``ns0`` prefixes in stored strings. The outer element
    is omitted; its text, child markup, and child tails remain in source order.

    Args:
        element: Element whose inner XML should be serialized.

    Returns:
        Trimmed inner XML using local names and conventional XML escaping.
    """

    parts = [escape(element.text or "")]
    for child in element:
        child_copy = deepcopy(child)
        child_copy.tail = None
        for descendant in child_copy.iter():
            descendant.tag = local_name(descendant.tag)
            descendant.attrib = {
                local_name(name): value
                for name, value in descendant.attrib.items()
            }
        parts.append(
            ET.tostring(
                child_copy,
                encoding="unicode",
                short_empty_elements=True,
            )
        )
        parts.append(escape(child.tail or ""))
    return "".join(parts).strip()


def place_title_parts(entry: ET.Element) -> tuple[list[str], PlaceNotes]:
    """Collect one K node's title text and unparsed entry references.

    One term slot is retained for every owned ``titlePart`` so ``terms_N``
    keys always address the corresponding array element. Only ``text``
    elements contribute to the term string; multiple text values are joined
    with one space. Inline XML within ``text``, including ``sref`` and ``mref``,
    remains markup and is not converted to reference values. A title part
    without text occupies an empty string slot rather than shifting indexes.

    Each owned ``entryReference`` becomes one inner-XML string in XML order.
    Its prose, separators, and ``sref``/``mref`` tags remain intact. All such
    strings for a title part form one flat JSON array.

    Args:
        entry: ``entryType="K"`` entry whose owned title parts are required.

    Returns:
        Term strings and a possibly empty ``terms_N`` notes mapping.
    """

    title_parts: list[ET.Element] = []

    def find_title_parts(parent: ET.Element) -> None:
        """Locate title parts owned by one place node.

        Args:
            parent: Current traversal element.

        Returns:
            ``None``.
        """

        for child in parent:
            child_name = local_name(child.tag)
            if child_name == "ipcEntry":
                continue
            if child_name == "titlePart":
                title_parts.append(child)
            else:
                find_title_parts(child)

    find_title_parts(entry)
    terms: list[str] = []
    notes: PlaceNotes = {}
    for title_part_index, title_part in enumerate(title_parts):
        text_values: list[str] = []
        for element in title_part.iter():
            if local_name(element.tag) != "text":
                continue
            value = inner_xml(element)
            if value:
                text_values.append(value)
        terms.append(" ".join(text_values))

        entry_references: list[str] = []
        for reference_container in title_part.iter():
            if local_name(reference_container.tag) != "entryReference":
                continue
            entry_references.append(inner_xml(reference_container))

        if entry_references:
            notes[f"terms_{title_part_index}"] = entry_references

    return terms, notes


def extract_places(root: ET.Element) -> list[PlaceRow]:
    """Extract the remaining ``entryType="K"`` hierarchy into place rows.

    Rows follow XML source order. ``parent_symbol`` is taken from the nearest
    enclosing K entry, even when non-entry wrapper elements occur between the
    two nodes. Outermost processed K subtrees are removed after every row has
    been built.

    Args:
        root: Mutable residual IPC tree after classified-aspect extraction.

    Returns:
        Place rows in deterministic XML source order.
    """

    parents = {child: parent for parent in root.iter() for child in parent}
    entries: list[ET.Element] = []
    rows: list[PlaceRow] = []

    def visit(
        element: ET.Element,
        parent_k_entry: ET.Element | None,
    ) -> None:
        """Build place rows recursively while carrying the nearest K parent.

        Args:
            element: Current tree element.
            parent_k_entry: Nearest enclosing ``entryType="K"`` node, if any.

        Returns:
            ``None``.
        """

        current_parent = parent_k_entry
        if (
            local_name(element.tag) == "ipcEntry"
            and element.get("entryType") == "K"
        ):
            terms, notes = place_title_parts(element)
            rows.append(
                (
                    element.get("kind"),
                    element.get("symbol"),
                    (
                        parent_k_entry.get("symbol")
                        if parent_k_entry is not None
                        else None
                    ),
                    json.dumps(terms, ensure_ascii=False),
                    json.dumps(notes, ensure_ascii=False) if notes else None,
                )
            )
            entries.append(element)
            current_parent = element

        for child in element:
            visit(child, current_parent)

    visit(root, None)

    entry_set = set(entries)
    for entry in entries:
        ancestor = parents.get(entry)
        while ancestor is not None and ancestor not in entry_set:
            ancestor = parents.get(ancestor)
        if ancestor is not None:
            continue
        parent = parents.get(entry)
        if parent is not None and entry in parent:
            parent.remove(entry)

    return rows


def table_exists(connection: sqlite3.Connection, table_name: str) -> bool:
    """Test whether SQLite contains a table with an exact name.

    Args:
        connection: Open SQLite connection used for schema inspection.
        table_name: Exact table name to find in ``sqlite_schema``.

    Returns:
        ``True`` when a table row with that name exists, otherwise ``False``.

    Raises:
        sqlite3.Error: If SQLite cannot query its schema catalog.
    """

    row = connection.execute(
        "SELECT 1 FROM sqlite_schema WHERE type = 'table' AND name = ?",
        (table_name,),
    ).fetchone()
    return row is not None


def route_guidance_headings(
    rows: list[HeadingRow],
) -> tuple[
    list[CoreGuidanceHeadingRow],
    list[IndexGuidanceHeadingRow],
    list[GuidanceExclusionRow],
]:
    """Route extracted guidance headings by resolved non-``ignt`` entry type.

    The routing value is intentionally omitted from stored rows. Core rows also
    omit the temporary, always-null ``refs`` field. Index rows receive
    pointer-free title cleanup and one normalized target list, then rows whose
    complete cleaned title array is empty are discarded. Optional exclusion
    lists become separate rows. A missing or unsupported type is rejected so a
    heading cannot silently disappear or be written to the wrong table.

    Args:
        rows: Extracted five-field guidance rows whose fourth field is the
            temporary resolved ``entryType`` routing value.

    Returns:
        Three-field core (``K``) rows, nonempty-title four-field index (``I``)
        rows, and two-field target/exclusion rows.

    Raises:
        ValueError: If a guidance heading has no corresponding ``I``/``K`` type.
    """

    core_rows: list[CoreGuidanceHeadingRow] = []
    index_rows: list[IndexGuidanceHeadingRow] = []
    exclusion_rows: list[GuidanceExclusionRow] = []
    for row in rows:
        if len(row) != 5:
            raise ValueError("guidance heading row has an invalid shape")
        title_parts, symbol, end_symbol, group_type, refs = row
        if group_type == "K":
            if refs is not None:
                raise ValueError(
                    "core guidance heading unexpectedly contains parsed refs"
                )
            core_rows.append((title_parts, symbol, end_symbol))
        elif group_type == "I":
            normalized_titles, normalized_refs, exclusion_row = (
                normalize_index_guidance(title_parts, refs)
            )
            if json.loads(normalized_titles):
                index_rows.append(
                    (
                        normalized_titles,
                        symbol,
                        end_symbol,
                        normalized_refs,
                    )
                )
            if exclusion_row is not None:
                exclusion_rows.append(exclusion_row)
        else:
            display_type = "missing" if group_type is None else repr(group_type)
            raise ValueError(
                f"guidance heading {symbol or '<missing symbol>'} has "
                f"unsupported group type {display_type}; expected 'I' or 'K'"
            )
    return core_rows, index_rows, exclusion_rows


def create_owned_table(
    connection: sqlite3.Connection,
    table_name: str,
) -> None:
    """Create one empty importer-owned table with integrity constraints.

    Args:
        connection: Open SQLite connection participating in the caller's
            transaction.
        table_name: Exact supported owned-table name to create.

    Returns:
        ``None``.

    Raises:
        ValueError: If ``table_name`` is not owned by this importer.
        sqlite3.Error: If SQLite rejects the DDL or lacks required JSON
            functions.

    Notes:
        This function neither drops an existing table nor commits. Transaction
        ownership remains with :func:`import_scheme`.
    """

    if table_name not in {
        "subsections",
        "gheadings_core",
        "gheadings_index",
        "gheading_index_exclusions",
        "index_terms",
        "notes",
        "classified_aspects",
        "places",
    }:
        raise ValueError(f"unsupported owned table: {table_name}")

    if table_name == "subsections":
        connection.execute(
            """
            CREATE TABLE subsections (
                title_parts TEXT NOT NULL
                    CHECK (json_valid(title_parts) AND
                           json_type(title_parts) = 'array'),
                symbol      TEXT,
                endSymbol   TEXT
            )
            """
        )
        return

    if table_name == "gheadings_core":
        connection.execute(
            """
            CREATE TABLE gheadings_core (
                title_parts TEXT NOT NULL
                    CHECK (json_valid(title_parts) AND
                           json_type(title_parts) = 'array'),
                symbol      TEXT,
                endSymbol   TEXT
            )
            """
        )
        return

    if table_name == "gheading_index_exclusions":
        connection.execute(
            """
            CREATE TABLE gheading_index_exclusions (
                target_list    TEXT NOT NULL
                    CHECK (json_valid(target_list) AND
                           json_type(target_list) = 'array' AND
                           json_array_length(target_list) > 0),
                exclusion_list TEXT NOT NULL
                    CHECK (json_valid(exclusion_list) AND
                           json_type(exclusion_list) = 'array' AND
                           json_array_length(exclusion_list) > 0)
            )
            """
        )
        return

    if table_name == "index_terms":
        connection.execute(
            """
            CREATE TABLE index_terms (
                symbol      TEXT,
                endSymbol   TEXT,
                terms       TEXT NOT NULL
                    CHECK (json_valid(terms) AND
                           json_type(terms) = 'array'),
                refs        TEXT NOT NULL
                    CHECK (json_valid(refs) AND
                           json_type(refs) = 'array' AND
                           json_array_length(refs) > 0)
            )
            """
        )
        return

    if table_name == "notes":
        connection.execute(
            """
            CREATE TABLE notes (
                symbol      TEXT,
                endSymbol   TEXT,
                note_xml    TEXT NOT NULL
            )
            """
        )
        return

    if table_name == "classified_aspects":
        connection.execute(
            """
            CREATE TABLE classified_aspects (
                kind          TEXT,
                symbol        TEXT,
                parent_symbol TEXT,
                terms         TEXT
                    CHECK (terms IS NULL OR
                           (json_valid(terms) AND
                            json_type(terms) = 'array'))
            )
            """
        )
        return

    if table_name == "places":
        connection.execute(
            """
            CREATE TABLE places (
                kind          TEXT,
                symbol        TEXT,
                parent_symbol TEXT,
                terms         TEXT NOT NULL
                    CHECK (json_valid(terms) AND
                           json_type(terms) = 'array'),
                notes         TEXT
                    CHECK (notes IS NULL OR
                           (json_valid(notes) AND
                            json_type(notes) = 'object'))
            )
            """
        )
        return

    connection.execute(
        """
        CREATE TABLE gheadings_index (
            title_parts TEXT NOT NULL
                CHECK (json_valid(title_parts) AND json_type(title_parts) = 'array'),
            symbol      TEXT,
            endSymbol   TEXT,
            refs        TEXT
                CHECK (refs IS NULL OR
                       (json_valid(refs) AND
                        json_type(refs) = 'array' AND
                        json_array_length(refs) > 0))
        )
        """
    )


def import_scheme(
    xml_path: Path,
    database_path: Path,
    preserve_existing_tables: bool,
) -> dict[str, tuple[int, bool]]:
    """Parse one scheme and transactionally populate every owned table.

    All extraction stages always run in order so each kind is removed from the
    residual tree even when its existing table is preserved. All non-preserved
    tables are rebuilt together in one transaction.

    Args:
        xml_path: IPC scheme XML file to parse as the source of truth.
        database_path: SQLite file to create or reuse.
        preserve_existing_tables: When true, independently skip every owned
            table that already exists; when false, rebuild all owned tables.

    Returns:
        In deterministic table order, a mapping from table name to
        ``(inserted_row_count, skipped_existing_table)``. A skipped table
        reports zero inserted rows.

    Raises:
        ET.ParseError: If the input is not well-formed XML.
        OSError: If the XML or database path cannot be accessed.
        ValueError: If source structure or reference content violates an
            explicitly checked importer invariant.
        sqlite3.Error: If the database cannot be opened, constrained rows
            cannot be inserted, or a transaction operation fails.

    Notes:
        XML parsing and extraction occur before ``BEGIN IMMEDIATE``. Once the
        transaction begins, any exception triggers an explicit rollback. The
        SQLite connection context may create a previously absent database file,
        but it cannot leave partially rebuilt owned tables.
    """

    with sqlite3.connect(database_path) as connection:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        group_types = collect_group_types(root)
        subsection_rows = extract_entries(root, "t", False)
        guidance_rows = extract_entries(root, "g", True, group_types)
        core_rows, index_rows, exclusion_rows = route_guidance_headings(
            guidance_rows
        )
        index_term_rows = extract_index_terms(root)
        note_rows = extract_notes(root)
        classified_aspect_rows = extract_classified_aspects(root)
        place_rows = extract_places(root)
        rows_by_table = {
            "subsections": subsection_rows,
            "gheadings_core": core_rows,
            "gheadings_index": index_rows,
            "gheading_index_exclusions": exclusion_rows,
            "index_terms": index_term_rows,
            "notes": note_rows,
            "classified_aspects": classified_aspect_rows,
            "places": place_rows,
        }

        connection.execute("BEGIN IMMEDIATE")
        try:
            results: dict[str, tuple[int, bool]] = {}
            if not preserve_existing_tables:
                connection.execute("DROP TABLE IF EXISTS gheadings")
            for table_name, rows in rows_by_table.items():
                if preserve_existing_tables and table_exists(connection, table_name):
                    results[table_name] = (0, True)
                    continue

                connection.execute(f"DROP TABLE IF EXISTS {table_name}")
                create_owned_table(connection, table_name)
                if table_name == "subsections":
                    connection.executemany(
                        """
                        INSERT INTO subsections (title_parts, symbol, endSymbol)
                        VALUES (?, ?, ?)
                        """,
                        rows,
                    )
                elif table_name == "gheadings_core":
                    connection.executemany(
                        """
                        INSERT INTO gheadings_core
                            (title_parts, symbol, endSymbol)
                        VALUES (?, ?, ?)
                        """,
                        rows,
                    )
                elif table_name == "gheading_index_exclusions":
                    connection.executemany(
                        """
                        INSERT INTO gheading_index_exclusions
                            (target_list, exclusion_list)
                        VALUES (?, ?)
                        """,
                        rows,
                    )
                elif table_name == "index_terms":
                    connection.executemany(
                        """
                        INSERT INTO index_terms
                            (symbol, endSymbol, terms, refs)
                        VALUES (?, ?, ?, ?)
                        """,
                        rows,
                    )
                elif table_name == "notes":
                    connection.executemany(
                        """
                        INSERT INTO notes (symbol, endSymbol, note_xml)
                        VALUES (?, ?, ?)
                        """,
                        rows,
                    )
                elif table_name == "classified_aspects":
                    connection.executemany(
                        """
                        INSERT INTO classified_aspects
                            (kind, symbol, parent_symbol, terms)
                        VALUES (?, ?, ?, ?)
                        """,
                        rows,
                    )
                elif table_name == "places":
                    connection.executemany(
                        """
                        INSERT INTO places
                            (kind, symbol, parent_symbol, terms, notes)
                        VALUES (?, ?, ?, ?, ?)
                        """,
                        rows,
                    )
                else:
                    connection.executemany(
                        """
                        INSERT INTO gheadings_index
                            (title_parts, symbol, endSymbol, refs)
                        VALUES (?, ?, ?, ?)
                        """,
                        rows,
                    )
                results[table_name] = (len(rows), False)
        except Exception:
            connection.rollback()
            raise
        else:
            connection.commit()

    return results


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse the source-selection and preservation options.

    Args:
        argv: Argument tokens excluding the executable name. ``None`` delegates
            to :mod:`argparse`'s normal ``sys.argv`` behavior.

    Returns:
        Namespace with optional ``scheme`` :class:`Path` and boolean
        ``preserve_existing_tables`` attributes.

    Raises:
        SystemExit: Raised by :mod:`argparse` for help or invalid syntax.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Import IPC subsection, guidance-heading, index-term, note, "
            "classified-aspect, and place data into SQLite."
        ),
    )
    parser.add_argument(
        "scheme",
        nargs="?",
        type=Path,
        help=(
            "IPC scheme XML file; if omitted, discover "
            "EN_ipc_scheme_YYYYMMDD.xml in the current directory"
        ),
    )
    parser.add_argument(
        "--preserve-existing-tables",
        "--preserve-existing",
        action="store_true",
        help="leave each existing owned table untouched and skip rebuilding it",
    )
    return parser.parse_args(argv)


def discover_scheme(directory: Path) -> Path:
    """Return the sole conventionally named IPC scheme in ``directory``.

    The date suffix is recognized structurally as eight decimal digits and is
    never fixed to a particular IPC edition. Ambiguous discovery is rejected
    so the importer cannot silently choose the wrong scheme.

    Args:
        directory: Directory whose immediate regular files should be examined.

    Returns:
        The sole matching ``EN_ipc_scheme_YYYYMMDD.xml`` path.

    Raises:
        FileNotFoundError: If no matching regular file exists.
        ValueError: If more than one matching regular file exists.
        OSError: If the directory cannot be enumerated.
    """

    matches = sorted(
        path
        for path in directory.iterdir()
        if path.is_file() and DEFAULT_SCHEME_PATTERN.fullmatch(path.name)
    )
    if not matches:
        raise FileNotFoundError(
            f"no EN_ipc_scheme_YYYYMMDD.xml file found in {directory}"
        )
    if len(matches) > 1:
        names = ", ".join(path.name for path in matches)
        raise ValueError(
            "multiple IPC scheme files found; provide one explicitly: " + names
        )
    return matches[0]


def main(argv: list[str] | None = None) -> int:
    """Resolve the input, execute the import, and report table outcomes.

    Args:
        argv: Optional command-line tokens excluding the executable name.

    Returns:
        Process exit status: ``0`` on success, ``1`` for XML/import/database
        failure, or ``2`` for source discovery and input-selection failure.

    Notes:
        User-facing errors go to stderr. Successful per-table import or
        preservation messages go to stdout. :func:`parse_args` may terminate
        directly with argparse's conventional status for syntax/help handling.
    """

    args = parse_args(argv)
    try:
        xml_path = (
            args.scheme if args.scheme is not None else discover_scheme(Path.cwd())
        )
    except (FileNotFoundError, OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if not xml_path.is_file():
        print(f"error: input file does not exist: {xml_path}", file=sys.stderr)
        return 2

    database_path = xml_path.with_suffix(".db")
    try:
        results = import_scheme(
            xml_path,
            database_path,
            args.preserve_existing_tables,
        )
    except (ET.ParseError, OSError, sqlite3.Error, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    for table_name, (inserted_rows, skipped) in results.items():
        if skipped:
            print(f"{table_name}: preserved existing table in {database_path}")
        else:
            print(f"{table_name}: imported {inserted_rows} rows into {database_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
