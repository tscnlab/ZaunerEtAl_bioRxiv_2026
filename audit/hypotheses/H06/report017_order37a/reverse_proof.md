# H06 order-37a two-step reverse-substitution proof

The order-37a unified patch is `exact_source_diff.patch`, SHA-256
`3fdf8165340f0a4c9bfdb155adf32ee51839e26dbb52842dd445ae655691b45a`.

The one-shot R 4.6.1 verifier copies the final result, unchanged companion,
and final handoff into an R temporary directory. It first applies the 37a
patch in reverse and requires exact reconstruction of the stopped order-37
identities:

- result: `938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061`,
  60,541 bytes;
- companion: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes; and
- handoff: `5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3`,
  10,408 bytes.

It then applies the historical order-37 patch in reverse and requires exact
reconstruction of the accepted pre-order-37 identities:

- result: `692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459`,
  56,355 bytes;
- companion: `205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731`,
  55,895 bytes; and
- handoff: `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829`,
  24,781 bytes.

Both reverse operations occur only in the temporary directory. They do not
modify project sources or historical evidence.
