# REPORT-018 order 57c: H09 environment process probe and companion retry

Date: 2026-08-22

Owner: H09 owner `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: sealed for one environment-only pre-render recovery and exactly one
H09 companion render. The H09 result and every later REPORT-018 target remain
held.

## Authority and disposition

The controlling independent acceptance is
`audit/report_harmonization/report018_h09_order57b_environment_stop_independent_acceptance.md`.
Its SHA-256 is
`1285402d9b1a18a4c4c6d7e96884bee077d66c309d21b686381b92aa7f744749`,
5,205 bytes.
It accepts order 57b as an environment-only stop at a read-only process probe.
The complete source and downstream gate had already passed up to that probe,
and the render allowance remains unconsumed.

This order continues order 57b. It does not reopen or repeat its source
classification. Preserve the complete order-57, order-57a, and retained
order-57b evidence byte-for-byte. Preserve the current H09 companion QMD
postimage without editing, formatting, reconstructing, or reapplying it.

## Required preflight identities

Before any execution, require all of the following exact identities:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `audit/hypotheses/H09/H09_analysis_preparation.qmd` | `394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f` | 51,736 |
| `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html` | `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05` | 593,181 |
| `notebooks/hypotheses/H09.qmd` | `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6` | 36,970 |
| `_build/nathealth/notebooks/hypotheses/H09.html` | `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16` | 244,127 |
| `artifacts/12_manifests/H09/H09_stage3_artifacts.csv` | `0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2` | 24,678 |
| `scripts/hypotheses/H09/h09_contract.R` | `866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701` | 16,374 |
| `artifacts/06_model_data/H09/H09_input_audit.csv` | `1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed` | 4,401 |
| `scripts/hypotheses/H09/build_h09_preparation_report_manifest.R` | `c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56` | 9,753 |
| `tests/hypotheses/H09/test_h09_preparation_report.R` | `9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7` | 12,824 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` | 603,493 |

Also require the exact owner order-57b stop identities:

- `/private/tmp/h09-order57b-working.J2KttI/ORDER57B_FAIL_CLOSED.md`,
  SHA-256 `4e745700f8939559bb04bdc9cf2cede0439d779361e4904c39c9e260c260b33c`,
  5,555 bytes;
- `/private/tmp/h09-order57b-working.J2KttI/verify_order57b_h09_companion.R`,
  SHA-256 `a6c418c70216227dd335e7de850c119db13f7bfda7f0340f88c7d81f0ecc99fa`,
  37,584 bytes; and
- `/private/tmp/h09-order57b-working.J2KttI/order57b_fail_closed_evidence_manifest.csv`,
  SHA-256 `3d310e931c7210adfa7ea0717b4398b40894e41d2177e349d5f133614ae4d10b`,
  11,610 bytes, with 42 of 42 members exact, unique, and non-circular.

Require the independent environment-stop checker to pass exactly before the
owner verifier is run. Do not proceed if a pin drifts or the retained owner
evidence is absent.

## Sole environment recovery

Create one fresh working and evidence directory under `/private/tmp`. Copy the
exact retained order-57b verifier into that temporary directory without
changing it. Run it exactly once in pre-render mode under R 4.6.1, the
accepted project library, and narrowly elevated read-only access sufficient
only for its existing `/bin/ps -Ao pid=,command=` inventory.

Use the exact environment and arguments:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
ORDER57B_WORKING_DIR=<fresh-absolute-directory> \
ORDER57B_EVIDENCE_DIR=<same-fresh-absolute-directory> \
ORDER57B_MODE=pre \
Rscript --vanilla <fresh-absolute-directory>/verify_order57b_h09_companion.R
```

The verifier must report the complete accepted PASS:

```text
REPORT018_H09_ORDER57B_PRE=PASS dispatch=36/36 stop=58/58+17/17 stage3=87+19 chunks=22 later=3 endpoints=19/1/1 links=23/22 helper=554 semantic=19/102/588/690 protected=545/545 support=16/16 R=4.6.1
```

Require zero competing H09, Quarto, Pandoc, helper, semantic, or loopback
process. The process probe is read-only. It must not terminate a process,
change a cache, or change a project file. This is the only authorized owner
pre-render verifier execution under order 57c. If it fails for any reason,
stop once and seal without a render.

## Exactly one companion render

Only after the complete pre-render gate passes, create one fresh, empty,
absolute semantic-audit directory under `/private/tmp`. From the project root,
run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-semantic-directory> \
quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the accepted library, the normal profile, the
accepted semantic hook, and the established narrow access to existing
user-owned caches. Do not alter `HOME`, bypass the profile, use
`--no-execute`, install or restore a package, redirect or reset a cache,
rerender the H09 result, or render any other target. If startup or rendering
fails, stop once and seal. No second retry is authorized.

## Dedicated helper and post-render completion

If and only if the render and semantic hook succeed, execute exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
```

Keep all order-57c working evidence outside the project until the helper has
finished. The helper may synchronize only the source-identical build companion
QMD and write the current H09 preparation manifest. Require exactly 555
unique, live-exact, non-circular rows: the accepted 554-member pre-render
inventory plus the one target-generated companion figure. The manifest must
exclude itself. Do not run a broad builder or run the helper twice.

After the helper, create one durable completion directory at
`audit/hypotheses/H09/report018_order57c_companion_retry/`. Run the unchanged
order-57b verifier in post-render mode once against the retained external
semantic evidence and require the complete post-render contract already
specified by order 57b:

- render exit zero and exactly one order-57c render invocation;
- exactly 19 native `gt` tables, one figure, one top-down Mermaid, and the
  accepted source order;
- exact reversible semantic repair of all 19 tables, unique document IDs, and
  every `headers` token resolving to exactly one intended `th` in its table;
- exact source, formula, sample, endpoint, caption, note, diagnostic,
  sensitivity, provenance, dynamic-link, reciprocal-navigation, deviation,
  country-label, and privacy contracts;
- the final 555-row preparation manifest wholly live-exact;
- the accepted H09 result source and HTML, all science and source data,
  historical evidence, tests, helper, profile, hook, lockfile, and unrelated
  paths exact; and
- every build delta target-owned, source-identical, or an expected search or
  sitemap update.

If the target-generated sample-support PNG changes, apply the exact frozen
input, geometry, visible-content, label, colour, and at-least-7-point
final-size contract from order 57b. Record the transition only in order-57c
evidence. Do not edit a historical manifest or promote a durable display.

## Secure loopback QA and return

After all nonvisual gates pass, serve `_build/nathealth` through one read-only
server bound only to `127.0.0.1`. Inspect the H09 companion at 1440 by 1000,
708 by 1000, and 720 by 500, plus the figure at 170 mm. Inspect all 19 tables,
the figure, Mermaid, headings, callouts, captions, notes, links, navigation,
disclosures, narrow scrollers, and final provenance.

Require no page overflow, clipping, overlap, missing content, broken
interaction, or report-attributable console warning or error. Close the QA
surface, reset the viewport, stop the server, prove no listener remains, and
require post-QA build and protected inventories to match post-render exactly.

Return one completion record and one unique non-circular evidence manifest,
or one consolidated fail-closed record. Retain external semantic and working
evidence until independent acceptance.

No source re-edit, test edit, historical-manifest rewrite, broad manifest
builder, result render, model or scientific execution, estimate or inference
change, scientific artifact or source-data change, profile, ledger, package,
lockfile, later target, second retry, commit, push, upload, or publication
action is authorized. The mandatory next stop is independent H09 companion
acceptance.
