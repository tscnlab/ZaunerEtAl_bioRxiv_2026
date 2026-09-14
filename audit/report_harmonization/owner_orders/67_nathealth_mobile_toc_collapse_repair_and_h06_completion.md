# REPORT-018 owner order 67: Nature Health mobile TOC repair and H06 completion

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_SHARED_CSS_REPAIR_WITHOUT_RENDER`

## Authority and disposition

The H06 result render is scientifically, semantically, and structurally sound,
but Order 66b stopped on one genuine shared navigation defect. At narrow width,
the **On this page** disclosure opens while its cloned section list remains
hidden. The accepted shared include clones Quarto's optional `collapse` class
from the desktop table of contents. Bootstrap therefore continues to apply
`display: none` to the cloned list after the enclosing `details` element opens.

The independent R 4.6.1 corpus audit confirms the mechanism on exactly 10 of
37 accepted routes. This order authorizes one candidate-first CSS repair, one
two-file promotion, corpus-wide verification, and completion of the deferred
H06 visual checks. It authorizes no Quarto render and no HTML rewrite.

## Exact preflight

Before creating a candidate or changing either stylesheet, the owner must:

1. reproduce every row of the Order 67 dispatch manifest by exact SHA-256 and
   byte count;
2. run
   `scripts/report_harmonization/check_report018_mobile_toc_collapse_defect.R`
   once with R 4.6.1 and require its exact successful summary, including the
   60-row owner seal, 10 of 10 hidden H06 links, exactly 10 affected routes,
   and the full 892 of 892 build identity;
3. reproduce the 18-row independent visual-stop manifest at SHA-256
   `6ccc6c94d1522ee90654b3bbca010b623c7739ed44e0df33c107e09b958060fd`;
4. require the source and built `styles-nathealth.css` copies to be
   byte-identical at SHA-256
   `051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87`,
   4,548 bytes each;
5. require the accepted mobile include `926a5fc0...`, Nature Health profile
   `e54c7179...`, 37-route corpus manifest `c42c3262...`, H06 result HTML
   `b701a6d6...`, both H06 sources, held preparation HTML, scientific seal,
   report verification, handoff, focused test, and lockfile exact;
6. require all 37 live HTML routes and every other current build member to
   reproduce the 892-row Order 66b post-QA inventory at SHA-256
   `8d00db3d2a7bfe8f17526cee08027bafd83f99bb7ad0e36c73e3e46cada5f355`;
7. require zero symbolic links under `_build/nathealth`;
8. require no competing navigation promotion, Quarto, Pandoc, semantic-hook,
   or writer process for this shared build; unrelated R or application
   processes are outside this predicate and must not be interrupted; and
9. create one fresh task-owned evidence directory under
   `audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/`
   and one fresh candidate root under `/private/tmp`.

Stop and seal before any candidate or durable write on any mismatch.

## Exact repair

The only authorized content change is this rule inside the existing mobile
media block, immediately after the current `.nathealth-mobile-toc ul` rule:

```css
  .nathealth-mobile-toc ul.collapse {
    display: block;
  }
```

The exact prospective stylesheet identity is:

- SHA-256
  `736b7f1309d8ddacda8b70999d37e6ee26920b9927cf1ae7215ec891a94b2dfe`;
- 4,611 bytes.

Do not change the mobile include, profile, HTML, JavaScript, any other CSS
selector or declaration, or any page content. Prove exact one-hunk reversal to
the 4,548-byte preimage.

## Candidate-first validation

Create a full byte-exact candidate copy of the accepted 892-file build outside
the project and replace only its `styles-nathealth.css` with the prospective
4,611-byte postimage. Require zero candidate symbolic links and exact identity
for the other 891 members.

Serve only the candidate build on one unused high port bound to `127.0.0.1`.
At both 708 and 390 pixels wide, inspect all 10 affected routes:

- `notebooks/preregistration_deviations.html`;
- `notebooks/hypotheses/H02.html`;
- `notebooks/hypotheses/H03.html`;
- `notebooks/hypotheses/H04.html`;
- `notebooks/hypotheses/H05.html`;
- `notebooks/hypotheses/H06.html`;
- `notebooks/hypotheses/H06_daily.html`;
- `notebooks/hypotheses/H07.html`;
- `notebooks/hypotheses/H10.html`; and
- `notebooks/hypotheses/H11.html`.

For each route, open **On this page** and require every cloned section link to
be visible and keyboard-focusable. Follow the first link, require the intended
fragment to exist and the disclosure to close under the accepted script, then
reopen it. Reject page-level horizontal overflow, clipping, overlap, hidden
content, broken focus, unresolved fragments, or page-attributable console
warnings or errors.

Also inspect the unaffected H09 result route at 1,440 and 390 pixels, and the
H06 result at 1,440 pixels. Require the mobile control to remain hidden on
desktop, the desktop right-hand table of contents to remain usable, and all
page navigation to remain unchanged. Stop the candidate server and prove its
listener absent.

## One-time promotion

Only after candidate PASS, replace exactly these two files once:

1. `styles-nathealth.css`;
2. `_build/nathealth/styles-nathealth.css`.

Both must equal the candidate postimage byte-for-byte at SHA-256 `736b7f...`
and 4,611 bytes. No other project or build path may change. In particular:

- all 37 HTML files must remain byte-identical;
- the other 891 build members must remain exact;
- `_includes/nathealth-mobile-toc.html`, `_quarto-nathealth.yml`, search and
  sitemap assets, the full 37-route corpus manifest, all QMDs, tests,
  scientific artifacts, handoffs, and historical evidence remain immutable;
- `audit/report_harmonization/phase4_corpus_manifest.csv` remains
  byte-identical and is not resealed; and
- the accepted H06 source, result HTML, held preparation page, and scientific
  package remain unchanged.

## Production QA and H06 completion

After promotion, repeat the 10-route 708/390 mobile-TOC checks against the
production build. Repeat H09 at 1,440/390 and H06 at 1,440, 708, and 720 by
500 pixels. For H06, complete the deferred Order 66b requirements:

- 14 tables and six figures present and usable;
- employment-eligibility sensitivity section complete;
- disclosures and the site-table scroller usable;
- desktop and mobile tables of contents, primary navigation, reciprocal
  preparation link, three source-data links, and DEV-015, DEV-030, DEV-031,
  and DEV-032 links correct;
- exported figures complete and unclipped at 642 pixels, the accepted 170-mm
  final width;
- result page, held preparation page, and source-data resources return HTTP
  200; and
- no page overflow, clipping, overlap, missing content, broken interaction,
  unresolved reader link, or page-attributable console warning or error.

Serve only `_build/nathealth` on `127.0.0.1`. Save bounded candidate and
production screenshots, structured route and visual observations, link and
console results, viewport evidence, and server lifecycle records. Close or
reset the QA surface, stop the server, prove the chosen listener absent, and
rehash all protected and build paths.

## Final seal

On complete PASS, write one completion record and one unique, non-circular
evidence manifest in the task-owned repair directory. The manifest must include
the order and dispatch, central checker and independent stop acceptance,
preimage and postimage stylesheets, exact reversal evidence, candidate and
production inventories, route and browser QA, H06 deferred QA, screenshots,
link and console checks, lifecycle evidence, and postflight hashes. Exclude the
final manifest itself.

Return exact SHA-256 and byte counts for both stylesheets, the completion
record, final manifest, route audit, and H06 visual acceptance evidence. The
Coordinator will independently close the shared repair and H06 result.

Stop and seal once on any genuinely new defect. Do not patch, retry, or widen
scope.

## Prohibitions

Do not run Quarto, knitr, Pandoc, a semantic hook, helper, analytical script,
or broad manifest builder. Do not edit HTML, QMD, JavaScript, includes,
profiles, tests, manifests, handoffs, scientific data or artifacts, package
libraries, lockfiles, manuscript files, ledgers, or any other stylesheet. Do
not render any target, reseal the corpus manifest, commit, push, upload,
delete, or alter a cache.
