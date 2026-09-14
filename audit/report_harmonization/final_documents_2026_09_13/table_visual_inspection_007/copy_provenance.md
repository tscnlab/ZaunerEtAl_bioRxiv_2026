# Inspection evidence copy provenance

The findings.md copy is byte-identical to the coordinator's temporary record at SHA-256 bf29758614a60addda56608b8f96aec1b91d50bb9ced7b86e98ec44a764853c1.

The two durable JSON copies add only one final LF to the original compactly terminated files. Their complete parsed contents and all protected file identities are exact. The originals remain at /private/tmp/table-visual-inspection.PrNv3t/.

- Original preflight.json: 5,291 bytes; 03c25670c8f4923fc0131f0e54c2f742755da169cde580f226c2ac139996bce5.
- Original postflight.json: 5,161 bytes; 57fa34ca245ce8b2c1032cae3877798ddd3a68eeb0db69c85cbacb9dd1dd6962.

The dispatch manifest pins the actual durable copies, including their final LF. An initial coordinator copy check expected the original byte hashes and stopped before dispatch-manifest creation. Exact byte comparison identified only this terminal-newline difference. No source package, candidate, scientific file or browser state changed during that check.
