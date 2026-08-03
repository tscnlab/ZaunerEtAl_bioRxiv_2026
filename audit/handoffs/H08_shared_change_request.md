# H08 shared change request

Date: 2026-08-01
Status: **H08 preparation companion ready; shared-profile integration required**
Shared files modified by the H08 worker: **none**

## Requested coordinator-owned Quarto profile change

Please edit `_quarto-nathealth.yml` so the H08 preparation companion is
immediately after the H08 results page in both the project render list and the
Nature Health hypothesis navigation.

### Render list

Current sequence:

```yaml
- notebooks/hypotheses/H08.qmd
- notebooks/hypotheses/H09.qmd
```

Requested sequence:

```yaml
- notebooks/hypotheses/H08.qmd
- audit/hypotheses/H08/H08_analysis_preparation.qmd
- notebooks/hypotheses/H09.qmd
```

### Hypothesis navigation

Current sequence:

```yaml
- href: notebooks/hypotheses/H08.qmd
  text: "H08 results"
- href: notebooks/hypotheses/H09.qmd
  text: "H09 results"
```

Requested sequence:

```yaml
- href: notebooks/hypotheses/H08.qmd
  text: "H08 results"
- href: audit/hypotheses/H08/H08_analysis_preparation.qmd
  text: "H08 preparation and provenance"
- href: notebooks/hypotheses/H09.qmd
  text: "H09 results"
```

This adjacency is required by REPORT-007 and by
`scripts/pipeline/hypothesis_preparation_provenance_contract.R`. The H08
manifest builder currently stops, as designed, with:

> The preparation page is not immediately after its result in the render list.

## Requested targeted render and hand-back

After updating the profile, please render only the two H08 pages with the
`nathealth` profile under R 4.6.1; a full-project render is neither requested
nor needed:

```bash
quarto render notebooks/hypotheses/H08.qmd --profile nathealth
quarto render audit/hypotheses/H08/H08_analysis_preparation.qmd --profile nathealth
```

Then return control to the H08 task. The H08 worker will:

1. verify the profile-integrated previous/next navigation and reciprocal
   links;
2. rerun the display-only physical-size record against the final website
   assets and inspect the resulting A4 proofs;
3. build the non-circular preparation-report manifest; and
4. run the strict preparation companion test without its preintegration
   switch.

No scientific input, metric, sample, estimate, interval, p-value, diagnostic,
or sensitivity needs to be recomputed for this integration.

## H08-owned work already complete

- Authoring source:
  `audit/hypotheses/H08/H08_analysis_preparation.qmd`
- Standalone verified render:
  `audit/hypotheses/H08/H08_analysis_preparation.html`
- Preparation source-data builder:
  `scripts/hypotheses/H08/build_h08_preparation_artifacts.R`
- Stored-output result-figure repair:
  `scripts/hypotheses/H08/rebuild_h08_reader_figures.R`
- Physical-size QA builder:
  `scripts/hypotheses/H08/build_h08_figure_physical_size_qa.R`
- Final-manifest builder:
  `scripts/hypotheses/H08/build_h08_preparation_report_manifest.R`
- Focused verification:
  `tests/hypotheses/H08/test_h08_preparation_report.R`
- REPORT-011 record:
  `artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv`
- Eight durable A4 proofs:
  `artifacts/12_manifests/H08/physical_size_qa/`

The standalone companion renders 49 document steps, 18 compact `gt` tables,
and three accessible descriptive figures from exact source CSV files. It fits
no model. Preintegration verification passes all frozen scientific assertions,
reciprocal source links, figure-source links, and eight REPORT-011 physical-
size inspections.

## REPORT-011 correction already applied

Every H08 reader-facing figure was assessed at 170 mm on an A4 portrait page
with 20-mm side margins. The record includes native width, intended width,
scale factor, smallest essential nominal text, and effective final text. All
figures are exported at 170 mm, have scale factor 1.0, and retain at least
7.5-pt essential text.

The first A4 inspection exposed clipped caption text in the five results-page
figures. Those captions were rewrapped and the figures were re-exported from
their stored H08 source CSV files only. No model was refitted and no scientific
result was recalculated. A second original-size A4 inspection passed all eight
figures for clipping, overlap, wrapping, distortion, important-text
readability, mark distinguishability, and data-region balance. The H08 results
page was then rerendered with the corrected 100% display widths and reciprocal
preparation link.

## Scope guard and stop condition

The H08 worker did not edit `_quarto-nathealth.yml`, shared preparation,
central ledgers or configuration, manuscript files, `renv.lock`, another
hypothesis, descriptives, or `manuscript/R0_NatMed/`. Work stops here until the
coordinator-owned profile adjacency is implemented and the two targeted H08
renders are handed back for final identity sealing.
