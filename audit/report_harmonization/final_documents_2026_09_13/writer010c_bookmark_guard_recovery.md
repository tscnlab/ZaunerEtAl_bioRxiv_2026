# Bookmark-aware prewrite guard recovery

14 September 2026. Coordinator task 019faf58-3df3-7383-8034-f715cdfdd154. Writer task 019ffb39-372e-7262-bfac-192751fd0e63.

Disposition: the first Order010c helper launch stopped before creating a DOCX. The sole faulty assertion required adjacent paragraphs to be adjacent XML siblings. The immutable document contains exactly one top-level bookmarkStart between paragraphs339 and340. This is a helper guard defect, not a document-content defect or a reason to alter the bookmark.

The current helper `audit/manuscript_nature_health/final_pagination_completion_2026_09_14/code/patch_s9_break.py` is SHA-256 `6370bf176b1a10a7dd6fa81e6cd8282158f920d80317d589c4b2215e64affe8c`, 5124 bytes. The corrected prospective helper is `df4e9e2d267e2c7b1dfcf178fc8243ce0fcb52e6888870da33fc017faedb4e27`, 5585 bytes. It is retained exactly in the adjacent `writer010c_bookmark_guard_recovery/prospective_patch_s9_break.py`, with exact old/new guard fragments and independent prewrite evidence. Use that file to avoid formatting reconstruction loops.

## Exact guard correction

Replace only `assert target.getprevious() is preceding` with the retained guard. It traverses intervening siblings, requires the preceding paragraph to be the already selected `Hourly routine analyses` paragraph, and permits exactly one otherwise empty `w:bookmarkStart` whose two attributes are `w:id=338` and `w:name=X7652973548e0e92457fc1c236fcb0c86891495d`. No arbitrary intervening content is allowed. The existing source/XML/paragraph SHA checks and all other assertions remain unchanged. The prospective helper reverses exactly to the preimage.

The coordinator parsed the entire prospective helper and executed every corrected prewrite guard and exact XML reverse assertion against the current immutable DOCX, stopping before the ZIP output-opening statement. This is non-analytical OOXML infrastructure validation. The nearest preceding paragraph, unique target, exact bookmark, empty break, raw paragraph identity, 20-byte removal, exact required XML postimage and exact reverse all pass. The bookmark's serialized identity remains unchanged in the prospective XML. No DOCX or renderer output was produced.

The original document remains `d6dd418054fb8287efe2a4d49fc2d4adaf5a4a56b8a6ded503645ca34c599701`. Required document.xml postimage remains `98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f`, 358283 bytes. Original Order010c and its 36-row dispatch remain immutable and controlling except for this explicit recovery of the first no-write helper launch.

## Resume once within the same document boundary

1. Rehash this recovery seal, the original36-row dispatch and all271 immutable Order010b members. Confirm final DOCX, patch proof and render execution record remain absent.
2. Preserve the current helper and all currently sealed preflight/code/stop files under a new `evidence/bookmark_guard_stop/` within the Order010c root, with a non-circular inventory. These include the final verifier prepared read-only while awaiting disposition, `initial_patch_preflight_stop.json` and the independent in-memory R postimage proof. Their exact set is pinned in this recovery manifest, not inferred from an earlier file count. Do not invent an unavailable console log; record the observed failure and tool-run accounting accurately. The document-operation marker already completed once and must not be repeated merely for this guard correction.
3. Apply only the exact helper guard change, require the prospective hash/bytes above, parse, and prove exact helper reverse. Execute the still-unapplied document patch once. All document/member/reverse contracts are unchanged. This is not a second document version or a third assembly.
4. Continue the already released single packaged150dpi document-render invocation and complete all final-page visual review, including the S9 sequence. No extra renderer allowance is created. Preserve all Order010b outputs and all19 native tables. S2 type size remains author-accepted and unchanged.
5. Return the complete final non-circular package, including the no-write first-launch history and this narrow recovery. No further patch, assembly, Quarto/Pandoc, source/HTML/display/science/package/site/download change or promotion is authorized.

The whole accepted Figure3/S3/S15B/native/browser disposition remains unchanged. This recovery addresses only XML sibling classification before the existing authorized write. A genuinely new defect must be reported without silently broadening the mutation.
