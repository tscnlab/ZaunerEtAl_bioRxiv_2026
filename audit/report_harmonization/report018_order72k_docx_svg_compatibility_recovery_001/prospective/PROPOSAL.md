# Temporary Word SVG compatibility proposal

Prepared 2026-09-11 22:08 UTC, 2026-09-12 local time. Status: proposal only.
No release, helper promotion, document assembly or visual acceptance.

## Exact proposed change

Frozen copied helper preimage, 9,614 bytes:
`23cf9ee0f46fc9b79962b76c19c6bc3af03d70af6fe580e0120294c2b5b726fe`.

Prospective helper postimage, 16,998 bytes:
`75432be9c10f042b9f46a0207c8fc898db274f483fd4065ab3a823bf6416c38b`.

The only proposed implementation target is the candidate copy of
`helpers/embed_accepted_svg_figures.py`. The live copy is unchanged. The
forward and reverse diffs, exact retained preimage and zero-fuzz reverse
receipt are provided. Applying the forward diff in reverse to a temporary
postimage copy reproduces the frozen preimage byte-for-byte with no offset
or fuzz. No accepted SVG, PNG, HTML, QMD, DOCX, assembly helper or runtime file
is proposed for modification.

The compatibility behavior is narrow:

- Inspect original relationship data and exact SVG bytes before any mutation.
- For an already valid native SVG drawing, preserve its `a:blip`, both standard
  extensions, all geometry/crops and all native/base relationships unchanged.
  Reuse the existing embedded member. The three current main figures therefore
  remain native-only with rId21/rId28/rId35. No fallback is manufactured.
- Preserve the existing base-only supplemental route. Accepted base SVGs are
  copied into the established `nh_...svg` names, their base relationships are
  retargeted once and their SVG extension is added. A pre-existing DPI sibling
  may remain; exact reversal removes only the added SVG node and removes the
  list only if the helper originally created it.
- Maintain shared-source S8 behavior and its two crop windows. Repeated use of
  one relationship is idempotent; conflicting retargets are rejected.
- Keep the orphan-removal block unchanged. Content-type validation rejects
  duplicates and conflicting SVG definitions before adding a missing default.
- Retain 22 exact SVG records and physical SVG parts, with 23 appearances plus
  29 table PNG drawings. Strengthen the final explicit 52/23/22 checks. There
  will be 19 new supplemental member names and three retained main SVG members,
  not 22 unnecessarily renamed members. Existing report fields remain, with an
  `existing_native_preserved` qualification for each SVG record.

The additional code is fail-closed validation of the new relationship forms
and small isolated functions needed to test them. It does not expand allowable
SVG exports, layouts or relationships. It rejects duplicate/malformed IDs,
unexpected namespaces/attributes/children/extensions, external or unresolved
targets, noncanonical paths, mismatched SVG payloads and unsupported fallback
forms. Base-only raster input is deliberately rejected because the frozen
supplement assembly path creates exact SVG parts. A pre-existing PNG/JPEG base
alongside an exact native SVG is validated and left untouched; this is not
raster generation or an assertion of renderer support.

## Test evidence and limits

All 139 isolated checks passed on their first runs: 116 relationship/OOXML
fixtures and 23 preservation-guard tests. The full `main()` functions were
excluded from the AST-loaded test environment. No full embedding/assembly
entry point was loaded or invoked, no DOCX package was saved, and no browser,
server, Word, office renderer or image exporter was used.

Coverage includes base-only, native-only and base-plus-SVG with/without DPI;
both standard extension orders; shared base/native references; S8-like shared
sources and crop siblings; duplicate, unexpected, malformed, missing, external,
unresolved and mismatched cases; exact add/reverse operations; content-type
conflicts; unchanged orphan cleanup and preservation of still-referenced
members; exact SVG bytes and unrelated parts; rejected native XML/relationship
mutations; and positive/negative final count gates. Actual rId21/rId28/rId35
drawings were inspected read-only and accepted by the new isolated predicate.
Their entire document XML, relationship XML and source DOCX hash remain exact.

These are isolated compatibility tests, not a successful full document build
or native Word rendering result. A future released assembly still requires
its complete 52-drawing, media-hash, bookmark, section, table and visual checks.

The R 4.6.1 preservation replay reproduced 1,290 rows: central828, owner444 and
independent18 seals, all canonical-unique within each manifest. The source
helper equals the temporary preimage. The frozen map remains 22 SVG sources,
23 appearances and 29 table PNG parts. R and package versions and exact
commands are recorded. This was infrastructure verification only; no
scientific estimate, data transformation or model was run.

## Complete downstream contract

`prepare_word_manuscript.py` remains unchanged, hash
`e89329f60bb477bf726fb1ccc0f3acecd107bab81d4541a1fca2633cf54415aa`.
Its existing main-figure move/resize path preserves the three native extension
lists and later supplies their `Main Figure 1/2/3` descriptions. Supplemental
`add_image_run()` creates exact SVG parts with base relationships and no
extensions. S7/S15 each insert independent A/B SVG drawings and one shared
caption. S8 uses one source in two approved crop windows. These paths are
unchanged and remain covered by the expanded map.

Assembly still requires three unique main figure floats and three unique
main table floats, 16 supplementary native tables, nineteen table keys and
the split-component figure keys. It preserves its existing typography and
author-block guards, portrait/landscape section sequence, A3 S2 section,
figure/caption placement, paragraph and footer rules, 22 precise bookmark
repairs and final 52-drawing assertion. The native-table miniplots disappear
only when their native table is replaced with the already accepted captures.
The nineteen editable table DOCX files remain a separate untouched deliverable.

No downstream inspected consumer requires main SVG members to be renamed
`nh_main_figure_...svg`; the authoritative report records the exact member used.
The `embedded_svgs` record count remains 22 and `drawing_appearances` remains
23. Retained old native members are referenced and not candidates for orphan
cleanup. Existing unrelated package members remain protected by the helper's
unchanged byte-equality check.

`future_commands_NOT_EXECUTED.json` records exact argument vectors, working
directory, current input pins and fresh destinations. It uses the already
rendered attempt2 DOCX and `word_table_manifest_attempt5.json`, SHA256
`54b6246876b0ec91ca125465d1b9fe847042e23137e45024ae067844176db18e`.
It does not invoke the stale historical runner or correction-manifest builder.
The source-helper hash in its input inventory is the current preimage; a
future release must separately pin the approved postimage at execution time.
The two command vectors would consume one released assembly/embedding trial
only after central approval, not one here. All output destinations are absent.

## Boundaries and handoff

Writer remained idle at cursor `77b03eaa-d0ba-4fa4-870a-a7fb1dc45167:20`.
Leases004/005 remain released. Assembly/embedding and office QA remain zero of
two. All correction HTML/DOCX render allowances are consumed and not reopened.
Native Word still requires author unlock and cannot be accepted from XML or an
alternate viewer. The rejected browser URL route remains stopped; no alternate
browser, local server or open-in-app workaround is proposed.

Approved Table3 and its order, all accepted assets, canonical outputs, scientific
inputs, the optional H11 exclusion and Brown/Figure S5 holds remain unchanged.
Review this sealed temporary proposal before any owner dispatch. To replay the
tests, copy the temporary source/test files into a fresh temporary directory;
their output guards intentionally prevent overwriting this evidence.
