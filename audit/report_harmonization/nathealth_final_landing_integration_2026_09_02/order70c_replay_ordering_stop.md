# REPORT-018 Order 70c replay-ordering stop

Date: 2026-09-02

Status: `FAIL_CLOSED_BEFORE_RESEAL_OR_CANDIDATE_TRANSFORMATION`

The exact three-site harness correction authorized by Order 70c was applied to the stopped implementation program. The corrected program is SHA-256 `59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175`, 52,650 bytes.

The mandatory central in-memory checker was then invoked before touching the existing candidate copy. It stopped before the prospective replay because the checker requires the implementation path to retain the stopped preimage SHA-256 `5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f`. The exact failed assertion was:

`identical(sha_file(implementation_path), "5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f") is not TRUE`

This creates an ordering conflict between the required post-repair replay and the checker's immutable stopped-program preimage pin. The checker itself remains exact at SHA-256 `0a0261563f4f3f9ac954fa906ddd8bbebfc96042dbdc6a062d52632c0b1df44f`, and its previously sealed 50-row prospective result remains exact at SHA-256 `3741309617903d7b7aa9afb734fab3cf8189145257b069ceadc3705ef845f07f`.

No candidate transformation occurred. The candidate remains an exact 892-file copy of the accepted build with zero symlinks, and its landing page remains `600b7a3d...`. No production path changed. The production landing page remains `600b7a3d...`, the corpus manifest remains `5d66d43d...`, and the production DOCX remains absent.

Per the Order 70c one-stop rule, the corrected program was not resealed or executed. No checker patch, candidate retry, promotion, render, or scope expansion was attempted pending central disposition.
