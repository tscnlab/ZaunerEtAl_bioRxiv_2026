# H03 order 34 reverse-substitution proof

Date: 2026-08-14

## Result source

The result preflight source is the exact Git `HEAD` blob for
`notebooks/hypotheses/H03.qmd`. Reading that blob without checkout produces
SHA-256 `5d329c24afbd321a2be8d87ca7453a8612ab6745d009d4cecef2c82a4c6dd59a`
and 67,332 bytes, exactly matching the order-34 preflight pin. Reversing the
current source diff against that blob therefore reproduces the sealed
preflight identity.

## Companion source

The companion had an accepted pre-existing owner modification, so its
preflight identity was not the Git `HEAD` blob. An R 4.6.1 in-memory reverse
substitution was applied to the final byte stream. It made only the exact
inverse order-34 operations:

- removed `lightbox: true`;
- removed the auxiliary read and manifest-verification block;
- restored the `Purpose`, site-registry, verification-state, site-alt-text,
  estimand-source-model, and multiplicity display strings;
- removed the auxiliary subsection and its one table;
- removed the auxiliary script and output-map rows and restored the prior
  row numbers;
- removed the four new table-label mappings; and
- removed the auxiliary environment row.

The reverse-substituted byte stream contained 64,129 bytes and produced
SHA-256 `b7671d848544228088df9bbe179a172fd7402e7fa18c3029be9b499d0ef2f760`,
exactly matching the companion preflight pin.

## Final identities

The forward sources are:

- result: `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`,
  68,198 bytes;
- companion:
  `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`,
  75,638 bytes.

The reverse proof operated in memory and did not write a replacement source,
artifact, render, model, or scientific output.

