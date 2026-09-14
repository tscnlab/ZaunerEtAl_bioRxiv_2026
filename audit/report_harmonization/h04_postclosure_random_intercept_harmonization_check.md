# H04 post-closure participant random-intercept harmonization check

Date: 2026-08-14

Status: **Source order and scientific-role separation are acceptable. A
bounded reader-language and exact cross-link synchronization remains before
harmonizer source acceptance. The owner-scoped renders are verification
evidence only and do not release the H04 REPORT-017 target render.**

## Source identities reviewed

- result report: `notebooks/hypotheses/H04.qmd`, SHA-256
  `3fc0ee272304bb32325bf92becc6b1eb28508981b0c2a273c20968997909c438`;
- preparation and provenance companion:
  `audit/hypotheses/H04/H04_analysis_preparation.qmd`, SHA-256
  `7a317e6e408dfd66bc7d8fd1cc643d21f5ffaad4f0eb20b9c4bf887d84278635`;
- current H04 handoff: `audit/handoffs/H04_worker_handoff.md`, SHA-256
  `c4944f4f91f0cf3bdb06945eebe76f32eb969c3f98e06bf62befab4cfd9fa3e8`;
- registered result HTML:
  `_build/nathealth/notebooks/hypotheses/H04.html`, SHA-256
  `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`;
- registered companion HTML:
  `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.html`,
  SHA-256
  `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`;
  and
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

The current H04 handoff was read completely before this document-specific
review was returned to the owner.

## Accepted source order and role boundary

The new result subsection occurs after the descriptive fixed-effect R²
section and before model checks. The companion subsection occurs after the
activity-by-site interaction material and before multiplicity and subsequent
technical construction. This is a coherent reader order.

Both pages preserve the controlling distinction:

- the population-mean quasi-Tweedie analysis with participant-clustered
  covariance remains the inferential analysis;
- the within-participant and between-participant Mundlak-style sensitivity is
  a separate population-mean augmentation and is not a mixed model,
  random-slope model, or variance-component analysis; and
- the new participant random-intercept model is an exploratory point
  decomposition with no random activity slopes, participant-day intercept,
  residual-correlation structure, or uncertainty intervals.

The exact `1/k` fractional weighting and support-qualified five-named-category
activity-by-site frame remain explicit. The reported marginal and conditional
R² values, participant increment, hierarchy-respecting allocation, residual
lag-one correlations, exact-zero mismatch, convergence checks, and all stated
qualifications must remain byte-for-byte scientifically unchanged except for
surrounding display wording. No auxiliary quantity may enter another
hypothesis, multiplicity family, diagnostic verdict, or claim.

## Bounded reader-language synchronization

Three new visible uses remain outside the approved vocabulary:

1. In `notebooks/hypotheses/H04.qmd`, both table display labels
   `Participant heterogeneity` should be `Participant-level variation`.
2. In `audit/hypotheses/H04/H04_analysis_preparation.qmd`, the prose phrase
   `stable participant-level heterogeneity` should be
   `stable participant-level variation`.
3. At first use in each page, the random-intercept explanation should state
   plainly that the model allows participants to have different overall
   exposure levels while retaining the stated fixed activity-by-site
   structure. The existing formula and technical terms may remain.

Internal object names, stored artifact names, established table identifiers,
and code-only uses of `heterogeneity` remain unchanged. The visible approved
term for the scientific interaction remains `activity-by-site interaction`.
`glmmTMB` may remain in the technical companion if its first use identifies it
as the software used to fit the generalized linear mixed model.

These are display-only wording changes. They must not change data, weights,
formulas, estimates, intervals, diagnostics, p-values, FDR decisions, table
rows, figure data, or model objects.

## Exact dynamic cross-link

Add the stable companion anchor
`{#sec-h04-prep-participant-random-intercept}` to the existing exploratory
participant random-intercept subsection. Add one dynamic relative source link
from the corresponding result subsection to:

```text
../../audit/hypotheses/H04/H04_analysis_preparation.qmd#sec-h04-prep-participant-random-intercept
```

Retain the existing general reciprocal companion-to-result QMD link. Do not
introduce a hard-coded HTML target, build path, absolute path, or second
navigation entry.

## Registered companion provenance

The profile already registers the H04 result and companion adjacently. The
canonical website companion HTML is present, the obsolete direct source-side
HTML is absent, and the website QMD provenance copy is stale. The safe H04
local direction is:

- inventory the existing registered website HTML and page assets read-only;
- remove the obsolete direct-HTML and direct-asset compatibility requirement;
- refresh only
  `_build/nathealth/audit/hypotheses/H04/H04_analysis_preparation.qmd` from the
  authoring QMD and require byte identity;
- do not overwrite the registered HTML or its assets; and
- update only H04-local helper, test, handoff, and manifest evidence.

The current helper and focused test implement this direction at SHA-256
`108842c73bf066fc33ae9f2ba3330893c332097572b5036a55f324e6947d5de7`
and `e0de433deab3cc220e4cf1b1b31f7eb01bee1a6379412d414ebd510e8d386884`,
respectively. They require independent owner sealing. H01 order 31f protects
no H04 `_build` member, so this exact source-copy refresh does not violate the
H01 stopped-state boundary. It must not touch `_quarto-nathealth.yml`, H01
paths, search or sitemap files, a global build inventory, or another build
member.

## Output-catalog follow-up

The provisional principal H04 outputs remain `fig-h04-primary-estimates` and
`tbl-h04-primary-results`. After the source synchronization is independently
accepted, add `tbl-h04-participant-random-intercept` to the harmonizer-owned
catalog as a supplemental detailed result or model-context table. The
Mundlak table should likewise remain supplemental sensitivity context. No
principal-output role is final until the author reviews its focused rendered
appearance.

## Hold

No shared profile edit, central-ledger edit, Quarto render, scientific
execution, commit, or push is authorized by this check. H04 does not enter the
active REPORT-017 render queue until H01 and the preceding serial targets are
accepted and the coordinator releases H04 explicitly.
