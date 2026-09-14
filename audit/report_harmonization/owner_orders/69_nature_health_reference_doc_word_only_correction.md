# REPORT-018 owner order 69: Nature Health reference-DOCX Word-only correction

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_POSTPROCESSOR_REPAIR_AND_DOCX_ONLY_RENDER`

## Authority and serial boundary

The author reopened final production because the accepted Word manuscript did
not use the repository's actual Nature manuscript reference document. This
order authorizes one narrowly bounded correction of the nested DOCX format,
one exact correction of the Word postprocessor's final-section geometry, and
one DOCX-only render. It does not authorize an HTML render, a supplementary
render, a root-profile render, a hypothesis render, a scientific execution, or
any write below `_build/nathealth`.

The accepted manuscript source, accepted standalone HTML, accepted figure and
table contents, and accepted scientific identities remain frozen. The final
website integration is a separate later serial order and must not start until
this Word correction is independently accepted.

## Exact preimages and protected identities

Require these exact identities before any edit or render:

- repository reference document: `assets/reference.docx`
  - SHA-256 `8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f`
  - 60,429 bytes
- legacy Nature Medicine manuscript used only as a preservation reference:
  `manuscript/R0_NatMed/ZaunerEtAl2026_NatMed.docx`
  - SHA-256 `9cd2e1ffb1395337528db4e3151a8fbbb3ab4be8352852424bda06aca9527e35`
  - 10,063,517 bytes
- frozen Nature Health manuscript source:
  `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
  - SHA-256 `9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0`
  - 80,774 bytes
- nested profile preimage: `manuscript/R0_NatHealth/_quarto.yml`
  - SHA-256 `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
  - 435 bytes
- accepted canonical HTML:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - SHA-256 `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`
  - 30,881,505 bytes
- accepted canonical DOCX preimage:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  - SHA-256 `07ff074d4bd4124656063f69a2437b4c646a8240ad771ce94d30339f41d0604c`
  - 28,749,374 bytes
- accepted Word postprocessor preimage:
  `scripts/manuscript_nature_health/prepare_word_manuscript.py`
  - SHA-256 `0e6310467104be48993ca00f63d18e8e0b6d9ac7b59605ac18f749ee250a8d9c`
  - 25,939 bytes
- merged bibliography:
  `manuscript/R0_NatHealth/references_merged.bib`
  - SHA-256 `4972d8011fd9ccd2067e5e583a9bbc8846a825218ca7b4b574bcc6bd4bea1c06`
  - 51,953 bytes
- manuscript stylesheet:
  `manuscript/R0_NatHealth/manuscript_displays.css`
  - SHA-256 `5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98`
  - 4,397 bytes
- strict manuscript validator:
  `tests/manuscript_nature_health/validate_current_revision.R`
  - SHA-256 `adf639878cca1bd1dff5886a50f839c39529732e3a75f4183011d3aadf65f354`
  - 23,841 bytes
- accepted table-capture implementation, which must not be executed:
  `scripts/manuscript_nature_health/capture_word_tables.mjs`
  - SHA-256 `9a38f12b93bd03f3332de2f3c862bedbd035659bd762b386b98166800a04af07`
  - 14,753 bytes
- accepted table PNG manifest:
  `audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_table_png_manifest.json`
  - SHA-256 `8dcb34ea1692dc1091d7e16625be86bc45c65636ffeb6b863a99c7dacc914398`
  - 18,358 bytes
- accepted supplementary-figure PNG manifest:
  `audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture/word_figure_png_manifest.json`
  - SHA-256 `375970be6b8567a52ec1589b0f89971819c6d85b75591768970bc1d4198fb881`
  - 7,241 bytes
- prior final independent acceptance:
  `audit/report_harmonization/report018_nature_health_order68a_final_independent_acceptance.md`
  - SHA-256 `fcf9ba53f2b131e335472c077360bf979d3b8abc49c70ab954350d5977364096`
  - 3,750 bytes
- prior independent acceptance seal:
  `audit/report_harmonization/report018_nature_health_order68a_final_independent_acceptance_manifest.csv`
  - SHA-256 `530aefee66085b5a82b87a0a0b7c01b8f1522ac8294d7605980a6f55d2bc381e`
  - 4,629 bytes

Also require `.Rprofile`, `renv.lock`, the accepted 37-route build, and the
current corpus manifest to remain unchanged throughout this order.

## One exact postprocessor repair

Preflight established that the accepted postprocessor preimage cannot remain
unchanged while applying the A4 reference document. In
`scripts/manuscript_nature_health/prepare_word_manuscript.py`, the function
`set_final_portrait_section()` hardcodes US Letter dimensions and margins, and
the function is always called after the landscape wrappers are inserted. If
left unchanged, the raw reference-DOCX sections would use A4 but the final
portrait section would revert to US Letter.

Authorize exactly this two-site repair and no other postprocessor change:

1. change `set_final_portrait_section(document)` so it also receives the
   already captured `base_sect_pr`;
2. replace its hardcoded final `w:pgSz` and `w:pgMar` construction with exact
   deep copies of those two elements from `base_sect_pr`, require both elements
   to exist, normalize the copied page size to portrait orientation, and leave
   all other final-section properties and all other postprocessor logic
   unchanged; and
3. change the sole call to
   `set_final_portrait_section(document, base_sect_pr)`.

Do not change the established landscape table margins, image sizes, display
ordering, S8 crop, structural assertions, or any other function. Require an
exact focused diff and reverse proof from the repaired postimage to the
25,939-byte preimage at SHA-256 `0e631046...`.

Before the DOCX render, run a prospective temporary-only unit/OOXML test using
the exact `assets/reference.docx`. It must prove:

- the captured base portrait `w:pgSz` is exactly 11,901 by 16,840 twips;
- its portrait `w:pgMar` values are copied exactly into the final portrait
  section after postprocessing;
- every intended landscape wrapper uses exactly the swapped A4 page size,
  16,840 by 11,901 twips, with landscape orientation and the unchanged accepted
  landscape-margin logic; and
- no generated section uses the former 12,240 by 15,840 US Letter geometry.

Format and compile-check the repaired script, record its postimage SHA-256 and
byte count before execution, and stop if the prospective test or exact reverse
proof fails.

## One exact profile edit

Create a recoverable byte-exact preimage of the nested profile. In
`manuscript/R0_NatHealth/_quarto.yml`, change only the `format: docx:` block
from:

```yaml
  docx:
    toc: false
    number-sections: false
```

to:

```yaml
  docx:
    toc: false
    number-sections: false
    reference-doc: ../../assets/reference.docx
```

The relative path is resolved from the nested project directory and must point
to the exact 60,429-byte repository reference DOCX above. Do not copy or alter
the reference document. Require YAML parse, exact one-hunk reverse proof, and
confirmation that the HTML format block is byte-identical.

## Preflight

Before rendering:

1. Reproduce every dispatch-manifest member by exact path, SHA-256, and byte
   count.
2. Preserve recoverable byte-exact preimages of the nested profile and canonical
   DOCX in a new task-owned evidence directory.
3. Run the frozen R 4.6.1 manuscript validator and require its exact PASS
   contract without changing the manuscript source.
4. Reproduce the postprocessor preimage, apply only the authorized repair,
   require its prospective geometry test and reverse proof to pass, and
   compile-check the repaired postimage with the bundled document runtime.
5. Verify that every file referenced by the two accepted PNG manifests exists,
   matches its recorded identity, and decodes as a nonblank image. Do not
   recapture any table or figure.
6. Verify the reference DOCX as a valid OOXML archive with the expected styles,
   numbering, section, header, and footer parts needed by Pandoc.
7. Require no competing R, Quarto, Pandoc, Word postprocessing, or shared-build
   process in this repository. Leave unrelated processes outside this project
   untouched.
8. Inventory the accepted 37-route `_build/nathealth` tree and require zero
   changes and zero symlinks before execution.

Stop before rendering on any mismatch.

## One DOCX-only render

From the nested project rooted at `manuscript/R0_NatHealth`, run exactly one
DOCX-only render of the frozen manuscript target. Use the installed Quarto CLI
and disable renv autoloading as in Order 68. The command must explicitly select
the DOCX format, for example:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to docx
```

Require that the accepted HTML remains byte-identical before and after this
command. Preserve the raw reference-DOCX-based Quarto output in the evidence
directory before postprocessing. If the command fails or touches the HTML or
shared website, restore the canonical DOCX and profile preimages as a pair,
seal one stopped package, and do not retry.

## One accepted Word postprocessing pass

Run the sealed repaired postprocessor postimage exactly once against the
preserved raw DOCX and the already accepted table and figure PNG manifests.
Do not recapture or regenerate displays. Preserve the accepted display order,
the 32 table parts, 17 supplementary figures, landscape treatment where needed,
and the accepted two-page Supplementary Figure S8 treatment. Write first to a
candidate DOCX outside the canonical output path. Replace the canonical DOCX
once only after structural verification passes.

## Required Word verification

Verify the candidate and promoted DOCX structurally and visually:

- confirm that styles, numbering, page dimensions, margins, headers, footers,
  title-page behaviour, typography, and caption treatment derive from the exact
  `assets/reference.docx` postimage;
- confirm the complete author list, abstract, 4,500-word main text, references,
  declarations, figure legends, and supplementary sequence remain present;
- require all 19 accepted tables and all 20 figures in exact topic order;
- require every table and figure image to carry alternative text;
- require zero native `gt` conversion remnants and zero one-cell float wrappers;
- render the final DOCX to page images with the approved document workflow and
  inspect every page at full resolution;
- reject blank pages, clipped or overlapping content, missing glyphs, broken
  references, orphaned headings or captions, split display-caption pairs,
  unreadable tables, unintended portrait wide tables, unintended landscape
  prose pages, or altered S8 cropping; and
- explain any page-count change caused by the reference document or preserved
  display layout rather than treating 83 pages as an invariant.

## Final stability and return

After QA, prove that the manuscript QMD, accepted HTML, bibliography, stylesheet,
validators, capture implementation, reference DOCX, legacy V0 DOCX, scientific
artifacts, `_build/nathealth`, and corpus manifest remained unchanged. The only
permitted live source changes are the one-line nested-profile addition and the
exact postprocessor repair. The only permitted canonical output change is the
DOCX.

Return:

1. the nested-profile postimage SHA-256 and byte count;
2. the repaired postprocessor SHA-256, byte count, prospective geometry test,
   focused diff, and exact reverse proof;
3. the final canonical DOCX SHA-256 and byte count;
4. the preserved raw Quarto DOCX identity;
5. reference-DOCX structural comparison evidence;
6. final DOCX structural checks;
7. complete page-by-page QA evidence and page count;
8. protected-path and shared-build stability checks;
9. one completion record and one unique, non-circular evidence manifest; and
10. complete teardown evidence.

## Prohibitions and mandatory stop

Do not edit the manuscript QMD, bibliography, stylesheet, tables, figures,
captions, claims, numeric tokens, validators, capture script,
reference DOCX, V0 DOCX, package state, lockfile, website source, or any file
below `_build/nathealth`. Do not render HTML, the supplementary standalone
document, a hypothesis page, the root website, or the full project. Do not
recompute science, recapture displays, commit, push, upload, submit, or contact
the journal. Do not alter the postprocessor beyond the exact two-site repair
specified above.

Stop once on any genuinely new source, reference-DOCX, render, postprocessing,
structure, layout, environment, process, preservation, or teardown defect. Do
not patch or retry inside this order. The mandatory next gate is independent
acceptance of the corrected Word manuscript before Order 70 website integration
may be dispatched.
