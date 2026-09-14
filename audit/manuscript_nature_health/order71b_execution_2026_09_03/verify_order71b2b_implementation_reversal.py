#!/usr/bin/env python3

"""Prove the Order 71b2b serializer fix reverses to its sealed preimage."""

from __future__ import annotations

import hashlib
from pathlib import Path


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


path = Path("scripts/manuscript_nature_health/prepare_word_manuscript.py")
postimage = path.read_text(encoding="utf-8")
assert sha256_bytes(postimage.encode("utf-8")) == (
    "aeeabb11d97d812627de53b29e92e92f7fc6a87c5dc7006d223232c2f2ab20a4"
)
assert len(postimage.encode("utf-8")) == 47981

assert postimage.count("from lxml import etree\n") == 1
preimage = postimage.replace("from lxml import etree\n", "", 1)

multiline = (
    "etree.tostring(\n"
    "            bookmark,\n"
    '            encoding="unicode",\n'
    "        )"
)
assert preimage.count(multiline) == 2
preimage = preimage.replace(multiline, "bookmark.xml")

for collection in ("ends_before", "ends_after"):
    serializer = (
        'etree.tostring(bookmark, encoding="unicode")\n'
        f"        for bookmark in {collection}"
    )
    original = f"bookmark.xml for bookmark in {collection}"
    assert preimage.count(serializer) == 1
    preimage = preimage.replace(serializer, original, 1)

assert "etree.tostring(bookmark" not in preimage
assert sha256_bytes(preimage.encode("utf-8")) == (
    "074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71"
)
assert len(preimage.encode("utf-8")) == 47744

print("PASS: Order 71b2b serializer fix reverses exactly to the sealed preimage")
