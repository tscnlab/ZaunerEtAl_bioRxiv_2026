# REPORT-018 H11 Order 60 fail-closed record

Date: 2026-08-22

Status: `FAIL_CLOSED_RENDER_NOT_ACCEPTED`

## Disposition

The single authorized H11 result render was attempted exactly once and exited
with status 1. Knitr completed all 53 cells and emitted its intermediate
Markdown. Quarto then failed during Sass cache resolution with:

```text
ERROR: unable to open database file
```

No accepted HTML target was produced, and the configured post-render semantic
hook did not execute. Order 60 prohibits a retry, repair, alternate cache,
helper, test edit, source patch, or second render. Work therefore stopped at
the render gate.

## Reproduced release gate

- Controlling order SHA-256:
  `9b7d6ae3d61c8c30382b8de8f4a9c42ee76150a99cfaa454b2adc89abdf67efa`.
- Dispatch manifest: 30 of 30 rows exact, unique, and non-circular in R 4.6.1.
- Complete preflight manifest: 28 of 28 rows exact, unique, and non-circular
  in R 4.6.1.
- Durable preflight checker: PASS on all 13 checks.
- Build preflight: 1,180 entries and zero symlinks.
- Process preflight: no competing H11, Quarto, Pandoc, semantic-hook, or
  loopback process.

## Sole render execution

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/report018-h11-order60.ZzzcSx/semantic \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render notebooks/hypotheses/H11.qmd --profile nathealth
```

- R: 4.6.1.
- Quarto: 1.9.37.
- Engine: knitr 1.51.
- Exit status: 1.
- Observed wall time: 8.433351 seconds.
- Last completed stage: all 53 knitr cells and `H11.knit.md` emission.
- Failure stage: Quarto Sass cache database open during Sass bundle resolution.

## Exact stopped state

- The complete pre-render and post-failure build inventories are
  byte-identical, each with SHA-256
  `b899d8f7267f931958b090be9c924a1b0656ea776e51321a93dce8931e9dad8e`.
- All 336 protected files are byte-exact. This includes all 193 H11 scientific
  assets and all 34 source-identical H11 build resources.
- The H11 result HTML remains the sealed stale endpoint with SHA-256
  `c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7`.
- The external semantic directory is empty. No summary, ledger, or reversible
  semantic transformation exists for this failed attempt.
- The result and companion QMDs, held companion HTML, profile, lockfile,
  handoff, tests, manifests, helper, sensitivity source, sensitivity HTML, and
  scientific artifacts remain unchanged.
- No H11, Quarto, Pandoc, semantic-hook, or loopback process remains.

## Verification and QA boundary

The durable post-render checker was not run because its required accepted HTML
and semantic summary do not exist. Secure-loopback browser QA was not started,
no port was allocated, and no screenshots were taken. The H11 companion and
sensitivity battery remained held and untouched.

This record does not authorize another render. A new sealed coordinator order
is required for any recovery attempt.
