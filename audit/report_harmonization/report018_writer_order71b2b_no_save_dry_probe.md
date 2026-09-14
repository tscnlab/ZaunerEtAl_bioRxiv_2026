# REPORT-018 Order 71b2b no-save dry-probe record

Date: 2026-09-03

Disposition: `PASS_FOR_ONE_RECOVERY_INVOCATION`

The Order 71b2a failure was reproduced as a generic-lxml serialization API
mismatch. The current helper contains four `bookmark.xml` accesses on generic
`lxml.etree._Element` objects. Its remaining `.xml` accesses are on
python-docx custom OOXML classes and are valid.

A read-only source transform was evaluated without editing the project source:

1. import `lxml.etree`;
2. replace exactly four generic `bookmark.xml` snapshots with
   `etree.tostring(bookmark, encoding="unicode")`;
3. execute the entire postprocessor workflow from the frozen raw DOCX in
   memory;
4. serialize the resulting DOCX only to an in-memory byte buffer; and
5. assert that the pseudo output path did not exist before or after the probe.

The bundled document runtime completed the full in-memory workflow and all
pre-repair, post-repair, exact-reversal, author-block, image, table and section
assertions. Results were:

- 124 internal hyperlinks and 102 unique target names;
- exactly 195 unique bookmark names after exactly 22 additions;
- zero unresolved targets;
- zero `fig-s3` hyperlinks and zero `fig-s3` bookmarks;
- 53 inline shapes, zero top-level tables and 27 sections;
- exact reversal after removing the 22 new pairs; and
- no filesystem DOCX output.

The probe found no second python-docx versus generic-lxml API mismatch in the
added helper. The project source remained at SHA-256
`074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71`
and 47,744 bytes throughout the probe.

