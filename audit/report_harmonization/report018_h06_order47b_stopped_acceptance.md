# REPORT-018 H06 order 47b stopped-state acceptance

Date: 2026-08-21  
Disposition: **result-source execution repair accepted; semantic endpoint
defect confirmed; bounded two-table endpoint repair approved**

## Accepted completed work

Order 47b changed only the stopped figure-QA table pipeline from
`dplyr::select()` to `dplyr::transmute()` in
`notebooks/hypotheses/H06.qmd`.

- Source preimage:
  `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`,
  60,677 bytes.
- Accepted current source:
  `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`,
  60,680 bytes.
- Exact reverse substitution reproduced the preimage.
- All 20 result R chunks parsed under R 4.6.1.
- The repaired six-row display retained all accepted values and mapped all six
  PASS statuses to `Verified`.

This display execution repair is accepted and must not be rolled back. The
current H06 contract remains accepted at
`b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`,
13,468 bytes.

## Accepted stopped render

Order 47b issued exactly one command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47b_semantic.Iq7j7q quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Quarto 1.9.37 and R 4.6.1 completed all 41 executable cells and wrote a fresh
result HTML. The command then exited 1 in the configured post-render semantic
hook with:

```text
Every native gt table must have one Quarto tbl-* endpoint.
```

The fresh, semantically unrepaired HTML is
`dc62f37001c2d7e9f5a2daa9167023e006aafecc72c2d0137925093e573027c1`
at 4,862,444 bytes. The hook failed before staging or mutation, so the external
semantic directory is empty and the HTML remains the exact pre-hook output.

## Exact semantic diagnosis

R 4.6.1 with xml2 1.6.0 found exactly 13 native `gt` tables. Eleven are inside
unique Quarto `tbl-*` endpoints. Exactly two native tables have no table
endpoint:

1. source chunk `exploratory-two-part-formulas`; and
2. source chunk `exact-confirmatory-formulas`.

Both are existing reader-facing formula tables. Their table code, rows,
columns, values, formula strings, roles, source notes, and order are accepted.
The source defect is only that their ordinary chunk labels are not Quarto
table labels and they have no Quarto-owned captions. The semantic repair
engine correctly fails closed in this state.

The current source contains 11 accepted `tbl-*` endpoints and six accepted
`fig-*` endpoints. Converting the two existing formula displays into Quarto
table endpoints yields the complete controlling result-page inventory of 13
native tables and six figures. The earlier 11-table render expectation is
superseded by this direct generated-HTML inventory. It was incomplete metadata,
not source, render, or scientific drift.

No other native table lacks an endpoint. The fresh page contains all six
figure endpoints, all internal links resolve, all four DEV anchors resolve,
active H06 navigation is present, and all nine country-coded site names are
present. The unnamespaced page does not yet satisfy ID and `headers` semantics,
as expected before the transactional hook.

## Exact approved source transition

The next continuation may make only these two label and caption transitions:

```yaml
#| label: exploratory-two-part-formulas
```

becomes:

```yaml
#| label: tbl-h06-exploratory-two-part-formulas
#| tbl-cap: "Exploratory two-part formulas."
```

and:

```yaml
#| label: exact-confirmatory-formulas
```

becomes:

```yaml
#| label: tbl-h06-exact-confirmatory-formulas
#| tbl-cap: "Exact evaluated Wilkinson formulas."
```

No executable R expression changes. The prospective result-source identity is
`d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`
at 60,791 bytes. Reversing exactly the two label and caption transitions must
reproduce the accepted current source byte-for-byte.

The two captions use the already visible code-summary concepts and make the
Quarto ownership explicit. This is required semantic integration, not a
language-harmonization or scientific change. The final whole-corpus audit may
reconcile harmonizer-wide table counts and catalogs after all serial renders;
it does not block this target render under REPORT-018.

## Preserved state and warnings

- All 75 protected paths remained exact.
- The held companion QMD and HTML remain
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`
  and `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`.
- Build changes are confined to the fresh H06 HTML, search and sitemap,
  byte-identical framework mtime drift, and four H06 PNG build copies that are
  byte-identical to their accepted source artifacts.
- No build symlink exists.
- No browser server or visual QA started.
- No model, inference, scientific artifact, source CSV, test, manifest,
  contract, profile, package, lockfile, ledger, companion, or H06 daily page
  changed.

Pandoc emitted three resource-fetch warnings for the already built H06 and H05
companion links and the absent optional `Datatype.woff2` font. Direct link
inspection proves both companion targets resolve in the retained site. The
font warning is an existing site cosmetic. Under REPORT-018 these warnings are
recorded and deferred. They do not authorize a source, CSS, font, link, or
shared-page cleanup and do not block a successful H06 result render if the
fresh page has no embedded error or unresolved reader link.

The owner completion record is
`b44fbefd93130c02245364d8910e1ab4ccbf8f470e0944b9d7c4015c6ee55269`
and its non-circular evidence manifest is
`a1fdab5dc8202dda9b3a0fe8eedc5e335901cee8da3d45981b758f6d0ab87e75`.

## Approved continuation boundary

One continuation may apply only the two endpoint/caption transitions above,
prove the exact prospective source and reverse reconstruction, verify 13
unique table plus six unique figure endpoints, parse all result chunks, and
then issue exactly one H06 result render with the normal profile and semantic
hook. It must complete the 13-table, six-figure semantic, link, protected,
build, secure-loopback, and visual acceptance package.

No other source cleanup, wording change, test or manifest edit, scientific
computation, model, inference, artifact regeneration, contract change,
profile, package, lockfile, ledger, companion render, H06 daily render, later
target, full-project render, commit, push, upload, or publication is
authorized. Stop once on any genuinely new defect.
