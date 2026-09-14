# Brown Stage 4 Sass-cache retry verification

Date: 2026-08-21

R 4.6.1 release checker:

```text
BROWN_ORDER51_SASS_RETRY_RELEASE=PASS acceptance=24/24 owner_stop=45/45 endpoints=5/5 quarto=1.9.37 sass_route=user_cache deno_kv=version_1 cache=exact owner=current_user failed_paths=absent R=4.6.1 digest=0.6.39
```

Direct bundled-Deno probe, executed once with elevated access:

```text
{"path":"/Users/zauner/Library/Caches/quarto/sass/sass.kv","version":1}
```

The probe left `sass.kv` exact at 36,864 bytes and SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`.
No `sass.kv-wal` or `sass.kv-shm` file remained. The failed first probe used
unsupported bundled-Deno permission flags, exited before opening the database,
and made no cache or project change. Air 0.4.1 and R parsing pass for the
release checker.
