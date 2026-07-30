# Pre-repair baseline

## Identity and scope

- Baseline commit: `20ba43c27e69fd952ce8023770538f2aa843ef5e`
- Branch at capture: `rewrite/NH`
- Captured: 2026-07-29
- Hash algorithm: SHA-256
- Scientific values recalculated: no
- Analytical or manuscript source modified during capture: no
- `renv.lock` modified during capture: no

This directory freezes the files and artifact graph that existed before the
Nature Health analytical repair. Hashing and dependency discovery are
structural operations; the manifests do not validate any scientific result.

## Manifests

- `source_file_hashes.csv` records tracked project source, configuration,
  bibliography, citation-style, and lock files exactly as stored at the
  baseline commit. Git blob SHA-1 identifiers are included as a second
  independent identity.
- `data_artifact_hashes.csv` records every file directly under `data/` in the
  baseline worktree, including persisted `.RData` objects and
  `metric_types.xlsx`.
- `render_dag.md` records declared render order, observed file dependencies,
  and baseline provenance defects.
- `r0_natmed_checksums.csv` records the protected, ignored Nature Medicine
  submission files without opening or modifying their contents.
- `pinned_source_hashes.csv` records the 35 site-release files acquired from
  the nine fixed Git commits for the clean rebuild, including URL, SHA-256,
  size, and cache acquisition time. Local cache paths are intentionally
  omitted from the tracked record.

## Protected Nature Medicine package

`manuscript/R0_NatMed/` was present and non-empty at capture: 33 files totaling
47,690,015 bytes. It remains outside the tracked project and is read-only for
this work. Future verification must reproduce every checksum in
`r0_natmed_checksums.csv`.

## Important baseline limitations

- The configured Quarto order renders `Descriptives.qmd` before `RQ1.qmd`,
  although `Descriptives.qmd` loads `data/H1_results.RData`, which
  `RQ1.qmd` produces. The declared order is therefore invalid for a clean
  build.
- `_quarto.yml` sets `freeze: auto`. The repository contains 240 tracked
  `_freeze` files, so an apparently successful render can reuse cached results
  rather than establish provenance.
- `index.qmd` references 25 files under `assets/`. The analytical documents
  write figures and tables under `figures/` and `tables/`; there is no declared
  deterministic assembly step that promotes those products into `assets/`.
- Persisted `.RData` files contain multiple or implicit objects and can depend
  on ambient workspace state. Their hashes establish identity only.
- `data/tbl1_data.RData` has no active producer or consumer in the baseline
  documents and is classified as an orphaned/stale artifact.

Final audit renders must use `freeze: false`, explicit inputs and outputs, and
a corrected deterministic dependency graph.
