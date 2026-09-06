#!/usr/bin/env python3
"""Create a core-only IPC scheme XML file.

The script removes complete ``ipcEntry`` subtrees when the entry has a
``kind`` value of ``i``, ``g``, ``n``, or ``t``, or has ``entryType="I"``.
All other elements, attributes, text, and hierarchy are retained.  The result
is indented and written with an XML declaration to a sibling file whose name
is formed by appending ``_core`` to the input stem.

Supply the IPC scheme XML filename as the optional positional argument.  When
it is omitted, the script searches the current directory for filenames of the
form ``EN_ipc_scheme_YYYYMMDD.xml`` and uses the one with the latest date.

Examples:
    python ipc_scheme_core.py EN_ipc_scheme_20260101.xml
    python ipc_scheme_core.py

Requirements:
    Python 3.9 or later.  Only the Python standard library is used.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import sys
import tempfile
import xml.etree.ElementTree as ET


SCHEME_FILENAME_RE = re.compile(r"^EN_ipc_scheme_(\d{8})\.xml$")
REMOVED_KINDS = frozenset({"i", "g", "n", "t"})


def find_scheme_file(directory: Path) -> Path:
    """Find the newest dated IPC scheme XML file in a directory.

    Args:
        directory: Directory in which to search.

    Returns:
        The path whose ``YYYYMMDD`` filename component is greatest.

    Raises:
        FileNotFoundError: If no exact ``EN_ipc_scheme_YYYYMMDD.xml`` match is
            present.
    """
    candidates = [
        path
        for path in directory.iterdir()
        if path.is_file() and SCHEME_FILENAME_RE.fullmatch(path.name)
    ]
    if not candidates:
        raise FileNotFoundError(
            f"no EN_ipc_scheme_YYYYMMDD.xml file found in {directory}"
        )
    return max(candidates, key=lambda path: path.name)


def local_name(tag: str) -> str:
    """Return an XML tag name without its namespace qualification.

    Args:
        tag: An ElementTree tag in either plain or ``{namespace}local`` form.

    Returns:
        The local portion of the tag name.
    """
    return tag.rsplit("}", 1)[-1]


def register_source_namespaces(source: Path) -> None:
    """Register namespace prefixes declared by the source XML document.

    Args:
        source: XML file whose namespace declarations should be retained when
            serializing the output.

    Notes:
        ElementTree reserves prefixes matching ``ns<digits>``.  Such prefixes
        are skipped and will receive an automatically generated output prefix.
    """
    seen: set[tuple[str, str]] = set()
    for _event, declaration in ET.iterparse(source, events=("start-ns",)):
        prefix, uri = declaration
        if declaration in seen:
            continue
        seen.add(declaration)
        try:
            ET.register_namespace(prefix, uri)
        except ValueError:
            pass


def should_remove(element: ET.Element) -> bool:
    """Determine whether an element roots an excluded IPC subtree.

    Args:
        element: XML element to examine.

    Returns:
        ``True`` only for an ``ipcEntry`` whose ``kind`` is one of ``i``,
        ``g``, ``n``, or ``t``, or whose ``entryType`` is ``I``.
    """
    return local_name(element.tag) == "ipcEntry" and (
        element.get("kind") in REMOVED_KINDS or element.get("entryType") == "I"
    )


def remove_excluded_subtrees(parent: ET.Element) -> int:
    """Remove excluded ``ipcEntry`` descendants from an XML element.

    Args:
        parent: Element whose descendants will be filtered in place.

    Returns:
        Number of directly identified subtree roots removed.  Descendants of a
        removed root are not counted separately because they are discarded as
        part of that subtree.
    """
    removed = 0
    for child in list(parent):
        if should_remove(child):
            parent.remove(child)
            removed += 1
        else:
            removed += remove_excluded_subtrees(child)
    return removed


def write_xml_atomically(tree: ET.ElementTree, destination: Path) -> None:
    """Write a UTF-8 XML tree without leaving a partial destination file.

    Args:
        tree: Parsed and transformed XML document.
        destination: Final output path.

    Raises:
        OSError: If the temporary file cannot be created, written, or moved.
    """
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            prefix=f".{destination.name}.",
            suffix=".tmp",
            dir=destination.parent,
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            tree.write(
                temporary,
                encoding="utf-8",
                xml_declaration=True,
                short_empty_elements=True,
            )
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, destination)
    except BaseException:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        raise


def create_core_scheme(source: Path) -> tuple[Path, int]:
    """Load an IPC scheme, remove excluded subtrees, and save the result.

    Args:
        source: Source IPC scheme XML path.

    Returns:
        A pair containing the output path and number of removed subtree roots.

    Raises:
        FileNotFoundError: If the source file does not exist.
        IsADirectoryError: If the source path is not a regular file.
        ValueError: If the document root itself is an excluded ``ipcEntry``.
        xml.etree.ElementTree.ParseError: If the source is not well-formed XML.
        OSError: If the source cannot be read or the result cannot be written.
    """
    if not source.exists():
        raise FileNotFoundError(f"input file does not exist: {source}")
    if not source.is_file():
        raise IsADirectoryError(f"input path is not a file: {source}")

    register_source_namespaces(source)
    tree = ET.parse(source)
    root = tree.getroot()
    if should_remove(root):
        raise ValueError("the document root is itself an excluded ipcEntry")

    removed = remove_excluded_subtrees(root)
    ET.indent(tree, space="  ")
    destination = source.with_name(f"{source.stem}_core.xml")
    write_xml_atomically(tree, destination)
    return destination, removed


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: Argument list without the program name, or ``None`` to use
            ``sys.argv``.

    Returns:
        Namespace containing the optional input path.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Remove kind=i/g/n/t and entryType=I ipcEntry subtrees from an "
            "IPC scheme and save beautified XML with an _core suffix."
        )
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=Path,
        help=(
            "IPC scheme XML file; if omitted, use the newest "
            "EN_ipc_scheme_YYYYMMDD.xml in the current directory"
        ),
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """Run the command-line transformation.

    Args:
        argv: Argument list without the program name, or ``None`` to use
            ``sys.argv``.

    Returns:
        Process exit status: zero on success and one on operational or XML
        errors.
    """
    args = parse_args(argv)
    try:
        source = args.input if args.input is not None else find_scheme_file(Path.cwd())
        destination, removed = create_core_scheme(source)
    except (OSError, ET.ParseError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(f"Input: {source}")
    print(f"Removed subtrees: {removed}")
    print(f"Output: {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
