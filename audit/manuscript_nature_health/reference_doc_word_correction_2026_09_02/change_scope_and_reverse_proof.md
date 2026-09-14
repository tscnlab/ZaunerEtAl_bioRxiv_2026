# Order 69 authorized change scope and reverse proof

Date: 2026-09-02

## Nested Quarto profile

- Preimage SHA-256: `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
- Postimage SHA-256: `c7c3fc8a96f1e65914cfb88c8d4de2bf8bcacb75fcf37902b262c79d2becae24`
- Change: one added line, `reference-doc: ../../assets/reference.docx`, in the DOCX format block.
- YAML parse: passed with R 4.6.1 and renv autoloading disabled.
- V0 behavior retained: `toc: false` and `number-sections: false`.
- HTML format block: byte-identical to the preimage.
- Reverse proof: applying the reverse of the one-hunk diff to a temporary copy of the postimage produced SHA-256 `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`, exactly matching the preserved preimage.

## Word postprocessor

- Preimage SHA-256: `0e6310467104be48993ca00f63d18e8e0b6d9ac7b59605ac18f749ee250a8d9c`
- Postimage SHA-256: `aae7c9307510ee5adc295e9e4d93e39496b0b50cc47d46bcfe5f22c6cf28e2c7`
- Change site 1: `set_final_portrait_section()` now receives the already captured `base_sect_pr`; its final page-size and margin elements are required and deep-copied from that base, with only page orientation normalized to portrait.
- Change site 2: the sole call passes `base_sect_pr`.
- Compile check: passed with the bundled document Python runtime.
- Reverse proof: applying the reverse of the focused diff to a temporary copy of the postimage produced SHA-256 `0e6310467104be48993ca00f63d18e8e0b6d9ac7b59605ac18f749ee250a8d9c`, exactly matching the preserved 25,939-byte preimage.

No manuscript text, bibliography, stylesheet, display asset, capture implementation, reference document, accepted HTML, canonical DOCX, or website file was changed during these checks.
