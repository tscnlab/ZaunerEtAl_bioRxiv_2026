# Order 61a bounded loopback lifecycle

- Served root: `_build/nathealth` only.
- Bind address: `127.0.0.1`.
- Port: `53671`, confirmed unused before start.
- Command: `python3 -m http.server 53671 --bind 127.0.0.1 --directory _build/nathealth`.
- Inspected route: `/audit/hypotheses/H11/H11_analysis_preparation.html`.
- Required viewports: 1440 by 1000, 708 by 1000, and 720 by 500.
- Figure proof width: 642 pixels, corresponding to the intended 170-mm placement.
- Read-only link checks: nine HEAD requests returned HTTP 200, including the result report, deviations page, H02 companion, and all paired source-data targets.
- The server log contained successful page, asset, script, style, figure, and HEAD requests. One browser-automatic request for unreferenced `/favicon.ico` returned 404. It produced no console warning, no visible missing content, and no semantic or interaction defect.
- All agent-created QA tabs were closed and the viewport override was reset.
- Server shutdown: keyboard interrupt, exit status 0.
- Post-shutdown `lsof -nP -iTCP:53671 -sTCP:LISTEN`: exit status 1 with no output.
- Post-shutdown `pgrep -af '[p]ython3 -m http.server 53671'`: exit status 1 with no output.
- Final disposition: PASS. No listener or server process remained.
