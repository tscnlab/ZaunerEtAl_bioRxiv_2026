# REPORT-018 Order72j H07 visual lease 003 stop

Status: `STOPPED_POLICY_BIND_REJECTED_BEFORE_CONTENT_LOAD`.

Visual acceptance: `FALSE`. This is a route-policy stop, not a demonstrated component or page defect.

Lease `ORDER72J-VISUAL-LEASE-003` is explicitly released with no browser content load. Mandatory gate: `REPORT018-ORDER72J-COMPONENT-REVIEW`.

## Exact stop

- Command: `python3 -m http.server 43137 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/hypotheses/H07/report018_order72j_split_svg_export/qa/serve`.
- Exit status: `1`.
- Error: `PermissionError: [Errno 1] Operation not permitted` during `TCPServer.server_bind()`.
- Per the dispatch instruction, no escalation and no alternate browser or serving route were attempted.
- No content loaded, no browser tab was created, no screenshot was taken, and browser console evidence is unavailable.

## Prepared immutable route

The narrow serve root contains exactly four non-symlink files: a byte-exact candidate SVG copy, a byte-exact pinned PNG comparator copy, one route index, and one local comparison page. The page exposes intrinsic proportion, 642 CSS px and 708 px routes with no external resources. Because binding was rejected, all requested visual observations are `NOT_INSPECTED`.

## Teardown and preservation

The server process exited on bind rejection. A post-stop `lsof` check found zero listeners on 127.0.0.1:43137. No task-created browser tabs or persistent processes remain.

The SVG candidate remains unchanged at SHA-256 `f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57` and was not promoted. The accepted static handoff and static non-circular manifest remain byte-exact. Post-stop R 4.6.1 replay passes the 123-row release manifest, 39 H07 execution pins and 1,451-entry H07 preservation inventory.

No renderer correction, Quarto, Word, LibreOffice, scientific computation, source mutation or accepted-artifact replacement occurred.
