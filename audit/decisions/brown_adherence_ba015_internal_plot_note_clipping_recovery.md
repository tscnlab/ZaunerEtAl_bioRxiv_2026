# Brown adherence BA-015 internal plot-note clipping recovery

Recovery ID: `BA-015-DISPLAY-001`
Related decision: `BA-015`
Related change: `CHG-154`
Date: 2026-08-20
Status: bounded display recovery and one replacement render authorized

## Disposition

The single authorized `BA-015` targeted render completed successfully and its
complete R 4.6.1 post-render verifier passed 28 of 28 checks. Native served-page
inspection at 1280 by 720 then found one display defect: the final line of the
plot-internal note in `fig-main-site-free-work-contrasts` extends past the
right edge of the raster. The full Quarto Figure 3 caption is present and wraps
normally. Every estimate, interval, significance marker, equal-site reference,
paired-source row, and reader claim is unaffected.

This is a bounded display-layout defect, not a scientific, source-data,
inferential, accessibility-text, or Quarto-source defect. The failed visual
record is accepted as a truthful fail-closed stop. `BA-015-DISPLAY-001`
authorizes one plot-note layout repair, one candidate rebuild and verification,
one replacement target render, and repeated bounded visual QA.

The recovery does not create a new multiplicity family or alter `BA-M6`.
`BA-015` and `CHG-154` remain the controlling scientific and change-ledger
entries. No ledger append is required for this recovery.

Stage 3 remains unaccepted at `BA-CS-G3-INTEGRATED-REVIEW`. Stage 4 and writer
notification remain blocked.

## Independently verified stopped state

The central R 4.6.1 audit verifies:

- the complete non-circular 48-member Stage 2 `BA-M6` manifest;
- all 18 derivation checks and all 31 independent verification checks;
- exactly 27 primary and 27 at-least-80-percent contrasts;
- exactly three primary 27-family FDR localizations: Wake in Dortmund at
  +15.000 percentage points with adjusted p = 0.003920, Wake in Madrid at
  -9.205 percentage points with adjusted p = 0.042309, and Sleep in Kumasi at
  +6.257 percentage points with adjusted p = 0.000389;
- retention of all three directions in the at-least-80-percent sensitivity;
- the exact 27-row paired display source, five accepted `BA-M4` diamonds, and
  three accepted `BA-M6` asterisks;
- all 17 independent display checks, 26 QMD-source checks, and 28 render checks;
- QMD SHA-256
  `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997`;
- first-render HTML SHA-256
  `05e5ef35a96f43675b0fd5586ccd693df1fe34e27baf41ee1fc63ee1801bd75c`;
- paired-source SHA-256
  `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc`;
- pre-recovery PNG SHA-256
  `b1ccad899fbaec5e55bfc829f422bcab06a3ad8b7e0b5e6bd9cba5b26cd458c9`;
- pre-recovery SVG SHA-256
  `d842bf0bca4b977340336210992872b1da1385e7de800823e8f5e3e454513959`;
- the exact sole failed visual item
  `BA_M6_internal_caption`, with the reader-facing caption passing; and
- complete loopback teardown, no listener on `127.0.0.1:60600`, and removal of
  the temporary served copy.

Direct inspection of the intended-size PNG confirms that the second internal
note line is clipped after the final word begins. The defect is reproducible
from the current builder caption string. No other visual defect was assessed
after the fail-closed stop.

## Frozen scientific and reader inputs

The following must remain byte-identical throughout recovery:

1. every member of
   `stage2_boundary/site_free_work_vs_equal_site_amendment/stage2_ba_m6_final_manifest.csv`;
2. `ba_m6_primary_site_free_work_vs_equal_site.csv`,
   `ba_m6_support80_site_free_work_vs_equal_site.csv`, and
   `ba_m6_support_gate.csv`;
3. the 27-row paired source
   `source_data/main_site_free_work_forest_with_ba_m6_source.csv`;
4. `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
5. every earlier `BA-003` through `BA-014` decision, artifact, manifest,
   author gate, and handoff;
6. `renv.lock`, package versions, models, frozen estimands, covariance,
   samples, multiplicity results, and all other scientific artifacts; and
7. the complete `BA-015` derivation, verification, first-render, and failed-QA
   evidence as historical records.

The first-render HTML is historical stopped evidence. It may be replaced only
by the one authorized replacement render after every candidate gate passes.

## Exact source repair

The only existing source file that may change is:

`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R`

Change only the final internal `plot.caption` layout. The preferred exact
repair preserves all words and places the final qualification on its own line:

```text
All estimates come from one pooled interaction model.
Sites are not independent replications or causal effects.
```

The semicolon separating those clauses may become a period as shown. No other
builder token, parameter, package, data mapping, layer, scale, marker, color,
label, size, dimension, DPI, axis, panel, legend, subtitle, or scientific
string may change. Exact reverse substitution must reconstruct builder
SHA-256
`2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def`.

The QMD caption and alt text must remain unchanged. Removing the qualification
from the full Quarto caption is prohibited. If the preferred three-line
internal note still clips in a temporary candidate, the redundant final
internal qualification may instead be omitted only from the raster, because
the identical qualification remains in the full Quarto caption. That fallback
must be documented before canonical replacement and may not trigger another
render attempt.

## Authorized recovery evidence root

Create only this new recovery root:

`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/`

It may contain:

- an exact pre-recovery copy of the builder and a non-circular pre-recovery
  manifest;
- one versioned recovery verifier;
- one fresh temporary-candidate inventory and candidate comparison records;
- pixel-difference and normalized-SVG comparison records;
- package, command, runtime, and session records;
- replacement-render verification records;
- native and deterministic responsive QA records and screenshots;
- loopback lifecycle and teardown evidence;
- one recovery handoff and renewed author gate; and
- one non-circular final recovery manifest.

Do not overwrite, delete, or reinterpret the failed-QA handoff, first-render
execution record, first-render HTML identity records, or any earlier sealed
manifest. The pre-recovery builder copy must reproduce the exact historical
builder hash above.

## Candidate and canonical display sequence

Use this exact sequence:

1. Rehash the central recovery authority and all stopped-state pins.
2. Create the recovery root and seal the pre-recovery builder and stopped
   display identities before editing.
3. Apply the one caption-layout edit and prove exact reverse substitution.
4. Parse and Air-check the builder without executing its body.
5. Run the repaired builder once with a fresh temporary candidate output root,
   using only the frozen Stage 2 and historical display inputs.
6. Require the candidate paired source to reproduce SHA-256
   `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc`
   exactly.
7. Verify all 27 points and intervals, five `BA-M4` diamonds, three `BA-M6`
   asterisks, three equal-site reference lines, state and site ordering,
   legends, axis limits, dimensions of 2640 by 3360 pixels, and 320 DPI.
8. Require all numerical and categorical columns in the paired source and all
   data-bearing SVG geometry to remain unchanged. PNG differences must be
   confined to the internal note band. Normalized SVG differences must be
   confined to the internal note text and its line placement.
9. Inspect the intended-size candidate and require the complete internal note
   to be visible with no clipping, overlap, or text below the accepted floor.
10. Only after every candidate check passes, replace the canonical PNG and SVG
    once. Do not rewrite the paired source.
11. Seal the new builder and display identities in recovery-specific evidence.

Any candidate failure stops the recovery without changing the canonical PNG,
SVG, HTML, or QMD. Do not create a second candidate after a failed canonical
replacement or after rendering.

## One replacement render

After every candidate, preservation, source, privacy, and display check passes,
execute exactly once from the continuing Brown worktree:

```text
RENV_PATHS_LIBRARY='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library' \
BROWN_ADHERENCE_PROJECT_ROOT='/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026' \
BROWN_ADHERENCE_AUTHOR_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile, and the existing
author-owned `renv` library from the outset. This recovery render is the one
explicitly authorized replacement after the accepted fail-closed visual stop.
No preliminary restricted-cache attempt, second recovery render, package
installation, or lockfile change is authorized.

The QMD must remain at its exact pre-recovery identity. The replacement HTML
must acquire exactly one new identity and must not be accepted until all
post-render checks and visual QA pass.

## Mandatory post-render and QA checks

Repeat every applicable source and render contract, including at minimum:

- all 17 prior independent display checks, 26 QMD-source checks, and 28
  post-render checks;
- exact 48-member Stage 2 preservation;
- exact 27-row paired-source preservation and all three `BA-M6` localization
  and sensitivity qualifications;
- all 16 native tables, all five accessible figures, captions, alt text,
  source links, cross-references, privacy checks, no-error checks, and complete
  reader-section order;
- exact intended-size PNG and SVG parity with the verified candidate;
- no clipping, overlap, cutoff, or missing plot-note text;
- native served-page inspection at the available 1280 by 720 viewport;
- intended-size inspection of the repaired PNG;
- deterministic responsive structural checks at 390-pixel width under the
  accepted `BA-013` method;
- full-page inspection resumed beyond Figure 3 through the final page section;
  and
- loopback binding only to `127.0.0.1`, successful teardown, no remaining
  listener, temporary-copy removal, and post-QA identity stability.

Do not claim a mobile screenshot or use an iframe, CDP, alternate browser
surface, or policy workaround.

## Prohibitions and stop conditions

This recovery does not authorize:

- a model fit or refit, prediction, new contrast, p-value, interval, FDR
  calculation, resampling, bootstrap, simulation, sample change, or participant
  data access;
- any edit to the QMD, paired source, Quarto caption, alt text, model, Stage 2
  output, prior manifest, ledger, lockfile, or earlier seal;
- a change to any point, interval, significance marker, reference line, axis,
  panel, site/state order, legend meaning, dimensions, or DPI;
- a second replacement render, full-project render, Stage 4 work, writer
  notification, commit, push, or upload; or
- acceptance of a partially inspected page.

Stop and seal one combined state if a frozen identity changes, reverse proof
fails, any candidate difference escapes the internal note band, any source or
render check fails, the replacement render does not complete, another visual
defect appears, or full-page QA cannot be completed.

## Mandatory author stop

If the recovery succeeds, seal the current QMD, replacement HTML, repaired
builder, repaired PNG/SVG, unchanged paired source, all `BA-M6` outputs,
recovery checks, QA, teardown, and non-circular manifest. Return to
`BA-CS-G3-INTEGRATED-REVIEW`.

The author must review the replacement page and provide the established exact
wording:

> Approve Brown cross-state integrated Stage 3 as written.

Only a later central decision may accept Stage 3, authorize Stage 4, and
release writer notification to task
`019ffb39-372e-7262-bfac-192751fd0e63`.
