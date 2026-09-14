# Brown adherence BA-M reader-label reopening

Date: 2026-08-24

Status: **SEALED TERMINOLOGY REOPENING; SOURCE AND DISPLAY REPAIR AUTHORIZED; RENDER HELD**

Implementing owner: Brown adherence task
`019fffdf-66d4-7802-9091-09283ad27b7f`

## Authority and disposition

The author identified the reader-visible use of internal multiplicity-family
labels such as `BA-M4` and `BA-M6` as a remaining language defect and asked
that it be corrected. This record narrowly reopens the accepted Brown Stage 3
reader report and Stage 4 provenance companion for that terminology defect.

The scientific authority remains `BA-016 / CHG-155`. This reopening changes no
sample, estimand, model, contrast, estimate, interval, p value, multiplicity
family, FDR decision, sensitivity result, diagnostic, qualification, or
scientific claim. It creates no new scientific decision or central-ledger
entry.

## Exact accepted baseline

The owner must stop before mutation unless all of these identities reproduce:

- Stage 3 QMD, `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`:
  `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43`,
  55,426 bytes;
- accepted Stage 3 HTML, the corresponding `.html`:
  `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d`,
  4,825,090 bytes;
- Stage 4 QMD, `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd`:
  `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475`,
  24,416 bytes;
- accepted Stage 4 HTML, the corresponding `.html`:
  `54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954`,
  4,341,698 bytes;
- accepted Figure 3 builder:
  `b361b4492f5f2203ef117d8186163047140eab2fe6ea6d981dcd051500151404`,
  17,802 bytes;
- accepted Figure 3 PNG:
  `c2c58e3c8119457975d57e94b062ddba41ca828ad4326b1e1e6ac19bb7f1151a`,
  350,620 bytes;
- accepted Figure 3 SVG:
  `126acff6b1794864fc5b5797915046f884cc0890d445adc2aa437058f6d90fe0`,
  32,059 bytes;
- frozen 27-row Figure 3 source table:
  `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc`,
  19,620 bytes; and
- frozen multiplicity registry:
  `19925dc988c3dc650cea6a63b537138b1315df0d7ee44a6e76dff7ac967ee21f`,
  1,276 bytes.

The accepted paired-source, Stage 3 render, and Stage 4 render decisions remain
byte-identical at `eb7da424...`, `cc5f751f...`, and `9890452d...`.

## Read-only findings

The sealed audit contains 14 classified reader surfaces:

- Stage 3 source has eight internal-label tokens, four each of `BA-M4` and
  `BA-M6`. All occur in ordinary reader prose, the Figure 3 caption, or its
  accessible description and must be replaced by scientific meanings.
- The accepted Figure 3 display independently exposes the same codes in its
  subtitle and legend and uses `equal-site` in its footer. A source-only QMD
  change would therefore be incomplete.
- Stage 4 source has 18 internal-label tokens. The first inferential paragraph,
  seven-row multiplicity table, and translated section heading already define
  the identifiers at their point of use and must remain. The derivation prose,
  two table captions, one display column, and verification list require the
  bounded translations in the change matrix.
- Technical chunk labels, object names, input columns, paths, and their Quarto
  embedded-source reflection are provenance surfaces, not reader terminology.
  They remain unchanged. Every normal-body use must either be translated or
  defined in the same heading, sentence, table row, or display label.

The exact classifications are in
`audit/report_harmonization/brown_ba_m_reader_label_audit.csv`. The 12 exact
substitutions are in
`audit/report_harmonization/brown_ba_m_reader_label_change_matrix.csv`.

## Authorized mutation boundary

The Brown owner may change only:

1. the two accepted QMDs named above, using exactly the matrix substitutions;
2. the Figure 3 builder, using only the five sealed display-literal changes;
3. one new dedicated R 4.6.1 display refresh and one focused verifier;
4. the exact Figure 3 PNG and SVG, once, after a temporary candidate passes;
   and
5. new non-circular owner evidence in a dedicated terminology-repair
   directory.

The exact prospective source postimages are:

- Stage 3 QMD:
  `ea8f639a5b58ef591bf4716928ef32db4de68b30e157e2670867a5c0ee2d9c05`,
  55,601 bytes;
- Stage 4 QMD:
  `8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92`,
  25,275 bytes; and
- Figure 3 builder:
  `7d65e028764d522635438b10cd0573315a32ace1753b8c53762b074164bd05fd`,
  17,867 bytes.

Each must reverse exactly to its accepted preimage.

## Candidate-first display contract

The refresh may read only the frozen 27-row display source and the minimum
frozen display registries or constants already used by the accepted Figure 3
construction. It must not read a model or inferential RDS, refit, predict,
recalculate a contrast or p value, run the broad builder, or write any other
artifact.

A fresh temporary candidate must reproduce:

- PNG:
  `2467061413fc1da4834eb92072598f5af46526631e573401bbe3fa874eb4695a`,
  348,627 bytes, 2,640 by 3,360 pixels at 300 dpi; and
- SVG:
  `8e5eee7e55b3e99953de87f6f00698c28903f5445db1bf01e15c662851123e8d`,
  32,073 bytes.

The decoded PNG comparison has exactly 58,782 changed pixels, confined to the
subtitle, legend, and footer text regions. Data-panel rows 340 through 3,090
have zero changed pixels. The SVG retains 265 nodes and 45 text nodes; exactly
five text strings and their directly dependent legend-glyph positions or text
lengths change. The full contract is sealed in
`audit/report_harmonization/brown_ba_m_reader_label_display_candidate_audit.csv`.

Only after every check passes may the owner preserve recoverable preimages and
replace the two durable display targets once.

## Preservation and verification

The owner must prove:

- 19 Stage 3 R chunks and 110 parsed expressions remain exact;
- 18 Stage 4 R chunks and 59 parsed expressions remain exact;
- every inline R expression, endpoint label, link target, scientific numeric
  token, source-data target, and multiplicity decision remains exact;
- all 27 Figure 3 rows, estimates, intervals, states, sites, symbols, colours,
  ordering, axes, facets, and reference lines remain exact;
- the accepted HTMLs, historical manifests, prior acceptance and render
  evidence, scientific and display source data, `renv.lock`, shared profiles,
  and every unrelated Brown artifact remain byte-identical; and
- every authorized source and display transition has exact forward and reverse
  evidence in a non-circular owner manifest.

R 4.6.1 parse, focused terminology, link, numeric-token, protected-identity,
decoded-pixel, normalized-SVG, Air, and scoped diff checks are required.

## Holds

No Quarto command, QMD execution, Pandoc invocation, HTML mutation, model or
scientific computation, broad builder, profile or lockfile change, central
ledger edit, manuscript edit, commit, push, upload, or publication is
authorized. Stage 3 and Stage 4 renders remain separate and held until this
source-and-display repair receives independent acceptance.
