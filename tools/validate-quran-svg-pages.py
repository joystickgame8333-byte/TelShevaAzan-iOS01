#!/usr/bin/env python3
"""Validate the complete offline vector Mushaf before an iOS build."""

from __future__ import annotations

import hashlib
import json
import struct
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path


PAGE_COUNT = 604
SOURCE_COMMIT = "5fbcb1d4d92b5a2972ab51472fe991b6066bb6e2"
AUDITED_CONTENT_SET_SHA256 = (
    "03a766c2b68d8fdd10dff49b6b4b1000ac911e54260dc0369cb4d835103978e3"
)
RESOURCE_DIRECTORY = (
    Path(__file__).resolve().parents[1]
    / "TelShevaAzan"
    / "Resources"
    / "Quran"
    / "MushafSVG"
)


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def fail(message: str) -> None:
    raise RuntimeError(message)


def main() -> int:
    manifest_path = RESOURCE_DIRECTORY / "manifest.json"
    notice_path = RESOURCE_DIRECTORY / "NOTICE.md"
    if not manifest_path.is_file() or not notice_path.is_file():
        fail("Mushaf manifest or source notice is missing")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != 1 or manifest.get("format") != "qsvg-zlib":
        fail("Unsupported Mushaf manifest format")
    source = manifest.get("source", {})
    if source.get("commit") != SOURCE_COMMIT:
        fail("Mushaf source is not pinned to the audited Quranpedia commit")

    page_entries = manifest.get("pages")
    if not isinstance(page_entries, list) or len(page_entries) != PAGE_COUNT:
        fail(f"Manifest must contain {PAGE_COUNT} pages")
    entries = {int(entry["number"]): entry for entry in page_entries}
    if set(entries) != set(range(1, PAGE_COUNT + 1)):
        fail("Manifest page numbers are incomplete")

    actual_names = sorted(path.name for path in RESOURCE_DIRECTORY.glob("p*.qsvg"))
    expected_names = [f"p{page:03d}.qsvg" for page in range(1, PAGE_COUNT + 1)]
    if actual_names != expected_names:
        fail("The packaged Mushaf does not contain exactly p001.qsvg through p604.qsvg")

    total_qsvg_bytes = 0
    total_svg_bytes = 0
    content_set_hasher = hashlib.sha256()
    for page in range(1, PAGE_COUNT + 1):
        path = RESOURCE_DIRECTORY / f"p{page:03d}.qsvg"
        packed = path.read_bytes()
        if len(packed) < 12:
            fail(f"Page {page}: qsvg payload is too small")

        expected_length = struct.unpack(">I", packed[:4])[0]
        cmf, flags = packed[4], packed[5]
        if (
            cmf & 0x0F != 8
            or (cmf * 256 + flags) % 31 != 0
            or flags & 0x20 != 0
        ):
            fail(f"Page {page}: invalid or unsupported zlib wrapper")
        try:
            svg_bytes = zlib.decompress(packed[4:])
        except zlib.error as error:
            fail(f"Page {page}: invalid zlib payload: {error}")
        try:
            apple_decode_bytes = zlib.decompress(packed[6:-4], wbits=-15)
        except zlib.error as error:
            fail(f"Page {page}: invalid raw DEFLATE payload for iOS: {error}")
        if apple_decode_bytes != svg_bytes:
            fail(f"Page {page}: iOS raw DEFLATE payload differs from zlib payload")
        if len(svg_bytes) != expected_length:
            fail(
                f"Page {page}: expected {expected_length} decoded bytes, "
                f"found {len(svg_bytes)}"
            )
        content_set_hasher.update(struct.pack(">I", len(svg_bytes)))
        content_set_hasher.update(svg_bytes)

        entry = entries[page]
        if entry.get("file") != path.name:
            fail(f"Page {page}: manifest file name mismatch")
        if entry.get("qsvgSha256") != sha256(packed):
            fail(f"Page {page}: packaged SHA-256 mismatch")
        if entry.get("svgSha256") != sha256(svg_bytes):
            fail(f"Page {page}: decoded SVG SHA-256 mismatch")

        try:
            root = ET.fromstring(svg_bytes.decode("utf-8"))
        except (UnicodeDecodeError, ET.ParseError) as error:
            fail(f"Page {page}: invalid UTF-8 SVG: {error}")
        if local_name(root.tag) != "svg" or not root.attrib.get("viewBox"):
            fail(f"Page {page}: missing SVG root or viewBox")

        has_content = False
        visible_paths = 0
        for element in root.iter():
            classes = element.attrib.get("class", "").split()
            if "ayahPolygon" in classes:
                fail(f"Page {page}: transparent ayahPolygon was not removed")
            if element.attrib.get("id") == "content":
                has_content = True
            if local_name(element.tag) == "path" and element.attrib.get("fill-opacity") != "0":
                visible_paths += 1
        if not has_content or visible_paths == 0:
            fail(f"Page {page}: rendered Mushaf artwork is missing")

        total_qsvg_bytes += len(packed)
        total_svg_bytes += len(svg_bytes)

    if content_set_hasher.hexdigest() != AUDITED_CONTENT_SET_SHA256:
        fail("Packaged Mushaf content does not match the audited 604-page source set")

    totals = manifest.get("totals", {})
    if totals.get("pageCount") != PAGE_COUNT:
        fail("Manifest total page count is incorrect")
    if totals.get("qsvgBytes") != total_qsvg_bytes:
        fail("Manifest compressed byte total is incorrect")
    if totals.get("svgBytes") != total_svg_bytes:
        fail("Manifest SVG byte total is incorrect")

    ratio = total_qsvg_bytes / total_svg_bytes
    print(
        f"Validated {PAGE_COUNT} vector Mushaf pages: "
        f"{total_qsvg_bytes / 1024 / 1024:.1f} MiB packaged "
        f"({ratio:.1%} of cleaned SVG size)."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - CI should show one concise failure.
        print(f"Quran SVG validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
