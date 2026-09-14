# REPORT-018 H11 Order 60 Sass-cache probe

Date: 2026-08-22

The Order 60 render completed all 53 knitr cells and then failed before HTML
production with `ERROR: unable to open database file` in Quarto Sass-cache
resolution.

The installed Quarto 1.9.37 bundle is byte-exact at SHA-256
`6c6abf6ecabde086cfe8a3f12bfcd4270b64f5fff75a30cd1d0b30ecf7295338`.
Its macOS route uses `darwinUserCacheDir()`, `quartoCacheDir("sass")`, and
`Deno.openKv()` for the database at
`/Users/zauner/Library/Caches/quarto/sass/sass.kv`.

The database is owned by user `zauner`, is 36,864 bytes, and has SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`.
A sandboxed read-only SQLite open reproduced `unable to open database file`.
The Quarto-bundled Deno 2.4.5 opened the same database once under narrow
elevated access and returned:

```json
{"path":"/Users/zauner/Library/Caches/quarto/sass/sass.kv","version":1}
```

The probe left the database byte-identical and left no `sass.kv-wal` or
`sass.kv-shm` file. No cache file was deleted, cleared, copied, redirected,
renamed, chmodded, or chowned.

A fresh elevated process and listener inventory found no H11, Quarto, Pandoc,
semantic-hook, or task-owned loopback process. One unrelated LightLogWeb
Shiny R process on `127.0.0.1:8767` was observed and left untouched.

This reproduces the previously accepted Brown Stage 4 and H09 environment
boundary. It is not evidence of a source, scientific, semantic, or page
defect.
