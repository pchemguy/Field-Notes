#!/usr/bin/env python3
"""Export IPC ``ipcEntry`` nodes and their immediate relationships to SQLite.

The destination is the input XML path with its suffix replaced by ``.db``.
An existing database is reused. The importer drops and recreates its five
tables before loading the XML; unrelated tables are not modified.

https://chatgpt.com/c/6a849350-28cc-83eb-b533-3fb48e4ab530
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS ipc_entries_k (
    id      INTEGER PRIMARY KEY,
    kind    TEXT,
    symbol  TEXT,
    parent  TEXT
);

CREATE TABLE IF NOT EXISTS ipc_entries_i (
    id      INTEGER PRIMARY KEY,
    kind    TEXT,
    symbol  TEXT,
    parent  TEXT
);

CREATE TABLE IF NOT EXISTS ipc_entries_tgin (
    id         INTEGER PRIMARY KEY,
    kind       TEXT NOT NULL CHECK (kind IN ('t', 'g', 'i', 'n')),
    symbol     TEXT,
    endSymbol  TEXT
);

CREATE TABLE IF NOT EXISTS edges_k_i (
    parent_k_id INTEGER NOT NULL,
    child_i_id  INTEGER NOT NULL,
    PRIMARY KEY (parent_k_id, child_i_id),
    FOREIGN KEY (parent_k_id) REFERENCES ipc_entries_k(id),
    FOREIGN KEY (child_i_id)  REFERENCES ipc_entries_i(id)
);

CREATE TABLE IF NOT EXISTS edges_structural_tgin (
    parent_id INTEGER NOT NULL,
    child_id  INTEGER NOT NULL,
    PRIMARY KEY (parent_id, child_id),
    FOREIGN KEY (child_id) REFERENCES ipc_entries_tgin(id)
);
"""

TABLES_TO_DROP = (
    "edges_structural_tgin",
    # Remove the generic names created by the preceding script version.
    "edges_structural_kind",
    "edges_k_k",
    "edges_i_i",
    "edges_k_i",
    # Remove the mixed-edge table created by the preceding script version.
    "edges_i_k",
    "ipc_entries_tgin",
    "ipc_entries_kind",
    "ipc_entries_k",
    "ipc_entries_i",
)


@dataclass(frozen=True)
class EntryRef:
    """Identify an inserted IPC entry while its descendants are parsed."""

    entry_type: str | None
    structural_id: int | None
    kind: str | None
    kind_id: int | None
    symbol: str | None


def local_name(tag: str) -> str:
    """Return an expanded XML name without its namespace."""

    return tag.rsplit("}", 1)[-1]


def create_argument_parser() -> argparse.ArgumentParser:
    """Create the command-line parser."""

    parser = argparse.ArgumentParser(
        description="Export entryType K/I ipcEntry nodes and immediate edges to SQLite."
    )
    parser.add_argument("xml_file", type=Path, help="IPC scheme XML file")
    return parser


def prepare_database(connection: sqlite3.Connection) -> None:
    """Drop any preceding importer schema and create the current schema."""

    for table in TABLES_TO_DROP:
        connection.execute(f"DROP TABLE IF EXISTS {table}")
    connection.executescript(SCHEMA_SQL)


def insert_entry(
    connection: sqlite3.Connection,
    attributes: dict[str, str],
    parent: EntryRef | None,
) -> EntryRef:
    """Insert an ipcEntry into exactly one node table and return its identity."""

    source_entry_type = attributes.get("entryType")
    kind = attributes.get("kind")
    symbol = attributes.get("symbol")
    entry_type: str | None = None
    structural_id: int | None = None
    kind_id: int | None = None

    # TGIN kinds form a node category distinct from entryType K and I. Test
    # kind first so such an entry can never leak into either structural table.
    if kind in {"t", "g", "i", "n"}:
        cursor = connection.execute(
            "INSERT INTO ipc_entries_tgin(kind, symbol, endSymbol) VALUES (?, ?, ?)",
            (kind, symbol, attributes.get("endSymbol")),
        )
        kind_id = int(cursor.lastrowid)
    elif source_entry_type == "K":
        entry_type = "K"
        parent_symbol = (
            parent.symbol if parent is not None and parent.entry_type == "K" else None
        )
        cursor = connection.execute(
            "INSERT INTO ipc_entries_k(kind, symbol, parent) VALUES (?, ?, ?)",
            (kind, symbol, parent_symbol),
        )
        structural_id = int(cursor.lastrowid)
    elif source_entry_type == "I":
        entry_type = "I"
        parent_symbol = (
            parent.symbol if parent is not None and parent.entry_type == "I" else None
        )
        cursor = connection.execute(
            "INSERT INTO ipc_entries_i(kind, symbol, parent) VALUES (?, ?, ?)",
            (kind, symbol, parent_symbol),
        )
        structural_id = int(cursor.lastrowid)

    return EntryRef(entry_type, structural_id, kind, kind_id, symbol)


def insert_edge(
    connection: sqlite3.Connection, parent: EntryRef, child: EntryRef
) -> None:
    """Insert one supported immediate parent-child relationship."""

    pair = (parent.entry_type, child.entry_type)
    if pair == ("K", "I"):
        connection.execute(
            "INSERT INTO edges_k_i(parent_k_id, child_i_id) VALUES (?, ?)",
            (parent.structural_id, child.structural_id),
        )

    if (
        parent.entry_type in {"K", "I"}
        and parent.structural_id is not None
        and child.kind_id is not None
    ):
        connection.execute(
            "INSERT INTO edges_structural_tgin(parent_id, child_id) VALUES (?, ?)",
            (parent.structural_id, child.kind_id),
        )


def import_xml(xml_path: Path, connection: sqlite3.Connection) -> None:
    """Stream K/I IPC entries and their immediate ipcEntry edges into SQLite."""

    entry_stack: list[EntryRef] = []

    for event, element in ET.iterparse(xml_path, events=("start", "end")):
        if local_name(element.tag) != "ipcEntry":
            if event == "end":
                element.clear()
            continue

        if event == "start":
            parent = entry_stack[-1] if entry_stack else None
            child = insert_entry(connection, element.attrib, parent)
            if parent is not None:
                insert_edge(connection, parent, child)
            entry_stack.append(child)
        else:
            entry_stack.pop()
            element.clear()


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line importer and return a process exit status."""

    args = create_argument_parser().parse_args(argv)
    xml_path: Path = args.xml_file
    if not xml_path.is_file():
        print(f"error: XML file does not exist: {xml_path}", file=sys.stderr)
        return 2

    database_path = xml_path.with_suffix(".db")
    try:
        with sqlite3.connect(database_path) as connection:
            connection.execute("PRAGMA foreign_keys = ON")
            prepare_database(connection)
            import_xml(xml_path, connection)
            connection.execute("PRAGMA optimize")
    except (OSError, ET.ParseError, sqlite3.Error) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Created: {database_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
