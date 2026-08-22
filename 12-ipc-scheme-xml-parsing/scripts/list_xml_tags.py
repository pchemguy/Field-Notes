#!/usr/bin/env python3
"""Inventory XML tags, attributes, and immediate nesting in SQLite.

The script accepts an optional XML filename as its sole positional argument. If
the argument is omitted, the script searches the current working directory for
exactly one file named ``EN_ipc_scheme_YYYYMMDD.xml``, where ``YYYYMMDD`` is an
eight-digit date. Discovery fails rather than selecting arbitrarily when no
matching file or more than one matching file is present.

The output database is written beside the selected XML file using the same
filename with its extension replaced by ``.db``. The database contains:

* ``xml_tags(name, count, attribute_names)``, with distinct attribute names
  encoded as a JSON array; and
* ``supsub_names(parent, child)``, with one row for each distinct pair of tag
  names in which ``parent`` immediately encloses ``child`` in the source XML.

On every successful run, the script retains the tables but replaces all rows in
both tables with observations from the selected XML file. XML parsing is
streaming, so element subtrees are not retained in memory.

https://chatgpt.com/c/6a834683-da58-83ed-9083-831528e28250
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path
from typing import TypedDict
from xml.parsers import expat


DEFAULT_XML_NAME_PATTERN = re.compile(r"EN_ipc_scheme_\d{8}\.xml\Z")


class TagSummary(TypedDict):
    """Summary accumulated for one XML element tag."""

    count: int
    attributes: list[str]


def summarize_xml(
    xml_path: Path,
) -> tuple[dict[str, TagSummary], list[tuple[str, str]]]:
    """Return tag summaries and distinct immediate parent-child pairs."""
    summaries: dict[str, TagSummary] = {}
    seen_attributes: dict[str, set[str]] = {}
    parent_child_pairs: list[tuple[str, str]] = []
    seen_parent_child_pairs: set[tuple[str, str]] = set()
    element_stack: list[str] = []
    parser = expat.ParserCreate()

    def record_start_tag(name: str, attributes: dict[str, str]) -> None:
        if name not in summaries:
            summaries[name] = {"count": 0, "attributes": []}
            seen_attributes[name] = set()

        summary = summaries[name]
        summary["count"] += 1

        for attribute_name in attributes:
            if attribute_name not in seen_attributes[name]:
                seen_attributes[name].add(attribute_name)
                summary["attributes"].append(attribute_name)

        if element_stack:
            pair = (element_stack[-1], name)
            if pair not in seen_parent_child_pairs:
                seen_parent_child_pairs.add(pair)
                parent_child_pairs.append(pair)

        element_stack.append(name)

    def record_end_tag(_name: str) -> None:
        element_stack.pop()

    parser.StartElementHandler = record_start_tag
    parser.EndElementHandler = record_end_tag

    with xml_path.open("rb") as xml_file:
        parser.ParseFile(xml_file)

    return summaries, parent_child_pairs


def write_database(
    database_path: Path,
    summaries: dict[str, TagSummary],
    parent_child_pairs: list[tuple[str, str]],
) -> None:
    """Replace both XML inventory tables with the supplied observations."""
    tag_rows = (
        (
            name,
            summary["count"],
            json.dumps(summary["attributes"], ensure_ascii=False),
        )
        for name, summary in summaries.items()
    )

    with sqlite3.connect(database_path) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS xml_tags (
                name TEXT PRIMARY KEY,
                count INTEGER,
                attribute_names TEXT
            )
            """
        )
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS supsub_names (
                parent TEXT NOT NULL,
                child TEXT NOT NULL,
                PRIMARY KEY (parent, child)
            )
            """
        )

        connection.execute("DELETE FROM xml_tags")
        connection.execute("DELETE FROM supsub_names")

        connection.executemany(
            """
            INSERT INTO xml_tags (name, count, attribute_names)
            VALUES (?, ?, ?)
            """,
            tag_rows,
        )
        connection.executemany(
            """
            INSERT INTO supsub_names (parent, child)
            VALUES (?, ?)
            """,
            parent_child_pairs,
        )


def resolve_xml_path(xml_path: Path | None) -> Path:
    """Resolve the XML input path supplied by the user or automatic discovery.

    Args:
        xml_path: Explicit XML path, or ``None`` to search the current working
            directory for ``EN_ipc_scheme_YYYYMMDD.xml``.

    Returns:
        The explicit path unchanged, or the sole discovered IPC scheme path.

    Raises:
        FileNotFoundError: No matching IPC scheme exists during discovery.
        ValueError: More than one matching IPC scheme exists during discovery.
        OSError: The current directory cannot be enumerated.
    """
    if xml_path is not None:
        return xml_path

    candidates = sorted(
        path
        for path in Path.cwd().iterdir()
        if path.is_file() and DEFAULT_XML_NAME_PATTERN.fullmatch(path.name)
    )

    if not candidates:
        raise FileNotFoundError(
            "no EN_ipc_scheme_YYYYMMDD.xml file found in the current directory"
        )
    if len(candidates) > 1:
        candidate_names = ", ".join(path.name for path in candidates)
        raise ValueError(
            "multiple EN_ipc_scheme_YYYYMMDD.xml files found; "
            f"specify one explicitly: {candidate_names}"
        )

    return candidates[0]


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            "Store XML tag counts, attribute names, and distinct immediate "
            "parent-child tag pairs in a SQLite database beside the input file."
        )
    )
    parser.add_argument(
        "xml_file",
        nargs="?",
        type=Path,
        help=(
            "XML file to inspect; when omitted, discover "
            "EN_ipc_scheme_YYYYMMDD.xml in the current directory"
        ),
    )
    return parser.parse_args()


def main() -> int:
    """Run the command-line program."""
    args = parse_args()

    try:
        xml_path = resolve_xml_path(args.xml_file)
        database_path = xml_path.with_suffix(".db")
        summaries, parent_child_pairs = summarize_xml(xml_path)
        write_database(database_path, summaries, parent_child_pairs)
    except (OSError, ValueError, expat.ExpatError, sqlite3.Error) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(database_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
