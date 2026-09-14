# Brown adherence BA-014 Stage 3 implementation verification

Date: 2026-08-20  
Status: independently verified at `BA-CS-G3-INTEGRATED-REVIEW`; author approval pending  
Transition effect: none

## Disposition

The `BA-014` / `CHG-153` implementation is independently verified as a
complete stored-output display amendment. The amendment remains at the
mandatory `BA-CS-G3-INTEGRATED-REVIEW` author stop. This verification does not
accept Stage 3 scientifically, authorize Stage 4, authorize writer
notification, or append a new decision or change-log row.

The exact required author wording remains:

> Approve Brown cross-state integrated Stage 3 as written.

Until that wording is supplied, the decision register remains closed at
`BA-014` and the change log remains closed at `CHG-153` for this analysis.

## Independently verified endpoints

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 51,128 | `05e1ae2b8dd5dea5d2230f97fe8c178556588d0144899e64e368cb6754a7e042` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 4,772,760 | `6b2ead4747c72a793dec4912af8112b5e605682f7e2544ea9006a867b22dcf0a` |
| `workday_site_and_coverage_guides_amendment/final_manifest.csv` | 49,776 | `e54b2ebfcbacefe07d7b17f213c485dec5fb77eea0263fcd759b2f112db8a842` |
| `workday_site_and_coverage_guides_amendment/stage3_amendment_handoff.md` | 1,910 | `06554d6c065915f4683d5894e687b40526b35e36a00c8fa916699a8d472458d0` |
| `workday_site_and_coverage_guides_amendment/renewed_integrated_author_gate.csv` | 1,043 | `5862614f2d2cffc782eb1fee874d7d36d21033a35b9181ee78e0decd27988a26` |

Paths beginning with `workday_site_and_coverage_guides_amendment/` are
relative to
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.

The renewed gate contains exactly one row with status
`pending_explicit_author_approval`. It pins the current QMD, HTML, paired
sources, and four display artifacts. It also records Stage 4 and writer
notification as blocked.

## Independent R verification

The durable checker is:

`scripts/report_harmonization/check_brown_ba014_stage3_package.R`

SHA-256: `a886aa75569b6d2e4b14d7d5b75251ce546cd3fe6cf9db6ab4553a4b8b4c62a7`

It was parsed and executed under R 4.6.1 with:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_ba014_stage3_package.R /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

The independent run verified:

1. all 86 final-manifest paths, byte counts, and SHA-256 identities are exact,
   unique, and non-circular;
2. every manifest row remains controlled by
   `BA-CS-G3-INTEGRATED-REVIEW` and pending explicit author review;
3. the Work-day paired source reconciles exactly to all 27 frozen primary
   any-valid Work-day site rows, with three states, nine country-coded sites,
   three equal-site references, and seven unchanged stored FDR localizations;
4. every plotted adherence estimate and interval, equal-site reference,
   site-minus-equal-site contrast, adjusted p-value, and significance flag
   matches the frozen compact source after only the authorized percentage
   conversion and keyed join;
5. the six-row coverage source is byte-identical to its frozen Stage 3 source
   and retains three states, two samples, and all six finite stored estimates
   and intervals;
6. both Quarto figure endpoints occur exactly once in the source and rendered
   HTML;
7. all 109 protected historical members remain exact, while the 111-member
   transition record contains exactly the two authorized QMD and HTML endpoint
   transitions;
8. the stored check sets pass at source 16 of 16, render 28 of 28, native visual
   QA 24 of 24, and finalization 17 of 17; and
9. the sole render record is attempt one of one under R 4.6.1 and Quarto
   1.9.37, with exit status zero and no attempt remaining.

## Display inspection

The current PNGs were inspected independently at their native sizes:

| Display | SHA-256 | Independent observation |
|---|---|---|
| Work-day site adherence PNG | `c0b68cfefb7e5b4686ed1849c0ed9a11c950abfcd677321d8037958aeab718a5` | three complete panels, all 27 intervals, country-coded sites, distinct equal-site lines, seven redundant diamond emphases, readable legend and qualification |
| Work-day site adherence SVG | `23d2953af30adf6321af56da031a4a158e4f700a9d3de0167bfa03d3eeba7c92` | identity and paired-source contract exact |
| Coverage-guides PNG | `64e81f96b1ec04d54dfdaf59b819a110dfd0ccf08c4538dcd54daf6334700643` | all six intervals retained, vertical tick guides visible, dashed zero line distinct, labels and legend readable |
| Coverage-guides SVG | `ad18eca0aa3d1bd05b845ae4b1cfd4d2756a17aa205fb8de4c6a11a3de7ced67` | identity and paired-source contract exact |

The served-page screenshots for the Work-day figure context and coverage
figure context were also inspected. The figures, explanatory prose, captions,
and source links are visible without clipping or overlap at the recorded
native viewport. This verification accepts the recorded `BA-013` bounded
viewport method and does not claim an independently emulated mobile viewport.

The recorded loopback endpoint `127.0.0.1:49783` was checked after completion
and had no listener.

## Central authority preservation

The controlling central authority remains exact:

| Artifact | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_cross_state_stage3_workday_site_and_coverage_guides_display_amendment.md` | `f532e6614f2ecb6ed64196d1239d77fa4ffd16a718039c100154c73d05bfef64` |
| `audit/decisions/brown_adherence_cross_state_stage3_workday_site_and_coverage_guides_display_amendment_manifest.csv` | `a045a7162c12af8a580b21643aeec7be5c57fbf19427a3d608493457fd87522a` |
| `audit/ledgers/decision_register.csv` after `BA-014` | `d89d551bf555696c34d90c3eb39486fafbe35c9bdbb072f7ca30fe16125f4e2d` |
| `audit/ledgers/change_log.csv` after `CHG-153` | `56d45faf1b5ee6b3666afafea5ac9ff6a5cdcbbd1b8d6e4acb6822e575ac8b6b` |

No ledger was edited by this verification. No source, display, HTML, model,
scientific artifact, package, lockfile, or prior evidence file was changed or
rendered.

## Mandatory next action

Hold the analysis at `BA-CS-G3-INTEGRATED-REVIEW`. Record no Stage 3
acceptance, Stage 4 transition, shared integration, or writer notification
until the author supplies the exact required wording. If the author instead
requests another scientific or display change, reopen prospectively under a
new central authority before any edit or render.
