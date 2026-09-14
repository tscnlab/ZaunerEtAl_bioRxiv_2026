# Nature Health figure and table integration QA

Date: 2026-08-31

## Scope

This record covers manuscript-only integration of the author-approved display selection. No analysis, model, scientific table, or source report was rerun or changed.

## Integrated sequence

Main manuscript:

1. Figure 1, study overview
2. Table 1, participant and measurement characteristics
3. Table 2, Brown et al. recommendation adherence
4. Figure 2, multiscale daily architecture
5. Table 3, metric synthesis across geographic and civil-photoperiod context
6. Figure 3, activity-associated exposure

Supplementary Information contains Tables S1 to S13 and Figures S1 to S16. The accepted repaired H06_daily display is Supplementary Figure S11. H05 begins at Supplementary Figure S12.

## Verification

- Quarto 1.9.37 rendered both documents successfully.
- R 4.6.1 was the available authoritative scientific runtime. No scientific computation was performed.
- Main-document cross-references resolved to Figure 1, Tables 1 and 2, Figure 2, Table 3, and Figure 3 in that order.
- All main and supplementary external images loaded in the rendered HTML. No broken image was detected.
- The three main figures have non-empty figure descriptions.
- The Supplementary Information uses uppercase left-side panel tags for the assembled two-panel displays.
- The wide participant/site and metric-synthesis tables retain horizontal scrolling within their accepted table containers.
- Table 3 retains the approved thematic order: Duration, Dynamics, Exposure history, Level, Spectrum, Timing. Within Timing, First light and Last light precede Mean timing.
- Captions identify Daytime, Pre-sleep, and Sleep as Brown et al. recommendation windows, not contexts. Reader-facing Evening is not used for the Brown pre-sleep window.
- No em dash occurs in the edited manuscript, Supplementary Information, or display stylesheet sources.
- Visual inspection found no missing assets or page-level horizontal overflow at the normal browser viewport. Embedded density thumbnails in accepted `gt` tables remain part of their table-cell semantics.

## Identities

- Main QMD: `60b7c2c994f3b7c6d0add32d1933fa7264006fbe5f72bfd932679116a73d3901`
- Supplementary QMD: `db7de312e662a5d1bd400dca44bdebf412b7a3a85465db2bdfca4fff96ea2a9d`
- Display CSS: `3ba76886364ac34823afa945b3a72abc60bcc96bca303b5c9eb4df13300fc1e9`
- Manuscript Quarto configuration: `537c4ccf896c7f6108d35d834b1dfa421e69031dc60bd1190ce283f5eaa243e5`
- Main HTML: `2428c3d500c69b3d952a239c808d877caa454b721eb1d06e04f4aa417d21962e`
- Supplementary HTML: `4955096c9e3036ee956e0e38702bc9719e939231854494e4202f256618fe3910`
- Accepted repaired H06_daily SVG: `4d95b3f1160a310baa6152f2ec7acecdd03da16c835ddcfbada6676cafd56d0d`
- Final Table 3 candidate: `2f7f6f475d9fe55ee37da3c73aa12474e347ec4619889278fbca0aeab2f40e1c`

## Remaining dependencies

The selection and placement are integrated for author review. Final submission numbering and any export-specific adjustments remain subject to the later journal-format and final corpus integration pass.

## Whole-manuscript continuity pass, 2026-09-01

A final meaning-preserving editorial pass was completed before author handover. It harmonised the Brown et al. terminology to recommendation windows or ranges, replaced one remaining fitted "Sleep context" phrase with "sleep estimate", made the abstract's immediate-context conclusion concrete, simplified the activity-figure confidence-interval wording, and improved the flow of the recommendation and study-strength discussion. No accepted number, inference, limitation, citation, display, or analysis identity was changed.

- Revised main QMD: `bcca83664f68f7a5a17012dc4985f9732ee68e747df19009862266781b30b77e`
- Revised main HTML: `c7eab48288fe8602c4f9b283f18a087f2aa8738419d16c03b72b241e2b47a4e1`
- The manuscript-only HTML render completed successfully with Quarto 1.9.37.
- All six main-text display cross-references resolved once each.
- No unresolved citation or cross-reference marker was detected.
- No em dash occurs in manuscript prose. Em dashes preserved in the rendered output occur only in an accepted table placeholder and the exact title of a cited publication.

## Integrated manuscript-package structure, 2026-09-01

Following author direction, the complete Supplementary Information was appended to the main manuscript after competing interests, matching the V0 structural principle. Main Figures 1 to 3 and Tables 1 to 3 remain embedded at their narrative Results positions. The appended section then contains Supplementary Tables S1 to S13 and Supplementary Figures S1 to S16. A standalone supplementary wrapper renders the same traceable body source for bounded review.

The author-contribution statement was also condensed to the official CRediT roles. Study-design contributions were incorporated into Methodology, while data collection and participant recruitment were consolidated under Investigation. No contributor was removed from the activities represented by those merged roles.

- Integrated main QMD: `cf97129bff8c71ab3c6f72762577724580ab55e308bcb0ce5570d6f7412b58d7`
- Supplementary body QMD: `169830e88e5cb4c8e4405accf4d7fb920854be4401cd9c392eebdb3e4c907b58`
- Standalone supplementary wrapper: `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b`
- Quarto configuration: `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
- Integrated main HTML: `6aecd753a381ca77721c9142a3846ce56cb9003759ec422e114e8a5ec92890fa`
- Standalone supplementary HTML: `fc1f701c82f841d8c724bc736d26f35286829854d5a43c3d59ad6a72d438b9ff`

## Pre-table-layout author-handover verification snapshot, 2026-09-01

This section records the manuscript snapshot that preceded the author's table-width and typography feedback. It is superseded by the final verification section below and by `phase3_brown_editorial_pass_2026-09-01.md`.

The integrated manuscript received one further meaning-preserving editorial pass. The abstract was tightened to 149 words while retaining the full analysed roster, sensor-specific participant and participant-day counts, multiscale model-fit allocation, recommendation adherence, day-type contrasts, and observational boundary. Introduction, Results, Discussion, Methods, captions, end matter, and the appended Supplementary Information were read as one document. No accepted estimate, interval, p-value, multiplicity decision, sample, model result, qualification, citation, or display placement changed.

Validation and visual QA:

- R 4.6.1 validation passed: 149 abstract words, 4,124 Introduction/Results/Discussion words, 3,043 Methods words, 76 audited paragraphs, 61 protected-number rows, 90 resolved citation keys, and 83 of 98 original references retained.
- Visible-text comparison against the pre-editorial renders found all 5,241 main-manuscript numerical tokens and all 3,347 Supplementary Information numerical tokens identical and in the same order.
- Quarto 1.9.37 rendered the integrated manuscript and standalone Supplementary Information successfully without executing scientific code.
- Desktop inspection at 1280 by 720 px and narrow inspection at 390 by 844 px found no page-level horizontal overflow, unresolved reference, or missing display. Wide tables scroll within their own containers. Long DOI and package-reference links wrap at narrow width.
- Main Figures 1 to 3 and Tables 1 to 3 remain at their Results narrative positions. Supplementary Tables S1 to S13 and Supplementary Figures S1 to S16 remain together after Competing interests and also render from the same source as a standalone Supplementary Information document.
- The Author contributions section uses the official CRediT role names and preserves the confirmed contributor assignments represented in the original manuscript.

Reader-table wording was coordinated with the responsible source owners so the manuscript copies do not become independent scientific variants. No owner was asked to render a report. Current source-only identities reported back were H01 `92d7795d5f64e451d3633e5987f6365ebf7ccb6b1bc24b469d064847b0c97e0a`, H05 `ad8f68bd58e015575b55284463f5535bf2a0b56219330d68e77795bd312bb37c`, H07 `d8dda5ff845749b762701729e79d72e94b5a8aee78488d1a3aca4a2056555064`, H08 `27654dcd9034eebe74223dacdc5631ad8c7350aae97acf0e2adb319bb7c943b1`, H09 `05cb50529b5cf71fb8f3e94cc6de259b9b0f11f4185a4c441c32a57efd211936`, H10 `cfff1ac01ff4ab1666c99d4b413410a65ce7b88f0193d0adbbd79cf7f3f021c2`, and H06_daily `d90c4ced3f40456b3d9998022c9317a64ff6812597111d3d8c01b40cf8429139`. The Descriptives owner reported builder `b9f0b1c357d65e411bd2f79e35eeae4b2efcb54550f8d82484e647e6381cae27` and reader source `8a656ddebbb5d50e2654d2fe8c69dec5f32e269159d1f12bb0d1a169dc964a51`. Each owner reported wording-only or accessibility-only changes with no change to values, intervals, p-values, multiplicity decisions, samples, or scientific scope.

Final manuscript-owned identities:

- Main QMD: `2c0f6bbfc69a434258c8d4bb1d9455a2f9e0920a9bbaa634adf5aaa9922323c3`
- Supplementary body QMD: `49c91cf49b6f5c6308f5b3ea39cba750da3942e0d058b45c4f2ec7782b2f34bf`
- Standalone Supplementary Information wrapper: `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b`
- Display stylesheet: `392ae8f69446ed18e8ebce4d1c5cf2a510264584497541f313249be4fb391677`
- Quarto configuration: `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
- Integrated main HTML: `122e96caf0d635086983a2e875d650417cce21c3623ba6a5b655cc47010be012`
- Standalone Supplementary Information HTML: `a52450b9a9792f5ff2f879766e009a6c5194d64ae072549dbce029997ab19861`
- R validation source: `b729d32c2bdc98d92e4db97a06b12c81adfd65b49dc071db84b54b26fb762c14`
- Protected-number audit: `4d0af0f66d355bab71b578ecee629ef6d4975ceba1095a691200f25645f08675`

## Final table-layout and editorial verification, 2026-09-01

The author-requested table correction and one further whole-document editorial pass are complete.

- All main and supplementary native `gt` tables render with a 12 px body-text base. Deliberately secondary notes remain smaller.
- Main and supplementary table wrappers use a 894.5 px page-column region at the inspected desktop viewport and retain local horizontal scrolling. The page itself has no horizontal overflow.
- Table 3 is byte-identical to the harmonizer-owned source at SHA-256 `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`. It preserves the 1,160 px table width, the seven accepted column widths, and 145 by 82 px density thumbnails.
- Responsible report owners converged their source-only table bases to 12 px without rendering reports or changing scientific content. Exact owner identities are recorded in `phase3_brown_editorial_pass_2026-09-01.md`.
- R 4.6.1 validation passed with a 149-word abstract, 4,157-word Introduction/Results/Discussion, 3,046-word Methods, 76 audited paragraphs, 61 protected-number rows, 90 resolved citations, and 83 of 98 original references retained.
- R 4.6.1 comparison found the numerical token sequences unchanged: 628 tokens in the main QMD and 60 in the Supplementary Information QMD.
- Browser checks found 12 px bases in all 20 integrated-manuscript and 17 standalone-supplement native tables, no missing images, no unresolved cross-references, and no page-level horizontal overflow.

Final manuscript-owned identities:

- Main QMD: `b3bd9f22d7d31c850011599457fcf6130a9f30772829469248021ff2e0e6bbb7`
- Integrated main HTML: `a122c5a9afba023bb23bf62666f51bdef918a12fbeb7c4f7e433ff3fdfdede22`
- Supplementary body QMD: `a3f2da00710a965fa06ccac2bd9bde2e0f6605ad948b3fc208dcf5aab7698af2`
- Standalone Supplementary Information HTML: `20d8361c20e8167c24c973c9806b448660ed0f33ed3b7f89676bcc508095993f`
- Display stylesheet: `e990b471a30a52ba83d86ad0867edc3dd89bae0b5e0c9b7d8f91d376ba6096ea`
- Manuscript-owned Table 3 HTML: `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`
- R validator: `b10ea3f1014062544f5afb095a8a99d72fcb84f3c3479ce8b6720120ca049c47`
