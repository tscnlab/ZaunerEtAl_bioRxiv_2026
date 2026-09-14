#!/usr/bin/env python3

"""Prove the Order 71b2c validator patch reverses to its sealed preimage."""

from __future__ import annotations

import hashlib
from pathlib import Path


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


path = Path(
    "audit/manuscript_nature_health/order71b_execution_2026_09_03/"
    "verify_order71b_docx.py",
)
postimage = path.read_text(encoding="utf-8")
assert sha256_bytes(postimage.encode("utf-8")) == (
    "80660a0c5eaea25660a182d049b4672a2ff846f5062d6c0caefb50b7feceefff"
)
assert len(postimage.encode("utf-8")) == 28592

start = postimage.index("    supplementary_identity_indices = set()\n")
end = postimage.index("    results = {", start)
sealed_loops = (
    "    for number in range(1, 18):\n"
    '        assert sum(text.startswith(f"Supplementary Figure S{number}.") '
    "for text in candidate_texts) == 2\n"
    "    for number in range(1, 16):\n"
    '        assert sum(text.startswith(f"Supplementary Table S{number}.") '
    "for text in candidate_texts) == 2\n"
    "\n"
)
preimage = postimage[:start] + sealed_loops + postimage[end:]
assert sha256_bytes(preimage.encode("utf-8")) == (
    "497eadb6a25c682df131d67bf6b40007856b2dde2d2c492753dde16dcf4b1a6b"
)
assert len(preimage.encode("utf-8")) == 27012

print("PASS: Order 71b2c validator patch reverses exactly to the sealed preimage")
