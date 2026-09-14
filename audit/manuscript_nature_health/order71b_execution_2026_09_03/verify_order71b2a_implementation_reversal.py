#!/usr/bin/env python3

"""Prove the Order 71b2a source patch reverses to its sealed preimage."""

from __future__ import annotations

import hashlib
from pathlib import Path


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


path = Path("scripts/manuscript_nature_health/prepare_word_manuscript.py")
postimage = path.read_text(encoding="utf-8")
assert sha256_bytes(postimage.encode("utf-8")) == (
    "074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71"
)
assert len(postimage.encode("utf-8")) == 47744

constants_start = postimage.index("MAIN_DISPLAY_BOOKMARK_DESTINATIONS = (")
constants_end = postimage.index("def relationship_signature", constants_start)
preimage = postimage[:constants_start] + "\n" + postimage[constants_end:]

helper_start = preimage.index("def add_missing_display_bookmarks")
helper_end = preimage.index("def relocate_author_block", helper_start)
preimage = preimage[:helper_start] + preimage[helper_end:]

call = "    display_bookmarks = add_missing_display_bookmarks(document)\n"
report = '                "display_bookmarks": display_bookmarks,\n'
assert preimage.count(call) == 1
assert preimage.count(report) == 1
preimage = preimage.replace(call, "", 1)
preimage = preimage.replace(report, "", 1)

assert sha256_bytes(preimage.encode("utf-8")) == (
    "1a2b8091b34cd0fa88dcf6143cf336c52b531773e66e1578ac818fddfba97adf"
)
assert len(preimage.encode("utf-8")) == 38747

print("PASS: Order 71b2a source patch reverses exactly to the sealed preimage")
