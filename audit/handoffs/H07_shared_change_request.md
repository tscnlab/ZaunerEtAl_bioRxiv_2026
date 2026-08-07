# H07 shared change request

Date: 2026-08-07
Status: **author-approved; H07-owned work complete, shared integration pending**
Shared files modified by the H07 worker: **none**

Decision `H07-005` authorized this coordinator-owned integration on
2026-08-07 without scientific recomputation.

## Required shared-site integration

Please add the following source immediately after
`notebooks/hypotheses/H07.qmd` in the `project.render` list of
`_quarto-nathealth.yml`:

```yaml
- audit/hypotheses/H07/H07_analysis_preparation.qmd
```

Please add the following item immediately beside the H07 result in the
“Hypothesis analyses” navigation:

```yaml
- href: audit/hypotheses/H07/H07_analysis_preparation.qmd
  text: "H07 preparation and provenance"
```

Then run the bounded H07 result and preparation render, rebuild
`artifacts/12_manifests/H07/H07_preparation_report_manifest.csv`, and run
`tests/hypotheses/H07/test_h07_preparation_report.R`. Once the profile entries
exist, that test automatically runs the full shared preparation-companion
verifier, including render-list and navigation adjacency.

No H07 scientific fit, prediction, derivative, bootstrap, simulation, or
diagnostic pilot needs to be repeated for this integration. The preparation
page reads only frozen H07 artifacts. Until the coordinator makes this shared
configuration change, the H07 worker’s bounded standalone preparation render
is copied into the expected `_build/nathealth` location solely for local link
and contract verification.
