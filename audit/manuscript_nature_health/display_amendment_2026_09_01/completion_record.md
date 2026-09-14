# Nature Health display amendment completion

Status: **ACCEPTED**

Date: 2026-09-01

Runtime: R 4.6.1 and Quarto 1.9.37.

## Authorized scope

Two author-requested presentation changes were applied through `manuscript/R0_NatHealth/manuscript_displays.css`:

1. Supplementary Table S2 now matches the accepted harmonizer geometry: the table has a 126 rem minimum width and its first metric column has a 22 rem width.
2. Supplementary Figure S3 is displayed at 82% of its container, capped at 44 rem on desktop. It remains full width below the 708 px breakpoint.

The accepted table fragment, figure asset, manuscript prose, values, captions, alt text, and all other displays were unchanged.

## Source identities

- Main QMD: `bc24cc7393a550d50ea0d4c337ad637c6347bb4762293f6f127183dab1d9a5ff`, unchanged.
- Supplement outline QMD: `d7e7ca45a833f573fce99798044599b6387eb04755106116c961a0326c0d130a`, unchanged.
- Standalone supplement wrapper: `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b`, unchanged.
- Nested Quarto configuration: `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`, unchanged.
- Display CSS before amendment: `e990b471a30a52ba83d86ad0867edc3dd89bae0b5e0c9b7d8f91d376ba6096ea`.
- Display CSS after amendment: `3e12d0a4d752c0fc69616915835d7e54a0db15c703d07ff9694632f1a377065b`.

## Rendered endpoints

- Main HTML before amendment: `62fd223a4b5cdb5dfa646515cad47cac75dfbd06f5ac9e390615395acb6d9124`.
- Main HTML after amendment: `498bc0ad5e9d08841f48411e290ae7ec8912a7af89c8fa8397c44d3f46864d99`, 30,528,489 bytes.
- Standalone SI HTML before amendment: `4db7c0d6318da11c9b46959817a175ef773fee86029d6bbda23117c3bb9a3697`.
- Standalone SI HTML after amendment: `b973fe471fcf0e47cdecd2ff3e71327141b1d6d318b5b671e77c23537981ca08`, 18,525,716 bytes.

Both targets were rendered separately with execution disabled. The first sandboxed main render stopped before output mutation because the Quarto Sass cache was inaccessible. The identical bounded render succeeded with access to that existing cache. A later plain `Rscript` invocation entered the repository's automatic `renv` startup and waited on its lock before reaching the repair script. It was interrupted before writing any candidate or accepted output and rerun as `Rscript --vanilla` under R 4.6.1.

## Semantic and content verification

- The main raw-render identity was `2ad7856b55326748a4132f88c7bbee45f37418120ae6c80489ba15be81c419b3`.
- The established mixed-table repair changed 47 IDs and 144 `headers` attributes across two tables, for 191 substitutions.
- The repair reversed exactly to the raw render identity.
- The final main page passes 20 native tables, 19 figures, 573 unique IDs, 2,882 resolved table-header tokens, and 85 internal fragment links.
- The standalone supplement passes 17 native tables, 16 figures, 352 unique IDs, and 2,090 resolved table-header tokens.
- R 4.6.1 comparison against the pre-amendment endpoints found identical visible main text, image alt text, figure captions, and table text in both documents.
- The complete Brown-integrated Phase 3 validation passed with 90 resolved citation keys and 83 of 98 previous references retained.

## Visual verification

Secure loopback QA served only `manuscript/R0_NatHealth/_output` on `127.0.0.1:55406` after a zero-symlink preflight.

- At 1,440 by 1,000 px, Supplementary Table S2 measured 2,142 px wide, its first metric column measured 374 px, and the first data row measured 88 px high. Figure S3 measured about 655 px wide. Neither page had page-level overflow.
- At 390 by 844 px, the table remained in a 324 px local horizontal scroller with its 374 px first column intact. The scroller was exercised to 520 px. Figure S3 used the available 324 px width. Neither page had page-level overflow.
- Both the complete manuscript and standalone supplement were inspected at both viewport sizes.
- No browser console warning or error was present.

The viewport override was reset, the QA tab was closed, the server was stopped, and `lsof` found no listener on port 55406. Temporary render candidates were removed after the final endpoints reproduced their validated identities.

## Changed-file inventory

- `manuscript/R0_NatHealth/manuscript_displays.css`
- `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
- `manuscript/R0_NatHealth/_output/supplementary_information_standalone.html`
- `audit/manuscript_nature_health/display_amendment_2026_09_01/main_mixed_gt_semantic_ledger.csv`
- `audit/manuscript_nature_health/display_amendment_2026_09_01/completion_record.md`
- `audit/manuscript_nature_health/display_amendment_2026_09_01/non_circular_manifest.csv`
