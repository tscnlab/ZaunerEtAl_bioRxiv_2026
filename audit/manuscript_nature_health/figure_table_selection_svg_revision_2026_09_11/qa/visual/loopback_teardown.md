# Loopback QA teardown

Date: 2026-09-11

The candidate QA tab was closed after the 1440, 708, and 390 CSS-pixel
reviews. The temporary viewport wrapper files were deleted from the served
directory. The byte-exact candidate remains as the sole file in that
directory.

The loopback server on `127.0.0.1:8765` was interrupted normally. A subsequent
`lsof -nP -iTCP:8765 -sTCP:LISTEN` check returned no listener.

The rendered candidate remains SHA-256
`7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4`,
29,370,696 bytes. The QMD and old canonical HTML also remain at their frozen
pre-recovery identities.
