# Order 69b pre-execution gate

Date: 2026-09-02

- Controlling order: 10,094 bytes, SHA-256 `2a563d1d237c84b87055cf2452797b43960eedde1d87ee6b3a4c17ac0f2b2f34`.
- Dispatch manifest: 2,986 bytes, SHA-256 `79f30002833cad3f593c5b7cd89e94fa6e61909ea71bbd689e63b762513ba4c0`.
- Postprocessor preimage: 28,151 bytes, SHA-256 `f4cec2eaddf7d5ce375573af5bd2c0ad92366d8869d7c23d66d4bb435e139135`.
- Preserved raw DOCX: 9,915,026 bytes, SHA-256 `a3f73e877106d8576a6aed362d6447551d68d366fd2e4c7a82ca7909329fb405`.
- Failed Order 69a candidate remains preserved at 28,792,313 bytes, SHA-256 `30fc35924e573ae4311b413127f08388bb3aa2bcb771ffaa1b7ae9e5ff200a25`.
- Stopped canonical DOCX remains preserved at 28,792,251 bytes, SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009`.
- The QMD, nested profile, accepted HTML, reference DOCX, table-capture manifest, and supplementary-figure-capture manifest match every identity required by Order 69b.
- The focused code change is limited to one footer-suppression helper and one call from `main()`. See `order69b_postprocessor.diff`.
- Compile check: PASS with the bundled document Python runtime.
- Postprocessor postimage: 31,160 bytes, SHA-256 `05ed9ca826757c643970a6d201fbcc15cfc83648d2ebdc8d44f707d85f214727`.
- Exact reverse proof: applying the reverse focused diff to a temporary copy of the postimage produced the 28,151-byte SHA-256 `f4cec2eaddf7d5ce375573af5bd2c0ad92366d8869d7c23d66d4bb435e139135` preimage.
- Read-only process filtering found no competing manuscript Word postprocessor, document renderer, Quarto render, or Nature Health website build. A separately opened LibreOffice application process was not acting on this repository and was left untouched.

Authorized next action: one postprocessor execution using only the preserved raw DOCX and the two accepted PNG manifests, writing one fresh candidate.
