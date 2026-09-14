# First candidate: bounded partial visual check

S2 part 3 was actually inspected at desktop and 708px narrow widths. The
document remained 708px wide, a horizontal gesture outside the table did not
move the page, and the table reached its right edge through keyboard scrolling.
The rendered 14-column grid matched the specification and no cell scroll-width
overflow was found. All timing rows and final notes were seen across the left
and right views; complete distribution plots were visible at 244px width.

The first right-view geometry snapshot preceded completion of its scroll
gesture. Its screenshot and metadata are retained, but it is not used as a
matched screenshot/geometry verdict. The later keyboard-right screenshot and
post-screenshot geometry establish the actual right edge. Native coordinate
scroll/drag attempts did not reliably reach the target under the viewport
override; supported region-focused keyboard input did. No browser denial
occurred and no browser surface was changed.

The next candidate adds a CSS-only, explicitly labelled inherited-width proof
control to the wrapper. This enables an actual visual comparison at 15.55in
for S2 and 10.55in for Table 2/S7 without changing the table fragment or its
source font sizes. This proof is not final Word or print acceptance.
