# Scientific discrepancies exposed by reader harmonization

These findings stop only the named document. They are not resolved
editorially by the report-harmonization task.

## RH-SCI-001 — H01 owner repair complete; central alias mapping pending

Date identified: 2026-08-12  
Document status: **scientific display repaired; links remain stopped pending central alias-map confirmation**  
Responsible scientific owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`  
Coordinator: `019faf58-3df3-7383-8034-f715cdfdd154`

Current accepted source identities:

- `notebooks/hypotheses/H01.qmd`:
  `8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96`;
- originally displayed source table
  `artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv`:
  `ecbf772d084582c643e1ee4523a8171db419d4e998f5d846ea34228238a6f709`.

The H01 QMD reads that stored CSV and displays it at
`tbl-h01-deviations`. The source-only harmonization pass correctly left this
block unchanged while REPORT-016 was pending. After REPORT-016 release, three
scientific conflicts are visible:

1. The `IMP-013; DEV-051` row calls the ratio of integrated melanopic to
   photopic exposure the current MDER. REPORT-016 classifies both records as
   resolved/superseded history and identifies DEV-058/METRIC-010—the mean of
   viable one-minute ratios—as the current MDER.
2. The `DEV-057` row describes exclusion of participant-days with more than
   1,440 valid minutes. REPORT-016 defines DEV-057 as the otherwise-eligible
   complete exact-zero melEDI day exclusion. The stable central ID is therefore
   attached to a different scientific rule in the H01 table.
3. The `DEV-008; DEV-054` row does not state the current distinction that the
   registered longest-period midpoint is retained while mean timing is a
   separately labelled adapted sensitivity. REPORT-016 places DEV-008 in
   resolved history and supplies that distinction explicitly.

The displayed table also contains eight noncentral `H01-*` identifiers
(`H01-001` through `H01-008`, with the exact set H01-001, H01-002, H01-003,
H01-004, H01-005, H01-006, H01-007, and H01-008). They have no anchors in the
86-ID authoritative register. The harmonization task will not invent a
replacement mapping, silently drop them, or link them to a central ID without
an explicit scientific/coordinator decision.

Required resolution before H01 link integration:

- the H01 scientific owner must reconcile the displayed deviation table with
  REPORT-016 and the accepted current H01 artifacts;
- the coordinator must specify the disposition of the eight H01-local IDs;
- the owner must return R 4.6.1 evidence that the repaired display changes no
  data, sample, model, estimate, interval, p-value, multiplicity result,
  diagnostic, sensitivity result, or scientific conclusion; and
- only after acceptance may each retained central stable ID be linked to its
  exact `../../preregistration_deviations.qmd#<lower-case-id>` anchor.

### Owner reconciliation returned

The H01 owner completed the scientific repair on 2026-08-12 without changing
either reader QMD or rendering the report. The corrected displayed table is
`2671fc9af9d6764a8b64c1417c8c84b3eb63a2f0a0c2c4ff4adb4eddeb03a347`.
It now uses DEV-058/METRIC-010 for the current MDER, assigns DEV-057 to the
complete exact-zero melEDI-day exclusion, gives the full DEV-008/DEV-054
longest-period distinction, and removes all eight reader-facing H01 aliases.
The 1,161-artifact protected inventory remained byte-identical, and the
focused R 4.6.1 reconciliation passed.

The owner proposed the following editorial-alias mapping, with no new central
record: H01-001 → IMP-001; H01-002 → DEV-009; H01-003 → IMP-004; H01-004 →
IMP-003 and IMP-004; H01-005 → DEV-018; H01-006 → DEV-009 and IMP-001;
H01-007 → IMP-024; H01-008 → IMP-023. The coordinator must still confirm
this mapping before the H01 exact-link order is released.

## RH-SCI-002 — resolved: registered hourly outcome is superseded provenance

Date identified: 2026-08-12  
Document status: **resolved and released for later serial harmonization/link order under CHG-129**  
Responsible scientific owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`  
Coordinator: `019faf58-3df3-7383-8034-f715cdfdd154`

Source identities when identified:

- `notebooks/hypotheses/H11.qmd`:
  `e4f13510317e62888f7fd785bacd8bd20ad9f3e90d24fa7bc9dc59e7215ec2e7`;
- `audit/hypotheses/H11/H11_analysis_preparation.qmd`:
  `a2d25df408b7282691342a19b030427c2fea6111a04719ffb8c6e382bab92def`.

In `tbl-h11-data-deviations`, the Outcome and epoch row states that the
registered hourly outcome "remains an unresolved sensitivity." REPORT-016
instead classifies DEV-042 as an approved, implemented, verified scientific
deviation: the accepted H11 analysis deliberately inherits H02's supported
30-minute zero-aware transformed arithmetic-mean melEDI. The overlay explains
the changed estimand, sample, and dependence structure but does not classify
an hourly-outcome sensitivity as open. Its only current qualification is
DEV-003.

This may be either stale reader wording or a genuinely outstanding H11
scientific obligation. The harmonization task cannot decide which. Before an
H11 owner order is issued, the coordinator/H11 scientific owner must state
whether the registered hourly-outcome sensitivity is required, completed, or
not part of the accepted H11 analysis. Any source correction must preserve the
accepted model and results and return R 4.6.1 evidence; harmonization will then
use the resolved disposition and exact DEV-042 link without editorially
changing the science.

### Resolution

The coordinator and H11 owner selected option (c) under CHG-129: the
registered hourly geometric-mean outcome remains preregistration provenance
but is outside, and superseded by, the author-approved final H11 analysis. It
is not an unfinished sensitivity. DEV-042 remains approved, implemented, and
verified; DEV-003 remains the current qualification. Fresh R 4.6.1 evidence
verified 81 Stage 2 scientific files, 42 accepted Stage 3 artifacts, and 48
activity-context outputs byte-for-byte, with no scientific recomputation.

Accepted post-resolution identities are:

- `notebooks/hypotheses/H11.qmd`:
  `6d8efe39896812437037ee60675f95fb71fd8f74f3eaf0e65b151f27f0822dbd`;
- `audit/hypotheses/H11/H11_analysis_preparation.qmd`:
  `fc7781c887ba4470b1bb660143f5df207e780efd257ca268138dae2d35d42e7f`;
- disposition record:
  `ba8797bcf53658f04e634614dda56535d480e11ad4eaca0c3cb96fc6279bde57`;
- reconciliation CSV:
  `7dc4ab4a68f21a7274562a06b19bedc904605dc8ab0d721d1b70f6c87b80a64b`.
