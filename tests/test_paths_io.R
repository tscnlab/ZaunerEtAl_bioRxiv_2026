source("scripts/pipeline/paths_io.R")

local({
  message("Checking exact-byte SHA-256 hashing")
  test_root <- tempfile("nathealth-paths-io-test-")
  dir.create(test_root, recursive = TRUE)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

  binary_path <- file.path(test_root, "binary-payload.bin")
  raw_payload <- as.raw(c(
    0x00,
    0x0d,
    0x0a,
    0x41,
    0x7f,
    0x80,
    0xfe,
    0xff,
    0x0d,
    0x0a,
    0x00
  ))
  binary_connection <- file(binary_path, open = "wb")
  writeBin(raw_payload, binary_connection)
  close(binary_connection)

  expected_binary_sha256 <- unname(unclass(
    as.character(openssl::sha256(raw_payload))
  ))
  connections_before <- rownames(showConnections(all = TRUE))
  observed_binary_sha256 <- artifact_sha256(binary_path)
  connections_after <- rownames(showConnections(all = TRUE))
  stopifnot(
    identical(observed_binary_sha256, expected_binary_sha256),
    identical(class(observed_binary_sha256), "character"),
    is.null(attributes(observed_binary_sha256)),
    length(observed_binary_sha256) == 1L,
    identical(connections_after, connections_before)
  )

  message("Checking text-file SHA-256 hashing")
  text_path <- file.path(test_root, "text-payload.txt")
  text_payload <- charToRaw("alpha\r\nbeta\n")
  text_connection <- file(text_path, open = "wb")
  writeBin(text_payload, text_connection)
  close(text_connection)

  expected_text_sha256 <- unname(unclass(
    as.character(openssl::sha256(text_payload))
  ))
  stopifnot(
    identical(artifact_sha256(text_path), expected_text_sha256)
  )

  message("Checking binary file cleanup after hashing")
  unlink(binary_path)
  stopifnot(!file.exists(binary_path))

  message("Path and artifact I/O checks passed")
})
