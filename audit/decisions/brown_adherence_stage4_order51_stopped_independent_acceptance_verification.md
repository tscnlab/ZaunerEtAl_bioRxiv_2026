# Brown Stage 4 order 51 stopped-state verification

Date: 2026-08-21

Command:

```text
BROWN_WORKTREE=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 Rscript --vanilla scripts/report_harmonization/check_brown_stage4_order51_stopped_acceptance.R
```

Result:

```text
BROWN_ORDER51_STOPPED_ACCEPTANCE=PASS central=9/9 owner_manifest=45/45 finalization=24/24 protected=1644/1644 endpoints=5/5 entries=exact knitr=39/39 render=failed_before_html owner_process=absent sass_cache=~/Library/Caches/quarto/sass/sass.kv R=4.6.1 digest=0.6.39
```

An independent elevated, read-only `ps -axo pid=,command=` check returned no
matching Brown Quarto, Pandoc, semantic-repair, or loopback process. Air 0.4.1
and R parsing pass for the checker.
