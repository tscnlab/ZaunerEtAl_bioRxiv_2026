# Stopped source check

The first verifier stopped when it passed HTML row markup containing an HTML
`<br>` element to the strict XML parser. The parser reported a br/th closing-tag
mismatch. The source row was valid HTML; no scientific text or source file was
changed to address this checker issue.

The corrected checker parses row copies as HTML inside a temporary table and
then removes only the three documented candidate layout attributes before
comparison. The original executed verifier remains here. The next complete
verification uses `verification_v2/`. All six candidate pages and source
fragments remain unchanged from the first build.
