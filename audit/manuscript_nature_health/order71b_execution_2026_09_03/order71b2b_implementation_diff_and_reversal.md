# Order 71b2b implementation diff and reversal

Date: 2026-09-03

The recovery changed only
`scripts/manuscript_nature_health/prepare_word_manuscript.py`.

- sealed recovery preimage: SHA-256
  `074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71`,
  47,744 bytes;
- recovery postimage: SHA-256
  `aeeabb11d97d812627de53b29e92e92f7fc6a87c5dc7006d223232c2f2ab20a4`,
  47,981 bytes.

The focused diff adds one `lxml.etree` import and replaces exactly four
generic bookmark-element `.xml` snapshots with
`etree.tostring(bookmark, encoding="unicode")`. `root.xml`,
`reversed_root.xml`, paragraph `_p.xml` snapshots and all other logic remain
unchanged. The companion verifier removes exactly these changes in memory and
requires the sealed preimage hash and byte count.
