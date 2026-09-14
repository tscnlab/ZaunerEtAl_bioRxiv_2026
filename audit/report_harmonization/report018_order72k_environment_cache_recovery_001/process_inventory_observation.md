# Read-only process boundary

2026-09-11, before the additive recovery seal. The sandbox first rejected
`/bin/ps` with operation not permitted. A separately reviewed, narrowly
elevated read-only process inventory succeeded. No process was stopped.

Command:

```sh
/bin/ps -axo pid,ppid,etime,command | rg 'quarto|pandoc|[Dd]eno|[Ll]ibre[Oo]ffice|soffice|capture_word_tables|order72k|http.server|embed_accepted_svg'
```

The only two matching rows were the inventory shell itself (PID 33918) and
its rg filter (PID 33920). No competing Quarto, Pandoc, Deno, Order72k render,
capture, office-render or preview-server command was found. Both Harmonizer
and Writer task snapshots were idle at this boundary. Writer's visual lease
is reserved but no surface or listener has started under the stopped attempt.

This observation is not permission to kill unrelated R processes. The owner
must perform a fresh scoped conflict check immediately before its retry.
