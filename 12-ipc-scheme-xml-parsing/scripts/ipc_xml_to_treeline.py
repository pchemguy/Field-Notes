#!/usr/bin/env python3
"""Convert IPC Scheme XML ``ipcEntry`` elements to a TreeLine document.

The source XML file is the sole source of truth. Each ``ipcEntry`` element is
projected to one TreeLine node, each XML attribute is projected to a TreeLine
text field, and the nearest enclosing ``ipcEntry`` determines the node's
parent. Non-``ipcEntry`` elements are transparent: they create no node and
contribute neither attributes nor text.

Every node also receives a final ``source`` property. Its value is the lexical
attribute portion of the original start tag after removing the qualified
element name and the closing ``>`` or ``/>``. Attribute order, whitespace, and
quotation marks are otherwise preserved. For example, the source tag
``<ipcEntry kind="g" symbol="A01B" />`` produces
``kind="g" symbol="A01B"``.

The parser processes the XML input incrementally and memory-maps it only to
recover lexical start-tag text from Expat byte offsets. TreeLine nodes are
retained in memory because the output is one JSON document containing a flat
node array. Output is written to a temporary file, flushed, synchronized, and
atomically moved over the destination, so a failed write does not leave a
partially written ``.trln`` file.

The implementation uses only the Python standard library, is compatible with
Python 3.11 or later, and was validated with Python 3.12.13. The generated JSON
schema targets TreeLine 3.2.1's native file format.

https://chatgpt.com/c/6a86cd05-5200-83eb-a8aa-74417a812bf0
"""

from __future__ import annotations

import argparse
import codecs
import hashlib
import json
import mmap
import os
import re
import sys
import tempfile
import uuid
from collections.abc import Sequence
from pathlib import Path
from typing import Any
from xml.parsers import expat


#: TreeLine native-format version recorded in the output document.
TREELINE_VERSION = "3.2.1"
#: Name of the single TreeLine node format emitted by the converter.
FORMAT_NAME = "IPC Entry"
#: Reserved final field containing the lexical ``ipcEntry`` attribute text.
SOURCE_FIELD_NAME = "source"
#: Namespace used to derive stable, deterministic UUID5 node identifiers.
UID_NAMESPACE = uuid.UUID("85b60d25-c759-4db7-870f-51d9bcc44ae2")
#: Characters replaced when an XML attribute name is not TreeLine-safe.
VALID_FIELD_CHARACTER = re.compile(r"[^\w.\-]", flags=re.UNICODE)
#: XML-declaration pattern used for ASCII-compatible encoding detection.
XML_ENCODING_DECLARATION = re.compile(
    rb"encoding\s*=\s*(['\"])([A-Za-z][A-Za-z0-9._-]*)\1", flags=re.IGNORECASE
)
#: Number of XML bytes submitted to Expat per incremental parse operation.
PARSE_CHUNK_SIZE = 1024 * 1024


def local_name(expanded_name: str) -> str:
    """Return the local component of an expanded XML name.

    Args:
        expanded_name: An unqualified name or an Expat-expanded name in
            ``namespace-uri}local-name`` form.

    Returns:
        The part following the final ``}``, or the original name when it is
        unqualified.
    """
    return expanded_name.rsplit("}", 1)[-1]


class FieldNameMap:
    """Map XML attribute names to stable, unique TreeLine field names.

    Standard unqualified IPC attribute names, such as ``kind`` and ``symbol``,
    pass through unchanged. Unsupported characters in other XML names are
    replaced with underscores. If two XML names normalize to the same field
    name, a deterministic hash suffix disambiguates the later name.

    Attributes:
        _xml_to_treeline: Mapping from original Expat attribute names to their
            assigned TreeLine field names.
        _treeline_to_xml: Reverse ownership mapping used to detect normalized
            field-name collisions.
    """

    def __init__(self) -> None:
        """Initialize an empty bidirectional field-name registry."""
        self._xml_to_treeline: dict[str, str] = {}
        self._treeline_to_xml: dict[str, str] = {}

    def get(self, xml_name: str) -> str:
        """Return the TreeLine field name assigned to an XML attribute.

        Args:
            xml_name: Original unqualified or Expat-expanded XML attribute
                name.

        Returns:
            A TreeLine-compatible field name. Repeated calls with the same XML
            name return the same value for the lifetime of this mapping.

        Notes:
            Collision suffixes use the first eight hexadecimal digits of a
            SHA-1 digest only as a deterministic identifier; no security
            property is required.
        """
        existing = self._xml_to_treeline.get(xml_name)
        if existing is not None:
            return existing

        # Standard IPC attributes are unqualified and pass through unchanged.
        candidate = local_name(xml_name)
        candidate = VALID_FIELD_CHARACTER.sub("_", candidate).strip("_")
        if not candidate:
            candidate = "attribute"

        owner = self._treeline_to_xml.get(candidate)
        if owner is not None and owner != xml_name:
            digest = hashlib.sha1(xml_name.encode("utf-8")).hexdigest()[:8]
            candidate = f"{candidate}_{digest}"

        self._xml_to_treeline[xml_name] = candidate
        self._treeline_to_xml[candidate] = xml_name
        return candidate


def node_uid(ordinal: int) -> str:
    """Create a deterministic TreeLine node identifier for a source ordinal.

    Args:
        ordinal: One-based position of the ``ipcEntry`` in XML document order.

    Returns:
        A 32-character lowercase hexadecimal UUID5 value.

    Notes:
        Identifiers are stable when ``ipcEntry`` document order is unchanged.
        Inserting or removing an earlier entry intentionally changes the IDs
        of subsequent nodes.
    """
    return uuid.uuid5(UID_NAMESPACE, f"ipcEntry:{ordinal}").hex


def detect_xml_encoding(source: mmap.mmap) -> tuple[str, int]:
    """Detect the source codec and encoded XML markup-character width.

    Args:
        source: Read-only memory map of the complete, non-empty XML file.

    Returns:
        A pair containing a fragment-safe Python codec name and the number of
        bytes occupied by each ASCII XML markup character. The codec is
        endian-specific for UTF-16 and UTF-32 so an isolated start-tag fragment
        can be decoded without a byte-order mark.

    Raises:
        LookupError: The XML declaration names an encoding unknown to Python.

    Notes:
        Detection follows XML byte-order signatures before consulting the
        optional encoding declaration. XML without a signature or declaration
        defaults to UTF-8. The returned width is used only while scanning for
        quotation marks and the closing angle bracket.
    """
    prefix = bytes(source[:1024])
    if prefix.startswith(b"\x00\x00\xfe\xff"):
        return "utf-32-be", 4
    if prefix.startswith(b"\xff\xfe\x00\x00"):
        return "utf-32-le", 4
    if prefix.startswith(b"\xfe\xff"):
        return "utf-16-be", 2
    if prefix.startswith(b"\xff\xfe"):
        return "utf-16-le", 2
    if prefix.startswith(b"\x00\x00\x00<"):
        return "utf-32-be", 4
    if prefix.startswith(b"<\x00\x00\x00"):
        return "utf-32-le", 4
    if prefix.startswith(b"\x00<\x00?"):
        return "utf-16-be", 2
    if prefix.startswith(b"<\x00?\x00"):
        return "utf-16-le", 2

    match = XML_ENCODING_DECLARATION.search(prefix)
    declared = match.group(2).decode("ascii") if match else "utf-8"
    codec = codecs.lookup(declared).name
    if codec == "utf-8-sig":
        codec = "utf-8"
    return codec, 1


def encoded_markup_character(character: str, encoding: str, width: int) -> bytes:
    """Encode one XML markup character without introducing a byte-order mark.

    Args:
        character: Single ASCII markup character to encode.
        encoding: Fragment-safe codec returned by :func:`detect_xml_encoding`.
        width: Expected encoded byte width for one markup character.

    Returns:
        Encoded bytes for ``character``.

    Raises:
        UnicodeEncodeError: The selected codec cannot encode ``character``.
        ValueError: The encoded result does not have the expected fixed width,
            meaning lexical tag capture is unsupported for that encoding.
    """
    encoded = character.encode(encoding)
    if len(encoded) != width:
        raise ValueError(
            f"XML encoding {encoding!r} is not supported for verbatim tag capture"
        )
    return encoded


def extract_start_tag(
    source: mmap.mmap, start: int, encoding: str, width: int
) -> str:
    """Extract a complete lexical XML start tag from a byte offset.

    Args:
        source: Read-only memory map containing the XML document.
        start: Byte offset of the start tag's opening ``<`` as reported by
            ``pyexpat``.
        encoding: Fragment-safe codec returned by
            :func:`detect_xml_encoding`.
        width: Encoded width of an ASCII XML markup character.

    Returns:
        Decoded start-tag text from the opening ``<`` through the closing
        ``>``, inclusive.

    Raises:
        UnicodeDecodeError: The captured bytes are invalid in ``encoding``.
        UnicodeEncodeError: A required markup character cannot be encoded.
        ValueError: The encoding is unsupported for lexical capture or no
            unquoted closing ``>`` exists before end of input.

    Notes:
        The scanner tracks single- and double-quoted attribute values, so a
        legal ``>`` inside an attribute value does not terminate the tag.
    """
    apostrophe = encoded_markup_character("'", encoding, width)
    quotation_mark = encoded_markup_character('"', encoding, width)
    closing_bracket = encoded_markup_character(">", encoding, width)
    quote: bytes | None = None
    position = start

    while position + width <= len(source):
        character = bytes(source[position : position + width])
        if quote is None:
            if character in (apostrophe, quotation_mark):
                quote = character
            elif character == closing_bracket:
                return bytes(source[start : position + width]).decode(encoding)
        elif character == quote:
            quote = None
        position += width

    raise ValueError(f"unterminated XML start tag at byte offset {start}")


def source_property_value(start_tag: str) -> str:
    """Derive the TreeLine ``source`` value from a lexical start tag.

    Args:
        start_tag: Complete start tag including the opening ``<`` and closing
            ``>``. The tag may use a namespace prefix and may be self-closing.

    Returns:
        Text between the qualified element name and the closing delimiter.
        Outer whitespace and the self-closing slash are removed. Attribute
        order, internal whitespace, line breaks, and quotation marks remain
        unchanged.

    Raises:
        ValueError: ``start_tag`` does not have the expected lexical wrapper.

    Examples:
        ``<ipcEntry kind="g" symbol="A01B" />`` becomes
        ``kind="g" symbol="A01B"``.
    """
    tag = start_tag.strip()
    if not tag.startswith("<") or not tag.endswith(">"):
        raise ValueError(f"invalid XML start tag captured for source: {start_tag!r}")

    name_end = 1
    while (
        name_end < len(tag)
        and not tag[name_end].isspace()
        and tag[name_end] not in "/>"
    ):
        name_end += 1

    attributes = tag[name_end:-1].rstrip()
    if attributes.endswith("/"):
        attributes = attributes[:-1].rstrip()
    return attributes.strip()


def read_ipc_entries(
    xml_path: Path,
) -> tuple[list[dict[str, Any]], list[str], list[str]]:
    """Parse IPC entries into TreeLine node records and format metadata.

    Args:
        xml_path: Path to the IPC Scheme XML source file.

    Returns:
        A three-item tuple containing:

        * node dictionaries in XML document order;
        * UIDs of root nodes in XML document order; and
        * TreeLine field names in first-observed attribute order, followed by
          the generated ``source`` field.

    Raises:
        OSError: The source cannot be opened, inspected, or memory-mapped.
        expat.ExpatError: The input is not well-formed XML or uses an XML
            feature rejected by Expat.
        LookupError: The declared XML encoding is unknown to Python.
        UnicodeError: Lexical start-tag bytes cannot be encoded or decoded as
            required.
        ValueError: The input is empty, lexical tag capture fails, or an XML
            attribute maps to the reserved ``source`` field name.

    Notes:
        Only explicitly written attributes are collected; DTD-defaulted
        attributes are excluded. Non-``ipcEntry`` elements do not create nodes
        and do not interrupt the nearest-``ipcEntry`` ancestry stack. The XML
        parser is fed in fixed-size chunks, while the resulting TreeLine node
        array remains resident until JSON serialization.
    """
    nodes: list[dict[str, Any]] = []
    top_nodes: list[str] = []
    parent_stack: list[dict[str, Any]] = []
    field_names: list[str] = []
    known_fields: set[str] = set()
    field_map = FieldNameMap()

    with xml_path.open("rb") as xml_file:
        if os.fstat(xml_file.fileno()).st_size == 0:
            raise ValueError("input XML file is empty")
        with mmap.mmap(xml_file.fileno(), 0, access=mmap.ACCESS_READ) as source:
            encoding, character_width = detect_xml_encoding(source)
            parser = expat.ParserCreate(namespace_separator="}")
            parser.ordered_attributes = True
            parser.specified_attributes = True

            def start_element(name: str, attributes: list[str]) -> None:
                """Handle an Expat start-element event.

                Args:
                    name: Unqualified or namespace-expanded element name.
                    attributes: Alternating attribute-name and attribute-value
                        strings in source order.

                Raises:
                    UnicodeError: The lexical start tag cannot be decoded.
                    ValueError: Lexical capture fails or an input attribute
                        conflicts with the generated ``source`` property.

                Notes:
                    Non-``ipcEntry`` events return immediately. For an
                    ``ipcEntry``, the new node is linked to the nearest open
                    ``ipcEntry`` regardless of intervening wrapper elements.
                """
                if local_name(name) != "ipcEntry":
                    return

                data: dict[str, str] = {}
                for xml_name, value in zip(attributes[::2], attributes[1::2]):
                    field_name = field_map.get(xml_name)
                    if field_name == SOURCE_FIELD_NAME:
                        raise ValueError(
                            "ipcEntry attribute 'source' conflicts with the generated "
                            "TreeLine source property"
                        )
                    data[field_name] = value
                    if field_name not in known_fields:
                        known_fields.add(field_name)
                        field_names.append(field_name)

                data[SOURCE_FIELD_NAME] = source_property_value(
                    extract_start_tag(
                        source,
                        parser.CurrentByteIndex,
                        encoding,
                        character_width,
                    )
                )

                uid = node_uid(len(nodes) + 1)
                node: dict[str, Any] = {
                    "format": FORMAT_NAME,
                    "uid": uid,
                    "data": data,
                    "children": [],
                }
                nodes.append(node)

                if parent_stack:
                    parent_stack[-1]["children"].append(uid)
                else:
                    top_nodes.append(uid)
                parent_stack.append(node)

            def end_element(name: str) -> None:
                """Handle an Expat end-element event.

                Args:
                    name: Unqualified or namespace-expanded element name.

                Notes:
                    Only an ``ipcEntry`` event pops the ancestry stack;
                    all other closing tags are ignored.
                """
                if local_name(name) == "ipcEntry":
                    parent_stack.pop()

            parser.StartElementHandler = start_element
            parser.EndElementHandler = end_element

            position = 0
            while position < len(source):
                end = min(position + PARSE_CHUNK_SIZE, len(source))
                parser.Parse(source[position:end], end == len(source))
                position = end

    field_names.append(SOURCE_FIELD_NAME)

    return nodes, top_nodes, field_names


def build_treeline_document(
    nodes: list[dict[str, Any]], top_nodes: list[str], field_names: list[str]
) -> dict[str, Any]:
    """Assemble a TreeLine 3.2.1 native JSON document.

    Args:
        nodes: Flat TreeLine node records in source document order.
        top_nodes: UIDs of root nodes in source document order.
        field_names: Ordered union of node property names. The caller places
            ``source`` last.

    Returns:
        JSON-serializable dictionary containing one ``IPC Entry`` node format,
        the supplied node array, and TreeLine document properties.

    Notes:
        The node label uses ``symbol`` when that field exists. Otherwise, it
        uses the first declared field, falling back to the literal
        ``ipcEntry`` only when no field is available. All fields are declared
        as TreeLine ``Text`` fields and included in output-line order.
    """
    if "symbol" in field_names:
        title_line = "{*symbol*}"
    elif field_names:
        title_line = f"{{*{field_names[0]}*}}"
    else:
        title_line = "ipcEntry"

    node_format = {
        "formatname": FORMAT_NAME,
        "fields": [
            {"fieldname": field_name, "fieldtype": "Text"}
            for field_name in field_names
        ],
        "titleline": title_line,
        "outputlines": [
            f"{field_name}: {{*{field_name}*}}" for field_name in field_names
        ],
    }
    return {
        "formats": [node_format],
        "nodes": nodes,
        "properties": {
            "tlversion": TREELINE_VERSION,
            "topnodes": top_nodes,
        },
    }


def write_json_atomically(document: dict[str, Any], output_path: Path) -> None:
    """Serialize a TreeLine document and atomically replace its destination.

    Args:
        document: JSON-serializable TreeLine document.
        output_path: Destination ``.trln`` path.

    Raises:
        OSError: A directory cannot be created, temporary or destination file
            operations fail, synchronization fails, or the atomic replacement
            cannot be completed.
        TypeError: ``document`` contains a value unsupported by ``json.dump``.
        ValueError: JSON serialization rejects a value in ``document``.

    Notes:
        Parent directories are created when absent. Serialization uses UTF-8,
        preserves non-ASCII characters, applies two-space indentation, and
        terminates the file with a newline. If any operation fails after the
        temporary file is created, that temporary file is removed before the
        exception is re-raised. An existing destination is replaced only after
        the complete new file has been flushed and synchronized.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="\n",
            prefix=f".{output_path.name}.",
            suffix=".tmp",
            dir=output_path.parent,
            delete=False,
        ) as temporary_file:
            temporary_name = temporary_file.name
            json.dump(document, temporary_file, ensure_ascii=False, indent=2)
            temporary_file.write("\n")
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_name, output_path)
    except Exception:
        if temporary_name is not None:
            Path(temporary_name).unlink(missing_ok=True)
        raise


def default_output_path(xml_path: Path) -> Path:
    """Derive the default TreeLine destination from an XML path.

    Args:
        xml_path: Source XML path.

    Returns:
        A sibling path whose final suffix is ``.trln``. For example,
        ``ipc-scheme.xml`` becomes ``ipc-scheme.trln``.
    """
    return xml_path.with_suffix(".trln")


def parse_arguments(argv: Sequence[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments for the converter.

    Args:
        argv: Argument sequence excluding the executable name. When ``None``,
            :mod:`argparse` reads arguments from :data:`sys.argv`.

    Returns:
        Namespace with ``input_xml`` and optional ``output_trln``
        :class:`~pathlib.Path` attributes.

    Raises:
        SystemExit: Argument syntax is invalid or help was requested.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Convert IPC Scheme XML ipcEntry elements and their attributes "
            "to a TreeLine 3.2.1 .trln file."
        )
    )
    parser.add_argument("input_xml", type=Path, help="source IPC Scheme XML file")
    parser.add_argument(
        "output_trln",
        nargs="?",
        type=Path,
        help="output .trln file (default: input name with .trln suffix)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the IPC XML to TreeLine conversion command.

    Args:
        argv: Optional argument sequence excluding the executable name. Pass
            ``None`` to use :data:`sys.argv`.

    Returns:
        Process exit status:

        * ``0`` — conversion completed and the output was atomically written;
        * ``1`` — input, XML parsing, encoding, transformation, or output I/O
          failed; or
        * ``2`` — input and output resolve to the same path.

    Notes:
        User-facing operational failures are reported to standard error without
        a traceback. On success, a compact node, root, and field count is
        written to standard output. ``argparse`` retains its conventional exit
        status of ``2`` for command-line syntax errors raised before this
        function can return.
    """
    args = parse_arguments(argv)
    input_path = args.input_xml.expanduser().resolve()
    output_path = (
        args.output_trln.expanduser().resolve()
        if args.output_trln is not None
        else default_output_path(input_path)
    )

    if input_path == output_path:
        print("error: input and output paths must be different", file=sys.stderr)
        return 2

    try:
        nodes, top_nodes, field_names = read_ipc_entries(input_path)
        document = build_treeline_document(nodes, top_nodes, field_names)
        write_json_atomically(document, output_path)
    except (OSError, expat.ExpatError, LookupError, UnicodeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(
        f"Wrote {len(nodes):,} ipcEntry nodes, {len(top_nodes):,} roots, "
        f"and {len(field_names):,} fields to {output_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
