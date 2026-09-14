# REPORT-017 Preparation 03 focused-test stop record

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/03_reference_profiles.qmd`  
Outcome: **STOPPED after a successful bounded render because the required focused test failed on a stale exact-string assertion.**

Preparation 04 was not started. No source, configuration, scientific input,
accepted artifact, production script, or test was edited during this order.

## Dispatch and immediate preflight

The identities checked immediately before execution matched the dispatch:

| File | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/03_reference_profiles.qmd` | `a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a` | 43,231 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| `tests/test_preparation03_report.R` | `28f8f68e87d391faa6c45269dfc267165fa0cd3299e95603c11f220fba120841` | 9,352 |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` | 31,435 |
| `artifacts/12_manifests/reference_profile_artifacts.csv` | `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062` | 9,132 |

The historical 39-path baseline was preserved unchanged at
`audit/preparation_reports/preparation03_final_profile_prerender_scoped_readset.csv`.
Its comparison with the current checkout found 30 unchanged paths and nine
reporting-era identity changes. The nine current identities were the released
page source and profile configuration plus the current finding register,
shared reporting decisions, H02 presentation exemplar, and comparison
contract. The reconciliation is stored in
`report017_preparation03_readset_reconciliation.csv`. Every stored
scientific/preparation artifact and every production script in the read set
was unchanged.

The refreshed 39-path baseline is
`report017_preparation03_prerender_scoped_readset.csv`. The immediate gate in
`report017_preparation03_immediate_prerender_verification.csv` passed 39 of 39
paths by size and SHA-256.

## Bounded-execution audit

Static inspection found 13 executable R chunks: one setup/read-and-check
chunk, 11 native `gt` table chunks, and one descriptive figure chunk that
reads the stored reference-profile CSV. The page also contains one Mermaid
overview, which is rendered by Quarto and does not execute R.

No executable chunk calls a preparation builder, the scientific reference-
profile verifier, profile learning or reconstruction, a model, prediction,
simulation, bootstrap, resampling routine, system command, source file, or
file-writing function. The setup chunk reads stored artifacts, checks their
identities and schemas, and forms lightweight reader-facing summaries.

The source keeps the version-specific qualification intact:

- the complete 394-of-394 reconstruction is assigned only to preceding
  manifest `c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`;
- the current manifest is
  `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`;
- current-manifest independent reconstruction remains open as FIND-043; and
- the incomplete provenance check is explicitly described as not being
  evidence that a current profile, metric, or downstream result is incorrect.

## Environment and sole render

Environment verification reported:

- Quarto 1.9.37 at `/usr/local/bin/quarto`;
- R 4.6.1, "Happy Hop";
- project root equal to this checkout;
- `renv` loaded through the normal project startup; and
- project library
  `renv/library/macos/R-4.6/aarch64-apple-darwin23`, followed by the existing
  user-owned `renv` sandbox cache.

Exactly one Quarto command was run:

```text
quarto render notebooks/preparation/03_reference_profiles.qmd --profile nathealth
```

It completed with exit status 0 in approximately 39.41 seconds and created
only the targeted page through the `nathealth` profile. The render log shows
all 29 document stages, including all 11 tables and the stored pooled-profile
figure.

## Rendered outputs and bounded build delta

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preparation/03_reference_profiles.html` | `262705d82ad3add77028492502f94b45d526424c25c1f5f3c8b4ac33b75b4c2c` | 358,781 |
| `_build/nathealth/notebooks/preparation/03_reference_profiles_files/figure-html/fig-pooled-reference-profiles-1.svg` | `b011c1ac17cc1cb05bfda58170371fa8c49813b277e0455f65373a60447a9923` | 147,638 |
| `_build/nathealth/search.json` | `8eda091bda3ab7feee55fecbc2748eee7f377b86e5a7b6fccf8e8400d2fd0ddb` | 1,547,072 |
| `_build/nathealth/sitemap.xml` | `be0016e64857e6a6c84a01eec8141b0ea447bbefad355aff2c0411e29c58868b` | 5,219 |

Before the render, the target HTML was 356,610 bytes with SHA-256
`aab4d78311fc1037975b70c65515d133182367c7da373ed5aae2c1440711d7e0`;
`search.json` was 1,535,458 bytes with SHA-256
`fedf8b394efb2fe499b8f05168b36e202e51ca023b8016577c53b93633b36e46`;
and `sitemap.xml` had SHA-256
`fb7d35e07c77e21ea3b231276fb89711e326ed49837f5d24654fe50d4936c5f8`.

Quarto touched the mtime of
`_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css`
without changing its 498,438 bytes or SHA-256
`b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`.
Its pre-render mtime `1786619001` was restored exactly.

Two H06_daily HTML files appeared concurrently outside the Preparation 03
read set and outside this render owner's scope. Their mtimes predated this
render. They are recorded as unrelated concurrent output, not as
Preparation 03 build products:

- `_build/nathealth/audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`;
- `_build/nathealth/notebooks/hypotheses/H06_daily.html`.

After the render, all 39 scoped read-set paths again passed exact size and
SHA-256 comparison. The result is stored in
`report017_preparation03_postrender_scoped_verification.csv`.

## Focused-test stop condition

The required command was run under R 4.6.1:

```text
/usr/local/bin/Rscript tests/test_preparation03_report.R _build/nathealth/notebooks/preparation/03_reference_profiles.html
```

It exited with status 1 and reported:

```text
Error: The open audit item lacks its non-discrepancy qualification.
Execution halted
```

The failure is an exact-string mismatch, not a loss of the required
qualification. The test requires the literal text
`This provenance gap is not evidence`. The accepted source instead says:

> The current files pass the identity and internal-consistency checks
> described below, but those checks do not independently reconstruct the
> scientific values. This incomplete provenance check is not evidence that a
> current profile, metric, or downstream result is incorrect.

The same sentence is present in the rendered HTML. The final callout also
keeps the 394-of-394 result on the preceding manifest and FIND-043 open for
the current manifest. Therefore, the scientific meaning required by PREP-002
is present, but the current focused test cannot pass against the accepted
source identity.

## Partial semantic audit before the stop

Read-only inspection before sealing the stop confirmed:

- the correct page title and top-level heading;
- exactly 11 native `gt` tables and 11 table source-note sections;
- a nonempty render-boundary callout;
- the stored pooled melEDI/illuminance SVG with a caption and substantive alt
  text;
- the paired link to `reference_profiles.csv`; and
- visible version-specific wording for both manifest identities and
  FIND-043.

The secure loopback visual QA was not started. This follows the order's
instruction to stop on an execution/test failure. No temporary server process
or loopback listener was created by this task, so teardown was not applicable.

## Required disposition

Independent acceptance needs a coordinator decision on the stale literal in
`tests/test_preparation03_report.R`. A narrowly authorized test repair could
accept the current sentence while preserving the same PREP-002 meaning. Until
then, desktop and 708-pixel loopback visual QA remain unexecuted and
Preparation 04 remains held.
