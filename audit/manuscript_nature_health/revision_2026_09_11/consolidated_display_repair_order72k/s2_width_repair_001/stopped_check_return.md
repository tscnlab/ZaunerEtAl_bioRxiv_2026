# S2 width repair: consolidated stopped return

Date: 2026-09-11. Status: **STOPPED_CAPTURE_CHECK**.
Return gate: `REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW`.
Owner: Writer `019ffb39-372e-7262-bfac-192751fd0e63`.

## Outcome and stopping boundary

The one expressly released S2 capture, attempt4, exited with code 1 before
writing its first PNG. The expanded all-cell text-rectangle guard flagged
seven unchanged distribution accessibility descriptions. The capture
destination contains only `supp_table_s2_source.html`, with SHA-256
`c4307361ddc23ba260512786b77c5924f305b13c8eec0d368dc3555aee6ae779`.
No part HTML, PNG or completed capture manifest was produced. No further
capture, guard edit, width adjustment or alternate browser route was attempted.

Source-markup checks in R 4.6.1 show that the seven flags exactly match the
first seven of 17 preserved span descriptions in the immutable rendered main
table and original fragment. All have the following source style:

```css
position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0
```

These are intentionally visually hidden descriptions. The guard compares
text-range geometry without accounting for that explicit clipping. The
source-based classification is therefore an accessibility-only guard false
positive, not a finding that the distribution column needs more width or
that these descriptions should be exposed. Harmonizer independently reached
the same conclusion; its four evidence files are pinned in
`independent_diagnosis_pins.csv`. The diagnosis note identity is
`3a6a6cf660a638ce14709c29e4afa54c8260336bf5192f8a7f07652372391657`.

This classification is not visual acceptance. No Unit or Scaling string
appears in the first-part failure list, but the revised widths have not been
inspected in completed images at original or intended Word size. The failed
guard is not waived. Correction rendering and assembly remain stopped.

## Exact authorized changes and preservation

The controlling repair order is
`audit/report_harmonization/owner_orders/72k_s2_unit_scaling_width_repair.md`,
SHA-256 `982dc5b6213ca813c0883455197140025d367388a7956b19747af61763b13d3f`.
Exactly its three live candidate transitions were applied and remain exact:

- Capture helper postimage:
  `7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a`.
- Both candidate CSS postimages:
  `03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9`.

Their exact preimages were saved before editing. Deterministic inverse
changes reproduce all three preimages byte-for-byte. Node syntax validation
passed before capture. Unit and Scaling widths are 80 and 100 CSS pixels,
respectively, and total width is 1,490 pixels; all other released settings
are unchanged. No additional implementation edit was made after failure.

The final read-only verification reproduces all 2,309 historical pin rows.
Only the three authorized live paths resolve to their retained exact
preimages for historical reconciliation. No fourth path is excepted, and no
historical manifest was edited. All other pinned members remain unchanged.
The current owner manifest separately records the three live postimages.

The immutable 12 served/source pairs, 19 initial capture files and all eight
attempt3 files remain exact. The partial attempt4 source preserves all 244
body-cell strings character-for-character against the immutable rendered
source and preceding source extraction. Comparison with the original HTML
fragment differs only in HTML whitespace. All 17 source image payloads are
exact. These are protected-content checks, not scientific recalculation or
completed-capture visual checks.

## Execution, teardown and lease release

The exact capture and server commands, actually granted narrow execution
permissions, exit code and full error are recorded in `execution_receipt.json`
and `capture_attempt4.log`. No broad permission prefix was requested.

The verified preview process was PID 40429, serving only the unchanged
12-file preview root on `127.0.0.1:58005`. It was stopped with SIGINT and
recorded closure at **2026-09-11T20:28:53Z**. Subsequent listener and exact-PID
checks returned no match. A task-specific temporary-profile process check
also returned no match. The capture helper awaits browser closure in its
`finally` block; no closure error was reported. A browser PID was not exposed
and is not invented here. See `teardown_receipt.json`.

No native document or CUA surface was opened in this recovery. Native Word
QA was not performed; author unlock confirmation remains outstanding. No
automatic unlock or substitute viewer was used. **Writer explicitly releases
`ORDER72K-VISUAL-LEASE-003` with this stopped return.** No task preview or
capture surface remains reserved.

## Remaining work and allowances

The additional S2 capture allowance is exhausted. The existing consolidated
selection HTML, main HTML and main DOCX correction allowances remain unused,
one each. Word assembly/SVG embedding remains 0 of 2, and office QA remains
0 of 2. The four previously accepted S5/S6/S10 PNG parts are preserved without
recapture. No final candidate Word document or integrated corrected HTML was
produced by this recovery. See `trial_update.csv`.

Standalone editable Word-table exports are a separate requested deliverable
and were neither changed nor replaced by this PNG-fallback repair. Table 3,
canonical manuscript sources, accepted scientific displays and prior failure
records remain protected. Brown execution and Figure S5 replacement, optional
H11 work, scientific prose changes and canonical promotion remain held.

A prospective guard-only release may account narrowly for the exact
source-proven hidden spans while retaining checks for visible text in every
cell. This return does not authorize that edit or a new attempt. Writer
remains stopped pending separate coordinator and dispatcher disposition.

## Reproducible record

`verify_stopped.R` performed file, structure, text and payload checks with
R 4.6.1, openssl 2.4.2, xml2 1.6.0 and jsonlite 2.0.0. Inputs, outputs and
the exact command are documented in `stopped_verification_session.txt` and
the companion CSV records. No research dataset was imported, no model was
evaluated and no estimate was calculated. `stopped_check_owner_manifest.csv`
and `stopped_check_owner_seal.json` provide the non-circular owner snapshot;
the manifest excludes only itself and its companion seal.
