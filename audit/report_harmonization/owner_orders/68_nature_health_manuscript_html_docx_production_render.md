# REPORT-018 owner order 68: Nature Health manuscript HTML and DOCX production render

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_TARGETED_MANUSCRIPT_RENDER`

## Authority and serial disposition

The author explicitly requested integration of the approved final manuscript wording followed by a full manuscript webpage render and a DOCX render. The Writer has completed and frozen the source, validation, table-capture, and Word-layout inputs. Navigation Order 67a is independently accepted, and its shared-build write lease is closed.

This order releases one nested Nature Health manuscript render only. It does not authorize a root-profile render, a full-project render, a supplementary standalone render, or a write to `_build/nathealth`. The accepted 37-route analysis website and navigation shell remain protected.

The final process preflight identified three orphaned R startups in this project that had remained inside renv activation for hours without reaching their requested scripts. PIDs 28387, 55020, and 69217, together with the waiting shell PID 55019, were stopped. The stale manuscript loopback server PID 85000 on port 8765 was also stopped. A fresh elevated read-only inventory then found no R, Quarto, Pandoc, semantic, manuscript-server, or build-writer process in this project. One unrelated R process in the separate LightLogWeb workspace remains untouched.

## Exact frozen inputs

Require these identities immediately before execution:

- manuscript source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
  - SHA-256 `9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0`
  - 80,774 bytes
- nested project profile: `manuscript/R0_NatHealth/_quarto.yml`
  - SHA-256 `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
  - 435 bytes
- merged bibliography: `manuscript/R0_NatHealth/references_merged.bib`
  - SHA-256 `4972d8011fd9ccd2067e5e583a9bbc8846a825218ca7b4b574bcc6bd4bea1c06`
  - 51,953 bytes
- manuscript stylesheet: `manuscript/R0_NatHealth/manuscript_displays.css`
  - SHA-256 `5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98`
  - 4,397 bytes
- strict source validator: `tests/manuscript_nature_health/validate_current_revision.R`
  - SHA-256 `adf639878cca1bd1dff5886a50f839c39529732e3a75f4183011d3aadf65f354`
  - 23,841 bytes
- HTML table-capture implementation: `scripts/manuscript_nature_health/capture_word_tables.mjs`
  - SHA-256 `9a38f12b93bd03f3332de2f3c862bedbd035659bd762b386b98166800a04af07`
  - 14,753 bytes
- Word postprocessor: `scripts/manuscript_nature_health/prepare_word_manuscript.py`
  - SHA-256 `c3f72f0fbe76ffc5acfd6f50ad4d7c716998ba6955f7449d25a931cced0d58b3`
  - 23,125 bytes

The pre-render output baselines are:

- manuscript HTML: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - SHA-256 `498bc0ad5e9d08841f48411e290ae7ec8912a7af89c8fa8397c44d3f46864d99`
  - 30,528,489 bytes
- manuscript DOCX: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  - SHA-256 `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02`
  - 52,450 bytes

Protect throughout:

- `.Rprofile` at `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4`, 26 bytes;
- `renv.lock` at `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`, 603,493 bytes;
- `index.qmd` at `86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80`, 91,250 bytes;
- `_build/nathealth/index.html` at `600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184`, 405,444 bytes;
- the live 37-route corpus manifest at `5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b`, 11,479 bytes;
- Navigation Order 67a independent acceptance at `d0398d9872340a5245beccc8462daee155f7a709503834cd6a7d882dba018cc8`, 2,444 bytes; and
- its 20-member non-circular seal at `39119c296606e43faa6b771cc9dacdbe6a598593224727df734bd4480b8ed856`, 3,771 bytes.

## Preflight and evidence boundary

Before Quarto:

1. reproduce every dispatch-manifest member by exact path, SHA-256, and byte count;
2. create one new evidence root under `audit/manuscript_nature_health/final_production_render_2026_09_02/` without modifying any pre-existing manuscript evidence;
3. inventory the complete nested `_output` directory and all protected paths above;
4. retain recoverable byte-exact preimages of the two canonical output files outside the production output directory until acceptance;
5. run `Rscript --vanilla tests/manuscript_nature_health/validate_current_revision.R .` from the repository root and require the exact R 4.6.1 PASS contract: 150-word abstract, exactly 4,500 Introduction/Results/Discussion words, 114 bibliography entries, 91 resolved cited keys, 31 internal targets, and 519 protected ordered numeric tokens;
6. require Node syntax PASS using `/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node --check` on the capture script;
7. require Python compilation PASS using `/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m py_compile` on the Word postprocessor;
8. require `git diff --check` PASS for all seven frozen source and implementation files;
9. repeat a narrow elevated read-only process inventory and require no competing process whose command or working directory indicates this repository's R, Quarto, Pandoc, manuscript render, table capture, Word conversion, semantic hook, or loopback QA; leave unrelated work untouched; and
10. require no listener on the selected QA port and zero symbolic links below `manuscript/R0_NatHealth/_output` before serving anything.

Stop before Quarto on any mismatch. Do not edit a frozen source, test, script, profile, bibliography, or stylesheet to make the preflight pass.

## One targeted Quarto render

Use the nested project rooted at `manuscript/R0_NatHealth`. Invoke exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd
```

The nested profile has execution disabled and produces the self-contained HTML and raw DOCX formats for this manuscript source. Run the command with only the narrowly elevated filesystem access needed for Quarto's existing user-owned Sass cache at `/Users/zauner/Library/Caches/quarto/sass/sass.kv`. Its preflight identity is SHA-256 `22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`, 36,864 bytes, owner `zauner`. Quarto may perform normal transactional cache access. Do not reset, redirect, delete, copy, rename, chmod, or chown the cache, and do not change `HOME`, `XDG_CACHE_HOME`, or `DENO_DIR`.

If Quarto exits nonzero or either expected output is absent, preserve both output preimages or restore them as a pair, seal one stopped package, and do not retry.

## HTML acceptance and Word production

On render success:

1. preserve the raw Quarto DOCX in the new evidence root before postprocessing;
2. run the strict R 4.6.1 validator again without changing any source;
3. verify the HTML is self-contained, has exactly one document main element, unique IDs, complete title and author metadata, resolved citations and cross-references, all 19 accepted `gt` tables, all three main figures, all 17 supplementary figures, captions, alternate text, and no embedded error, warning, unresolved reference, local user path, or missing resource;
4. serve only `manuscript/R0_NatHealth/_output` on one unused high port bound to `127.0.0.1`, after the mandatory zero-symlink preflight;
5. inspect the exact manuscript HTML route at 1,440 by 1,000, 708 by 1,000, 390 by 844, and a 200-percent-equivalent view, including every main and supplementary table, every figure, wide-table scrolling, citations, internal links, and end matter;
6. reject page-level horizontal overflow, clipped or overlapping content, unreadable table text, missing rows or columns, missing figures or captions, broken internal navigation, or page-attributable console warning or error;
7. while that final HTML is served, use the frozen Node capture script once to generate faithful high-resolution PNG derivatives for all 19 accepted tables and the 17 supplementary figures into the task-owned evidence root;
8. require the capture manifest to contain the exact selector set, preserve all visible table text and order, and contain no missing selector or blank image;
9. run the frozen Python postprocessor once from the preserved raw Quarto DOCX and captured manifests to one candidate final DOCX outside the canonical output path;
10. require 27 bounded sections with 13 landscape table ranges, 52 drawings, zero remaining native `gt` tables, zero one-cell float-wrapper tables, all three main figures and 17 supplementary figures exactly once and in topic order, all substantive tables on landscape pages, figures in portrait sections, and captions kept with their displays; and
11. only after structural PASS, replace the canonical DOCX once with the exact candidate.

Render the final DOCX to page images with the approved document workflow. Inspect every page, expected to be 82 unless content-preserving pagination changes are fully explained. Reject any blank defect page, orphaned heading or caption, clipped or overlapping content, missing glyph, split display-caption pair, illegible table, unexpected portrait table, unexpected landscape prose section, duplicated or missing figure, or ordering defect. Retain a page-by-page QA ledger and bounded screenshots or contact sheets sufficient for independent review.

## Final stability and teardown

After QA:

1. close or reset the browser surface;
2. stop the loopback server and prove its listener absent;
3. delete no historical evidence and remove only disposable temporary candidates after their hashes and disposition are recorded;
4. rehash the seven frozen inputs, all protected navigation and website pins, both final outputs, raw DOCX evidence, capture manifests, and conversion implementation;
5. require the accepted 37-route `_build/nathealth` corpus and its manifest to remain byte-identical across the manuscript production run;
6. require no QMD, bibliography, test, script, stylesheet, profile, package, lockfile, analysis, scientific artifact, or shared website path to have changed; and
7. write one completion record and one unique, non-circular evidence manifest excluding itself.

Return exact SHA-256 hashes and byte counts for the final manuscript HTML, final DOCX, raw Quarto DOCX, table and figure capture manifests, structural checks, HTML visual QA, DOCX page QA, lifecycle record, completion record, and final evidence manifest.

## Prohibitions and mandatory stop

Do not edit any frozen source after dispatch. Do not execute R code from the QMD, rerun an analysis, recalculate a scientific result, rebuild a scientific table or figure, alter a claim or numeric token, render the root Nature Health website, render the supplementary standalone target, mutate `_build/nathealth`, update the 37-route corpus manifest, run a full project render, commit, push, upload, submit, or contact the journal.

Stop once on any genuinely new source, render, table, figure, citation, link, Word-layout, environment, or preservation defect. Do not patch or rerender inside this order. The mandatory next gate is independent acceptance of the paired final manuscript HTML and DOCX or independent disposition of the single fail-closed attempt.
