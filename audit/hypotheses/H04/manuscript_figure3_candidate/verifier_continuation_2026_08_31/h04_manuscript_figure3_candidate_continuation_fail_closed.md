# H04 manuscript Figure 3 verifier continuation

Date: 2026-08-31  
Status: **FAIL-CLOSED AFTER THE SOLE RELEASED CONTINUATION INVOCATION**

## Release pins

- Candidate-only order SHA-256: `841efaef5f49467d3e7938aded1d1496d450da53b7dd3ba95b794a4d9a1f63fa`
- Corrected focused verifier SHA-256: `e63f7ea9930f73145fea3d53f2969a8965f0d96818f2c4d9dee5b33091d33688`
- Historical stopped manifest SHA-256: `0064354f99f48edd59d09ca297b4aff933fc709f05c9722fbb22c92c5f3f4e49`
- Historical stopped record SHA-256: `08bd1dac08c62558bc0e3230163bcf2f161b6697b7e7e2ff6985080502902c84`
- Candidate PNG SHA-256: `697e86ae17862f35f270e1c236bbb22aba2aab8b8ffd4234e96b3af951da2a58`
- Candidate SVG SHA-256: `169497f3f112f870177d78e57cf9671d647d3dfbb3eec7bea72c9ee6a741ca14`

All release pins were exact immediately before the continuation. The candidate root remained `/private/tmp/h04_manuscript_figure3_candidate.7bhj5n`.

## Continuation verifier

The continuation copy has SHA-256 `b2a8e6a1fef4891cdade9bbcf0ed88b99a8ba5c5b70bf263babb875ecd455bcf`. It differs from the corrected verifier only by requiring the fresh `verifier_continuation_2026_08_31` evidence subdirectory. The namespace-safe SVG text queries are unchanged. No duplicate `manifest_identity_ok` assignment was present.

Reversing the evidence-path edits produced SHA-256 `e63f7ea9930f73145fea3d53f2969a8965f0d96818f2c4d9dee5b33091d33688`, byte-identical to the corrected verifier. Air formatting and R 4.6.1 parsing passed before invocation.

## Sole invocation result

The verifier was invoked exactly once under R 4.6.1 against the unchanged candidate. It recorded 20 passing gates and two failing gates:

1. `builder_input_identity_evidence`: all 15 paths and both SHA-256 columns agree by value. The verifier's `frozen_inputs$sha256_observed` retains path names from `vapply()`, while the CSV column is unnamed. `identical()` therefore fails on the names attribute rather than on an input identity.
2. `reader_language_and_frame_note`: every frame token, `1/k`, the interaction-model wording, the exclusion of `heterogeneity model`, and the exclusion of an internal H04 label pass individually. The candidate uses the grammatical plurals `site-average estimates` and `site-average category estimates`; the verifier requires the exact singular substring `site-average estimate`.

The candidate passed all scientific identity, frame, panel-d source, estimability, FDR, vector token, temporal SVG, decoded-pixel, panel-tag, and dimension gates. No patch or second invocation was made.

## Preservation boundary

The historical stopped evidence and candidate bytes remain unchanged. No candidate regeneration, canonical promotion, H04 QMD or HTML edit, source-data or scientific change, Quarto run, manuscript-selection render, shared manifest, configuration, ledger change, commit, push, or upload occurred.

Acceptance remains withheld. A further central release must decide whether to adjust the two verifier contracts or alter the candidate's visible singular/plural wording.
