# REPORT-018 owner order 66b: H06 result no-rerender verification and QA

Date: 2026-09-02

Owner: H06 task `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: `SEALED_FOR_ONE_NO_RERENDER_COMPLETION`

## Authority and disposition

Order 66a completed its sole result render and stopped on five assertions in a
new post-render harness. The stopped state is independently accepted by
`audit/report_harmonization/report018_h06_order66a_post_render_stop_independent_acceptance.md`.
The independent R 4.6.1 replay proves that all five failures are verifier-only
classifications and that no source, scientific, semantic, or demonstrated page
defect is present.

This order authorizes one no-rerender completion against the existing H06
result HTML. The failed Order 66a verifier and all its stopped evidence remain
immutable. The centrally accepted checker is the corrected verification path;
the owner must not patch, copy, replace, or rerun the failed verifier.

## Exact preflight

Before opening a browser or starting a server, the owner must:

1. reproduce every row of the Order 66b dispatch manifest by exact SHA-256 and
   byte count;
2. reproduce the 21-row non-circular independent acceptance manifest at
   SHA-256
   `4030e9f05fe3445c3236e5349446848de1aeda554761d5232c1eb906d0fb6d86`;
3. require the Order 66a owner record `5518c730...`, owner manifest
   `eee5e8ce...`, failed verifier `d6de04cd...`, and failed results
   `bb119977...` exact;
4. require the canonical H06 result HTML
   `b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
   4,898,662 bytes;
5. require the result QMD `5f8ec988...`, held preparation QMD `5b128499...`,
   held preparation HTML `ae3dd53c...`, profile `e54c7179...`, lockfile
   `3bf99c63...`, and all accepted H06 scientific identities exact;
6. require the current build to contain 892 files and zero symbolic links;
7. require no competing H06, Quarto, Pandoc, semantic-hook, or project
   loopback process; and
8. create one new empty task-owned evidence directory at
   `audit/hypotheses/H06/employment_eligibility_sensitivity/order66b_result_no_rerender_completion/`.

Stop before QA on any mismatch. Unrelated application and R processes are not
part of this gate and must not be interrupted.

## Corrected read-only verification

With `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the accepted R 4.6.1 project
library, execute exactly once:

```sh
Rscript --vanilla scripts/report_harmonization/check_h06_order66a_post_render_stop.R
```

Require its exact successful contract:

- 33 of 33 stopped-state members exact and non-circular;
- the five and only five stopped assertions classified;
- 1,911 unique document IDs;
- 14 native `gt` tables with all 421 header tokens resolving once within
  their own table;
- 14 nonempty Quarto table captions;
- one unique external GitHub `.qmd` target and no internal `.qmd`, local
  filesystem, or build-path reader link;
- 21 of 21 dispatch paths exact with absolute Sass-path handling;
- exact six-path build delta;
- exact semantic reversal and reapplication for all 424 substitutions;
- 46 of 46 sensitivity-package members exact; and
- 31 of 31 standalone report checks passing.

Then execute the unchanged focused reader-source test exactly once under the
same R 4.6.1 library and require its PASS for two reader QMDs and three stored
sensitivity tables.

Record both console outputs in the new evidence directory. These are read-only
verification commands. No test, source, manifest, HTML, semantic file, or
historical evidence may be changed.

## Secure loopback visual QA

Only after the corrected verification passes:

1. repeat the zero-symlink build preflight;
2. serve only `_build/nathealth` on one unused high port bound only to
   `127.0.0.1`;
3. inspect `/notebooks/hypotheses/H06.html` at 1,440 by 1,000, 708 by 1,000,
   and 720 by 500;
4. inspect the complete page, all 14 tables, all six figures, the employment
   eligibility sensitivity section, disclosures, scrollers, captions,
   alternate text, desktop and collapsed mobile tables of contents,
   navigation shell, reciprocal preparation link, three source-data links,
   and DEV-015, DEV-030, DEV-031, and DEV-032 links;
5. inspect exported figures at 642 pixels, corresponding to the accepted
   170-mm final width, and require the established text-size, completeness,
   and no-clipping contracts;
6. reject page overflow, clipping, overlap, missing content, broken
   interaction, unresolved link, or page-attributable console warning or
   error;
7. verify the result page, held preparation page, and each linked source-data
   resource return HTTP 200;
8. save bounded screenshots, a structured observation table, link status,
   viewport evidence, and server lifecycle evidence in the new evidence
   directory; and
9. close or reset the QA surface, stop the server, prove no listener remains,
   and require byte-identical build and protected inventories across QA.

## Final seal and stop rule

On complete PASS, write one concise acceptance record and one unique,
non-circular evidence manifest in the new Order 66b directory. The manifest
must include the accepted HTML, both sources, held preparation HTML, central
checker and acceptance, Order 66a stopped evidence, semantic evidence,
corrected verification outputs, browser observations, screenshots, lifecycle
proof, and pre/post build and protected inventories. Exclude the final
manifest itself.

Return exact SHA-256 and byte counts for the result HTML, completion record,
and final evidence manifest. Do not update a central coordination file. The
Coordinator will independently accept the result before any preparation-page
or later-target release.

Stop and seal once on any genuinely new verifier, semantic, link, structural,
visual, build, protected-path, or environment defect. Do not patch or retry.

## Prohibitions

Do not run Quarto, knitr, Pandoc, the semantic hook, a report helper, a broad
manifest builder, or any analytical script. Do not edit or replace the H06
QMDs, HTML, tests, manifests, handoff, sources, scientific artifacts, profile,
package library, lockfile, H06 daily files, manuscript, shared configuration,
or ledger. Do not render the preparation page or any other target. Do not
commit, push, upload, delete, or alter a cache.
