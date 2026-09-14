# H09 shared change request

Date: 2026-08-12

Status: **Stage 4 website integration requested; remaining shared gap artifact
is optional and coordinator-owned; METRIC-011 requires no new shared H09
change**

Shared files modified by the H09 worker: **none**

## Why this request exists

H09 may edit only hypothesis-owned paths. Its Stage 1 audit found two issues
that could not be repaired inside H09 by changing coordinator-owned
preparation or registry artifacts. The owner has now resolved the score gate
and authorized an H09-owned exact-midpoint construction for the primary
dataset under PREP06-BASE-002. Stage 2 was approved as amended under H09-002,
and the owner approved the standalone reader report under H09-003 with a brief
predictor-definition amendment. The H09-owned analysis-preparation and
provenance companion is now ready for coordinator-owned website integration.
No shared file was changed by the H09 worker.

## METRIC-011 requires no new shared change

The final shared `METRIC-011` decision changes only numerical-zero L10 mean
melEDI cells. H09's registered rolling-window outcome is L10 midpoint timing,
so the decision is outside H09's scientific estimand. The H09 worker repinned
only the affected shared/base identities in H09-owned provenance records and
verified all 12 stored primary L10-midpoint frames (9,378 rows) plus 65
scientific artifacts exactly. No model or diagnostic was rerun and no H09
result or claim changed.

The bounded H09 overlay manifest is
`artifacts/12_manifests/H09/H09_METRIC-011_provenance_reseal_manifest.csv`
(SHA-256
`cb4e0701c0f642c36e138ef670af373eeeef850e538a991af32bcf7f63583cad`).
No coordinator-owned shared file needs modification for this follow-up. A
proposed central-ledger note is recorded in the worker handoff only.

## Resolved request 1: MCTQ/MEQ aggregate-score acceptance

Resolution: the owner explicitly accepted the pinned aggregate calculated
fields `msf_sc` and `meq` at H09-G4. H09 therefore fitted both registered
constructs as separate analyses and multiplicity families. This task-local
decision does not establish item-level scoring provenance. The coordinator
may record the resolution centrally; no new shared scoring artifact was
required for H09 Stage 2.

The pinned chronotype acquisition and normalized artifact provide strong
source identity and value-preservation evidence:

- nine cached site-level `chronotype` objects;
- one normalized row per `site, Id` for 186 participants;
- source repository, commit, DOI, relative path, object name, row, and SHA-256;
- aggregate `msf_sc`, `meq`, and `meq_type` fields; and
- normalization key, schema, missingness, label, interval, and value audits.

However, the available source objects label `msf_sc` and `meq` as calculated
fields and do not contain the item-level questionnaire responses, scoring
function, questionnaire version, missing-item rule, or participant-level
score-construction audit. H09 can verify ranges, missingness, source revisions,
key uniqueness, and the internal ordering of MEQ score categories, but cannot
independently reconstruct MCTQ correction or MEQ item scoring.

Before Stage 2, please do one of the following centrally:

1. provide an approved scoring-provenance artifact documenting the MCTQ and
   MEQ versions, item mappings, calculation rules, valid ranges, missing-item
   handling, MCTQ sleep correction, software/function revision, and checksums;
   or
2. record an explicit author decision that the pinned upstream aggregate
   calculated fields are the accepted H09 predictors despite the absence of
   item-level reconstruction.

This request does not authorize omission of MEQ. The preregistration names
both MCTQ and MEQ, and the Stage 1 recommendation is to analyse them as
separate constructs and multiplicity families.

## Partially resolved request 2: registered longest-period midpoint

The registration's fifth H09 outcome is the midpoint of the longest period
above 250 lx melanopic EDI. V0 instead used mean timing above 250 lx. The
primary enriched data currently retain the selected longest-period UTC onset
and offset, winner-selection rule, exact-identifiability flag, censoring flag,
and local time zone, but they do not contain an approved registered midpoint
field or metric-registry row. The gap-timing-unaware artifact contains neither
the registered midpoint nor the endpoints needed to construct it.

The author approved the registered branch at H09-G2 and PREP06-BASE-002
permits H09 to construct the exact-identifiable primary midpoint from approved
endpoints in H09-owned code. That primary implementation is complete. If a
future shared implementation or complete gap-timing-unaware sensitivity is
required, please add centrally:

- one approved participant-day registered-midpoint field for both placements;
- an explicit exact-identifiable/censoring rule;
- local-time and DST-safe midpoint construction from the selected period;
- metric display-registry and scenario-crosswalk entries;
- primary and gap-timing-unaware support/reason-code diagnostics;
- value, key, and scenario manifests with SHA-256 checksums; and
- a preparation note distinguishing this event midpoint from duration-weighted
  mean timing across all exposure above 250 lx.

The H09 Stage 1 document computes a provisional exact-identifiable midpoint in
memory only to quantify candidate support. It is not an approved shared metric
and is not written to an artifact.

Mean timing remains a named adapted sensitivity and was not substituted for
the registered midpoint. The current gap-timing-unaware artifact still lacks
both the registered midpoint and its endpoints. Stage 2 therefore retains the
fifth sensitivity member as explicitly non-estimable; this is not a blocker to
the current H09 result gate.

## Website integration requested

Please add the following H09-owned preparation source immediately after the
H09 result page in both the `render` list and the hypothesis sidebar of
`_quarto-nathealth.yml`:

```yaml
- audit/hypotheses/H09/H09_analysis_preparation.qmd
```

For the sidebar entry, use:

```yaml
- href: audit/hypotheses/H09/H09_analysis_preparation.qmd
  text: "H09 preparation and provenance"
```

After integration, rerender only the affected Nature Health website scope and
verify that the H09 result and preparation pages remain adjacent, reciprocal
links resolve, and the copied website source remains byte-identical to
`audit/hypotheses/H09/H09_analysis_preparation.qmd`. The H09 worker has not
edited the shared profile.

## Return condition

No upstream return is required for the completed H09 analysis. If the
coordinator later supplies a shared registered-midpoint field or a complete
gap-timing-unaware artifact, H09 must reopen the affected identity, sample,
multiplicity, and sensitivity checks before using it. No shared ledger,
registry, preparation script, Quarto configuration, manuscript file, or
lockfile was changed by the H09 worker.
