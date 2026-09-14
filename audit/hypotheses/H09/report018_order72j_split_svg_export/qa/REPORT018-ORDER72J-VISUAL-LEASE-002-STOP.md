# REPORT018-ORDER72J-VISUAL-LEASE-002: H09 fail-closed return

Date: 2026-09-11

Status: `STOPPED_BEFORE_CONTENT_LOAD_POLICY_BIND_REJECTED`

Visual lease: `ORDER72J-VISUAL-LEASE-002`

Lease disposition: `RELEASED_WITHOUT_VISUAL_ACCEPTANCE`

## Scope and preflight

The static H09 Order72j package was unchanged at the start of this lease. A
read-only R 4.6.1 preflight rehashed all 123 release rows, 37 H09 execution
pins, and 566 H09 preservation rows. Both candidate SVGs remained exact and
byte-identical to their sole retained trials.

Only the bounded directory `qa/serve/` was prepared for the already-authorized
loopback comparison route. It contains immutable copies of the two candidate
SVGs and their pinned accepted PNG and PDF comparators, plus two static local
HTML route files. It contains no symlinks and no external resources. No project
root, artifact root, or source-data root was exposed as the server root.

## Exact loopback stop

The selected unused port was `43129` on `127.0.0.1`. The sole server attempt
was:

```text
python3 -m http.server 43129 --bind 127.0.0.1 --directory <project-root>/audit/hypotheses/H09/report018_order72j_split_svg_export/qa/serve
```

The process exited with code 1 before a listener was created and before any
content loaded. The controlling exception was:

```text
PermissionError: [Errno 1] Operation not permitted
```

This is a policy or sandbox bind rejection, not a candidate, comparator,
source, or scientific-contract failure. The lease instructed the owner to stop
immediately if policy rejected loopback before content loaded. No escalation,
alternate port, alternate server, direct file navigation, or retry was used.

## Browser and visual disposition

No in-app browser tab was created, so there is no route viewport, page console,
screenshot, or panel-level visual observation to report. Intrinsic, 642 CSS px,
708 px, PNG, and PDF comparisons were not performed. Consequently, this lease
does not establish visual acceptance or rejection of either candidate.

No candidate, trial, accepted PNG/PDF, source CSV, plotting source, test, QMD,
HTML build, Quarto configuration, Word artifact, model, or promoted artifact
was modified. No correction trial was consumed.

## Teardown and final protection

The failed server command returned synchronously and yielded no live execution
session. A post-stop `lsof` check found zero listeners on
`127.0.0.1:43129`. There were zero task-created browser tabs to close. The
candidate SVGs, their retained trials, the original 25-row static seal, the
original component-review handoff, and all 123 + 37 + 566 protected pins were
rehash-checked again before the separate QA seal was created.

The original `non_circular_manifest.csv` was not overwritten. The new
`qa_non_circular_manifest.csv` seals only the lease-specific QA package and
excludes itself.

Final visual disposition at `REPORT018-ORDER72J-COMPONENT-REVIEW`:
`VISUAL_QA_NOT_RUN_POLICY_BIND_STOP`.

