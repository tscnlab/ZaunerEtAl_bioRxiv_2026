# S2 attempt4: independent source-based guard diagnosis

The actual granted capture exited1 before any PNG was written. This is a
failed execution, not a visually accepted S2 repair.

Independent read-only R 4.6.1 reconciliation matches every one of the seven
reported error strings exactly to the first seven of 17 distribution
accessibility descriptions in both the immutable rendered main HTML and
the original protected table fragment. All 17 descriptions are span nodes
with the same inline style:

```css
position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0
```

The unchanged text is intentionally visually hidden. The new guard walks
every text node and compares Range rectangles to the cell without accounting
for that explicit source clipping. Source-based inference: the seven flags
are false positives for accessibility-only content, not evidence that those
descriptions should be visible or that the distribution column needs widening.

No Unit or Scaling string appears in the first-part error list. This does
not constitute visual acceptance of their new widths. No part was captured,
and neither original-size nor intended-Word-size inspection is available.

The smallest prospective correction would preserve all 17 descriptions and
their source styles, continue checking all visible text in every cell on both
axes, and separately account for only these exact source-proven hidden spans.
It must not broadly skip arbitrary clipped content or suppress visible text
overflow. This is a recommendation for coordinator release only, not an edit,
retry or permission to accept a failure. The frozen width/font/padding/image
settings and all existing holds remain unchanged.

Evidence: diagnose_s2_attempt4_guard.R,
s2_attempt4_guard_classification.csv and
s2_attempt4_guard_classification_session.txt. No new browser invocation,
render, capture, source mutation or scientific computation occurred in this
independent diagnosis.
