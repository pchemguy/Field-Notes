#!/usr/bin/env python3
"""Extract complete ``ipcEntry entryType="I"`` subtrees from an IPC scheme.

The script processes the source incrementally, writes only outermost matching
entries, and leaves any matching entries nested inside their original parent.
The result is a well-formed, UTF-8 XML document named ``entryType_I.xml`` by
default.

https://chatgpt.com/c/6a85975b-5118-83ed-bdad-6ec6de198d5b
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import BinaryIO, Sequence


OUTPUT_ROOT = "entryTypeIEntries"


def local_name(tag: object) -> str:
    """Return an expanded XML tag's local name.

    Non-string tags, such as the special tags used for comments and processing
    instructions, return an empty string.
    """

    if not isinstance(tag, str):
        return ""
    return tag.rsplit("}", 1)[-1]


def is_target(element: ET.Element) -> bool:
    """Return whether *element* is an IPC entry with ``entryType="I"``."""

    return (
        local_name(element.tag) == "ipcEntry"
        and element.get("entryType") == "I"
    )


def register_namespace(prefix: str, uri: str) -> None:
    """Register a source namespace when ElementTree permits its prefix."""

    try:
        ET.register_namespace(prefix, uri)
    except ValueError:
        # ElementTree reserves prefixes matching ns\d+ for internal use.
        pass


def write_entry(output: BinaryIO, element: ET.Element) -> None:
    """Indent and serialize one extracted subtree to *output*."""

    element.tail = None
    ET.indent(element, space="  ", level=1)
    output.write(b"  ")
    output.write(ET.tostring(element, encoding="utf-8", short_empty_elements=True))
    output.write(b"\n")


def extract_entries(source: Path, destination: Path) -> tuple[int, int]:
    """Extract target entries from *source* into *destination* atomically.

    Returns:
        A pair containing the number of outermost subtrees written and the
        total number of matching entries, including nested matches.

    Raises:
        OSError: If an input or output file operation fails.
        xml.etree.ElementTree.ParseError: If the source is not well-formed XML.
        ValueError: If source and destination identify the same file.
    """

    if source.resolve() == destination.resolve():
        raise ValueError("input and output paths must be different")

    destination.parent.mkdir(parents=True, exist_ok=True)
    parser = ET.XMLParser(
        target=ET.TreeBuilder(insert_comments=True, insert_pis=True)
    )

    temporary_path: Path | None = None
    extracted_count = 0
    matching_count = 0
    target_depth = 0
    element_stack: list[ET.Element] = []
    selected_roots: set[int] = set()

    try:
        with source.open("rb") as input_file, tempfile.NamedTemporaryFile(
            mode="w+b",
            prefix=f".{destination.name}.",
            suffix=".tmp",
            dir=destination.parent,
            delete=False,
        ) as output_file:
            temporary_path = Path(output_file.name)
            output_file.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
            output_file.write(f"<{OUTPUT_ROOT}>\n".encode("ascii"))

            events = ET.iterparse(
                input_file,
                events=("start", "end", "start-ns"),
                parser=parser,
            )

            for event, item in events:
                if event == "start-ns":
                    prefix, uri = item
                    register_namespace(prefix, uri)
                    continue

                element = item
                if event == "start":
                    element_stack.append(element)
                    if is_target(element):
                        matching_count += 1
                        if target_depth == 0:
                            selected_roots.add(id(element))
                        target_depth += 1
                    continue

                target = is_target(element)
                selected = id(element) in selected_roots

                if target:
                    target_depth -= 1

                if selected:
                    write_entry(output_file, element)
                    extracted_count += 1
                    selected_roots.remove(id(element))

                parent = element_stack[-2] if len(element_stack) >= 2 else None
                element_stack.pop()

                # Elements inside a selected subtree must remain intact until
                # that subtree is serialized. Everything else can be released.
                if target_depth == 0:
                    element.clear()
                    if parent is not None:
                        try:
                            parent.remove(element)
                        except ValueError:
                            pass

            output_file.write(f"</{OUTPUT_ROOT}>\n".encode("ascii"))
            output_file.flush()
            os.fsync(output_file.fileno())

        os.replace(temporary_path, destination)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)

    return extracted_count, matching_count


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            'Extract complete ipcEntry entryType="I" subtrees from an IPC '
            "scheme while preserving nested entries."
        )
    )
    parser.add_argument("xml_file", type=Path, help="source IPC scheme XML file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("entryType_I.xml"),
        help="output path (default: entryType_I.xml)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line extractor and return its process exit status."""

    args = parse_args(argv)
    try:
        extracted_count, matching_count = extract_entries(
            args.xml_file, args.output
        )
    except (OSError, ET.ParseError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    nested_count = matching_count - extracted_count
    print(
        f"Wrote {extracted_count} outermost subtree(s) to {args.output} "
        f"({matching_count} matching entries total; {nested_count} nested)."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
