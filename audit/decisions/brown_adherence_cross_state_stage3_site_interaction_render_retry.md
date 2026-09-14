# Brown adherence Stage 3 site-interaction render retry

Decision ID: `BA-012`  
Change ID: `CHG-151`  
Date: 2026-08-20  
Status: coordinator authorized; one environment-recovery render attempt only

## Decision

The single render authorized by `BA-011` and `CHG-150` did not reach Quarto
document execution. After approximately 24.5 minutes, the live R child was
still inside project-profile loading and recursive directory creation during
`renv` activation. A stack sample placed all 1,425 samples in
`R_LoadProfile`, with 1,330 samples below `dir.create` or `mkdir`. The process
was interrupted fail closed, all recorded child processes were confirmed
absent, and the historical HTML remained byte-identical.

This is an environment-access failure before QMD execution. It is not a
scientific discrepancy, a failed reader render, or a defect in the accepted
site-interaction source and display amendment. `BA-012` and `CHG-151`
therefore authorize exactly one narrowly escalated replacement render using
the established existing author-owned `renv` library and cache access. They
do not authorize a source revision, display rebuild, package installation,
lockfile change, model execution, or any further retry.

The mandatory author stop remains `BA-CS-G3-INTEGRATED-REVIEW`. Stage 4,
writer notification, shared integration, manuscript edits, commit, push,
upload, and every other Brown analysis remain blocked.

## Controlling authority and failed-attempt evidence

| Artifact | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_display_amendment.md` | `cd7eab89e4462af4d615ad099e84785aaf1e07acd31c25f4ac91cec99d9314c6` |
| `audit/decisions/brown_adherence_cross_state_stage3_site_interaction_display_amendment_manifest.csv` | `d9fde022565b4c6e500aff20e4f25c9ff77bd38399f61ead3f0fb7b1e775b5de` |
| `audit/ledgers/decision_register.csv` after `BA-011` | `2575425c666af4d2ab7f56da92a8ffad02a15200ab4e6b5f405759bf31d3f3ca` |
| `audit/ledgers/change_log.csv` after `CHG-150` | `df08f07f4244725d5c22dbde16e22b54d65e0032620c3660e54280fe1eb8bcf0` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_interaction_display_amendment/site_interaction_fail_closed_manifest.csv` | `b57f7b0bbe8f30448d9c3ef1cbefc401ef8af81a9ba3151d1352fcbffa85db9b` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_interaction_display_amendment/site_interaction_stage3_handoff.md` | `7eb5b642130eed5a4cc3cb087c412f956bb995a8cdc9e37220a4886f75e2d180` |

The continuing task must verify the fail-closed manifest at 40 of 40 exact,
unique, non-circular members before starting the replacement attempt. It must
also confirm that the first render's recorded processes are absent and that
no loopback listener remains.

## Frozen replacement-render inputs

The following identities are immutable for this retry:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 49,315 | `ef6ed62690afa30fe2801e559b487462a11c4130e903e3725bb164554bed191a` |
| historical `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 3,893,719 | `ce7ac00d380a405f55a116c3aabc73cc9ba95eb487ee446eb616b76fcff2b468` |
| `site_interaction_display_amendment/source_data/main_site_free_work_forest_source.csv` | 3,423 | `06883e6c5a345c98b6834ac547122b006c7fdbe865a80704c3b4d65076585692` |
| `site_interaction_display_amendment/figures/main_site_free_work_forest.png` | 324,853 | `201f199480acfc9f2ab56f0cee304565a4d95cf2977f680b7116597c42ef6b23` |
| `site_interaction_display_amendment/figures/main_site_free_work_forest.svg` | 30,013 | `6ab907d9d0dd282970492866b25e05625f0a4b640d83623ddaeebb2f8ee90c54` |

Paths beginning with `site_interaction_display_amendment/` are relative to
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.

The stored display build must remain 10 of 10 passed and the source gate must
remain 26 of 26 passed. The paired source must remain exactly 27
`primary_any_valid` state by site rows, with three states, nine country-coded
sites per state, and exactly five accepted FDR localizations. The PNG must
remain 2,640 by 3,360 pixels. The QMD, paired source, PNG, SVG, and every
scientific or historical input must remain byte-identical before and after
the replacement render.

## Exact one-attempt command

Run from:

`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`

Execute exactly once:

```sh
RENV_PATHS_LIBRARY='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library' \
BROWN_ADHERENCE_PROJECT_ROOT='/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026' \
BROWN_ADHERENCE_AUTHOR_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile, and only the narrow
elevated access needed for the existing author-owned `renv` library and cache.
Do not disable profile loading or `renv` activation. Do not set an alternate
temporary library, install or update a package, modify `renv.lock`, run
`renv::restore()`, or render any other target.

The render may replace only the targeted HTML and ordinary target-owned
render intermediates. It may not modify the QMD, paired source, PNG, SVG,
frozen inputs, prior fail-closed evidence, central authority, or any other
scientific artifact.

## Required replacement verification and QA

After a successful render, complete the verification and QA already required
by `BA-011`, without reopening content or recalculating results:

1. rerun the complete source and HTML contracts for the integrated report;
2. verify the new forest plot from the frozen paired source, including 27
   estimates, 27 confidence intervals, three zero lines, three equal-site
   reference lines, nine sites per panel, and exactly five emphasized
   contrasts;
3. verify native `gt` tables, cross-references, links, privacy, accessible
   labels, absence of embedded errors, and all protected identities;
4. inspect the exported PNG at its intended size and the complete reader page
   through one secure `127.0.0.1` loopback server at 1440 by 1000 and 390 by
   844, including the figure, caption, source link, surrounding tables, and
   complete page flow;
5. prove complete server teardown, no remaining listener, and post-QA
   identity stability; and
6. seal one non-circular final manifest, updated handoff, final checks,
   render record, visual-QA record, and renewed
   `BA-CS-G3-INTEGRATED-REVIEW` author gate inside the existing amendment
   directory.

The replacement evidence must record the exact command, working directory,
R and Quarto versions, library path, start and end times, exit status, target
HTML pre- and post-identities, and confirmation that this was the sole
`BA-012` attempt.

Stop and return one sealed failed state on any unexplained identity change,
startup failure, QMD execution failure, render error, scientific
recalculation, missing contrast, broken link, privacy issue, material
semantic or visual defect, or incomplete teardown. No additional render
attempt is authorized.

## Mandatory author stop

The mandatory stop remains `BA-CS-G3-INTEGRATED-REVIEW`. The required author
decision remains:

> Approve Brown cross-state integrated Stage 3 as written.

Stage 4 and notification of manuscript task
`019ffb39-372e-7262-bfac-192751fd0e63` remain blocked until that explicit
approval.
