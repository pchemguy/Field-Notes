#!/usr/bin/env python3
"""Extract ``ipcEntry kind="n"`` subtrees below ``entryType="I"`` entries.

https://chatgpt.com/c/6a859cf9-9edc-83eb-93ea-3d6d53f2406a
"""

from __future__ import annotations

import argparse
import copy
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


OUTPUT_FILENAME = "kind_n_under_entryType_I.xml"


def local_name(tag: str) -> str:
    """Return an XML tag name without its optional namespace."""
    return tag.rsplit("}", 1)[-1]


def register_source_namespaces(source: Path) -> None:
    """Register source namespace prefixes for cleaner serialized XML."""
    seen: set[tuple[str, str]] = set()
    for _event, namespace in ET.iterparse(source, events=("start-ns",)):
        prefix, uri = namespace
        if namespace in seen or prefix in {"xml", "xmlns"}:
            continue
        seen.add(namespace)
        try:
            ET.register_namespace(prefix, uri)
        except ValueError:
            # ElementTree reserves prefixes such as ns0 for its own use.
            pass


def extract(source: Path, destination: Path) -> int:
    """Extract matching elements and return the number written."""
    register_source_namespaces(source)
    source_root = ET.parse(source).getroot()
    output_root = ET.Element("ipcEntries")

    # Each stack item stores an element and whether an entryType="I"
    # ipcEntry occurs strictly above it.
    stack: list[tuple[ET.Element, bool]] = [(source_root, False)]
    count = 0

    while stack:
        element, beneath_i = stack.pop()
        is_ipc_entry = local_name(element.tag) == "ipcEntry"

        if is_ipc_entry and element.get("kind") == "n" and beneath_i:
            clone = copy.deepcopy(element)
            clone.tail = None
            output_root.append(clone)
            count += 1

        child_beneath_i = beneath_i or (
            is_ipc_entry and element.get("entryType") == "I"
        )
        children = list(element)
        for child in reversed(children):
            stack.append((child, child_beneath_i))

    ET.indent(output_root, space="  ")
    ET.ElementTree(output_root).write(
        destination,
        encoding="utf-8",
        xml_declaration=True,
        short_empty_elements=True,
    )
    return count


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description=(
            'Extract all ipcEntry kind="n" subtrees nested anywhere under '
            'an ipcEntry entryType="I".'
        )
    )
    parser.add_argument("xml_file", type=Path, help="IPC XML scheme file")
    return parser.parse_args()


def main() -> int:
    """Run the command-line extraction."""
    args = parse_args()
    source = args.xml_file
    destination = Path.cwd() / OUTPUT_FILENAME

    if not source.is_file():
        print(f"Error: input file not found: {source}", file=sys.stderr)
        return 2

    try:
        count = extract(source, destination)
    except (ET.ParseError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(f"Extracted {count} ipcEntry element(s) to {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
