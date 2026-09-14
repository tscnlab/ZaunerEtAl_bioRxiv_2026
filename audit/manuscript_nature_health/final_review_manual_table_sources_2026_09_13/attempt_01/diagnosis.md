# Attempt 01: structural-check stop

The static page builder completed. The verifier stopped at the final selected
body row of S2 part 1. Inspection showed a single trailing newline after the
closing `tr` tag in the source node serialization, absent when that row became
the last row in a sliced table. Source/candidate strings were 115,073 and
115,072 characters; every character through the shorter string matched.

This was serialization outside the row, not a cell, image, number, header or
scientific-content difference. The subsequent verifier removes only terminal
CR/LF after each serialized row. It does not normalize cell whitespace or
relax any content, attribute, image-payload or note check. This stopped attempt
and its exact executed verifier/checks are retained. Attempt 02 rebuilds the
same pages and reruns the complete checks. No browser or visual trial occurred.
