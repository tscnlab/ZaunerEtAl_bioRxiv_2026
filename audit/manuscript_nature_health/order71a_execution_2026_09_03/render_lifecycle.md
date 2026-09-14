# Nature Health Order 71a HTML render lifecycle

Date: 2026-09-03

## Scope

This record covers the manuscript-only HTML production authorized under Order 71a. It does not cover or authorize a Word render, supplementary-only render, website render, full-project render, scientific analysis, model fit, or change to an accepted scientific source.

## Source preflight

Immediately before rendering, the manuscript source, Supplementary Information outline, accepted Table 3 include, nested Quarto configuration, merged bibliography, manuscript stylesheet, canonical HTML preimage, protected DOCX, and protected integrated website were rehashed. The R 4.6.1 source validator passed with:

- 147 abstract words;
- exactly 4,500 words across the Introduction, Results and Discussion;
- 114 merged bibliography entries and 91 resolved citation keys;
- 31 checked internal link targets with none pending; and
- 501 ordered numerical tokens matching the author-edited snapshot.

Microsoft Word's native Compute Statistics word counter independently returned 147 words for the exact abstract text.

## Terminology implementation

The manuscript uses R² or variance explained when the reported quantity is an actual R², an R² allocation, or the marginal-to-conditional R² increment. The daily-pattern Shapley decomposition is described as an allocation of full-model in-sample R². Brown-adherence and exploratory participant-intercept decompositions are described through marginal R², conditional R², and explained-variance increments.

The separate hourly time-of-day decompositions for reported light source and immediate setting do not compare fitted-linear-predictor variance with observed-outcome variance and therefore are not R². They are described as shares of variation in fitted hourly patterns. No reader-facing instance of “model-fit credit” or “fitted-pattern variance” remains.

## Quarto execution

The first sandboxed command stopped before Pandoc because Quarto could not open its user-owned Sass cache. It left the canonical HTML byte-identical to its preimage. The harmonizer and coordinator accepted the environment diagnosis and authorized one same-target retry with narrowly elevated access to the existing cache. No cache was redirected, reset, deleted, copied, renamed, chmodded, or chowned.

The authorized retry ran from `manuscript/R0_NatHealth/` with the single HTML target:

```text
quarto render ZaunerEtAl2026_NatHealth_phase3_brown.qmd --to html
```

It exited successfully and produced only `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`. The canonical DOCX and integrated website remained byte-identical. The Sass database also retained its exact pre-render identity and no WAL or SHM file remained.

## Post-render validation

The R 4.6.1 source validator passed again without a source change. The strict HTML verifier passed with one manuscript main element, 19 accepted semantic `gt` tables, 20 accepted figures, 28 authors, 582 unique identifiers, 2,762 resolved table-header tokens, 124 resolved internal fragments, and fully embedded resources. The fresh Quarto output contained globally unique table identifiers, so no post-render semantic repair was needed.

Browser QA covered 1,440 by 1,000, 708 by 1,000, 390 by 844, and 720 by 500 viewports. It found no page-level horizontal overflow, unloaded image, missing figure alt text, unresolved reference, or warning/error console message. All 19 wide-table regions retained bounded horizontal scrolling. Table 1's caption was left aligned, Supplementary Table S2 retained the wider explanatory column, and Supplementary Figure S3 displayed at 82% of its container width. The temporary loopback server was stopped and its port had no remaining listener.

## Environment retry authority

- authorization: `audit/report_harmonization/report018_writer_order71a_environment_retry_authorization.md`, SHA-256 `f4f7dfb8b041cfb6714243c150c4170e9e2af0808a402afcaca1a67cf45b29ae`;
- 11-row non-circular manifest: SHA-256 `33773186f14847c4fa24d7516ad235386d4fea8e690e33a5051df4cdfbf20389`;
- execution receipt: SHA-256 `caaee92d9acb45e8af5fd5ed3c35feaaea7c9dc0d4a2493ef267e15277609ab1`.

No further render is authorized within Order 71a.
