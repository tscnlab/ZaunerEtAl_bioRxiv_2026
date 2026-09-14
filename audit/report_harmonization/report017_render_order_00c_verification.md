# REPORT-017 Phase 4 shared order 00c verification

Date: 2026-08-13  
Scope: placement-context source repair and focused render only  
Status: **source and render verified; pixel-level browser review remains pending**

## Accepted inputs

- pre-edit `notebooks/placement_decision.qmd`:
  `6a8cc0eb69ca0ccfccad519dd89d983310e1a3f1865170fa61167577c9c1e379`
- `_quarto-nathealth.yml`:
  `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`

Both identities matched before editing. The title and subtitle remained
byte-identical.

## Source repair

The former purpose, future work order, input/output inventory, internal
decision-file path, and unevaluated setup chunk were replaced by:

- one note callout titled `Answer in brief`;
- a plain explanation of why near-eye and chest measurements remain separate;
- the same-participant and same-participant-day rule for direct comparisons;
- the separate primary near-eye and complementary chest model roles;
- repeated-measurement, practical-unit, 95% CI, and exact-sample reporting
  rules; and
- the bedside sleep-environment interpretation.

Only the two authorized dynamic links occur:

- `[Descriptive results](descriptives.qmd)`
- `[Preparation 02: coverage and sample flow](preparation/02_coverage_sample_flow.qmd)`

The page contains no future-tense work order, internal path, task mechanics,
implementation inventory, executable chunk, diagram, or preregistration-
deviation mention.

Post-edit source:

- SHA-256: `b090bb87107f310662692db682118f339d7c404c09a45d9735af406d63a78498`
- bytes: 2425

The complete unified source diff is stored at
`audit/report_harmonization/report017_render_order_00c_source.diff`. It was
compared byte-for-byte with a fresh `diff -u` of the sealed pre-edit and final
sources.

## Focused render

Quarto 1.9.37 ran exactly:

```text
quarto render notebooks/placement_decision.qmd --profile nathealth --no-execute
```

The render completed through Pandoc without R or knitr execution. No other QMD
or full project was rendered.

Rendered page:

- path: `_build/nathealth/notebooks/placement_decision.html`
- SHA-256: `672ccfb77050e373e447c2e552131f95dd579bb6027e6a66979c79b7c4a3824c`
- bytes: 48597

## Structural and link checks

Read-only R 4.6.1 and `xml2` checks establish that:

- the callout and all three intended section headings are present;
- the rendered reader content contains exactly the two authorized links;
- both links resolve to existing Nature Health HTML outputs;
- no reader-content link uses `.qmd`, `file:`, `_build`, or an absolute local
  path;
- the old `What this notebook uses and produces` text is absent from both the
  HTML and refreshed search index;
- the page contains no code, table, figure, or cell-error element;
- the placement decision, primary/complementary roles, non-equivalence
  boundary, common-sample comparison, repeated-measurement rule, practical
  units, 95% CIs, exact sample reporting, and sleep-environment interpretation
  all occur in rendered prose; and
- the navigation, 86-anchor reader-link, and country-coded site-name contracts
  pass.

The refreshed search index contains four placement-page records: the page
summary and the three reader section headings. `sitemap.xml` contains the
placement-page URL once.

## Exact build delta

Complete before/after inventories were compared by path, bytes, SHA-256, and
modification time.

- Sources: 93 before and 93 after. Only
  `notebooks/placement_decision.qmd` changed. The 92 invariant source rows are
  byte- and metadata-identical, with canonical inventory SHA-256
  `71e6e21427628c13a1167088036bb7a3590a5d810e03ea2dba044dab0492e810`.
- Nature Health outputs: 827 before and 827 after. Exactly three directly
  dependent outputs changed:
  `notebooks/placement_decision.html`, `search.json`, and `sitemap.xml`.
  The 824 invariant output rows are byte- and metadata-identical, with
  canonical inventory SHA-256
  `dbfd589d1453eecfbca7b7c4d3a60d5f13f3161bd4b6848e7cfa9d499d2a5b24`.

The final support-output identities are:

- `_build/nathealth/search.json`:
  `be603bfabb04512afce13546878088514f2bb9869924518a9a9b0c0bd6423711`
- `_build/nathealth/sitemap.xml`:
  `0204e3156cfd4192762e9024b5868431041b94e84652a4bc162615619c7841de`

One byte-identical Bootstrap stylesheet received a transient render-time
modification timestamp. Its exact pre-render timestamp was restored, leaving
no unrelated final output delta.

`git diff --check` passes for the source, configuration, exact diff, and audit
records.

## Visual review boundary

The page is a short prose-only context page with one callout, three headings,
and two text links. DOM inspection confirms nonempty headings and links, no
wide tables, figures, code blocks, fixed-width content, or error elements.
This provides a strong clipping and readability proxy, and the source repair
does not introduce a dense or wide layout.

The available browser blocks local `file://` navigation, so a current
pixel-level full-page screenshot could not be inspected without an
unauthorized alternate-browser or local-server workaround. Pixel-level visual
acceptance therefore remains pending in the later integrated display audit.

## Boundary

No scientific data, result, artifact, claim, ledger, shared configuration,
other reader source, or unrelated final build output changed. No commit or push
was performed.
