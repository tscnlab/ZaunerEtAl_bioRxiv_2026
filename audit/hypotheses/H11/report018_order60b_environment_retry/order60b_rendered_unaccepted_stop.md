# REPORT-018 H11 Order 60b rendered-but-unaccepted stop

Date: 2026-08-22

Disposition: `FAIL_CLOSED_AFTER_RENDER_CHECKER`

## Outcome

Both mandatory pre-render gates passed. The single authorized environment
retry was then consumed exactly once and rendered the unchanged H11 result
target successfully. The configured semantic hook completed. The mandatory
unchanged post-render checker was invoked once and failed while running its
temporary Stage 3 transition-aware test. Order 60b therefore stopped before
secure-loopback browser QA.

No checker retry, test execution, source or test patch, second render, cache
workaround, loopback server, browser QA, companion render, or sensitivity
execution occurred.

## Passed gates

- Order 60b dispatch: 33/33 exact, unique, and non-circular in R 4.6.1.
- Independent Order 60a stop seal: 23/23 exact, unique, and non-circular.
- Corrected transition-aware checker: PASS 8/8.
- Complete unchanged H11 preflight checker: PASS 13/13.
- Pre-render build: 1,180 entries and zero symlinks.
- Pre-render protected state: 335 historical identities plus the sealed
  coordination-matrix transition, 336 current paths in total.
- Existing Sass database: accepted identity, schema-1 provenance, user
  ownership, and no WAL or SHM file.
- No competing H11, Quarto, Pandoc, semantic-hook, or loopback process.

## Sole render

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/report018-h11-order60b-semantic.tVg7A2 \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
quarto render notebooks/hypotheses/H11.qmd --profile nathealth
```

- Exit status: 0.
- Observed wall time: 12.20004625 seconds.
- Knitr cells: 53 of 53 completed.
- Semantic disposition: `REPAIRED`.
- Native tables: 15.
- Semantic IDs: 146.
- Header references: 229.
- Substitutions: 375.
- Accepted post-hook HTML SHA-256:
  `2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a`.

## Post-render checker failure

The unchanged checker was invoked exactly once with
`H11_RESULT_PHASE=postrender`. It exited 1 because its temporary
`h11-stage3-transition-aware` test returned status 1. It stopped before
writing the final combined post-render audit CSV.

A single bounded read-only predicate inspection, without rerunning the test,
found three exact historical strings absent from the fresh HTML:

1. `Gender is a distinct construct`;
2. `pointwise 95% intervals`;
3. `0.050214`.

All eight reader images and their alt text were present, 23 figure captions
were present, forbidden historical terms were absent, and the historical
p-value display predicates passed. The same test had passed against the stale
pre-render HTML. The failure therefore reflects a fresh rendered-source versus
historical-test contract mismatch. Neither source nor test was changed.

## Exact stopped state

- The only build changes are the authorized result HTML, `search.json`, and
  `sitemap.xml`; no build path was added or removed.
- All 336 protected files remain exact.
- All 193 scientific assets remain protected and unchanged.
- The complete 25-file Sass-cache inventory is byte-identical before and
  after rendering. No cache content was copied into the project.
- The semantic summary and ledger are preserved in this evidence directory.
- The held companion, profile, lockfile, handoff, tests, historical manifests,
  helper, sensitivity source, and sensitivity HTML remain unchanged.
- Zero build symlinks and zero related processes remain.
- No loopback server was started, so no listener or browser surface existed.

The newly rendered H11 result page is not accepted because the required
post-render checker did not pass. This record does not authorize another
render or a source/test repair. Independent review and a new sealed order are
required. H11 companion and sensitivity remain held.
