# Nature Health Phase 3 Brown editorial and table-integration pass

Date: 2026-09-01

## Scope

This was a manuscript-only editorial, rendering, and display-integration pass after author feedback. It changed no data, model, estimate, interval, p-value, multiplicity decision, sample definition, figure content, or scientific-report output. Only manuscript-owned sources, bounded manuscript renders, manuscript validation, and this audit record were written.

The active `clarify-scientific-writing` workflow guided the meaning-preserving prose pass. The active `quarto-authoring` workflow guided source edits, inclusion behaviour, bounded renders, cross-reference checks, and browser inspection.

## Editorial outcome

- The abstract is 149 words and retains the full 191-person roster, the 184 participants and 1,478 participant-days with recorded light data, the screened near-eye sample of 141 participants and 816 participant-days, and the complementary chest sample of 154 participants and 902 participant-days.
- Introduction, Results, Discussion, and Methods were read in sequence and revised for directness, transitions, antecedent clarity, and consistent placement language.
- Recommendation-window language remains Daytime, Pre-sleep, and Sleep. These are identified as Brown et al. recommendation windows, not contexts.
- Reader-facing multiplicity language now consistently identifies reported adjusted values as FDR-adjusted p values. The full Benjamini-Hochberg method name remains only in Methods for reproducibility.
- Near-eye measurements remain the primary ocular-exposure evidence during wear. Chest measurements remain separate complementary non-ocular evidence and are not pooled into the ocular sample.
- The user-confirmed recruitment interpretation remains explicit: the chest option broadened recruitment among people reluctant to wear glasses-mounted sensors, especially at San José (CR). It did not make otherwise-ineligible people eligible.
- Main figures and tables remain integrated at their Results locations. Supplementary Tables S1 to S13 and Supplementary Figures S1 to S16 remain together after Competing interests and also render from the same source as standalone Supplementary Information.
- Author contributions remain condensed under the official CRediT role names.
- No em dash occurs in the edited manuscript, Supplementary Information, stylesheet, or manuscript-owned Table 3 source.

## Table typography and width correction

- Every rendered native `gt` table in the integrated manuscript and standalone Supplementary Information has a 12 px body-text base. Deliberately secondary source notes and footnotes remain smaller.
- Every main and supplementary table wrapper uses the left page-column region and local horizontal scrolling. At the inspected desktop viewport, each wrapper was 894.5 px wide rather than the approximately 799 px prose column.
- The page itself did not acquire horizontal overflow. Wide tables scroll only inside their table wrapper.
- Table 3 preserves the approved native geometry through Quarto inclusion: 1,160 px table width; column widths 135, 205, 135, 155, 125, 205, and 200 px; and 145 by 82 px density thumbnails.
- The manuscript-owned Table 3 copy is byte-identical to the harmonizer-owned corrected candidate. Both have SHA-256 `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`.
- The shared reader-facing MDER note is: “The MDER uses the mean of viable minute-level ratios in both the descriptive summary and geographic-association model cells.” It contains neither internal hypothesis labels nor workflow language.

## Source-owner convergence

The author asked that the responsible report owners receive the same table correction so manuscript copies and later report renders do not diverge. Each owner performed a source-only change, retained smaller secondary annotations where appropriate, and did not enter the serial report-render queue.

| Reader source | Current source SHA-256 | Source-only outcome |
|---|---|---|
| Descriptives table builder | `d944e4b4343b98f27a02beb50219f197007cd6c5cb6eecb5ed6f71b14d4ab886` | Eight reader-table endpoints use 12 px and local overflow |
| Descriptives reader QMD | `c17fef3ca932fa8cf195f6ae6604e822e3b46235cefd6a081d4eef69b88546bc` | Source aligned, no render |
| H01 | `4618b80ed84518d94b8e8fe8b80db1fc43d272c2781c5294b3cc48b019348d43` | Native table bodies use 12 px |
| H02 | `b50b55eebb75f120928707821dc3b8e8d6f16905418c56d8d689744926ff3de8` | Helper uses 12 px and local overflow |
| H03 | `27c1fea54e5f32570613df80768d1fb5b668f3033aee90069820e951001c2513` | All native table bodies use 12 px and local overflow |
| H04 | `cf1c65c7e6fd8db2c024ac4353849a0ae4eae2b2151f672d5076e183fec37016` | All 17 native tables use 12 px and local overflow |
| H05 | `f748873f5f68198665fc3cb3d7047f586c619408f86e5e22bd9814593f9f2780` | Helper and explicit table bases use 12 px |
| Main hourly H06 | `013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a` | Helper and main site-specific table use 12 px |
| Complementary H06 daily | `ddf7e8af287831b80243b4d35e83546fa6ee8f7f3794c9874d4712648b3eb2e7` | Native table base uses 12 px |
| H07 | `c2d24ee7199fc8399e7edfa1192a21de7c31bd7854a89d356386c5e669ff55ca` | Eight reader tables use 12 px |
| H08 | `56cdd3382ff933f20706d50e75af00160ebdc3c503307f9fdf02fb7c2ae6e859` | Native tables use 12 px and local overflow |
| H09 | `ae5b23d11e2c623b7150df7fe14292df4380e6417028630c30a30ae7dff1b34c` | Native tables use 12 px and local overflow |
| H10 | `0b2daad24e16ad62a87c2b74d5989cb2ff3738dca47d5dd3fda0af366e93c855` | Twelve native tables use 12 px and local overflow |
| H11 | `ea9ac2edb470f956cf854430b865e8adbf98b07d8e6ac307484c9e5ccc0c38de` | Ten native tables use 12 px and local overflow |
| Brown Stage 3 reader QMD | `cca627a3f9a60f5c4b7d04112145c865c4035646b60668f9be765298682b12af` | Sixteen reader-table calls use the 12 px helper default |
| Brown Stage 4 provenance QMD | `577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d` | Seventeen technical tables use the 12 px helper default |

These source changes do not reseal the still-serialised report HTML corpus. They prepare the next authorised owner renders and do not replace the existing scientific acceptance identities.

The harmonizer independently reconciled every executable dispatch and return in `audit/report_harmonization/table_presentation_dispatch_ledger_2026_09_01.md`, SHA-256 `3d6017b28ad0a79dbb903bd6b41a3973f2ec7ac3966b9dfdf55079f835995b46`. No intended owner remained uncontacted or ambiguously queued.

## Validation and invariants

The final R 4.6.1 manuscript validator passed:

- abstract: 149 words;
- Introduction: 417 words;
- Results: 2,593 words in six sections;
- Discussion: 1,147 words with no subheadings;
- Introduction, Results, and Discussion: 4,157 words;
- Methods: 3,046 words in 14 sections;
- audited paragraphs: 76;
- protected-number rows: 61;
- resolved citation keys: 90;
- original Nature Medicine references retained: 83 of 98;
- ethics-site records: nine; and
- canonical health-evidence records: nine from 11 candidates.

An R 4.6.1 source-token comparison found the complete numerical token sequences unchanged between the pre-editorial and final sources: 628 tokens in the main QMD and 60 in the Supplementary Information QMD. The clarity-workflow checker also found all 124 citation and cross-reference keys unchanged. Its apparent addition of one `902` token reflects adding the formerly omitted unit in the abstract, not adding a number: raw R counts show three occurrences of `902` before and three after. Its added FDR tokens are the deliberate terminology normalisation described above.

## Render and browser verification

- Quarto 1.9.37 completed bounded renders of the integrated manuscript and standalone Supplementary Information. No full-project or report render was run.
- The main render contained 20 native `gt` tables and the standalone supplement contained 17. Every table computed to a 12 px body-text base.
- All 16 supplementary table wrappers and all three main table wrappers used the 894.5 px page-column width with local horizontal scrolling.
- Table 3 retained seven columns, the specified widths, a rendered width of 1,160 px, and 145 by 82 px density thumbnails.
- Neither document had page-level horizontal overflow at the inspected desktop viewport.
- No image failed to load and no unresolved cross-reference marker was detected in either document.

## Final manuscript-owned identities

- Main QMD: `b3bd9f22d7d31c850011599457fcf6130a9f30772829469248021ff2e0e6bbb7`
- Integrated main HTML: `a122c5a9afba023bb23bf62666f51bdef918a12fbeb7c4f7e433ff3fdfdede22`
- Supplementary body QMD: `a3f2da00710a965fa06ccac2bd9bde2e0f6605ad948b3fc208dcf5aab7698af2`
- Standalone Supplementary Information QMD: `84b88515af524e78f66ba947017afa195a000fa57663aa715d113fe1dab91f3b`
- Standalone Supplementary Information HTML: `20d8361c20e8167c24c973c9806b448660ed0f33ed3b7f89676bcc508095993f`
- Display stylesheet: `e990b471a30a52ba83d86ad0867edc3dd89bae0b5e0c9b7d8f91d376ba6096ea`
- Manuscript-owned Table 3 HTML: `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`
- R validator: `b10ea3f1014062544f5afb095a8a99d72fcb84f3c3479ce8b6720120ca049c47`
