# Invalid diagnostic production-boundary output

Date: 2026-08-24

This directory preserves a diagnostic execution that must not be treated as a production-boundary seal.

The temporary diagnostic correctly printed seven boundary checks and showed `protected_delta_and_source_checkpoint=FALSE`. Its line-replacement harness replaced the fail-closed assertion with `print(checks_frame)` but did not insert the intended immediate exit. The diagnostic therefore continued and wrote five seal-shaped evidence files despite the failed gate.

The five files were moved intact into this directory immediately after detection. Their original hashes and bytes are preserved in the accompanying non-circular manifest. The invalid `candidate_production_seal.csv` must never authorize promotion, resealing, acceptance, or any other transition.

The diagnostic did not copy or promote the candidate, modify `_build/nathealth`, edit `phase4_corpus_manifest.csv`, alter H09, edit authoring sources, run Quarto or Pandoc, execute the semantic hook, or start a loopback server. The accepted 37 HTML files and the candidate remain unchanged.

The output is useful only as stopped evidence:

- six of seven checks passed;
- the purpose-based process predicate found zero conflicting processes;
- the loopback check found zero listeners; and
- the protected-delta gate failed because the live protected set exceeded the centrally sealed H09 package.

No valid `candidate_production_seal.csv` or `candidate_production_boundary_checks.csv` exists at the navigation evidence root after quarantine.
