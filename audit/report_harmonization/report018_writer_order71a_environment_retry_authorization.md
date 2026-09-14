# REPORT-018 Writer Order 71a environment-only retry authorization

Authorized at: 2026-09-02T22:07Z

Destination: Nature Health Writer task
`019ffb39-372e-7262-bfac-192751fd0e63`

Status: `AUTHORIZED_ONCE_AND_EXECUTED`

## Basis

The first Order 71a manuscript-HTML command stopped before Pandoc with
`ERROR: unable to open database file` while Quarto attempted to access its
Sass cache. It did not constitute a completed render. The canonical manuscript
HTML remained byte-identical to its accepted preimage, which the Writer copied
to
`audit/manuscript_nature_health/order71a_execution_2026_09_03/preimage_ZaunerEtAl2026_NatHealth_phase3_brown.html`.
The manuscript DOCX and production website also remained byte-identical.

Quarto 1.9.37 on macOS resolves this cache through
`$HOME/Library/Caches/quarto`; the installed bundle does not provide a usable
`XDG_CACHE_HOME` or Quarto/Sass-cache override. Redirecting it through a changed
`HOME` is prohibited. A private-temporary-cache route was therefore explicitly
rejected.

## Exact authorization

One environment-only retry of the same narrow manuscript HTML target was
authorized using normal transactional access to the existing user-owned cache
database:

`/Users/zauner/Library/Caches/quarto/sass/sass.kv`

At authorization it was owned by `zauner:staff`, measured 36,864 bytes, and
had SHA-256
`22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`.
No WAL or SHM companion was present.

The Writer was required to preserve normal `HOME`, `XDG_CACHE_HOME`, and
`DENO_DIR`; freeze and reverify every input and protected output; and run only
the same narrow manuscript HTML target from `manuscript/R0_NatHealth` with
narrowly elevated filesystem access. Cache deletion, reset, copying, renaming,
permission changes, ownership changes, source edits, configuration edits,
package changes, Word rendering, website rendering, supplementary-only
rendering, project rendering, and scientific execution were prohibited.

Any failed retry or new substantive error required a fail-closed stop without
a second retry. Orders 71b and 71c remained held.

## Frozen identities

The accompanying non-circular manifest records the exact frozen manuscript,
Supplementary Information, accepted Table 3, accepted participant-profile SVG,
pre-render HTML preimage, protected DOCX, protected website, configuration,
stylesheet, bibliography, and cache identities. The Writer executed the retry
after receiving the authorization in its task. This durable record was written
immediately afterward because the successful retry completed before the file
seal could be persisted.

Manifest:
`audit/report_harmonization/report018_writer_order71a_environment_retry_authorization_manifest.csv`

Orders 71b and 71c are still held pending independent acceptance of the full
Order 71a source and HTML seal.
