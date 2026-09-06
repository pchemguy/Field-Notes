#!/usr/bin/env python3
"""Export every ``ipcEntry`` element's selected attributes to SQLite.

The input XML is processed incrementally, so the script can handle a complete
IPC scheme without loading the document into memory.  The output database is
placed beside the XML file and named from its stem.  If that database already
exists, it is reused; only the ``ipc_entries`` table is replaced.

https://chatgpt.com/c/6a849f8e-d250-83ed-8ead-00a47c725b29
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
import xml.etree.ElementTree as ET
from collections.abc import Iterator
from pathlib import Path


TABLE_NAME = "ipc_entries"
BATCH_SIZE = 10_000


def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Collect all ipcEntry attributes from an IPC XML scheme into "
            "a stem-matched SQLite database."
        )
    )
    parser.add_argument("xml_file", type=Path, help="IPC scheme XML file")
    return parser.parse_args()


def local_name(tag: str) -> str:
    """Return an XML tag's local name, without its namespace."""

    return tag.rsplit("}", 1)[-1]


def iter_ipc_entries(xml_path: Path) -> Iterator[tuple[str | None, ...]]:
    """Yield the requested attributes from every ``ipcEntry`` element."""

    for _event, element in ET.iterparse(xml_path, events=("end",)):
        if local_name(element.tag) != "ipcEntry":
            continue

        yield (
            element.get("kind"),
            element.get("entryType"),
            element.get("symbol"),
            element.get("endSymbol"),
        )
        element.clear()


def export_ipc_entries(xml_path: Path, database_path: Path) -> int:
    """Replace ``ipc_entries`` and populate it from the IPC scheme."""

    connection = sqlite3.connect(database_path)
    try:
        connection.execute("BEGIN IMMEDIATE")
        connection.execute(f"DROP TABLE IF EXISTS {TABLE_NAME}")
        connection.execute(
            f"""
            CREATE TABLE {TABLE_NAME} (
                kind      TEXT,
                entryType TEXT,
                symbol    TEXT,
                endSymbol TEXT
            )
            """
        )

        count = 0
        batch: list[tuple[str | None, ...]] = []
        insert_sql = (
            f"INSERT INTO {TABLE_NAME} "
            "(kind, entryType, symbol, endSymbol) VALUES (?, ?, ?, ?)"
        )

        for row in iter_ipc_entries(xml_path):
            batch.append(row)
            if len(batch) >= BATCH_SIZE:
                connection.executemany(insert_sql, batch)
                count += len(batch)
                batch.clear()

        if batch:
            connection.executemany(insert_sql, batch)
            count += len(batch)

        connection.commit()
        return count
    except BaseException:
        connection.rollback()
        raise
    finally:
        connection.close()


def main() -> int:
    """Run the command-line exporter."""

    args = parse_arguments()
    xml_path = args.xml_file.resolve()

    if not xml_path.is_file():
        print(f"error: XML file does not exist: {xml_path}", file=sys.stderr)
        return 2

    database_path = xml_path.with_suffix(".db")

    try:
        count = export_ipc_entries(xml_path, database_path)
    except (ET.ParseError, OSError, sqlite3.Error) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Exported {count:,} ipcEntry elements to {database_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
