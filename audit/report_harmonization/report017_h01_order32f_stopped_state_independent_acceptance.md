# REPORT-017 H01 order 32f stopped-state independent acceptance

Date: 2026-08-15

## Independent disposition

The order 32f stop is accepted as correct and fail-closed. The single fresh-candidate run stopped before any durable figure replacement, builder edit, test edit, manifest reseal, Quarto render, or browser QA. The new defect is limited to the display-validation harness. It is not a scientific, source-data, figure-content, report-source, or rendered-page defect.

The owner record is `audit/hypotheses/H01/report017_order32f_continuation/order32f_stopped_state.md`, SHA-256 `9a050f6603b3d33452813193cd22deb56ca5f991cf3d86a42cc25d3b305dbdcd`. Its non-circular 11-row manifest is SHA-256 `872a129792bf677c805aaee51b131e49d614fcc9c86e682d0c9c661925efa7a7`; an independent R 4.6.1 audit reproduced all 11 paths, hashes, and byte counts.

## Accepted completed work

- The 37-row order 32f dispatch and nested 41-row order 32e stopped-state seal were exact before mutation.
- The three authorized order 32f harness corrections were applied to the temporary display-refresh implementation.
- Air 0.4.1 formatting, R 4.6.1 parsing, and the pre/post Air abstract-syntax comparison passed.
- The required non-mutating preflight passed synthetic path mapping 4/4, all 30 paired-label widths, zero label collisions, the exact Figure 1 historical-to-source baseline transition, and exact Figures 5 and 6 baselines.
- The fresh candidate run executed once and stopped nonzero. No retry followed.

## Confirmed defect

At current refresh-script lines 778 through 792, the geometry validator iterates with a closure scalar named `figure_id`, then evaluates `filter(.data$figure_id == figure_id)`. Tidy data-mask lookup resolves both sides to the `baseline_specs$figure_id` column, retains all three specification rows, and passes a three-value expected-width vector into a one-row `mutate()`. The resulting error is `expected_width must be size 1, not 3`.

The smallest safe correction is to use a distinct closure scalar such as `current_figure_id`, bind exactly one `current_spec` row outside the later `mutate()`, fail unless `nrow(current_spec) == 1L`, and use scalar `current_spec$png_width[[1]]` and `current_spec$png_height[[1]]`. No other display or scientific logic needs to change.

## Full remaining-path audit

To avoid another narrow retry, the complete code path after the failing geometry block was inspected and replayed read-only against the retained candidate files. Under R 4.6.1:

- all three candidate PNG dimensions and 320 dpi metadata pass;
- the six current candidate files are byte-identical to the prior order 32e candidates;
- all three candidate SVG node structures and visible-text multisets match their source-derived baselines;
- all 30 paired labels occur exactly once and have valid terminal-`px` widths;
- the corrected label-box calculation finds zero collisions;
- the final 708-pixel minimum text sizes are 7.13333 pt for Figure 1 and 7.09457 pt for Figure 6;
- the remaining typography, source-evidence, parameter, session, and attempt-summary blocks contain no further closure/data-mask collision of this class.

This replay was read-only. It did not promote a candidate, write a project artifact, or replace the required fresh end-to-end validation.

## Preservation

The following current identities were independently reproduced after the stop:

- result QMD `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- companion QMD `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- stopped result HTML `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`;
- frozen companion HTML `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
- builder `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`;
- profile `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- all six durable Figure 1, 5, and 6 PNG/SVG targets at their accepted pre-candidate identities.

The current refresh implementation is `10288d5fb28df713c43f52a5f3e984070d8062701a28a3e6eb4fe8d9d8b223aa`, 28,717 bytes. The prior order 32e candidate directory remains 12/12 exact, the order 32d quarantine remains 3/3 exact, and the new partial order 32f candidate directory remains retained at `/private/tmp/H01-order32f-candidates.eDOsrp`.

No model, inference, prediction, bootstrap, resampling, Shapley calculation, scientific artifact regeneration, Quarto render, browser QA, commit, push, or upload occurred.

## Queue state

H01 remains stopped before durable display replacement and before its one authorized rerender. The H01 companion and every later REPORT-017 render remain held. Any continuation must preserve all three retained temporary directories, make the single geometry-validator classification repair, use a new fresh candidate directory, and retain the one-combined-stop protocol.
