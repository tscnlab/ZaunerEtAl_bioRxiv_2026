# Protected-content checker parse correction

The first `reconcile_capture.R` invocation stopped at parsing before it read
the capture or wrote reconciliation outputs. One extra closing parenthesis
in the image-payload identity predicate caused the error. The failed source
is preserved unchanged. `reconcile_capture_verified.R` removes that single
extra parenthesis and updates only the recorded script-name command.

This is the plainly mechanical candidate-only checker repair allowed by the
original Order72k boundary. No predicate, source, expected identity, table
cell or test threshold was removed or weakened. It is not a new capture,
browser trial, document render or scientific computation. The successful
capture and all original evidence remain unchanged.

Failed command exit code: 1. Exact diagnostic:

```text
Error: unexpected ')' in:
"    identical(x$image_aria_hidden, \"true\") && is.null(x$image_alt) &&
    identical(x$image_payload_sha256, unname(unclass(as.character(openssl::sha256(charToRaw(images[i])))))))"
Execution halted
```
