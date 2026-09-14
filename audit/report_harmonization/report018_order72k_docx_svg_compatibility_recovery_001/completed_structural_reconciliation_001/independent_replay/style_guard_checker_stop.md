# Read-only replay checker stop

The copied `verify_document_verified.R`, redirected only to this temporary
evidence root with input guards, stopped before producing a final checks table:

    Error in xml_nodeset(NextMethod()): Expecting an external pointer: [type=NULL]

The named-style lookup subsets an xml_nodeset using a logical vector that can
contain NA for styles without a name. This is an evidence-only selector issue.
The original replay script and all document/input bytes are preserved.
The separately named replay adds only `which(!is.na(style_names) & ...)` to
select existing styles with an exact case-normalized Heading 1 name. Its
exactly-one-match requirement and all document checks remain intact.
No producer, package save, render or visual operation is performed.

