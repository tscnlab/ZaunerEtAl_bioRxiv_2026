# Nature Health final serial render completion

Status: **ACCEPTED**

Date: 2026-09-01

Runtime: R 4.6.1 and Quarto 1.9.37.

## Final reader endpoints

- Main manuscript HTML: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - SHA-256: `62fd223a4b5cdb5dfa646515cad47cac75dfbd06f5ac9e390615395acb6d9124`
  - Bytes: 30,528,125
- Standalone Supplementary Information HTML: `manuscript/R0_NatHealth/_output/supplementary_information_standalone.html`
  - SHA-256: `4db7c0d6318da11c9b46959817a175ef773fee86029d6bbda23117c3bb9a3697`
  - Bytes: 18,525,374

## Preserved source pins

- Main QMD: `bc24cc7393a550d50ea0d4c337ad637c6347bb4762293f6f127183dab1d9a5ff`
- Supplement outline QMD: `d7e7ca45a833f573fce99798044599b6387eb04755106116c961a0326c0d130a`
- Standalone supplement wrapper QMD: `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b`
- Display CSS: `e990b471a30a52ba83d86ad0867edc3dd89bae0b5e0c9b7d8f91d376ba6096ea`
- Main Table 3 fragment: `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`
- Nested Quarto configuration: `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`

## Render and semantic disposition

The initial main render attempt stopped before output mutation because the sandbox could not open the existing Quarto Sass cache. One environment-only retry of the identical target command with access to the existing user-owned cache completed successfully. The standalone supplement then rendered successfully once.

The raw main render had eight duplicate internal `gt` IDs shared by exactly two embedded tables. A candidate-first, byte-level repair changed only their `id` and `headers` values. The 191-row ledger records 47 ID and 144 headers substitutions and reverses exactly to raw-render SHA-256 `ec9eb3e9974d2a94788dade97bcec181201508dad3449464f1d22986107789fe`. Visible text, table structure, captions, rows, cells, figures, links, and all non-semantic attributes were unchanged.

The final main page passes 20 native tables, 19 figures, 573 unique IDs, 2,882 scoped header tokens, and 85 internal fragment links. The standalone supplement passes 17 native tables, 16 figures, 352 unique IDs, and 2,090 scoped header tokens. The pre-render and post-render output inventories both contain 20 files; only the two authorized HTML endpoints changed.

## Visual acceptance

Secure loopback QA used only `manuscript/R0_NatHealth/_output`, bound to `127.0.0.1:53113`, after a zero-symlink preflight. Both pages passed at 1440 by 1000 and 390 by 844 pixels. Representative figures were also inspected at a 720 by 500 viewport, yielding 654-pixel display width. Wide tables remained contained and horizontally operable. Main Table 3 preserved the six required thematic groups and its scroller was exercised at desktop and phone width. There was no page-level overflow, broken figure image, duplicate document ID, or browser console warning or error.

The browser viewport was reset, the QA tab was closed, the server was stopped, and `lsof` found no listener on the QA port. Source and output identities were rechecked after teardown.
