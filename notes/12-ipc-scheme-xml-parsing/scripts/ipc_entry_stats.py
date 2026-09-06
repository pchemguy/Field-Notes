#!/usr/bin/env python3
"""Report ``ipcEntry`` counts by ``kind`` and ``entryType``.

The input is parsed incrementally, so the script can process the complete IPC
scheme without loading the XML tree into memory. XML namespace prefixes and
default namespaces do not affect element matching.

https://chatgpt.com/c/6a844517-9b78-83ed-b037-dd7b6fb1b67e
"""

from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from typing import Sequence


MISSING_LABEL = "<missing>"


def local_name(name: str) -> str:
    """Return an XML expanded name without its namespace."""
    return name.rsplit("}", 1)[-1]


def get_attribute(element: ET.Element, wanted_name: str) -> str | None:
    """Return an attribute by local name, treating an absent value as missing."""
    for name, value in element.attrib.items():
        if local_name(name) == wanted_name:
            return value
    return None


def collect_stats(
    xml_path: Path,
) -> tuple[Counter[str | None], Counter[str | None], Counter[tuple[str | None, str | None]]]:
    """Count ``ipcEntry`` elements by each attribute and by their combination."""
    by_kind: Counter[str | None] = Counter()
    by_entry_type: Counter[str | None] = Counter()
    combinations: Counter[tuple[str | None, str | None]] = Counter()

    for _event, element in ET.iterparse(xml_path, events=("end",)):
        if local_name(element.tag) == "ipcEntry":
            kind = get_attribute(element, "kind")
            entry_type = get_attribute(element, "entryType")
            by_kind[kind] += 1
            by_entry_type[entry_type] += 1
            combinations[(kind, entry_type)] += 1
        element.clear()

    return by_kind, by_entry_type, combinations


def sort_value(value: str | None) -> tuple[bool, str]:
    """Return a deterministic sort key, placing missing values last."""
    return value is None, value or ""


def display_value(value: str | None) -> str:
    """Render a possibly missing attribute value for tabular output."""
    return MISSING_LABEL if value is None else value


def print_table(
    by_kind: Counter[str | None],
    by_entry_type: Counter[str | None],
    combinations: Counter[tuple[str | None, str | None]],
) -> None:
    """Write human-readable summary tables to standard output."""
    total = sum(combinations.values())
    print(f"ipcEntry total: {total}")

    print("\nBy kind:")
    print("kind\tcount")
    for kind in sorted(by_kind, key=sort_value):
        print(f"{display_value(kind)}\t{by_kind[kind]}")

    print("\nBy entryType:")
    print("entryType\tcount")
    for entry_type in sorted(by_entry_type, key=sort_value):
        print(f"{display_value(entry_type)}\t{by_entry_type[entry_type]}")

    print("\nBy kind / entryType:")
    print("kind\tentryType\tcount")
    for kind, entry_type in sorted(
        combinations, key=lambda pair: (sort_value(pair[0]), sort_value(pair[1]))
    ):
        print(
            f"{display_value(kind)}\t{display_value(entry_type)}\t"
            f"{combinations[(kind, entry_type)]}"
        )


def counter_rows(counter: Counter[str | None], field: str) -> list[dict[str, object]]:
    """Convert a single-attribute counter to stable JSON rows."""
    return [
        {field: value, "count": counter[value]}
        for value in sorted(counter, key=sort_value)
    ]


def print_json(
    by_kind: Counter[str | None],
    by_entry_type: Counter[str | None],
    combinations: Counter[tuple[str | None, str | None]],
) -> None:
    """Write the complete statistics as formatted JSON."""
    result = {
        "total_ipc_entries": sum(combinations.values()),
        "by_kind": counter_rows(by_kind, "kind"),
        "by_entry_type": counter_rows(by_entry_type, "entryType"),
        "by_kind_and_entry_type": [
            {"kind": kind, "entryType": entry_type, "count": combinations[(kind, entry_type)]}
            for kind, entry_type in sorted(
                combinations,
                key=lambda pair: (sort_value(pair[0]), sort_value(pair[1])),
            )
        ],
    }
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Count IPC scheme ipcEntry elements by kind and entryType."
    )
    parser.add_argument("xml_file", type=Path, help="IPC scheme XML file")
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit structured JSON instead of tab-separated summary tables",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line program and return its process exit status."""
    args = parse_args(argv)
    try:
        by_kind, by_entry_type, combinations = collect_stats(args.xml_file)
    except (OSError, ET.ParseError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if args.json:
        print_json(by_kind, by_entry_type, combinations)
    else:
        print_table(by_kind, by_entry_type, combinations)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
