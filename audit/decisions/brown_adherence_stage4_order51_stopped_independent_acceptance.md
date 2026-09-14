# Brown adherence Stage 4 order 51 stopped-state independent acceptance

Date: 2026-08-21

Workflow: `REPORT-018`

Controlling decision: `BA-016`

Controlling change: `CHG-155`

Status: **ACCEPTED FAIL-CLOSED ENVIRONMENT STOP**

## Disposition

Order 51 is independently accepted as a clean environment stop. Its single
authorized Stage 4 render completed all 39 knitr progress steps, then failed
before final HTML creation while Quarto 1.9.37 opened its Deno KV Sass cache.
The recorded error is `unable to open database file`. No evidence identifies a
source, scientific, semantic, link, privacy, accessibility, or reader-page
defect.

The failed attempt consumed the render authority in order 51. A new,
separately sealed environment-recovery authority is required before any retry.

## Independent replay

The durable checker
`scripts/report_harmonization/check_brown_stage4_order51_stopped_acceptance.R`
passed under R 4.6.1 and reproduced:

- nine of nine central release, order, dispatch, and receipt identities;
- 45 of 45 exact, unique, non-circular owner-manifest members;
- 24 of 24 failure-finalization checks;
- 1,644 of 1,644 protected identities;
- the exact protected entry set, with zero additions and zero missing paths;
- five of five endpoint identities;
- the complete 39-of-39 knitr console sequence and Sass-cache stack;
- absence of the order-51 resource tree, knit intermediate, and exact failed
  session directory; and
- the owner's final no-process record.

An independent elevated, read-only process listing additionally found no live
Brown render, Pandoc, semantic-repair, or loopback process.

## Preserved endpoints

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Accepted Stage 3 QMD | 55,426 | `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43` |
| Accepted Stage 3 HTML | 4,825,090 | `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d` |
| Harmonized Stage 4 QMD | 24,416 | `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475` |
| Historical semantic Stage 4 HTML | 4,340,432 | `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f` |
| `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| Owner completion record | 3,178 | `ab9d1b3c78739740b6d55b369fba171f2876957a472c653ef09b583860618a68` |
| Owner 45-member manifest | 8,763 | `3339f3d9f3485e1c30c7772cc7762ae70dd23243ae29977f35cbca84bf99d5e5` |

No semantic candidate was created and no canonical HTML promotion occurred.
The historical Stage 4 HTML therefore remains the current endpoint pending a
successful replacement render and independent acceptance.

## Environment diagnosis

The installed Quarto 1.9.37 source bundle, SHA-256
`6c6abf6ecabde086cfe8a3f12bfcd4270b64f5fff75a30cd1d0b30ecf7295338`,
routes macOS user cache access through `darwinUserCacheDir()`, selects
`quartoCacheDir("sass")`, and opens `sass.kv` with `Deno.openKv()`.
Consequently the relevant database is:

`/Users/zauner/Library/Caches/quarto/sass/sass.kv`

That database exists, is 36,864 bytes, and is owned by the current user.
`XDG_CACHE_HOME` is not the macOS routing branch in this Quarto build. The
bounded recovery is therefore narrow elevated access to the existing
user-owned cache for one unchanged render attempt. It must not alter `HOME`,
redirect the cache, bypass the accepted R library, or modify a source or
lockfile.

## Scientific boundary and next gate

No model fit, prediction, inferential calculation, resampling, scientific
artifact regeneration, source edit, Stage 3 action, package or lock change,
commit, push, or upload occurred.

The next eligible action is one separately sealed environment-only retry. It
must use the same Stage 4 target and accepted R 4.6.1 library, with only the
execution permission boundary changed. If that retry fails, the owner must
stop without a further retry.
