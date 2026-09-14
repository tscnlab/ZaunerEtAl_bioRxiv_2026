# REPORT018-ORDER72D-WRITER-SVG-CANDIDATE-REVIEW

Date: 2026-09-11.

Status: **STOPPED for renderer-specific visual finding ORDER72D-VIS-01.**
The complete native-SVG review candidate exists; it is not a production release.

## Candidate and controlling authority

Candidate: `ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx` in this directory.

- SHA-256: `933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9`.
- Size: 16,623,183 bytes.
- Exactly 20 accepted SVG image parts, resolving to 21 appearances.
- Three main figures and 17 supplementary figures; S8 retains its two crops.
- No manually generated raster fallback and no substituted scientific content.

Controlling order:
`audit/report_harmonization/owner_orders/72d_writer_complete_svg_review_candidate.md`,
SHA-256 `06f61b2f0f5556b0fd217e495c5c32d431e547d353bf12d82d1b00f906fd55ce`.

Release manifest:
`audit/report_harmonization/report018_order72d_writer_svg_integration/release_manifest.csv`,
SHA-256 `a57b86091331372db3eca6302a94de1c11f0e2412f55462579cbfd56b6e594d6`.

The copied `combined_accepted_svg_manifest.json` and `embedding_raw_report.json`
record every exact source SVG, hash, embedded part, relationship, extent and crop.
The helper's historical seven-held status sentence is preserved only as raw
metadata; all 20 SVG exports are present in this candidate.

## Structural and preservation result

All five embedding checks passed: exact document-XML reversal, accepted SVG
bytes retained, unaffected package members unchanged, no new raster parts,
and exact SVG part count. All 50 release-manifest members and 45 input/preservation
pins were exact before integration and after embedding, rendering and visual QA.
See `preservation_after_visual_qa.json` and the final stop checks.

The pre-embedding baseline remains
`acb6548997c29e96a065dfd5a26a682a3f0fb08170185e0c57aab3b1b0b256c0`.
The partial-SVG candidate remains
`252d17764c21ad1a07e541946d1c49e66ef0734b438f0845194ba45882ed86ff`.
The accepted production Word download remains
`74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`.
The production HTML, manuscript QMD, references and source figures were not
changed by Order72d.

## Visual result and stop disposition

The packaged `documents` renderer, using its bundled LibreOffice, generated
109 pages. Eighty-eight are byte-identical to the previously reviewed baseline;
the 21 changed pages exactly correspond to figure appearances. All 21 figure
appearances were inspected. Page 107, S17, has a newly substituted serif face
and right-clipped internal note in this renderer. The corresponding baseline
image is complete and sans serif. Full observations and the appearance/page
map are in `visual_observations.md`.

The author opened the candidate in native Microsoft Word. Main Figures 1 and 2,
both S8 crops, and S17 were visually inspected there without editing or saving.
S17 appears sans serif with an intact note in native Word at 130%. Therefore the
failure is currently renderer-specific. Native Word's successful open and the
sampled displays do not waive the recorded LibreOffice QA failure or prove every
application/rendering pathway. No source repair, second candidate or rerender
was attempted.

Requested disposition: the coordinator and harmonizer should classify
`ORDER72D-VIS-01` and route any necessary format-only repair to the appropriate
SVG owner or document-rendering boundary. Do not introduce a silent
manuscript-only variant of the figure. This handoff does not request scientific
refitting, raster replacement, production promotion or an unrestricted retry.

## Separate scientific dependency

The author asked again to dispatch the Brown pre-sleep alignment. The existing
Brown task and coordinator were notified; the Brown owner confirmed work has
started from the completed audit and central Stage 1 reopening. The target is
preceding sleep, complete ensuing daytime, then following three-hour pre-sleep,
all classified by the daytime wake-start date. The current Word copy deliberately
retains the older accepted main Brown results. Its affected claims and displays
remain held until the replacement analysis is accepted. This dispatch does not
change Order72d's frozen inputs.

## Evidence seal

`stopped_manifest.csv` is a unique non-circular manifest of this order's new
durable outputs and evidence plus its controlling authorities and protected
inputs. It excludes itself and application-created transient Word lock files.
Those lock files are not manipulated. The generated contact sheets are retained
but not represented as a completed additional inspection after the stop.

No full-project render, scientific computation, source mutation, commit, push,
submission or upload was performed. The document render-and-verify workflow
used the active `documents` skill. The earlier independent manuscript revision
also used the active clarity and Quarto authoring skills, but those did not alter
this format-only integration.
