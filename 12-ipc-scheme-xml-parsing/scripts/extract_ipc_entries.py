#!/usr/bin/env python3
"""Extract selected IPC ``ipcEntry`` subtrees in successive stages.

The input IPC scheme is parsed once into memory.  Each stage selects the
outermost matching ``ipcEntry`` elements in document order, removes those
subtrees from the in-memory source tree, and places them in a separate,
well-formed XML document.  Consequently, content removed by an earlier stage
cannot be extracted again by a later stage.

The source file is never modified.  Five beautified files are written:
``kt.xml``, ``kg.xml``, ``ki.xml``, ``tI.xml``, and ``kn.xml``.

https://chatgpt.com/c/6a8456b4-6700-83eb-bcbf-451e8841eac0
"""

from __future__ import annotations

import argparse
import copy
import os
import sys
import tempfile
import xml.etree.ElementTree as ET
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path


IPC_ENTRY_LOCAL_NAME = "ipcEntry"


class ExtractionError(Exception):
    """Represent a validation or output failure during IPC extraction."""


@dataclass(frozen=True)
class Stage:
    """Describe one successive extraction pass.

    Attributes:
        filename: Required output filename.
        selection: Human-readable selection stored in the output root.
        predicate: Function returning whether an ``ipcEntry`` matches.
    """

    filename: str
    selection: str
    predicate: Callable[[ET.Element], bool]


@dataclass(frozen=True)
class StageResult:
    """Contain one completed stage's output tree and match statistics.

    Attributes:
        stage: Definition of the completed extraction stage.
        output_root: Root of the generated XML document.
        extracted_roots: Number of separately emitted outermost subtrees.
        nested_matches: Number of matching descendants retained inside those
            emitted subtrees.
    """

    stage: Stage
    output_root: ET.Element
    extracted_roots: int
    nested_matches: int


def local_name(tag: str) -> str:
    """Return an expanded XML tag's local name.

    Args:
        tag: ElementTree tag, optionally in ``{namespace}name`` form.

    Returns:
        The tag name without its namespace URI.
    """

    return tag.rsplit("}", 1)[-1]


def is_ipc_entry(element: ET.Element) -> bool:
    """Return whether an element is an IPC entry container.

    Args:
        element: XML element to inspect.

    Returns:
        ``True`` only for elements whose local tag name is ``ipcEntry``.
    """

    return isinstance(element.tag, str) and local_name(element.tag) == IPC_ENTRY_LOCAL_NAME


def parse_scheme(path: Path) -> tuple[ET.ElementTree, list[tuple[str, str]]]:
    """Parse an IPC scheme and collect its namespace declarations.

    Args:
        path: IPC XML file to parse.

    Returns:
        A pair containing the parsed tree and namespace declarations in their
        first-observed order.

    Raises:
        ExtractionError: If the file cannot be read or is not well-formed XML.
    """

    namespaces: list[tuple[str, str]] = []
    seen_namespaces: set[tuple[str, str]] = set()
    root: ET.Element | None = None

    try:
        for event, value in ET.iterparse(path, events=("start-ns", "end")):
            if event == "start-ns":
                binding = value
                if binding not in seen_namespaces:
                    namespaces.append(binding)
                    seen_namespaces.add(binding)
            else:
                root = value
    except (OSError, ET.ParseError) as exc:
        raise ExtractionError(f"cannot parse {path}: {exc}") from exc

    if root is None:
        raise ExtractionError(f"no root element found in {path}")

    for prefix, uri in namespaces:
        try:
            ET.register_namespace(prefix, uri)
        except ValueError:
            # ElementTree reserves automatically generated prefixes such as
            # ns0.  The namespace URI is still preserved in the output.
            pass

    return ET.ElementTree(root), namespaces


def count_matches(root: ET.Element, predicate: Callable[[ET.Element], bool]) -> int:
    """Count all matching IPC entries, including nested matches.

    Args:
        root: Root of the current in-memory source tree.
        predicate: Stage-specific IPC-entry predicate.

    Returns:
        Total number of matching entries currently present.
    """

    return sum(1 for element in root.iter() if is_ipc_entry(element) and predicate(element))


def find_outermost_matches(
    root: ET.Element,
    predicate: Callable[[ET.Element], bool],
) -> list[tuple[ET.Element, ET.Element]]:
    """Find outermost matching entries and their parents in source order.

    Descendants of a match are deliberately not searched.  This retains any
    nested matching entries within the selected outer shell and prevents them
    from being emitted twice.

    Args:
        root: Root of the current in-memory source tree.
        predicate: Stage-specific IPC-entry predicate.

    Returns:
        ``(parent, matching_child)`` pairs in document order.
    """

    matches: list[tuple[ET.Element, ET.Element]] = []

    def visit(parent: ET.Element) -> None:
        """Traverse children until a matching subtree boundary is reached."""

        for child in list(parent):
            if is_ipc_entry(child) and predicate(child):
                matches.append((parent, child))
            else:
                visit(child)

    visit(root)
    return matches


def extract_stage(source_root: ET.Element, stage: Stage) -> StageResult:
    """Remove one stage's outermost matches and build its output document.

    Args:
        source_root: Root of the mutable in-memory IPC source tree.
        stage: Selection and output definition for this pass.

    Returns:
        The generated output root and extraction statistics.
    """

    total_matches = count_matches(source_root, stage.predicate)
    outermost = find_outermost_matches(source_root, stage.predicate)
    output_root = ET.Element(
        "ipcEntryCollection",
        {"selection": stage.selection},
    )

    for parent, element in outermost:
        parent.remove(element)
        element.tail = None
        output_root.append(element)

    return StageResult(
        stage=stage,
        output_root=output_root,
        extracted_roots=len(outermost),
        nested_matches=total_matches - len(outermost),
    )


def write_xml_atomic(root: ET.Element, destination: Path) -> None:
    """Beautify and atomically write one UTF-8 XML document.

    Args:
        root: Root element to serialize.
        destination: Final output pathname.

    Raises:
        ExtractionError: If the destination cannot be written or replaced.
    """

    destination.parent.mkdir(parents=True, exist_ok=True)
    serializable_root = copy.deepcopy(root)
    ET.indent(serializable_root, space="  ")
    tree = ET.ElementTree(serializable_root)
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
        os.replace(temporary_path, destination)
    except OSError as exc:
        if temporary_path is not None:
            try:
                temporary_path.unlink(missing_ok=True)
            except OSError:
                pass
        raise ExtractionError(f"cannot write {destination}: {exc}") from exc


def build_stages() -> tuple[Stage, ...]:
    """Return the required extraction stages in processing order.

    Returns:
        Immutable sequence for ``kind=t``, ``kind=g``, ``kind=i``,
        ``entryType=I``, and finally ``kind=n``.
    """

    return (
        Stage("kt.xml", 'kind="t"', lambda element: element.get("kind") == "t"),
        Stage("kg.xml", 'kind="g"', lambda element: element.get("kind") == "g"),
        Stage("ki.xml", 'kind="i"', lambda element: element.get("kind") == "i"),
        Stage(
            "tI.xml",
            'entryType="I"',
            lambda element: element.get("entryType") == "I",
        ),
        Stage("kn.xml", 'kind="n"', lambda element: element.get("kind") == "n"),
    )


def validate_paths(source: Path, output_dir: Path, stages: Sequence[Stage]) -> None:
    """Validate the input and ensure no output can overwrite it.

    Args:
        source: IPC scheme pathname.
        output_dir: Directory that will receive the result files.
        stages: Configured extraction stages.

    Raises:
        ExtractionError: If the source is not a file or collides with an
        output pathname.
    """

    if not source.is_file():
        raise ExtractionError(f"input is not a file: {source}")

    source_resolved = source.resolve()
    for stage in stages:
        if (output_dir / stage.filename).resolve() == source_resolved:
            raise ExtractionError(
                f"input file would be overwritten by output {stage.filename}"
            )


def extract_scheme(source: Path, output_dir: Path) -> list[StageResult]:
    """Run all successive IPC extraction stages and write their outputs.

    Args:
        source: IPC scheme XML pathname.
        output_dir: Directory for the five fixed output filenames.

    Returns:
        Stage results in extraction order.

    Raises:
        ExtractionError: If validation, parsing, or output writing fails.
    """

    stages = build_stages()
    validate_paths(source, output_dir, stages)
    tree, _namespaces = parse_scheme(source)
    source_root = tree.getroot()
    results = [extract_stage(source_root, stage) for stage in stages]

    for result in results:
        write_xml_atomic(result.output_root, output_dir / result.stage.filename)

    return results


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments.

    Args:
        argv: Optional argument sequence; ``None`` uses ``sys.argv``.

    Returns:
        Parsed command-line namespace.
    """

    parser = argparse.ArgumentParser(
        description=(
            "Successively extract IPC ipcEntry subtrees into kt.xml, kg.xml, "
            "ki.xml, tI.xml, and kn.xml."
        )
    )
    parser.add_argument("scheme", type=Path, help="IPC scheme XML file")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="output directory (default: input file's directory)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line IPC extractor.

    Args:
        argv: Optional argument sequence; ``None`` uses ``sys.argv``.

    Returns:
        Process exit code: zero on success and one on failure.
    """

    args = parse_args(argv)
    source = args.scheme
    output_dir = args.output_dir if args.output_dir is not None else source.parent

    try:
        results = extract_scheme(source, output_dir)
    except ExtractionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    for result in results:
        nested_suffix = (
            f", {result.nested_matches} nested match(es) retained in outer subtrees"
            if result.nested_matches
            else ""
        )
        print(
            f"{result.stage.filename}: {result.extracted_roots} subtree(s)"
            f"{nested_suffix}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
