# Independent SVG packaging-stop disposition

2026-09-11. Read-only review. No compatibility repair is dispatched.

The Writer's sealed stopped return is reproduced: all 444 current members and
4,339 historical versions match. The four source aliases resolve by exact path
and expected version. All eight Quarto runtime preimages and current versions
match; only the explicitly recorded main xref transition changed. Table 3 is
byte-exact. The verified R 4.6.1 audit passed all 17 checks.

## Every affected drawing

| Main figure | docPr ID | Existing native SVG relationship | Embedded member |
|---|---|---|---|
| 1 | 22 | rId21 | word/media/rId21.svg |
| 2 | 29 | rId28 | word/media/rId28.svg |
| 3 | 36 | rId35 | word/media/rId35.svg |

All three SVG payloads match the explicit accepted source map. Each `a:blip`
lacks its base `r:embed`, but has one resolving internal native SVG relationship
and two extensions: the standard DPI extension with `a14:useLocalDpi val="0"`,
and the standard SVG extension. None has a crop node. The existing drawing
geometry and all namespace/extension data must be preserved except for any
separately approved, exactly reversible compatibility change.

The raw DOCX has 20 drawings, not three: its other 17 are the byte-exact S2
distribution PNGs inside the native table. All 20 image relationships are
classified, internal and resolving. They are not 17 more affected scientific
SVGs. The first independent checker incorrectly equated three scientific SVGs
with all raw drawings. It and its partial output remain unchanged. The named
verified checker replaces that erroneous assertion with stronger complete
classification against all 17 source S2 payloads; no owner checker or artifact
was changed.

## Downstream assumptions reviewed

1. `prepare_word_manuscript.py` moves each unique main figure paragraph out of
   its one-cell float and changes only its geometry/label/paragraph layout.
   `resize_drawing_paragraph()` does not create the missing base relationship
   or remove either extension. The existing compatibility defect will therefore
   survive assembly. Native S2 tables are replaced by approved captures, so the
   17 raw table miniplots are removed with the native table, not promoted as
   additional figure drawings.
2. The same helper creates supplemental SVG image parts using a base image
   relationship and no extension list. It reuses exact source bytes. S7/S15
   produce separate A/B drawings; S8 uses two pre-existing approved crop windows
   on one SVG. These base-only and repeated-source paths must keep working.
   Together with 29 table PNG parts, the explicit map requires 52 drawings:
   23 SVG appearances from 22 sources, plus the 29 table parts. No hard-coded
   three- or twenty-drawing count belongs in final assembly acceptance.
3. `embed_accepted_svg_figures.py` currently looks up the absent base attribute
   before inspecting the native SVG extension. Even if that lookup were fixed,
   its single-extension requirement rejects the valid DPI sibling. A recovery
   must address both assumptions together, not consume an assembly trial on
   only the first exception.
4. Any change must validate the original relationship type, internal target,
   exact payload, extension URI and cardinality before retargeting. An existing
   native SVG must not be verified against an already-mutated relationship.
   Shared-source/repeated-drawing relationships must remain consistent.
5. The helper's current reversal removes an entire newly added extension list.
   If recovery inserts an SVG extension into an existing non-SVG list, reversal
   must remove only that inserted node and retain the DPI sibling. If recovery
   adds a missing base attribute, that exact insertion must also be reversed
   by the integrity proof. Leaving the existing native-only main drawings
   unchanged would avoid both XML mutations but still requires native Word QA.
6. Relationship-based orphan cleanup, SVG content type, exact source bytes,
   unchanged unrelated package members, no new raster parts, exact drawing
   count/geometry/crops and internal bookmarks must remain explicit checks.
   XML validity and a successful helper do not establish native Word rendering.
7. Historical `run_stage.py` still points assembly to
   `word_table_manifest_sealed.json`; the accepted current table mapping is
   `s2_accessibility_guard_recovery_001/word_table_manifest_attempt5.json`.
   Any future single released invocation needs the latter exact mapping and
   the existing attempt2 raw DOCX. Do not rerun historical staging/capture or
   either consumed HTML/DOCX render to obtain different packaging.

## Disposition

The stop is independently confirmed as a packaging incompatibility, with no
changed scientific values or SVG bytes. Preserve all current outputs and keep
assembly/embedding and office QA at zero of two until a separate, sealed,
candidate-only recovery is released. No rsvg installation, raster substitution,
SVG edit, extra render, Brown execution or canonical promotion is proposed.

The already built paired HTMLs may receive the separately recorded bounded
visual review and then be shown to the user. Their eligibility does not depend
on fixing Word. Native Word acceptance remains pending author unlock.
