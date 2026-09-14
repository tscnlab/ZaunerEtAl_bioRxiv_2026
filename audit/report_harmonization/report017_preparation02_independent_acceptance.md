# REPORT-017 Preparation 02 independent acceptance

Date: 2026-08-13

Verdict: **ACCEPTED**

## Source and render identity

The final source SHA-256 is
`572173e119c9e8faac93fd61687d3a209d470742dbd82efe44a12ac87e6275fd`.
Replacing only `flowchart TB` with `flowchart LR` reproduces the immediate
pre-repair identity
`b65673d2ecfd8913a6e9c8ba06d7c1b98bca3665769864bb7f7e68be78a8f3ef`.
The three earlier approved removals of redundant manual `Table` prefixes are
retained. No other source change belongs to the final diagram repair.

The accepted Nature Health configuration remains
`b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5`.
The final target HTML is
`0eeb0114db9161d5bc69b9a0186bd629b302d5fec2e08dcf35e78d049f20886d`.
The owner record proves that the sole final render used Quarto 1.9.37 and R
4.6.1, completed all 27 knitr steps in 43.12 seconds, and changed only the
target HTML, search index, and sitemap. No package, configuration, source,
scientific artifact, or protected input changed during that render.

## Independent structural and scientific-preservation checks

The owner manifest independently reproduced all 14 listed SHA-256 identities
and byte counts. The 32-row final protected verification contains 32 existing,
byte-identical entries and no mismatch. The exact one-token reverse
substitution passed under R 4.6.1.

The focused R 4.6.1 test was rerun independently through the normal project
profile and passed the bounded-render, terminology, native-gt, and provenance
contract. It confirmed 12 bounded R chunks, 11 semantic native-gt tables,
country-coded sites, the accepted counts and units, dynamic links, and the
absence of builder, model, prediction, resampling, simulation, bootstrap,
Shapley, write, raw-console, and error output.

DEV-055 resolves to the exact accepted reader entry. The three repaired
cross-references render once each as Table 1, Table 3, and Table 6. No `Table
Table` duplication remains.

## Independent secure-loopback visual QA

A temporary static server used the exact document root `_build/nathealth`,
bound only to `127.0.0.1:62687`, and exposed the exact Preparation 02 route.
The server command was:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

The listener PID was 38950. No build symlink existed. Screenshots and live DOM
measurements were inspected in the in-app Browser at 1440 by 1000 and 708 by
1000 pixels.

At desktop size, the Mermaid measured 538.93 by 733.99 CSS pixels with a
matching view box and 16 px labels. All nodes, labels, arrows, and branches
were clear. The 11 tables measured 1,148.5 CSS pixels and the page had no
horizontal overflow.

At 708 pixels, the document client and scroll widths were both 693 pixels.
The Mermaid retained 538.93 by 733.99 CSS pixels and 16 px labels. Each table
was 642 pixels wide with 13 px cell text. The title, prose, callout, diagram,
tables, country-coded sites, DEV-055 link, mobile navigation, and page
navigation had no clipping, overlap, harmful wrapping, or page-level
overflow. No rendered error or duplicate Table label was present.

The server was stopped immediately after inspection. No listener remained on
port 62687 and PID 38950 no longer existed. The 827-file build inventory hash
was `4a736ef72e54828102aefde2254efe7b5489e0dd1303ec1b3cdf717886717229`
before and after the loopback inspection. The source, configuration, and target
HTML identities also remained exact.

## Disposition

Preparation 02 is accepted. Preparation 03 may start as the sole next
REPORT-017 target. Its visible PREP-002/FIND-043 reconstruction qualification
must remain unchanged. This acceptance does not authorize any later page,
scientific builder, full-project render, package change, or shared-profile edit.

The non-circular acceptance manifest is
`audit/report_harmonization/report017_preparation02_independent_acceptance_manifest.csv`.
