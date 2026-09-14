# Brown adherence Stage 4 order 51 environment-retry verification

Date: 2026-08-21

Independent checker:

`scripts/report_harmonization/check_brown_stage4_order51_environment_retry_acceptance.R`

Execution:

```text
BROWN_WORKTREE=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 Rscript --vanilla scripts/report_harmonization/check_brown_stage4_order51_environment_retry_acceptance.R
```

Result:

```text
BROWN_ORDER51_ENVIRONMENT_RETRY_ACCEPTANCE=PASS authority=19/19 owner_manifest=70/70 finalization=22/22 protected=1644/1644 tables=17 headers=683 idrefs=800 semantic=100+552 reverse=exact cache=25/25 visual=21/21 scrollers=17/17 R=4.6.1 digest=0.6.39 xml2=1.6.0
```

Additional checks:

- Air 0.4.1 format check: PASS.
- R 4.6.1 parse: PASS.
- Scoped `git diff --check`: PASS.
- Manual inspection of the native main, native exploratory, 390-pixel main, and 390-pixel exploratory full-page captures: PASS with no new clipping, overlap, or missing-content finding.
- Elevated process check: no surviving relevant process.
- `lsof -nP -iTCP:56207 -sTCP:LISTEN`: no listener.
