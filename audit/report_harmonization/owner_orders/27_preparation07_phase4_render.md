# REPORT-017 order 27: Preparation 07 target render and visual QA

Date: 2026-08-14  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/07_example_days.qmd`  
Scope: one normal-profile target render and bounded secure-loopback QA

## Authority and accepted pins

The central coordinator released exactly one Preparation 07 target render
after independent source/test acceptance. Reproduce all pins immediately
before execution and stop on drift:

| File | Required SHA-256 |
|---|---|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| `tests/test_preparation07_report.R` | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| independent acceptance record | `3708afb4f5600b6c021a93579179a5bf164f5d7b7bcfca0a0c26d1f6b52ca7ce` |
| independent acceptance manifest | `96481a17ec91de252cbca671cb876466529ace7f8df747b462634985c634c164` |
| sealed equivalence audit | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| sealed equivalence evidence | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| sealed equivalence manifest | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |
| current stale target HTML | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |

The accepted source-only focused test must pass under R 4.6.1 before the
render. Reconcile the current Preparation 07 protected set and record a fresh
scoped `_build/nathealth` inventory. Preflight that build root for symlinks and
stop if any symlink resolves outside it.

## Sole render command

Run exactly:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

Use Quarto 1.9.37 and the normal project R 4.6.1 profile. Use the established
narrowly elevated permission only for transient writes to the existing
user-owned renv cache. Do not bypass `.Rprofile` or `renv/activate.R`.

Do not run another target, a full-project render, a second attempt without a
new stop disposition, a scientific verifier, a preparation builder, a model,
prediction, bootstrap, simulation, or Shapley computation. Do not install or
update a package or edit `renv.lock`.

## Scientific and artifact preservation

The render may read stored display inputs, perform the bounded identity/schema
checks in the accepted QMD, calculate lightweight display summaries, and draw
the three HTML figures from the frozen source-data CSV. It must not recreate
the fixed selection or regenerate a durable artifact.

Prove byte identity for at least:

- the historical showcase manifest and strict verifier;
- current site/daylight RDS and CSV;
- selected days, eligible counts, and selection settings;
- paired figure source-data CSV;
- durable showcase PNG and SVG;
- sealed equivalence audit/evidence/manifest;
- accepted QMD, focused test, profile, and `renv.lock`; and
- every other member of the accepted Preparation 07 protected set.

Stop on any protected drift, scientific discrepancy, missing file, execution
error, or need to change source/test/configuration.

## Source, HTML, and semantic checks

After the sole render, require all of the following:

1. the QMD, focused test, and profile retain their accepted hashes;
2. `Rscript tests/test_preparation07_report.R` passes against the new target
   HTML under R 4.6.1;
3. the HTML contains exactly seven native `gt` tables with one Quarto-owned
   caption each and no prohibited terminal table renderer;
4. the HTML contains all three example-day figure endpoints with captions and
   alt text, plus the existing Mermaid overview;
5. the approved reader explanation and the plain label
   `Equivalent values, different file version` appear correctly;
6. both manifest-recorded and current site/daylight hashes render in the
   technical provenance table without being presented as equal file
   identities;
7. all nine site names include their country codes and retain submitted order
   and colours;
8. the paired figure source-data link resolves, as do navigation and all
   other internal links;
9. there is no internal hard-coded `.html` source link, unresolved QMD target,
   empty link label, visible machine status code, raw tibble, warning, error,
   or failed cross-reference; and
10. the no-hypothesis-analysis-handoff statement and display-only hierarchy
    remain clear.

Record the exact target HTML hash and byte size. Constrain final build deltas
to the expected target HTML and normal Quarto search/sitemap bookkeeping.
Identify any byte-identical stylesheet mtime refresh and restore only that
mtime if the established REPORT-017 contract requires it. Do not alter build
content to make a check pass.

## Secure loopback visual QA

After all nonvisual checks pass, use the authorized `$quarto-authoring` local
inspection workflow:

1. start one temporary read-only static HTTP server with document root exactly
   `_build/nathealth`;
2. bind only to `127.0.0.1` on one unused high or OS-selected port;
3. expose no upload/write endpoint and use no public tunnel, LAN bind, Chrome,
   Computer Use, CDP, or raw browser command;
4. record command, PID, address, port, root, start time, and exact Preparation
   07 URL;
5. inspect only that route in the supported in-app Browser at 1,440 by 1,000
   and 708 by 1,000;
6. stop the server immediately after QA and prove that no listener remains;
   and
7. rehash source, test, config, target HTML, protected inputs, and scoped build
   inventory after teardown.

At both viewports inspect title, hierarchy, callout, prose wrapping, clipping,
overflow, link labels, figure captions/alt text, navigation, and all seven
tables. Native HTML tables must be reasonably usable at a typical desktop
screen size. At 708 pixels, contained working horizontal scrolling is
acceptable and preferable to unreadably compressed type.

Inspect all three HTML figures at their final display size for readable site,
participant, date, axis, state-band, and daylight-context labels; no clipping,
overlap, distortion, broken units, or indistinguishable marks; and consistent
site order. Confirm that the durable PNG and SVG remain byte-identical. There
is no exported table PNG endpoint on this page.

Measure the existing LR Mermaid labels at both viewports. Require at least
7 pt equivalent type and no clipping, overlap, or unusable horizontal
expansion. Stop and return a bounded display defect if the diagram fails. Do
not edit or rerender under this order.

## Evidence to return

Return one completion packet with:

- pre/post source, test, profile, target HTML, and protected-input hashes;
- Quarto/R versions, exact sole command, exit status, elapsed time, and any
  warnings;
- focused source/HTML test output;
- native-table, figure, provenance, link/navigation, country-code, semantic
  HTML, no-error, and build-delta results;
- desktop and narrow loopback screenshots or supported Browser evidence,
  measured Mermaid type, table overflow behavior, and figure final-size QA;
- server start and teardown evidence with no remaining listener;
- a durable verification record and non-circular manifest; and
- `git diff --check` plus proof that no unauthorized source, scientific,
  artifact, configuration, ledger, or lockfile change occurred.

Do not release a hypothesis render. Preparation 07 requires independent
acceptance after this return, and every hypothesis render remains held.
