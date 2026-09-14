# H01 order-32a complete-verifier stopped-state seal

Date: 2026-08-15
Status: **STOPPED after the single authorized complete verifier execution**

Repaired verifier SHA-256: `620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18`
Fresh reconstructed baseline retained at: `/private/tmp/H01-order32a-baseline.A5iuk8`
R version: 4.6.1
Verifier exit status: 1
Verifier elapsed time: 7.13 seconds
Source contracts passed: 62/66
Focused tests passed: 4/4

## Complete defect list

- `companion_inline_r_allow_list`: expected `no removals`; observed `added: | removed:`.
- `result_top_level_assignment_allow_list`: expected `added=h01_support_orientation; removed=`; observed `added=h01_support_orientation; removed=`.
- `companion_top_level_assignment_allow_list`: expected `added=; removed=source_dir`; observed `added=; removed=source_dir`.
- `companion_scientific_numeric_tokens`: expected `41 unchanged prose numeric tokens`; observed `42 current prose numeric tokens`.

No verifier retry or source repair was attempted. No Quarto render, QMD chunk, model, prediction, bootstrap, simulation, reporting builder, or scientific artifact regeneration ran. All 28 dispatch identities, the original verifier, the stopped order-32 evidence, the current assembled sources, tests, manifests, handoff, held HTML, and profile remain exact.

The initial direct baseline command stopped before entering the mode-0644 script. The still-empty baseline was then reconstructed once by the sealed script through `/bin/sh`, producing the six exact required identities.
