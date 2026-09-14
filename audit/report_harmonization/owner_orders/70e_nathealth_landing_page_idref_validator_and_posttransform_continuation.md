# REPORT-018 owner order 70e: IDREF validator and post-transform continuation

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_POST_TRANSFORM_CONTINUATION`

## Accepted state

The Order 70d stop is independently accepted as a validator-only cardinality
defect. Preserve the transformed candidate exactly. Do not rerun, regenerate,
reverse, delete, or recopy the candidate transformation.

The retained candidate contains 893 regular files and zero symbolic links.
Its landing page is SHA-256
`c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21`,
29,023,063 bytes, and its Word download is the exact accepted `6cd59239...`,
28,792,333 bytes. The other 891 accepted build members remain byte-identical.
Production remains at landing page `600b7a3d...`, corpus manifest
`5d66d43d...`, and an absent Word download.

## Exact validator correction

Apply only
`audit/report_harmonization/report018_navigation_order70e_idref_validator_expected.diff`
to the current implementation preimage `86a9131c...`, 52,946 bytes. Change the
landing-page IDREF total from 2,775 to 2,776 and require the exact breakdown:

- `aria-labelledby`: 6;
- `aria-describedby`: 6;
- `aria-controls`: 1;
- `headers`: 2,762;
- `data-bs-target`: 1; and
- `data-target`: 0.

Continue to require zero unresolved IDREF rows. Change no other implementation
logic. The final implementation must be SHA-256
`345837702576f0ed5ddfbd01dd484820e5edb0ae730acb786168ecd1c9cc7ed8`,
53,259 bytes. Require R 4.6.1 parse success and an exact reverse proof to the
Order 70d preimage. Update only the existing one-row implementation sidecar to
the exact final identity before executing any implementation mode.

## Retained-candidate checker

Run `scripts/report_harmonization/check_report018_order70e_retained_candidate.R`
once after the implementation and sidecar are exact. Use R 4.6.1,
`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, `Rscript --vanilla`, and the accepted
project library `renv/library/macos/R-4.6/aarch64-apple-darwin23`.

The checker may write evidence only. It must not change candidate or
production content. Require:

- exact final implementation and sidecar identities plus reverse proof;
- 893 candidate files and zero symbolic links;
- exact retained candidate landing page and Word identities;
- exact 891-member and 36-route protection;
- all 2,776 IDREF rows in the exact attribute breakdown and zero unresolved;
- zero duplicate IDs and zero unresolved table-header tokens;
- all 28 authors, 19 tables, 20 figures, 2,762 table-header tokens, 124
  manuscript fragments, 74 embedded images, 20 site scripts, and manuscript
  main children preserved exactly;
- the exact Brown SVG at `200e85cb...`, 108,600 bytes;
- 46,071 of 46,071 local references resolved;
- all 12 hard-pin, transition, self-pin, and ordering checks; and
- evidence-only generation of the candidate transition, addition, promotion,
  static, inventory, DOM, link, preservation, and protected-route ledgers
  required by the existing promotion mode.

Stop without retry on any mismatch.

## Browser, promotion, and postflight continuation

Only after the retained-candidate checker passes, complete the already
authorized candidate browser QA. Recreate the pre-promotion process gate and
preseal the exact two-row candidate promotion manifest produced by the
checker. Then execute the existing `promote` mode once, followed by complete
production browser QA, corpus-manifest reseal, `postflight` mode, completion
record, non-circular completion manifest, and server teardown.

Preserve Orders 70, 70a, 70b, 70c, and 70d except for the exact validator
correction and post-transform continuation stated here. The only production
build changes remain replacement of `index.html` and addition of the exact
Word download. Preserve the exact SVG and all accepted manuscript, figure,
table, caption, citation, route, navigation, and responsive behavior.

Stop and seal once on any genuinely new defect. Do not patch or retry inside
this continuation.

## Prohibitions

Do not run candidate mode or regenerate the candidate. Do not run Quarto,
knitr, Pandoc, a QMD, a report helper, scientific code, or a full-profile
render. Do not edit manuscript text, accepted HTML, accepted DOCX, figures,
tables, captions, SVG, navigation include, stylesheets, profile, package
state, lockfile, other routes, historical checkers, or historical evidence.
Do not commit, push, upload, deploy, or submit.

