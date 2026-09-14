# REPORT-017 H02 order 33f stopped-state independent acceptance

Date: 2026-08-20

Status: STOPPED STATE ACCEPTED. The H02 result render and semantic repair are
structurally sound, but result-page acceptance remains held until one bounded
no-rerender test correction and the deferred visual QA are complete. The H02
companion and every later render remain held.

## Independently reproduced state

The owner ran exactly one normal-profile target render for
`notebooks/hypotheses/H02.qmd`. R 4.6.1 and Quarto 1.9.37 completed all 45
cells with exit status 0. No model fit, prediction, bootstrap, simulation,
Shapley, dominance, or scientific-artifact regeneration occurred.

The fresh result HTML is
`_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
`736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
296,427 bytes. The configured semantic hook reported `REPAIRED` for 15 native
gt tables, 152 IDs, 253 `headers` tokens, and 405 reversible substitutions.
The retained ledger reverses the output to pre-hook SHA-256
`9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84`,
284,147 bytes. The normalized DOM and visible text are unchanged across that
repair.

The owner stopped correctly before loopback QA. The owner execution record is
`audit/hypotheses/H02/report017_order33f_result_render/render_execution_record.md`,
SHA-256 `8fe279da0dc645e8c3a25cf663d57b21c4139b79138772795eaf34b6eed7b828`.
Its 64-row non-circular evidence manifest is SHA-256
`2481dba7362f6472cc508e20434567bb3d8b70c7f18607685501606eec7af855`.
Independent R 4.6.1 verification passed all 64 identities and byte counts,
including the retained external semantic summary and ledger.

## Accepted successful checks

The fresh page has exactly 15 native gt table endpoints and five figure
endpoints. There are zero duplicate document IDs. All 530 table-header
references and all 552 document ID references resolve. All 22
preregistration links resolve to the accepted 18 unique anchors. All nine
country-coded site labels pass. The paired-placement test passes. All 210
protected paths remain byte-identical. The complete build delta has 21
classified and permitted entries, with no symlink or unclassified change.
Post-render and post-inspection inventories are identical.

The accepted sources remain result SHA-256
`4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`
and companion SHA-256
`92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`.
The held companion HTML remains SHA-256
`d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`.
The profile remains SHA-256
`80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

## Complete reader-test classification

The owner identified three stale opening assertions in the complete reader
test. A subsequent independent R 4.6.1 audit evaluated the full remaining
test contract in one pass so that no further masked assertion needs a
piecemeal cycle.

The complete stale set is:

1. the preparation-manifest mismatch set omits the newly rendered H02 HTML;
2. the worker-manifest mismatch set omits the same HTML;
3. the result-HTML identity still pins the pre-render file;
4. one shortened FDR phrase does not match the accepted full rendered phrase;
5. four `diagnostic p` literals do not match the accepted `check p` display;
6. a 160-character caption ceiling rejects three accepted figure captions of
   178, 181, and 194 characters.

All assertions after that caption gate were independently evaluated. Every
expected endpoint occurs exactly once, all 15 native tables retain no more
than ten data rows and six terminal header columns, all 20 expected captions
are present and nonempty, all five images have nonempty alt text and relative
sources, and every image file exists. The caption-length failure is therefore
an obsolete arbitrary test heuristic, not a source or display defect. The
exact classification is recorded in
`audit/report_harmonization/report017_h02_order33f_reader_contract_audit.csv`.

## Shared DOC-001 link classification

The only unresolved reader link is
`../../supplementary_information.html`. This is the same shared
Supplementary information target already retained as the controlling
DOC-001 hold for earlier accepted pages. It is not an H02 source, semantic,
or scientific defect. The H02 continuation must classify exactly this one
shared target and continue to fail on every other unresolved reader link.
DOC-001 remains open until the separately authorized shared page render and
final inbound-link audit are complete.

## Bounded next action proposed for coordinator authorization

Use one no-rerender continuation. Edit only
`tests/hypotheses/H02/test_h02_reader_report.R` to apply the complete
classification above in one pass. Preserve every source-only, scientific,
endpoint, link, artifact, execution-boundary, and companion-identity gate.
Replace the caption character ceiling with exact one-caption-per-endpoint and
nonempty-caption structural checks.

Then run the complete H02 reader, preparation, and paired-placement tests and
the existing semantic, link, deviation-anchor, navigation, country-code,
manifest, build-delta, and protected-identity checks against the existing
fresh HTML. If they pass, perform the deferred secure-loopback visual QA on
that existing HTML at 1440 x 1000, 708 x 1000, 200 percent, and intended
final display sizes. Inspect all five figures and the principal table and
figure under the accepted desktop-first and contained-narrow-scroll table
policy. Stop the loopback server, prove no listener remains, and seal one
combined completion package.

No Quarto rerender, QMD edit, scientific execution, artifact regeneration,
companion render, later render, profile or ledger change, broad manifest
builder, commit, push, or upload is needed or proposed.
