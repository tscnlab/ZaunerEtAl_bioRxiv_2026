# REPORT-017 render-completion scheduling override

Date: 2026-08-20

Controlling decision: REPORT-018

## Active safe point

H02 order 33f is the sole bounded exception. Its one result render completed
successfully and preserved all scientific inputs. Finish only the complete
reader-test classification already identified in the stopped-state audit,
rerun the three focused H02 tests against the existing HTML, complete semantic
and protected checks, perform secure-loopback visual QA, and seal acceptance.
Do not rerender H02 in this cleanup.

## Queue after H02

Switch immediately to render-completion sequencing:

1. shared Supplementary information;
2. H02 preparation and provenance companion;
3. H03 result, then companion;
4. H04 result, then companion;
5. H05 result, then companion;
6. main hourly H06 result, then companion;
7. complementary H06_daily result, then companion;
8. H07 through H11, each result followed by its companion;
9. shared Sensitivity battery; and
10. one final integrated corpus audit and DOC-001 disposition.

The harmonizer may prepare the next target's read-only preservation inventory
while the active target completes, but only one Quarto render may run at a
time.

## No-new-cleanup rule

Do not start new language, terminology, stylistic, optional-link, output-role,
test-literal, or cosmetic figure/table cleanup. Keep accepted source changes.
Record nonblocking findings for later author review and continue the queue.
Only a REPORT-018 hard blocker may interrupt rendering, and any necessary
repair must be consolidated into one render-enabling correction after the
complete page has been inspected.

## Continuing acceptance contract

Every target retains:

- exact source, profile, test, artifact, and pre-render HTML pins;
- normal-profile R 4.6.1 execution with no model or scientific recomputation;
- the post-render native-`gt` semantic repair and reversal audit;
- complete endpoint, link, anchor, navigation, source-data, country-label,
  protected-input, and build-delta checks;
- secure `127.0.0.1` loopback QA rooted exactly at `_build/nathealth`;
- desktop and narrow page-integrity review under the accepted table policy;
- final-size inspection of exported outputs where applicable; and
- listener teardown and post-QA identity verification.

No full-project render, package or lockfile change, scientific-source edit,
ledger reinterpretation, manuscript mutation, commit, push, upload, or
publication is authorized.
