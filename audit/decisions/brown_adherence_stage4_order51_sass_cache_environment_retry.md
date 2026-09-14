# Brown adherence Stage 4 order 51 Sass-cache environment retry

Date: 2026-08-21

Workflow: `REPORT-018`

Controlling decision: `BA-016`

Controlling change: `CHG-155`

Status: **ONE ENVIRONMENT-ONLY STAGE 4 RENDER RETRY AUTHORIZED**

## Authority

Order 51 is independently accepted as a fail-closed environment stop under
`audit/decisions/brown_adherence_stage4_order51_stopped_independent_acceptance.md`,
SHA-256
`6d263488af7b82c2af3f0b9280f1de8f13644cb2785b2eb2851b0536547eddb4`.
Its 24-member non-circular acceptance manifest, SHA-256
`f2a93f2897e9dd6d0871f26522b3e0ebb346ddcc15b1fba8369dc6ab82aeb95f`,
passes completely under R 4.6.1.

This authority changes only the execution permission boundary for one
replacement render. It creates no source, scientific, semantic, or reporting
change.

## Reproduced environment diagnosis

The installed Quarto 1.9.37 source bundle routes the macOS Sass cache through
`~/Library/Caches/quarto/sass/sass.kv` and opens it using `Deno.openKv()`.
The database exists, is owned by the current user, and is 36,864 bytes at
SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`.

A direct elevated probe with Quarto's bundled Deno opened the exact database,
read cache schema version `1`, closed it successfully, and left the database
hash, byte count, and file set unchanged. This proves that the required
recovery is access to the existing user-owned cache. It does not require a
cache reset, redirect, copy, permission edit, or project change.

## Required preflight

Immediately before execution, the owner must:

1. reproduce the independent 24-member stopped-state acceptance manifest;
2. reproduce all 45 members of the owner order-51 stop manifest;
3. reproduce the accepted Stage 3 QMD and HTML, the harmonized Stage 4 QMD,
   the historical Stage 4 HTML, and `renv.lock`;
4. confirm that the order-51 resource tree, knit intermediate, and exact
   failed session directory remain absent;
5. confirm that no Brown render, Pandoc, semantic-repair, or loopback process
   is active; and
6. confirm that the existing Sass cache is user-owned and can be opened at
   schema version `1` without changing its bytes.

The durable checker
`scripts/report_harmonization/check_brown_stage4_order51_sass_cache_retry_release.R`
must pass immediately before the owner attempts the render.

## Exact render command and execution boundary

From the isolated Brown worktree, invoke the same accepted command exactly
once:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
BROWN_ADHERENCE_PROJECT_ROOT=/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 \
BROWN_ADHERENCE_AUTHOR_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
quarto render audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd --to html
```

The command must run with narrow elevated filesystem access sufficient for
Quarto to read and update its existing user-owned Sass cache. `HOME` must not
be changed or repurposed. `XDG_CACHE_HOME`, `DENO_DIR`, the accepted R library,
the renv autoloader setting, the QMD, and the target must not be changed. No
cache file may be deleted, cleared, replaced, copied, renamed, chmodded, or
chowned. Quarto itself may make its normal transactional cache update during
the one render.

If this attempt fails, stop and seal the complete environment result. No
second retry is authorized.

## Authorized writes

The owner may replace only:

- `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html`;
  and
- new, non-circular retry, raw-render, semantic, verification, link, privacy,
  responsive, visual-QA, lifecycle, and completion evidence under
  `audit/analyses/brown_adherence/language_harmonization/stage4_render/environment_retry/`.

The existing order-51 stopped package must remain byte-identical. The owner
must record the pre-render and post-render Sass-cache filenames, byte counts,
and hashes as mutable environment evidence, but must not copy cache contents
into the project.

## Successful-render continuation

If the render succeeds, the owner must continue without another Quarto
invocation through the complete candidate-first semantic and reader acceptance
contract already defined by order 51:

1. preserve the exact raw render;
2. apply the unchanged accepted semantic engine only to a temporary candidate;
3. require exact composed reversal to the raw HTML and exact forward
   reapplication;
4. promote the accepted candidate once only;
5. verify one main element, 17 native `gt` tables, one top-down Mermaid,
   unique IDs, resolving header and IDREF tokens, all reciprocal and source
   links, privacy, protected scientific tokens, and historical identities;
6. complete native served-page and deterministic 390-pixel responsive QA;
7. stop the loopback server, remove the temporary served copy, and prove no
   listener remains; and
8. return one non-circular completion package for independent acceptance.

Any genuine page, semantic, link, privacy, or visual defect requires one
combined fail-closed return. Do not patch or rerender.

## Prohibitions and next stop

No Stage 3 render, source edit, model fit, prediction, inference, resampling,
scientific artifact regeneration, package or lock change, cache reset, new
language pass, cosmetic cleanup loop, manuscript edit, commit, push, or upload
is authorized.

The mandatory next stop is independent acceptance of either the successful
language-harmonized Stage 4 package or the complete one-attempt environment
failure package.
