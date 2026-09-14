# REPORT-017 order 32c render execution record

## Scope and command

- Target: `notebooks/hypotheses/H01.qmd`
- Command: `quarto render notebooks/hypotheses/H01.qmd --profile nathealth`
- Render count: one
- Companion or other target render: none
- Profile: normal project `.Rprofile` and `renv/activate.R`
- Narrow permission: existing user-owned renv cache only
- Exit status: 0
- Process runtime: 92.56 seconds
- Launch request: 2026-08-15T05:50:26Z
- Completion observed: 2026-08-15T05:52:39Z
- Quarto: 1.9.37
- R: 4.6.1
- Consequential packages: gt 1.3.0, xml2 1.6.0, rvest 1.0.5, knitr 1.51

## Configured semantic hook

The final hook line was:

```text
gt-html-semantics target=_build/nathealth/notebooks/hypotheses/H01.html disposition=REPAIRED pre=72593d59a28275720b192613c19547a3149cbf4c0175575714fdd30fec41f1e1 post=d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410 tables=36 ids=783 headers=4798
```

The final HTML is 1,643,915 bytes with SHA-256
`d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`.
The companion HTML remained byte-identical at SHA-256
`5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

## Evidence limitation

The full live Quarto console stream was not written to an audit log before the
terminal session closed. The command, lifecycle, exit status, final output,
versions, and exact hook line above are retained, but this does not satisfy the
order's request to preserve the complete console transcript. This limitation
is included in the combined stopped-state defect list. No second render was
run to reconstruct it.

