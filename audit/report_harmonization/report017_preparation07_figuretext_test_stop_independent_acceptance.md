# REPORT-017 Preparation 07 figure-text test stop independent acceptance

Date: 2026-08-14

Outcome: **ACCEPTED AS A TEST-ONLY STOP.** The four authorized figure-theme
size changes are exact, reversible, and protected-input safe. No render ran.
The source-only focused test fails only because its typography assertion still
requires the superseded 9 pt and 9.5 pt literals.

The returned source is
`notebooks/preparation/07_example_days.qmd`, SHA-256
`e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1`.
The owner stop record is
`audit/preparation_reports/report017_preparation07_figuretext_failed_source_test_verification.md`,
SHA-256
`9fa4f2ae38ce697043a98ae20dabb03eeb626b2e5fb8abf85d4277122544b357`.
Its 24-entry manifest is SHA-256
`79fddcba317def3b90142e9205d3821c746b894a291f0d8e9c8abd65d322a485`
and independently verifies 24/24 identities and byte counts.

The source repair proof reconstructs the accepted pre-edit QMD
`37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7`.
The numeric-token proof contains 402 tokens before and after, with exactly the
four authorized changes and 398 other tokens identical. The post-edit and
post-test protected inventories are byte-identical at
`3a48482232fbf7a0b9d9832db353bde6e2467c5d387765012bbe9dc141187590`.
The 817-file build inventories are byte- and mtime-identical at
`9ab3459065c543e0531d26e00d5bf5b21c0d9aea46191c4e1573a92542aff641`.
The existing HTML therefore remains
`aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401`.

The stale test block at lines 256 to 262 explicitly requires
`axis.text` and `legend.text` at 9 pt and a generic 9.5 pt size near the
`strip.text` block. Those are precisely the display values that order 29
replaced. This is a test-contract mismatch, not a reader-source, figure, data,
or scientific defect.

The smallest repair is test-only. Replace only the existing typography
conjunction so it requires:

- exact 10 pt `legend.title`;
- exact 10 pt `legend.text`;
- a `strip.text` block whose first size setting is 10 pt;
- exact 10 pt `axis.text`; and
- the still unchanged exact 10 pt `axis.title`.

Use a whitespace-tolerant regular expression only for the multiline
`strip.text` block and exact fixed-string checks for the four single-line
settings. Preserve the existing assertion message and every other test gate.
Do not edit the QMD, HTML, configuration, artifacts, manifests, or scientific
files, and do not render. After a separately authorized test repair, run only
the R 4.6.1 test parse, complete source-only focused test, exact diff and
reverse-substitution checks, and protected identities. The Preparation 07
target render and every hypothesis render remain held until that test-only
repair is independently accepted and separately released.

