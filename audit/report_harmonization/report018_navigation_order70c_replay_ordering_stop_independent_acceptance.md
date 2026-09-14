# REPORT-018 Order 70c replay-ordering stop independent acceptance

Date: 2026-09-02

Status: `PASS_FAIL_CLOSED_STOP_ACCEPTED`

The Order 70c owner stop is accepted as an evidence and execution-ordering
defect, not as a manuscript, figure, table, or site defect. The owner stopped
before resealing or executing the corrected integration program and before
changing the retained candidate or any production path.

Independent checks reproduce the stop record at SHA-256
`1b4f0b5f5945f6bb2477b7e7d5aa7e17c240ea7e1e7e436647a5bc5ddd92d01a`,
1,742 bytes, and its eight-row non-circular manifest at SHA-256
`a85fb9812c1c328ed61a880bfa886a26c2a2eeae89dfa4bdeb6fcce279649f15`,
1,343 bytes. All eight rows reproduce exactly.

The corrected but unexecuted Order 70c program remains at SHA-256
`59a17d431b754e6bab2a79578ec19edf4c56c227eb265e4b91d06c6302fa1175`,
52,650 bytes. The historical central checker remains byte-identical at
`0a0261563f4f3f9ac954fa906ddd8bbebfc96042dbdc6a062d52632c0b1df44f`,
15,958 bytes. Its immutable preimage assertion explains the stop exactly.

The retained candidate contains exactly 892 regular files, zero symbolic
links, and reproduces the accepted build inventory. Its landing page and the
live landing page both remain at `600b7a3d...`. The production corpus manifest
remains at `5d66d43d...`, and the production Word download remains absent.

No Quarto, knitr, Pandoc, QMD, manuscript, scientific, browser, candidate
transformation, promotion, or production operation occurred in the stopped
attempt.

