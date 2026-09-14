# H06 order-37 reverse-substitution proof

The exact unified patch is `exact_source_diff.patch`, SHA-256
`a4f676fe588fdd72f76081244129ba032908ca7d37683776fa2411f8ae1c485a`.

The one-shot R 4.6.1 source test copies the three final mutable sources to a
temporary directory and applies this patch in reverse with path strip level 1.
It then requires the reconstructed files to reproduce these sealed pre-edit
identities exactly:

- `notebooks/hypotheses/H06.qmd`:
  `692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459`,
  56,355 bytes;
- `audit/hypotheses/H06/H06_analysis_preparation.qmd`:
  `205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731`,
  55,895 bytes; and
- `audit/handoffs/H06_worker_handoff.md`:
  `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829`,
  24,781 bytes.

The reverse operation occurs only in an R temporary directory. It does not
modify the project sources. The test compares the reconstructed and final QMD
structures before deleting the temporary directory.
