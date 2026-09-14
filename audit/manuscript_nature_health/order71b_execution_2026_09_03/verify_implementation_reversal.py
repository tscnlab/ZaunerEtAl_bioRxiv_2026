#!/usr/bin/env python3

"""Prove the two Order 71b implementation changes reverse to locked preimages."""

from __future__ import annotations

import hashlib
from pathlib import Path


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


yaml_path = Path("manuscript/R0_NatHealth/_quarto.yml")
script_path = Path("scripts/manuscript_nature_health/prepare_word_manuscript.py")

yaml_text = yaml_path.read_text(encoding="utf-8")
script_text = script_path.read_text(encoding="utf-8")

assert sha256(yaml_text) == "3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0"
assert sha256(script_text) == "1a2b8091b34cd0fa88dcf6143cf336c52b531773e66e1578ac818fddfba97adf"

yaml_addition = (
    "    filters:\n"
    "      - ../../_extensions/kapsner/authors-block/authors-block.lua\n"
)
assert yaml_text.count(yaml_addition) == 1
yaml_preimage = yaml_text.replace(yaml_addition, "", 1)
assert sha256(yaml_preimage) == "c7c3fc8a96f1e65914cfb88c8d4de2bf8bcacb75fcf37902b262c79d2becae24"
assert len(yaml_preimage.encode("utf-8")) == 482

assert script_text.count("import hashlib\n") == 1
script_preimage = script_text.replace("import hashlib\n", "", 1)
helper_start = script_preimage.index("EXPECTED_AFFILIATIONS = (")
helper_end = script_preimage.index("def find_paragraphs", helper_start)
script_preimage = script_preimage[:helper_start] + script_preimage[helper_end:]
call = "    author_block = relocate_author_block(document)\n"
report = '                "author_block": author_block,\n'
assert script_preimage.count(call) == 1
assert script_preimage.count(report) == 1
script_preimage = script_preimage.replace(call, "", 1)
script_preimage = script_preimage.replace(report, "", 1)
assert sha256(script_preimage) == "05ed9ca826757c643970a6d201fbcc15cfc83648d2ebdc8d44f707d85f214727"
assert len(script_preimage.encode("utf-8")) == 31160

print("PASS: both focused changes reverse exactly to the locked preimages")
