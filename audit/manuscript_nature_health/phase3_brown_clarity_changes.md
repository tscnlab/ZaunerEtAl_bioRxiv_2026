# Brown-integrated clarity and invariant record

Date: 2026-08-21

## Sources compared

- Preserved source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd`
  - SHA-256: `acb6544209fe9c34f5a28b03eb72bf02283af47b6757f05a3a523c9538e6ed0c`
- Revised source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`
  - Final SHA-256: `a6c1376c32783a943d2db19784fcd12e067727ba8a2fd9e9f67bcb5aa9df019f`

The preserved source was not overwritten. The Brown integration was made in a traceable sibling source.

## Clarity decisions

- The main state-period analysis precedes the exploratory cross-state extension.
- Pooled minute fractions, state-period proportions and hourly context means are named as different estimands.
- The Results retain effect sizes, intervals, multiplicity and the three supported site localisations, while moving repeated interpretation into shorter boundary sentences.
- The exploratory cross-state paragraph states the withheld within-participant claim before reporting between-participant estimates.
- Qualifiers are attached to the claim they constrain. Model-dependent allocations are distinguished from causal importance, response variance and individual prediction.
- Repeated wording in the existing Results and Discussion was compressed without changing the accepted numerical claims. The main-text count fell below the author-approved 4,400-word ceiling while retaining the requested numerical detail.
- The retained CIE standard uses a manuscript-local citation key so its standard number and official title capitalization survive the Nature citation style.
- No em dash was introduced.

## Mechanical invariant comparison

Command:

```text
python3 /Users/zauner/.codex/skills/clarify-scientific-writing/scripts/check_invariants.py manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd --json
```

Results requiring reconciliation:

- citation and cross-reference keys: match, 118 occurrences in each source;
- numeric citation groups: match;
- mathematical spans: match;
- numbers: 512 occurrences in the preserved source and 575 in the revision;
- unit-bearing number pairs: 157 and 175;
- acronyms: 158 and 170.

The numerical and acronym differences are expected because the revision adds the accepted Brown sample, contrasts, intervals, FDR results, response-scale partition, coverage checks and anonymous-profile dimensions. Several older numbers occur fewer times because repeated prose was compressed or a unit was stated once for a compact series. They were not silently changed. Every manuscript-facing Brown value was checked in R 4.6.1 against the sealed accepted CSVs, and all retained paragraph-level numerical claims are listed in `phase3_brown_protected_number_audit.csv`.

The checker is deliberately conservative. Its difference result records authorized scientific additions and reduced repetition, not an unresolved discrepancy. Final acceptance depends on the claim-source and protected-number validators, not on token-count equality between scientifically different revisions.
