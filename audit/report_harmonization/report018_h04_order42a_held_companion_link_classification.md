# REPORT-018 H04 order 42a held-companion link classification

Date: 2026-08-20

Finding: `H04-42A-001`

Disposition: **EXPECTED HELD-COMPANION INTEGRATION DEPENDENCY. NONBLOCKING FOR
RESULT-PAGE VISUAL ACCEPTANCE.**

The fresh H04 result page links once to:

`../../audit/hypotheses/H04/H04_analysis_preparation.html#sec-h04-prep-participant-random-intercept`

The current accepted companion QMD contains the explicit target anchor exactly
once. The held companion HTML predates that accepted source synchronization,
so it still exposes the older generated section ID and lacks the new explicit
anchor. Order 42a intentionally rendered only the result page and held the
companion.

R 4.6.1 independently verified the order-42a 24-row owner manifest, all 260
protected identities, all 17 tables, all seven figures, and the complete
static-gate record. The link above is the only unresolved reader link. All
other internal links, 26 source-data links, five preregistration-deviation
links, semantic ID references, navigation, and country-site checks pass.

Under REPORT-018 render-completion priority, this exact fragment mismatch is
deferred to the immediately following H04 companion render. It must resolve
after that render. No second unresolved internal link is permitted, and the
classification does not authorize a source edit, result rerender, companion
render, or link suppression.

The fresh H04 result HTML remains
`da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`.
It may proceed to secure-loopback visual QA without rerendering. Final result
acceptance requires that visual QA and post-QA stability pass. The H04
companion and all later renders remain held until then.
