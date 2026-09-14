# Browser QA limitations

Date: 2026-09-11

- The supported in-app browser did not expose a direct fixed-viewport resize
  command for the content page. Read-only fixed-width wrapper pages were used
  and disclosed in the viewport banner. The reviewed iframe widths were
  exactly 1440, 708 and 390 CSS pixels.
- Screenshots were emitted to the review conversation for visual inspection.
  The supported browser surface did not provide a path for saving those
  screenshots as local files, so no local screenshot hashes are claimed.
- The QA wrapper's instrumentation emitted a MutationObserver error because it
  attempted to observe a non-Node before the iframe target existed. Two such
  wrapper-only console entries were recorded while changing wrapper widths.
  The direct candidate had previously shown no candidate-originating console
  error, and the DOM, image, table and overflow checks in this run all passed.
- Browser QA does not establish Microsoft Word compatibility. Writer's native
  Word findings, including the Supplementary Figure S5 blank-panel failure,
  remain a separate stopped-candidate issue and require their own repair and
  native Word review.
