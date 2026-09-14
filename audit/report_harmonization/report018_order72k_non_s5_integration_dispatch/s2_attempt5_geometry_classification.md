# S2 intended-size preview geometry classification

The initial independent checker is preserved as review_s2_attempt5_capture.R.
It stopped before writing verification results because it assumed the final
PNG dimensions equalled the rounded requested resize box.

Read-only inspection of make_intended_size_previews.mjs establishes a second
aspect-preserving fit-inside operation. The geometry JSON records the requested
box, not the final raster dimensions. R read the PNG IHDR dimensions directly:

| Part | Requested box | Actual PNG |
| --- | --- | --- |
| 1 | 1465 by 854 | 1464 by 854 |
| 2 | 1493 by 727 | 1492 by 727 |
| 3 | 1493 by 741 | 1492 by 741 |

The separately named review_s2_attempt5_capture_verified.R reproduces that
existing two-stage geometry exactly: first round the inch-based target box,
then scale inside it with preserved aspect ratio and round the final pixels.
Every actual dimension matches. No tolerance was broadened. No image, Word
page size or data changed, and no new rendering or capture occurred.

This is a display-only resampling/metadata distinction, not a table-layout
failure. The actual surrogate PNGs were independently inspected at original
resolution and remain legible and uncropped. Native Word page acceptance is
still separate and pending. The dimension CSV records both requested and
actual sizes instead of treating them as interchangeable.
