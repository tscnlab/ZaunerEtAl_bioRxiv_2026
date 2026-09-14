# H01 METRIC-011 L10 production-bootstrap gate

Decision ID: `H01-012`  
Date: 2026-08-12  
Status: verified; awaiting explicit author approval

## Decision

Accept the bounded H01 METRIC-011 point-refit and 50-successful-refit pilot
package as independently verified evidence for an author decision. Do not yet
authorize the four-target production bootstrap, merge any amended H01 result,
or replace any accepted Stage 2--4 report artifact.

The author must explicitly approve all three dispositions recorded in the H01
gate before production begins:

1. retain the established Gaussian `log10(melEDI + 0.1)` models as acceptable
   with limitations for the four affected primary L10 targets;
2. accept that METRIC-011 changes no fitted sample, inferential-support
   decision, sensitivity classification, or scientific claim; and
3. authorize at least 1,000 successful joint bootstrap refits for each of the
   four affected primary L10 targets.

## Verified bounded result

The isolated refit covers only the all-available and paired/common primary
near-eye and chest L10-mean branches. Eight unique normalized cells enter 16
fitted-frame rows. Participant, participant-day, observation, and site counts
are unchanged. The largest raw p-value shift is
`6.231682e-13`, the largest Benjamini--Hochberg adjusted-p shift is
`3.32e-13`, and no support decision changes. All four point fits avoid a major
diagnostic gate and retain the existing assessment of acceptable with
limitations.

The pilot retained 50 successful refits per target, 200 retained draws in
total, with no failed or warning refits. Its observed wall time was 73.95
seconds. The projected wall time for four targets with 1,000 successful refits
each is 24.65 minutes (0.411 hours). Pilot intervals are not inferential and
must not enter reports or claims.

## Preservation boundary

The 830 protected non-L10 artifacts, every unchanged gap-timing-unaware L10
output, and the separate METRIC-010 gate remain frozen. No production
bootstrap, report merge, manuscript change, or central scientific-result
update is authorized by this decision. The accepted four-stage H01 record
remains the controlling published-style result until the bounded amendment is
author-approved, run, verified, and integrated.

## Verification and identities

Fresh R 4.6.1 execution of
`tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R` passed all input-pin,
sample, normalization-scope, multiplicity, diagnostic, sensitivity, pilot,
preservation, and manifest checks.

| Artifact | SHA-256 |
|---|---|
| Bounded author-gate report | `2c1743203d40b0405563ecfed0b8d212eb55d66af2f2f67741f60e8e1ba3e4cc` |
| Author-gate manifest | `4ea6b40205796078821bbd35911fb26e3a793ead4f5104c42e785b5b35c08c29` |
| Isolated point-fit manifest | `51d3462833724af0238810b88b6d9e75e93d2d3a0aebcb2f5077e8adb0354346` |
| Pilot manifest | `7d7970368b94a0dfa5dcbce7b3b42fe712f11bdd2475c8d5addb7426a53d4f0e` |
| Focused gate test | `fbbeab68b6680241c33a755f7aeb29e9f5e8b46a660968c642641d189b12d177` |

## Reopening condition

Reopen this verification if any pinned identity, fitted sample, target set,
model family, diagnostic classification, support decision, pilot outcome,
production-refit count, runtime estimate, or protected-artifact guard changes.
After explicit author approval, production remains bounded to the four named
L10 targets and must stop again if its verifier fails or its results change an
accepted support decision or claim.
