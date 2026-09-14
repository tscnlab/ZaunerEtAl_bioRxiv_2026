# REPORT-018 owner order 70d: checker sequence and retained-candidate resume

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_FINAL_NO_RENDER_CONTINUATION`

## Accepted stop and preserved authority

The Order 70c replay-ordering stop is independently accepted. The stopped
attempt changed no candidate or production content. Preserve Orders 70, 70a,
70b, and 70c as controlling except for the exact checker, seal, and retained-
candidate sequencing corrections specified here.

The historical Order 70c checker must remain byte-identical at SHA-256
`0a0261563f4f3f9ac954fa906ddd8bbebfc96042dbdc6a062d52632c0b1df44f`.
The corrected, unexecuted Order 70c implementation is the exact preimage for
this continuation at SHA-256
`59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175`,
52,650 bytes.

## Exact final implementation transition

Apply only the focused resume-state diff in
`audit/report_harmonization/report018_navigation_order70d_resume_state_expected.diff`.
It replaces the empty-root requirement with an exact verification that the
existing `candidate_build` is the sole candidate-root member, contains the
accepted 892-file inventory, and has zero symbolic links. It removes the
second baseline-copy operation. It changes no transformation, validator,
browser, promotion, rollback, corpus, manuscript, figure, table, or SVG logic.

The exact final implementation postimage must be SHA-256
`86a9131c715b4ee18b2e5790c5a1e3ea68dec35da0716a9de90635aeb412b8bc`,
52,946 bytes. Require R 4.6.1 parse success and exact reverse proof first to
the Order 70c postimage at `59a17d43...`, then to the stopped Order 70
preimage at `5c9d894b...`, 52,114 bytes.

Replace the one-row implementation sidecar only after the final postimage is
exact. It must contain the unchanged logical path, the final `86a9131c...`
hash, and 52,946 bytes. The implementation must reproduce that sidecar before
any mode runs.

## Copied continuation checker

Use only
`scripts/report_harmonization/check_report018_order70d_preflight.R`. Run it
once after the final implementation and sidecar are exact, using R 4.6.1,
`RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, `Rscript --vanilla`, and the accepted
project library `renv/library/macos/R-4.6/aarch64-apple-darwin23`.

Require all of the following in that single run:

- three of three exact implementation transition and reverse proofs;
- the complete 50 of 50 literal, XPath, and semantic replay checks;
- the 10 of 10 hard-pin, self-pin, and ordering classifications;
- exactly 28 ordered author metadata values and 28 body author paragraphs;
- 19 native semantic tables, 20 figure endpoints, 2,762 resolving table-
  header tokens, 124 resolving manuscript fragments, and 74 embedded images;
- the exact 108,600-byte Brown SVG at `200e85cb...`;
- exact manuscript main children and all 20 site scripts;
- the retained 892-file candidate baseline and zero symbolic links;
- unchanged live landing page `600b7a3d...`, unchanged corpus manifest
  `5d66d43d...`, and absent production Word download; and
- no candidate or production write by the checker.

The earlier `renv` startup loop is accepted as environment-only. Its durable
sample and stop record are sealed in the dispatch. If the prescribed no-
autoload invocation does not pass, stop without another retry.

## One continuation

After the checker passes, execute the final implementation in `candidate`
mode once against the retained candidate root. Do not create, copy, delete,
move, or rename a second candidate baseline. Continue the already authorized
static validation, bounded candidate browser QA, pre-promotion process gate,
single promotion, production QA, corpus-manifest reseal, postflight, evidence
seal, and server teardown from Orders 70, 70a, 70b, and 70c.

The only production build changes remain the replacement `index.html` and
addition of the exact accepted Word download. The other 891 build members,
including the other 36 HTML routes, remain byte-identical. The new landing
page must retain the exact accepted SVG, all manuscript content, tables,
figures, citations, links, captions, and navigation behavior.

Stop and seal once on any genuinely new defect. Do not patch or retry inside
this continuation.

## Prohibitions

Do not run Quarto, knitr, Pandoc, a QMD, a report helper, scientific code, or
a full-profile render. Do not edit manuscript text, accepted HTML, accepted
DOCX, figures, tables, captions, SVG, navigation include, stylesheets,
profile, package state, lockfile, other routes, historical checker, or
historical evidence. Do not commit, push, upload, deploy, or submit.

