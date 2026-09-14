# Order72k initial render cache failure

The Writer's first selection HTML command failed before producing output.
Its retained log identifies `Deno.openKv` from `sassCache`, with the message
`unable to open database file`. No subsequent render or visual inspection
was attempted.

Read-only inspection by the Harmonizer confirms the installed Quarto 1.9.37
implementation in `/Applications/quarto/bin/quarto.js`:

- `darwinUserCacheDir`, lines 36128-36134, uses
  `HOME/Library/Caches/quarto` for the Quarto cache.
- `compileWithCache`, lines 87610-87612, uses the project temporary Sass cache
  only for inputs containing `@import`; other inputs use the shared cache.
- `sassCache`, lines 79977-79988, opens `sass.kv` in that directory.
- The supplied `QUARTO_CACHE_DIR` variable is not read by this implementation.

The failed command and log are preserved under the Writer candidate root as
`selection_html_attempt1_command.json` and `selection_html_attempt1.log`.

No change to HOME, shared-cache repair, installed-runtime edit, Sass-content
workaround or silent render retry was made. The Coordinator was asked to
confirm an environment-only extension: a process-local copy of the installed
JavaScript bundle with only the macOS cache function redirected to an explicit
task temporary directory, preserving installed Deno/resources and render
logic. A logged environment retry would retain the aborted command evidence
and leave the subsequent layout-correction budget unchanged. This proposal
is not itself a completed fix or authorization receipt.

Writer was informed of the pending disposition. Its exclusive visual lease
remains reserved; there is currently no active visual surface or listener.
All scientific execution and canonical promotion remain outside scope.
