# REPORT-017 owner order 29a: Preparation 07 typography test repair

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Editable file: `tests/test_preparation07_report.R`

## Authority and pins

The coordinator approved the order 29 focused-test stop as a bounded
test-only repair. Recheck these identities before editing:

- repaired QMD:
  `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1`;
- stale focused test:
  `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`;
- unchanged HTML:
  `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401`;
- profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- owner source-test stop:
  `9fa4f2ae38ce697043a98ae20dabb03eeb626b2e5fb8abf85d4277122544b357`;
- owner 24-entry manifest:
  `79fddcba317def3b90142e9205d3821c746b894a291f0d8e9c8abd65d322a485`;
- independent stop acceptance:
  `d12eb171be6f562c1c806f9233dde766699ac7b57ff9e9033d324f6ce0a82a76`;
- independent 13-entry manifest:
  `3d1fdb100484ac5fe2261c636232102eea50b66243044ef3a25a32f323ab925f`.

## Exact test-only repair

Edit only the existing typography assertion at lines 256 to 262. Replace its
stale conjunction with checks for:

1. exact `legend.title = ggplot2::element_text(size = 10)`;
2. exact `legend.text = ggplot2::element_text(size = 10)`;
3. a whitespace-tolerant `strip.text = ggplot2::element_text(` block whose
   first size setting is `size = 10,`;
4. exact `axis.text = ggplot2::element_text(size = 10)`; and
5. unchanged exact `axis.title = ggplot2::element_text(size = 10)`.

Use fixed-string checks for the four single-line settings. Use one
whitespace-tolerant Perl regular expression for the multiline `strip.text`
block. Preserve the existing assertion message exactly:

```text
REPORT-011 figure typography contract is absent.
```

Preserve every other test byte and gate. Do not edit the QMD, HTML, profile,
artifacts, manifests, audit records, decisions, ledgers, lockfile, or any
scientific file.

## Verification boundary

Run only:

- R 4.6.1 parsing of the repaired test;
- the complete source-only focused test with no HTML argument;
- an exact test diff and reverse-substitution proof to the starting test SHA;
- the protected-identity comparison, proving the test is the only changed
  path and the QMD remains at its accepted repaired identity; and
- scoped `git diff --check`.

Do not run Quarto, evaluate a QMD chunk, start a browser or server, or render
any target. Stop on any additional failure or drift.

Return pre/post test identities, the exact assertion delta, reverse proof,
R 4.6.1 parse and focused-test results, protected identities, and a
non-circular manifest. Preparation 07 target rendering and every hypothesis
render remain held pending independent source/test acceptance and a separate
release.

