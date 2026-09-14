#!/usr/bin/env python3
"""Read-only editorial checks. No scientific calculation or rendering."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / "audit/manuscript_nature_health/revision_2026_09_11/title_framing_author_approval"
SOURCE = ROOT / "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
BEFORE = AUDIT / "source_before.qmd"
EXPECTED_BEFORE = "bda9f4ad9c974c6e23cc358d687cc05848df06b5c614f6f564c07c46dee71d09"
ALLOWED = {"P-I02", "P-I04", "P-D01", "P-D09", "P-M14"}
PARAGRAPH = re.compile(r"(<!-- (P-[A-Z]\d+[A-Z]?) -->\n)([^\n]+)")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def abstract(text: str) -> str:
    return re.search(r"^# Abstract\n\n(.*?)\n\n# Introduction", text, re.M | re.S).group(1)


def paragraph_map(text: str) -> dict[str, str]:
    return {m.group(2): m.group(3) for m in PARAGRAPH.finditer(text)}


def words(text: str, retain_display_calls: bool = False) -> int:
    text = re.sub(r"\[@[^]]+\]", " ", text)
    text = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1" if retain_display_calls else " ", text)
    text = re.sub(r"@[A-Za-z][A-Za-z0-9_.:-]+", " ", text)
    text = re.sub(r"[`*_#{}]", " ", text)
    return len(text.split())


def masked(text: str) -> str:
    text = re.sub(r'^title: .*$', 'title: [APPROVED EDIT]', text, count=1, flags=re.M)
    text = text.replace(abstract(text), "[APPROVED ABSTRACT EDIT]", 1)
    return PARAGRAPH.sub(lambda m: m.group(1) + "[APPROVED PARAGRAPH EDIT]"
                         if m.group(2) in ALLOWED else m.group(0), text)


def main() -> None:
    before, after = BEFORE.read_text(), SOURCE.read_text()
    old, new = paragraph_map(before), paragraph_map(after)
    original_abstract, revised_abstract = abstract(before), abstract(after)
    changed = [key for key in old if old[key] != new.get(key)]
    old_yaml, new_yaml = [t.split("---", 2)[1] for t in (before, after)]
    approved_title = re.search(r'^title: "([^"]+)"$', new_yaml, re.M).group(1)
    old_yaml, new_yaml = [re.sub(r'^title: .*$', '', t, flags=re.M) for t in (old_yaml, new_yaml)]
    checker = Path("/Users/zauner/.codex/skills/clarify-scientific-writing/scripts/check_invariants.py")
    spec = importlib.util.spec_from_file_location("clarity_invariants", checker)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    invariants = module.compare_texts(before, after)
    numbers = lambda t: re.findall(module.NUMBER_RE, t)
    refs = lambda t: re.findall(module.CITATION_KEY_RE, t)
    abstract_replacement = (
        "Site, civil-photoperiod and person-level associations were metric-specific rather than uniform.",
        "Associations with site, day length and personal characteristics differed across exposure measures.",
    )
    main_before_text = "\n".join(v for k, v in old.items() if k.startswith(("P-I", "P-R", "P-D")))
    main_after_text = "\n".join(v for k, v in new.items() if k.startswith(("P-I", "P-R", "P-D")))
    main_before, main_after = words(main_before_text), words(main_after_text)
    checks = {
        "preimage_identity_exact": sha(BEFORE) == EXPECTED_BEFORE,
        "approved_title_exact": approved_title == "The health-relevant architecture of the everyday light exposome",
        "frontmatter_other_than_title_byte_exact": old_yaml == new_yaml,
        "paragraph_identifiers_and_order_unchanged": list(old) == list(new),
        "only_approved_paragraphs_and_day_length_gloss_changed": set(changed) == ALLOWED,
        "all_other_bytes_unchanged": masked(before) == masked(after),
        "abstract_only_one_sentence_simplified": original_abstract.replace(*abstract_replacement) == revised_abstract,
        "abstract_under_150_words": len(revised_abstract.split()) <= 150,
        "abstract_numbers_in_same_order": numbers(original_abstract) == numbers(revised_abstract),
        "all_source_numbers_in_same_order": numbers(before) == numbers(after),
        "citation_and_cross_reference_tokens_in_same_order": refs(before) == refs(after),
        "mechanical_invariants_all_match": not invariants["has_differences"],
        "no_health_outcome_limitation_byte_exact": old["P-D08"] == new["P-D08"],
        "all_results_paragraphs_byte_exact": all(old[k] == new[k] for k in old if k.startswith("P-R")),
        "brown_methods_byte_exact": all(old[k] == new[k] for k in ("P-M12", "P-M12A", "P-M12B")),
        "model_scale_definitions_byte_exact": all(old[k] == new[k] for k in ("P-M13", "P-M16")),
        "day_length_gloss_only_methods_edit": old["P-M14"].replace("civil photoperiod,", "civil photoperiod (day length including civil twilight),", 1) == new["P-M14"],
        "main_narrative_under_4500_project_convention": main_after <= 4500,
        "no_em_dashes": "\u2014" not in after,
    }
    protected = {
        "manuscript/R0_NatHealth/references_merged.bib": "fa7454dedb2f84e5bf49fb9c590d1eadbaef2756dae05aa4bc2c2beceecc00a0",
        "assets/reference.docx": "8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f",
        "_build/nathealth/index.html": "9c1beea41a0b203b8a8b032eade2ba7e4ab5067857d39e296a8503231af46eec",
        "_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx": "74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8",
        "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx": "933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9",
        "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/stopped_manifest.csv": "76bebd6da0ab5985c67b229780d6c8143d82bd8fdb969b1b22d38b4d96d9ecf3",
    }
    for path, expected in protected.items():
        checks["protected:" + path] = sha(ROOT / path) == expected
    result = {
        "operation": "Source-only author-approved editorial checkpoint; no render or scientific calculation",
        "checks": checks,
        "all_passed": all(checks.values()),
        "changed_paragraph_ids": changed,
        "abstract_words_before": len(original_abstract.split()),
        "abstract_words_after": len(revised_abstract.split()),
        "main_narrative_words_before": main_before,
        "main_narrative_words_after": main_after,
        "main_narrative_including_display_calls_before": words(main_before_text, True),
        "main_narrative_including_display_calls_after": words(main_after_text, True),
        "word_count_method": "Existing project convention from validate_current_revision.R: whitespace-separated words; tagged Introduction/Results/Discussion prose, excluding headings, display blocks, citation keys and Markdown display-call links. The conservative count retaining those link labels is reported separately, not silently equated with this convention.",
        "source_before_sha256": sha(BEFORE),
        "source_after_sha256": sha(SOURCE),
        "invariant_checker": str(checker),
        "invariants": invariants,
    }
    print(json.dumps(result, indent=2))
    if not result["all_passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
