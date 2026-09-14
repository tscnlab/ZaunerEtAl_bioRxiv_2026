# Brown adherence BA-015 two-line fallback candidate recovery

Recovery ID: `BA-015-DISPLAY-002`
Parent recovery: `BA-015-DISPLAY-001`
Related decision: `BA-015`
Related change: `CHG-154`
Date: 2026-08-20
Status: first candidate accepted as stopped; one fallback candidate authorized

## Disposition

The preferred three-line internal-note candidate under
`BA-015-DISPLAY-001` is accepted as a correct fail-closed candidate stop. It
preserves the paired source and every scientific element, but it does not meet
the display-preservation contract because adding a third caption line changes
the ggplot caption grob height and shifts the full panel geometry.

No canonical PNG, SVG, QMD, or HTML was replaced. No render followed. The one
replacement-render authority in `BA-015-DISPLAY-001` therefore remains unused.

`BA-015-DISPLAY-002` authorizes one fresh two-line fallback candidate. It must
retain the original two-line caption height and omit only the redundant raster
clause `Sites are not independent replications or causal effects.` The full
Quarto Figure 3 caption remains byte-identical and continues to state that the
site estimates are components of one pooled model, not independent site
replications or causal effects of location.

This extension authorizes no new inference and does not alter `BA-015`,
`CHG-154`, any ledger row, or the mandatory author gate. Stage 4 and writer
notification remain blocked.

## Independently verified first-candidate stop

The central R 4.6.1 audit verifies:

- all 22 pre-recovery checks and all 17 source-repair checks pass;
- the preferred live builder has SHA-256
  `8eb479b44192c814031f2b8d5f6eebf31b00c0a3787815d138f6ca60c7615977`;
- exact reverse substitution reconstructs historical builder SHA-256
  `2401bee54437867c19a47c6a24151ea825c311f4bc9534e51182ad208d039def`;
- the candidate paired source is byte-identical at SHA-256
  `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc`;
- the preferred candidate PNG has SHA-256
  `69264628c8c7627cda86cef408afa0e1c3ebbbb5cfe2ddef04d45a5b8629880a`;
- the preferred candidate SVG has SHA-256
  `cc950631b37d142ea7f300815ac981258c0442cac603d6230403f70874a2829c`;
- all 15 candidate build checks, all 27 rows, all points and intervals, five
  `BA-M4` diamonds, three `BA-M6` asterisks, three sensitivity directions,
  2640 by 3360 dimensions, and historical approximately 300 DPI pass;
- exactly two of the 25 candidate checks fail:
  `pixel_differences_confined_to_internal_note_band` and
  `normalized_non_note_SVG_exact`;
- the 809,522 changed pixels span rows 343 through 3317 and columns 66 through
  2640, which confirms a full-layout shift rather than a note-only change;
- the canonical PNG, SVG, QMD, and first-render HTML remain at their exact
  stopped-state identities; and
- the candidate run reports zero model fits, predictions, inference, and
  resampling.

Direct inspection confirms that the preferred candidate note is complete and
legible. The rejected candidate is not scientifically wrong. It is rejected
only because the added caption line reflows the plot layout beyond the
authorized note band.

## Exact fallback source edit

Starting from the current preferred builder, change only this caption fragment:

```text
"All estimates come from one pooled interaction model.\n",
"Sites are not independent replications or causal effects."
```

to this one-line source fragment:

```text
"All estimates come from one pooled interaction model."
```

Together with the existing newline after the equal-site explanation, the
raster retains exactly two internal note lines:

```text
Dotted black line: no difference. Long-dashed blue line: state-specific equal-site estimate.
All estimates come from one pooled interaction model.
```

No other builder line or token may change. Require both reverse proofs:

1. restoring the omitted third line and terminal newline reconstructs the
   preferred-builder SHA-256 `8eb479b4...`; and
2. restoring the original semicolon-wrapped two-line form reconstructs the
   historical-builder SHA-256 `2401bee5...`.

Parse and Air-check the fallback builder before executing it. The QMD, its full
caption and alt text, and the paired source remain unchanged.

## New evidence boundary

Create only this new subdirectory inside the existing recovery root:

`plot_note_clipping_recovery/fallback_candidate_recovery/`

It may contain:

- a frozen inventory of the first candidate stop;
- one fallback-candidate verifier;
- one fresh candidate inventory;
- PNG pixel and normalized-SVG comparison records;
- source, package, command, runtime, and session records;
- candidate intended-size inspection evidence;
- canonical replacement and post-replacement identity checks;
- replacement-render and complete QA records;
- loopback lifecycle and teardown evidence;
- one recovery handoff and renewed author gate; and
- one non-circular final manifest.

Do not alter the existing `candidate_*`, `source_repair_*`, pre-recovery, or
failed-QA records. The first temporary candidate may remain in place as
read-only evidence. If the environment later removes it, do not reconstruct
it; the durable inventory and comparison records remain the historical stop.

## One fresh fallback candidate

After the source and preservation gates pass:

1. create one new temporary directory distinct from
   `/private/tmp/brown-ba015-candidate.3SU5jw`;
2. run the fallback builder exactly once against that new candidate root;
3. require the paired source to reproduce SHA-256 `4c2d1828...` exactly;
4. require all 27 points and intervals, five `BA-M4` diamonds, three `BA-M6`
   asterisks, equal-site and zero references, labels, axes, panels, site/state
   ordering, colors, symbols, dimensions, and DPI to remain exact;
5. compare the fallback candidate directly with the historical canonical PNG
   and SVG, not with the rejected three-line candidate;
6. require every PNG pixel outside the union of the old and new second
   internal-note text bounds to be identical;
7. require all normalized non-caption SVG content and geometry to be exact;
8. require the first internal note line to be exact and the second to contain
   only `All estimates come from one pooled interaction model.`;
9. require the omitted clause to remain present in the unchanged full Quarto
   caption; and
10. inspect the intended-size candidate and require complete text, no clipping,
    no overlap, and no change to panel geometry.

The candidate must stop without canonical replacement on any failure. No
third candidate is authorized.

## Canonical replacement and render

If every fallback-candidate gate passes, replace the canonical PNG and SVG
once. Do not rewrite the paired source or QMD. Seal the old and new identities
and exact note-band containment before rendering.

Then continue the still-unused replacement-render authority from
`BA-015-DISPLAY-001`. Execute the same exact target command once with R 4.6.1,
Quarto 1.9.37, the normal project profile, and the established existing
author-owned `renv` library. No preliminary restricted-cache attempt and no
second replacement render are authorized.

Repeat all prior display, source, render, scientific-preservation, privacy,
link, caption, alt-text, table, figure, no-error, responsive, and teardown
checks. Repeat native served-page QA at 1280 by 720, intended-size PNG
inspection, deterministic 390-pixel structural verification, and full-page
inspection through the final section. The internal raster note and full Quarto
caption must both be inspected explicitly.

## Unchanged prohibitions and stop gate

No model fit or refit, live prediction, contrast, p-value, interval, FDR
calculation, resampling, bootstrap, simulation, sample change, participant
data access, QMD edit, paired-source edit, prior-seal edit, ledger change,
lockfile change, package installation, full-project render, Stage 4 work,
writer notification, commit, push, or upload is authorized.

Any new failure returns one combined sealed state. If the fallback succeeds,
return to `BA-CS-G3-INTEGRATED-REVIEW` with the exact mandatory author wording:

> Approve Brown cross-state integrated Stage 3 as written.

Only a later central decision may accept Stage 3, authorize Stage 4, and
release writer notification.
