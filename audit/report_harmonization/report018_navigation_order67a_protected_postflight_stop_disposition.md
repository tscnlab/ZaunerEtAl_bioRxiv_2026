# REPORT-018 Navigation Order 67a: protected-postflight disposition

Date: 2026-09-02  
Status: **ACCEPTED VERIFIER ALLOWLIST OMISSION; READ-ONLY COMPLETION AUTHORIZED**  
Finding: `NAV-67A-POSTFLIGHT-PROT-001`

## Finding

The single Order 67a production promotion and browser QA completed. The
postflight then stopped because its protected-transition allowlist named the
mobile-TOC include, corpus manifest, and H06 result HTML, but omitted the H06
companion HTML. The H06 companion is one of the 37 approved HTML shell
transitions.

The exact omitted transition is:

- `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`
- preimage SHA-256
  `ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683`,
  849,545 bytes
- postimage SHA-256
  `aeac00b6806ae10368e133e904784e7c2fcc79747bb8c8e2dc95fe2d721a944e`,
  849,699 bytes

The 154-byte increase exactly matches the approved mobile-TOC script change.
Substituting the postimage script with the retained preimage script reconstructs
the retained companion preimage byte-for-byte. The promotion manifest already
records this route as Order 25 of its 38 targets, and the resealed 37-row corpus
manifest records the current companion hash.

## Complete read-only replay

R 4.6.1 independently audits all 54 preflight-protected paths. Exactly four
changed:

1. the shared mobile-TOC include;
2. the navigation-only corpus manifest;
3. the H06 result HTML;
4. the H06 companion HTML.

The first three were already named by the stopped verifier. The fourth is the
omitted approved route above. The remaining 50 protected paths are exact. No
protected path is missing, added, or otherwise changed.

The complete downstream state also passes read-only:

- current build equals the sealed candidate, 892 of 892 files;
- current corpus manifest is live-exact for all 37 HTML routes and preserves
  all 37 historical source paths and source hashes;
- production route QA passes 74 of 74 rows;
- production desktop QA passes 3 of 3 rows;
- extended H06 QA passes 4 of 4 view modes under the separately sealed inert
  marker and 10-link TOC classifications;
- at least eight nonempty browser screenshots remain sealed;
- both Nature Health stylesheets remain exact;
- the production loopback server is stopped, its listener is cleared, the
  viewport is reset, and session QA tabs are closed.

No downstream masked protected transition or page defect remains.

## Authority

The failed postflight and executed implementation remain immutable evidence.
Do not patch or rerun the executed Order 67a implementation. The owner may
create one task-owned read-only completion verifier that classifies exactly the
four transitions above, rehashes the current sealed state, records final checks,
and creates one non-circular completion record and manifest.

No production file may change. No promotion, rollback, Quarto, QMD execution,
Pandoc, knitr, semantic hook, browser-server rerun, source edit, CSS edit,
corpus-manifest rewrite, scientific computation, manuscript action, commit,
push, or upload is authorized. Any fifth protected transition, build mismatch,
or new structural defect must stop.

Final independent Navigation Order 67a acceptance remains mandatory before the
Nature Health manuscript HTML and DOCX render task is released.
