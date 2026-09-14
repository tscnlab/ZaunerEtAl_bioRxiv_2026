# Order72k stylesheet cache stop

The first selection HTML attempt started at 2026-09-11 18:44:11 UTC and exited
at 18:44:12 UTC with status 1. No HTML was produced. The log reports
`ERROR: unable to open database file` at `Deno.openKv` inside `sassCache`.

The candidate runner supplied `QUARTO_CACHE_DIR` pointing to the new task
temporary directory. Read-only inspection of installed Quarto 1.9.37 shows
that it does not read this variable. Its `darwinUserCacheDir` instead derives
`Library/Caches/quarto` from the existing user home, and the stylesheet compiler
calls `sassCache(quartoCacheDir("sass"))` for this bundle. The requested
candidate cache directory was not created. This is an environment/preflight
defect in the runner's chosen cache override, not an input-identity or
scientific-result discrepancy.

No automatic retry was made. No shared cache repair, home-variable override,
runtime modification, package installation or other out-of-scope workaround
was attempted. The harmonizer has been asked for a bounded environment
disposition. The initial command and failure log remain unchanged.

Trial state: selection HTML 1 of 2 used, failed before output; main HTML 0 of 2;
main DOCX 0 of 2; Word assembly/embedding 0 of 2; office QA 0 of 2; S2 captures
0 of 3; table S5/S6/S10 captures 0 of 2. Candidate source preparation is
complete, but there is no new rendered candidate to accept.

No browser tab, document, static server, listener, office renderer, capture
browser or scientific process was started by this order. The one rendering
subprocess has exited. No other task or research process was interrupted.

Current candidate paths and expected operations are recorded in
`dry_run_manifest.json`. The helper and authoring-source diffs are retained.
The original release, input pins and dependency addendum were not modified.
