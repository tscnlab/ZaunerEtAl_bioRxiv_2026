# REPORT-017 H04 order 35a source independent acceptance

Date: 2026-08-15

## Disposition

H04 order 35a is independently accepted. The consolidated result and preparation/provenance rewrite remains unchanged, and the complete source-only verification contract now passes without warning. No reader-source or scientific discrepancy is open. H04 rendering remains held.

## Accepted identities

- result QMD: SHA-256 `63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c`;
- preparation/provenance companion: SHA-256 `52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da`;
- corrected source test: SHA-256 `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`, 33,144 bytes;
- owner execution audit: SHA-256 `05c2d9a16a04f8ce3e0b76d1244c3711406e8318507e6f8474d242ca05191957`;
- source audit: SHA-256 `09a9d857ef2dce9d46902678e9c5630bdcb4ace93cbc00f4a5d72aa4267f621d`;
- exact four-change diff: SHA-256 `83bb6bccd7630e34e9128543d9753cc5f81ab3646511b8070ec17969fa718407`;
- reverse proof: SHA-256 `9285e908164a0edb78a298101052c182b4aabf45b3cf91ff72bba43dea999daf`;
- protected-identity audit: SHA-256 `0e31faaa40bbaf5ddc5cf74f0de825bdaa86296ca3de1fbafe1299816f1a391d`;
- 23-row non-circular owner manifest: SHA-256 `5928e53945fe2853bfdb614e911571ae43c6eb3caa83c920b69f071348025568`.

The reverse proof reconstructs the stopped test at SHA-256 `02e7494ad081f6395fe19ceca2ed3ded1fe8bc3e8dbaf550e3279f3406ac427f`, 33,154 bytes. All prior order35 evidence remains historical and unchanged.

## Independent R 4.6.1 verification

The unchanged participant random-intercept assessment passed against the accepted stored artifacts without refitting. The complete corrected H04 source test then passed all 37 checks and reproduced the owner source-audit SHA-256 exactly, with no warning. All 23 owner-manifest paths, hashes, and byte counts matched; paths were unique and the manifest did not contain itself. Scoped `git diff --check` passed.

The accepted test retains all endpoint, chunk, inline-R, assignment, formula, numeric-token, artifact, link, anchor, country-coded-site, scientific-role, no-scientific-call, package-protection, stored-result, and baked-label hold contracts.

The random-intercept and Mundlak tables remain supplemental. `fig-h04-primary-estimates` and `tbl-h04-primary-results` remain the provisional principal outputs. Their roles and appearance remain provisional until the later focused render and author visual review.

No Quarto render, QMD execution, scientific computation, artifact regeneration, shared-profile edit, central-ledger edit, commit, or push occurred during this acceptance.
