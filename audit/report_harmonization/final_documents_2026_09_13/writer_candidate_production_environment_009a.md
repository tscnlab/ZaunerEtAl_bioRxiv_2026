# Order 009a: one environment-only HTML recovery

14 September 2026. Continuing owner: Writer task `019ffb39-372e-7262-bfac-192751fd0e63`. This is additive to Order 009, not a new production workflow or a scientific reopening.

## Diagnosis and preserved boundary

Order 009's initial main HTML command exited 1 at `Deno.openKv` inside `sassCache`, before producing the target HTML. Its receipt and failure log remain immutable. Independent inspection of installed Quarto 1.9.37 reproduces the cause of the ineffective cache override: `darwinUserCacheDir()` resolves the normal user `Library/Caches/quarto`, and this Sass branch opens `sass/sass.kv` there. This build does not read `QUARTO_CACHE_DIR`. The failure is consistent with restricted cache access; it is not proof of database corruption or proof that permissions are the only possible cause.

The same version-specific mechanism was independently documented under the earlier Order72k environment recovery. No old Brown hold or output-count rule is imported from that historical order. The current Order 009 source, figure, table, S2-size and finite-production contracts remain controlling.

This order permits the unmodified installed Quarto process to use its existing user-owned cache at `/Users/zauner/Library/Caches/quarto`, including ordinary Sass entries and SQLite journals. It supersedes only Order 009's temporary-only cache-write assumption. Cache files are mutable runtime state, not scientific preservation pins. No manual cache repair, deletion, reset, chmod, chown, runtime patch, Deno substitution, theme edit, injected Sass import, package installation, profile change or HOME override is authorised.

This is workflow authority, not OS permission. Request the exact narrow Quarto command through the execution tool with `sandbox_permissions: require_escalated`, explaining the normal cache access, and without a broad reusable approval prefix. If permission is denied, do not switch executor, interpreter or runtime to evade it. Preserve the denial and complete unaffected authorised work.

## Exact recovery and receipts

Before starting, rehash the new non-circular 009a dispatch manifest, the original 45-row dispatch, all 263 owner-package members, all input identities in `evidence/html_round1_command.json`, and the runtime pins. Verify no competing Quarto/Pandoc process for this candidate, the failed PID is absent, and the target HTML is absent. Read-only process inspection may use its normal narrow elevated permission flow. Do not terminate unrelated R jobs.

Working directory:

`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/manuscript_nature_health/final_review_production_2026_09_14/project/manuscript/R0_NatHealth`

Exact target command, retaining the original logical initial output directory:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library TMPDIR=/private/tmp/nh_order009_kgqi5px0 /Applications/quarto/bin/quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to html --no-execute --output-dir render_html_round1
```

Verify the recorded scratch directory still exists, is user-owned and contains no symlink before use. If the environment has removed it, create one new scratch with `mktemp -d` under `/private/tmp` and record that sole path substitution before the command. Leave HOME unchanged and omit the ineffective `QUARTO_CACHE_DIR` assignment. No other target, source edit or argument is authorised.

Do not edit the consumed `html_round1_command.json`, `html_round1.log`, original runtime record, or `helpers/run_stage.py` to erase or reset that attempt. Record this invocation separately under the candidate root's new `evidence/environment_recovery_009a/`, including command, cwd, selected environment, actual approval outcome, timestamps, process ID, exit status and output hashes. A new receipt-only helper is allowed there if needed; it must not alter the target argv, invoke a second render or run the old stage again. The exact Quarto process, not an opaque multi-stage runner, receives the narrow elevated execution request.

Normal changes to the candidate-local `.quarto` metadata and target output are expected. Inventory and classify them without resealing a historical input manifest. Retain exact preimages of any existing generated file that would be replaced; do not restore or delete the failed state to make a count pass. No accepted live manuscript, table, HTML, Word output, website, science or package file may change.

## Budget and continuation

Exactly one additional environment-recovery invocation is released. The failed initial command remains counted as failed. A successful recovery supplies the missing initial HTML and does not consume the single consolidated production-layout correction round.

On success, continue the existing Order 009 content/semantic checks, native-table exports, image assembly, Word production, full-page QA and bounded localhost review. There is no extra render for any other stage. For the already released narrow Quarto commands, the same installed-runtime cache-access permission flow may be used with their unchanged target and finite trial count; do not deliberately repeat the now-known failing cache override first. Record each command separately, preserving the existing stage guards and count contracts.

If this single environment retry fails, preserve one consolidated diagnosis and stop the affected HTML-dependent path. Do not spend the layout-correction allowance on another attempt at the same environment defect. Unaffected work may continue within Order 009. Unexpected computation, input mismatch, or escaped output scope stops immediately.

S2's existing secondary text size remains expressly accepted and unchanged. No new author text-size or screenshot-cropping gate is introduced. Writer returns the existing Order 009 complete candidate package or one consolidated remaining blocker. Final promotion and the separate 37-route website remain held.

## Source of version-sensitive diagnosis

The controlling implementation is the installed `/Applications/quarto/bin/quarto.js`, specifically `core/appdirs.ts`, `core/sass/cache.ts` and `compileWithCache()`, pinned in the accompanying manifest. The [official environment-variable reference](https://quarto.org/docs/advanced/environment-vars.html), checked on 14 September 2026, does not document `QUARTO_CACHE_DIR` as a supported control. No permission conclusion is inferred from that documentation alone; the installed code and failed execution record supply the direct evidence.
