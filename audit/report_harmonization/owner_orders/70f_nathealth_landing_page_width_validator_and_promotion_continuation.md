# REPORT-018 owner order 70f: browser-width validator and promotion continuation

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_VALIDATOR_ONLY_PROMOTION_CONTINUATION`

## Accepted stop

The recovered Order 70e run stopped before `promotion_started.txt` and before
any production write. The stop is accepted as a browser-evidence field-name
defect only. The sealed JSON uses `width`; the implementation validator asks
for `viewport_width`.

Preserve the retained 893-file candidate, all candidate browser evidence, the
892-file production preimage, the 37-row corpus manifest, all accepted source
files, and the absent production Word download exactly. Do not regenerate the
candidate or rerun candidate browser QA.

## Prospective preflight

Before editing the implementation, run
`scripts/report_harmonization/check_report018_order70f_promotion_preflight.R`
once with R 4.6.1, `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, `Rscript --vanilla`,
and the accepted project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`.

The checker is SHA-256
`3fda0656ae83c0e3115292a9ce47b3d4a5bedea9353b0f02c723b33d4e2e2f94`,
17,397 bytes. Require exactly:

`ORDER70F_PREFLIGHT=PASS checks=20/20 browser=77/77 candidate_files=893 production_files=892 links=46071/46071 prospective_sha256=f87eaf01f7ea76cba94a1d30bd45ddc07c6fcf55f8ea87c1bb94bf510a56f66a R=4.6.1`

The checker must reproduce the exact prospective implementation seal and the
20-row preflight ledger. It writes only into
`audit/report_harmonization/report018_navigation_order70f_preflight/` and may
not change candidate, browser QA, build, source, corpus, or production bytes.
Stop without editing on any mismatch.

## Exact implementation correction

Apply only
`audit/report_harmonization/report018_navigation_order70f_width_validator_expected.diff`
to the current implementation preimage
`345837702576f0ed5ddfbd01dd484820e5edb0ae730acb786168ecd1c9cc7ed8`,
53,259 bytes. The only authorized substitutions are:

- `route_qa$viewport_width` to `route_qa$width`; and
- `landing_qa$viewport_width` to `landing_qa$width`.

Change no other implementation byte or logic. The final implementation must be
SHA-256
`f87eaf01f7ea76cba94a1d30bd45ddc07c6fcf55f8ea87c1bb94bf510a56f66a`,
53,241 bytes. Require R 4.6.1 parse success and an exact reverse proof to the
Order 70e preimage.

Replace the existing one-row `implementation_script_seal.csv` with the exact
prospective seal already written by the preflight checker. The resulting
sidecar must be SHA-256
`16adbeca251561ddfa7b7e8c1b29242e7007a9ef3c8baf5c6671419919fa6c53`,
198 bytes. Re-read the sidecar and require its path, hash, and byte count to
match the final implementation before entering implementation mode.

## Promotion and postflight sequence

After the implementation, reverse proof, parse, and sidecar all pass:

1. refresh the one-row pre-promotion process gate and require zero conflicting
   writers and zero listeners on the bounded candidate and production ports;
2. preserve and recheck the already sealed 74-route and three-landing-row
   candidate browser evidence without rerunning it;
3. recheck the exact two-row promotion manifest and empty backup root;
4. execute the existing `promote` mode exactly once;
5. run complete production browser QA for all 37 routes at 708 and 390 pixels
   and for the landing page at 1,440, 708, and 390 pixels;
6. require the exact accepted SVG in the production landing page;
7. reseal only the landing-page HTML hash in the 37-row corpus manifest;
8. execute the existing `postflight` mode once;
9. write one completion record and one non-circular completion manifest; and
10. stop both bounded servers, clear their listeners, reset browser viewport
    overrides, and close only task-owned QA tabs.

The only production build changes remain replacement of `index.html` with the
retained candidate at SHA-256 `c8abe2f9...` and addition of the exact Word
download at SHA-256 `6cd59239...`. The other 891 build files, including the
other 36 HTML routes, must remain byte-identical. The corpus manifest must
retain every source identity and change only its first `html_sha256` row.

Stop and seal once on any genuinely new defect. Do not patch or retry inside
this continuation.

## Prohibitions

Do not run candidate mode. Do not regenerate or delete the retained candidate.
Do not rerun candidate browser QA before promotion. Do not run Quarto, knitr,
Pandoc, a QMD, a report helper, scientific code, or a full-profile render. Do
not edit manuscript text, accepted HTML, accepted DOCX, figures, tables,
captions, SVG, navigation include, stylesheets, profile, package state,
lockfile, other routes, historical checkers, or historical evidence. Do not
start a second owner, perform a second promotion, commit, push, upload, deploy,
or submit.
