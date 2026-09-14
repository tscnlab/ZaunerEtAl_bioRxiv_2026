# Reader-report harmonization Phase 2 authorization

Decision ID: `REPORT-014`  
Change ID: `CHG-124`  
Date: 2026-08-12  
Status: author approved for scoped first adjustment run

## Approved reader vocabulary

The shared reader-facing vocabulary and document structures in
`audit/report_harmonization/` are approved with the author's amendments.
Document owners must preserve scientific meaning, numerical values,
uncertainty, qualifications, and evidence roles while using these reader
terms consistently:

- `[predictor]-by-site interaction`, explained as an association that is
  allowed to differ by study site;
- `site-average estimate`, explained as an average that gives every site equal
  weight;
- `nonlinear GAM analysis`, with generalized additive model (GAM) explained at
  first use and `GAM` permitted thereafter;
- `model checks`, with `model diagnostics` permitted when technically needed
  after first use;
- `same participants and participant-days at both sensor positions` before a
  shorter matched- or common-sample label is used;
- transformations and back-transformed quantities explained at first use,
  including the resulting reader-facing unit;
- autocorrelation and the AR(1) structure explained before `AR(1)` is used
  alone;
- `95% confidence interval (95% CI)` at first use and `95% CI` thereafter;
- `false-discovery-rate (FDR) adjustment` at first use and `FDR` thereafter;
  the abbreviation `BH` is not used in reader prose or displays, although the
  full Benjamini--Hochberg method name remains available for reproducibility;
- participant-cluster-robust confidence intervals explained before the
  technical `HC3` covariance label is used;
- `symlog`, `Shapley allocation`, and `derivative` retained only after their
  approved plain first-use explanations; and
- every displayed study-site name followed by its ISO alpha-2 country code in
  prose, tables, figures, legends, captions, and alt text.

Internal workflow, migration, artifact, and audit vocabulary is removed from
the main reader flow. Exact identifiers, hashes, manifests, workflow stages,
legacy labels, and superseded analysis history may remain only in audit or
collapsible technical provenance where they are genuinely needed.

## Approved structures and links

The approved result, analysis-preparation/provenance, descriptive, and shared
preparation templates may now be applied with documented hypothesis-specific
exceptions. Cross-document links use Quarto source targets ending in `.qmd`
and stable cross-reference anchors; hard-coded `.html`, `_build`, `file://`,
and absolute local paths are not allowed in reader sources.

Every statement of a preregistration deviation must describe the deviation in
plain language and link to its stable entry in the new preregistration-
deviations Quarto document. The new document may be generated only after the
central deviation register and hypothesis crosswalk reconcile exactly.

## Preliminary display authorization

The proposed principal and supplemental outputs are approved only for a first
display-adjustment run. Owners may apply the accepted small styling changes,
native `gt` conversions, table structure, site labels, captions, alt text, and
the specified display-only H05/H10/H11 consolidations from stored accepted
inputs. The eleven identified H06 reader-identifier repairs are included.

This is not final approval of either the principal-output shortlist or the
adjusted appearance. The harmonization task must collect focused renders and
present the candidate main and supplemental figures and tables to the author
for visual approval before declaring them final.

## Ownership and safe execution points

The following existing tasks retain exclusive responsibility for their
reader-facing sources:

| Documents | Owner task | Safe point |
|---|---|---|
| Shared landing, placement, deviations, supplementary and navigation | `019faf58-3df3-7383-8034-f715cdfdd154` | Coordinator-owned; the landing and supplementary pages retain their documented scientific/content holds |
| Descriptives | `019fb87f-41b5-75c1-bc11-aa7fa233ef89` | Accepted current source; safe for display-only harmonization |
| Preparation 01--07 | `019fbd2a-3d80-7ed0-b93e-96457a9e7f26` | Accepted current sources; preserve the Preparation 03 and 04 reconstruction qualifications |
| H01 | `019fb4ce-d84c-73d1-be48-dc244be5b5f0` | Accepted current source; safe for display-only harmonization |
| H02 | `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44` | Accepted current source; safe for display-only harmonization |
| H03 | `019fbe52-c067-7521-b2cf-62d9398d173b` | Author-approved reader sources; shared navigation remains coordinator-owned |
| H04 | `019febf4-4868-72f3-bd97-31a85e86f8f0` | Author-approved reader sources; shared navigation remains coordinator-owned |
| H05 | `019fba35-6fd8-73c3-970f-e41f8b759bb6` | Accepted current source; safe for display-only harmonization |
| Main hourly H06 | `019fbd4a-288b-7a72-ac70-2d17ba6d2f04` | Accepted and frozen as the main H06 result; safe for display-only harmonization without touching H06_daily |
| H07 | `019fbe52-6781-7c32-bdcf-379c88ef1e78` | Author-approved reader sources; shared navigation remains coordinator-owned |
| H08 | `019fbdb6-b6a8-7e53-8e84-7a2967af9ea5` | Accepted current source; safe for display-only harmonization |
| H09 | `019fdc1b-b927-7fb1-ac61-88993c0a818a` | Author-approved reader sources; shared navigation remains coordinator-owned |
| H10 | `019fdc1b-b77b-7972-aed0-784da328e115` | Accepted current source; safe for display-only harmonization |
| H11 | `019fba59-0f3c-74a0-ab3d-58d389365ad1` | Author-approved reader sources; shared navigation remains coordinator-owned |
| H06_daily complement | `019fec6a-20d3-7710-ab9b-a035e0874182` | Deferred until its Stage 3 and Stage 4 reader sources are author accepted |

At this decision point, all document-owner tasks other than H06_daily are
idle/not loaded. The harmonization task may issue one scoped order per owner.
Because H06_daily is running its authorized scientific Stage 2 production,
owners may begin source-only and static editorial work, but computation-heavy
or high-cost Quarto renders must be serialized and held until H06_daily reaches
its next author gate. Owners must not be awakened in a simultaneous burst.

## Scientific boundary

This authorization changes no data, sample, metric, model, prediction,
estimate, interval, p-value, FDR result, diagnostic statistic, sensitivity,
Shapley allocation, bootstrap, simulation, or scientific claim. It authorizes
no shared-preparation rebuild and no full-project render. A possible
scientific discrepancy stops that document and returns to its scientific
owner rather than being repaired editorially.

## Reopening condition

Reopen if an owner or source identity changes before its scoped order, a
scientific result is found to be unstable, a dynamic link cannot resolve
without shared configuration work, a qualification would be weakened, or the
author rejects the first adjusted principal/supplemental display package.

