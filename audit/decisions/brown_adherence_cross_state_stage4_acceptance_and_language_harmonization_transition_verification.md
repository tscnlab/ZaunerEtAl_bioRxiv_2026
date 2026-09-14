# Brown adherence cross-state Stage 4 acceptance transition verification

Date: 2026-08-21

Status: **PASS**

## Command and environment

The durable read-only checker is:

`scripts/report_harmonization/check_brown_stage4_author_acceptance_and_harmonization_transition.R`

SHA-256:
`e5de07bff0a74ad5fbfd80607a6a3349dc83a5478bc34e3b9e624c3fa97d2d23`

It was Air-formatted, parsed, and executed under R 4.6.1 with:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_author_acceptance_and_harmonization_transition.R /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

No project profile, Quarto render, browser server, model package, scientific
calculation, or file mutation occurred during verification.

## Reproduced output

```text
BROWN_STAGE4_AUTHOR_ACCEPTANCE=PASS stage4_manifest=113/113 BA-016=unique CHG-155=unique writer=authorized harmonization=sealed_and_held
```

The checker independently reproduced:

- the unique `BA-016` decision row and `CHG-155` change row;
- the central Stage 3 acceptance and Stage 4 transition record, verification,
  and manifest;
- the central Stage 4 semantic-repair acceptance, verification, and manifest;
- the exact Stage 3 and Stage 4 QMD and HTML identities;
- the Stage 4 manifest, manifest verification, handoff, open-gate evidence,
  and `renv.lock` identities; and
- all 113 Stage 4 final-manifest members by unique path, SHA-256, and byte
  count, with no circular member.

The author supplied the exact gate sentence recorded in the controlling
transition. `BA-CS-G4-REVIEW` is therefore closed. The Nature Health
provenance-only follow-up is authorized. The paired Stage 3 and Stage 4
source-language package is authorized but remains held behind H06_daily order
48b until the serial safe point.
