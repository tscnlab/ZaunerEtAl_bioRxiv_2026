# REPORT-018 Writer Order 71b predispatch proof

Date: 2026-09-03

Disposition: `PASS_WITH_CORRECTED_RELOCATION_CONTRACT`

## Reference and source identities

The V0 compact-author reference, Word reference document, installed
authors-block filter, accepted manuscript sources, accepted HTML, and protected
canonical DOCX all match the exact identities in the accompanying non-circular
manifest. The V0 front matter has one compact numbered line containing 28
authors, then the date, one paragraph containing 14 numbered affiliations, the
correspondence paragraph, and the Abstract heading.

## Independent isolated reproduction

The installed authors-block filter was previously exercised against the
Nature Health metadata in the isolated raw DOCX at SHA-256
`695730aa60d02dd4861b97d20ea68aca55c64b995e50e8a841b1b8b566495beb`.
Independent inspection confirmed one compact line containing all 28 accepted
authors in source order and one paragraph containing all 14 accepted
affiliations in source order. The filter placed the affiliation and
correspondence paragraphs after the YAML abstract.

The historical relocation helper at SHA-256
`90f6e4b0f9d993950f4b317651463e901ba1ac4e541736aed8f51292adda4744`
is not an accepted implementation input. It correctly stopped without writing
an output because it requires style `Abstract Title`, while both the isolated
raw DOCX and current canonical DOCX contain the unique `Abstract` paragraph in
style `Normal`.

A temporary, task-external proof changed only the anchor contract. It required
exactly one ISO date, exactly one paragraph whose normalized text is
`Abstract`, exactly one complete 14-affiliation paragraph, and exactly one
correspondence paragraph. It also required the raw affiliation and
correspondence blocks to follow the abstract and preserved every paragraph's
text and style while moving only those two paragraph elements. The proof
passed with:

- 28 authors, all present in accepted order;
- 14 affiliations, all present in accepted order;
- identical paragraph count;
- identical multiset of paragraph text and styles; and
- consecutive front order Date, Affiliations, Correspondence, Abstract at
  non-empty paragraph indices 2, 3, 4, and 5.

The temporary corrected helper was 2,814 bytes at SHA-256
`f1fa15d48619023643f12ffdf491206ca67f23f5def77735faa8122cb72411d0`.
The temporary relocated DOCX was 9,915,338 bytes at SHA-256
`f8b428c6d38e074c0bb00aa16ff07a66be996c162a58775a1fd207ca75c1961b`.
These temporary files are proof only and are not authorized manuscript inputs.

## Release condition

Order 71b may be dispatched once. The Writer must implement the corrected
style-independent but structurally fail-closed anchor contract in the accepted
Word postprocessor. The historical helper must not be copied or invoked
unchanged. Order 71c remains held until separate independent acceptance of the
new canonical DOCX.
