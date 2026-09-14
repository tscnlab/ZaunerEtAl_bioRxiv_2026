# H10 worker handoff

Date: 2026-08-12  
Branch: `rewrite/NH`  
Status: **CLOSED — METRIC-011 bounded L10 reseal complete**  
Resampling: **none**

## Gate and ownership record

The author approved H10 Stages 1–4, including the standalone reader report,
the analysis-preparation and provenance companion, and the core diagnostic
plots. The later METRIC-011 normalization reopened H10 only for primary
darkest-10-hour (L10) mean branches that consumed eight changed records and
for the complete 17-test BH families containing those branches.

H10 did not edit shared preparation, central ledgers, Quarto configuration,
manuscript files, another hypothesis, or `renv.lock`; it did not commit, push,
upload, or run a full-project render.

## Controlling inputs

| Input | SHA-256 |
|---|---|
| Primary metric manifest | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| Site/context manifest | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| Base-model manifest | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| Base input bundle | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |
| Near-eye participant-day context RDS | `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a` |
| Chest participant-day context RDS | `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057` |
| METRIC-011 decision | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| METRIC-011 evidence manifest | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |
| Controlling METRIC-010 decision | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
| Independent primary MDER audit | `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb` |
| State-support manifest | `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619` |
| Gap-preparation manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |

The complete H10 input audit contains 36 exact identities. The current
Preparation 06 model-ready layer, METRIC-010 MDER values, and METRIC-011 L10
normalization are independently verified. Complete independent reconstruction
of the exact current state-support classification remains open under
PREP-003/FIND-044. This is a provenance qualification, not evidence that the
stored data are incorrect. FIND-049/CHG-101 remains resolved.

## METRIC-011 boundary and implementation

Exactly eight primary L10 means changed from
`4.163336342344337e-17` lx to exact zero: three near-eye and five chest
participant-days. All eight occur in both the all-available and
placement-matched samples. No sample membership, demographic field, support
field, non-L10 scientific value, gap-timing-unaware L10 value, or MDER value
changed.

`scripts/hypotheses/H10/run_h10_metric011_update.R` refitted only:

- two primary all-available L10 bundles;
- four primary placement-matched L10 main models;
- four primary-side primary-versus-gap common-sample L10 main models;
- 36 primary L10 leave-one-site-out rows; and
- four primary L10 participant-deletion models.

The L10 slot was then reinserted into each complete affected 17-test BH family.
The update performed no bootstrap, simulation, or other resampling and did not
trigger the pilot-runtime gate.

## Identity, multiplicity, and result disposition

- All 15 frozen-component identity guards passed, including every non-target
  model bundle and frame, every MDER object, all sample objects, and all
  non-L10 or frozen-gap raw p-values.
- Forty-seven L10 raw p-values changed by at most `5.10e-13`; zero non-L10 raw
  p-values changed.
- Complete-family recalculation changed 162 adjusted values by at most
  `7.88e-13`. Of these, 128 were non-L10 BH-derived fields whose raw p-values
  remained exact. No raw or adjusted significance decision changed.
- All accepted METRIC-010 MDER outputs remained unchanged.

The current primary L10 main-effect results are:

| Placement | Association | Ratio (95% CI) | Raw p | BH-adjusted p | Exact fitted sample |
|---|---|---:|---:|---:|---:|
| Near eye (primary) | Age, per 10 years | 0.906 (0.821–1.000) | 0.043 | 0.147 | 141 participants; 816 participant-days/observations |
| Near eye (primary) | Female minus Male | 0.866 (0.721–1.039) | 0.109 | 0.266 | 141; 816 |
| Chest (complementary) | Age, per 10 years | 0.937 (0.861–1.020) | 0.124 | 0.234 | 154; 902 |
| Chest (complementary) | Female minus Male | 0.763 (0.648–0.897) | <0.001 | **0.016** | 154; 902 |

The separately labelled age-by-site and biological-sex-by-site L10 tests did
not meet their 17-metric BH rules. The broader accepted result is unchanged:
11 primary main associations and two chest age-by-site interactions meet their
separately labelled BH rules.

Primary placement-matched L10 models use 643 participant-days from 112
participants at each placement; the unchanged gap comparator uses 640/112.
Primary-versus-gap common L10 samples are 809/141 near eye and 894/154 at
chest in both scenarios. Participant-level paired/common IS and IV remain
unavailable and were not approximated.

## Diagnostics and visual verification

All four primary L10 additive models converged and remain **acceptable with
specified limitations**; the specified limitation is residual-spread review.
No diagnostic classification, participant-influence disposition, or
leave-one-site-out conclusion changed. Across all 68 primary additive models,
25 remain acceptable, 43 acceptable with specified limitations, and zero not
acceptable for inference.

The Stage 2 audit rendered 69/69 operations, the reader report 47/47, and the
preparation companion 49/49 under R 4.6.1 and the project library. The eight
reader figures, two preparation figures, and all four L10 pages (5, 22, 39,
and 56) in the 68-page diagnostic appendix passed native-size raster/PDF
inspection for clipping, overlap, distortion, awkward wrapping, excess
whitespace, and essential-text readability.

Final render and diagnostic identities at closure:

| Artifact | SHA-256 |
|---|---|
| Stage 2 HTML | `8c26ac679abf649144911eb22b849f9c377a503a2674ed4771f29ffe996f04c4` |
| Reader HTML | `6bd3da932b7f743c2c28b2b5abe7a3772fc2ee6587c75f6fff1dca8910332c84` |
| Preparation HTML (standalone and integrated, identical) | `efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8` |
| 68-page diagnostic appendix | `4d68c4ce78e295bd7425179c3b40699ef9cb2cb3312d318cd7f9cdf15dddaa77` |
| Eight-page reader physical-size proof | `5f0aa286875e01b3f2685718f17a009a867bd9228aecd080b9bae4bf19dbd093` |
| Two-page preparation physical-size proof | `94b0203c09748b365d225cb571a1dffaa947d1b690937db29471523a70e085db` |

The Stage 2, reader-report, and strict preparation-companion regression suites
all pass. Reciprocal result/preparation links and coordinator-owned profile
adjacency remain intact. No shared integration edit is requested.

## Coordinator-owned ledger proposals

H10 did not edit a central ledger. Proposed entries are:

| Ledger | Proposed entry |
|---|---|
| Hypothesis gate | H10 Stages 1–4 accepted; METRIC-011 bounded L10 reseal complete on 2026-08-12. |
| Scientific package | Retain 11 adjusted main findings and two adjusted chest age-by-site interactions; the chest Female-minus-Male L10 association remains BH-significant. |
| METRIC-011 boundary | Record 8 primary L10 cells normalized to exact zero; 2 all-available bundles, 8 matched/common main models, 36 LOSO rows, and 4 deletion models selectively refitted; no resampling. |
| Identity audit | Record 15/15 frozen guards PASS; 0 non-L10 raw-p changes, 0 MDER changes, and 0 significance-decision changes. |
| Provenance | Current base, METRIC-010, METRIC-011, and repaired gap inputs independently verified; retain PREP-003/FIND-044 only for complete state-support reconstruction. |
| Diagnostics | Record 25 acceptable, 43 acceptable with specified limitations, zero not acceptable; all four primary L10 models remain acceptable with specified limitations. |
| Integration | Retain coordinator-owned results/companion adjacency and reciprocal links; targeted renders and strict H10 tests pass. |
