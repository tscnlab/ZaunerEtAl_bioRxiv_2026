#!/usr/bin/env python3

"""Promote the fully validated Order 71b2d DOCX candidate exactly once."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
CANDIDATE = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.docx"
CANONICAL = ROOT / "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx"
OUTPUT = EVIDENCE / "order71b2d_promotion.json"
EXPECTED_CANDIDATE = "74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8"
EXPECTED_PREIMAGE = "6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    for path in (CANDIDATE, CANONICAL):
        if not path.is_file():
            raise FileNotFoundError(path)
    if OUTPUT.exists():
        raise FileExistsError("Order 71b2d has already been promoted")

    candidate_hash = sha256(CANDIDATE)
    preimage_hash = sha256(CANONICAL)
    assert candidate_hash == EXPECTED_CANDIDATE
    assert preimage_hash == EXPECTED_PREIMAGE

    temporary = CANONICAL.with_suffix(".docx.order71b2d.tmp")
    if temporary.exists():
        raise FileExistsError(temporary)
    shutil.copyfile(CANDIDATE, temporary)
    assert sha256(temporary) == candidate_hash
    os.replace(temporary, CANONICAL)
    assert sha256(CANONICAL) == candidate_hash

    result = {
        "status": "PASS",
        "promotion_count": 1,
        "canonical_path": str(CANONICAL),
        "canonical_preimage_sha256": preimage_hash,
        "canonical_postimage_sha256": sha256(CANONICAL),
        "canonical_postimage_bytes": CANONICAL.stat().st_size,
        "candidate_sha256": candidate_hash,
        "candidate_equals_canonical": CANDIDATE.read_bytes() == CANONICAL.read_bytes(),
    }
    assert result["candidate_equals_canonical"]
    OUTPUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
