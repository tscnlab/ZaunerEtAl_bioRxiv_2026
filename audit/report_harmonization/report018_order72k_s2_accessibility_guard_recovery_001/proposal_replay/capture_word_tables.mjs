#!/usr/bin/env node

/*
 * Capture the accepted HTML/gt manuscript tables as faithful, high-resolution
 * PNG fallbacks for the Word rendering. The browser manuscript remains live
 * HTML; these images are used only to avoid lossy gt-to-DOCX conversion.
 */

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createHash } from "node:crypto";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
// BEGIN S2_SCREEN_READER_CONTRACT
const S2_SCREEN_READER_CONTRACT = [
  {
    "source_body_row": 2,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Time above 1,000 lx melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "fe47619e411cd55ac5de9a59ac4a149866be86331e340872e5d14c3e8a33ea3d",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 3,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Time above 250 lx melEDI during wake distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "1036bb5970943489ba41944679ee69c016e3d058e6cbcd6e6e5e868a207a0653",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 4,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Time below 10 lx melEDI before sleep distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "a9466832fbe118c043032f2b9891ec3932b8db50060790401e3452e0c82bda7f",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 5,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Time below 1 lx melEDI during sleep distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "fd641c08bb3f4dc03ca796fe5f14e93768333caa2c6ee234d6c0e017ffb285f2",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 6,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Longest period above 250 lx melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "6eb4de282ffa499a5d56b2860c0ce407bf2288bf3182616dfde4cb30e0dce0a9",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 8,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Interdaily stability distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "d11653fb6c70ac47e6dee9ffcf994647f2629c206ea363eae0e7caae9f5e2460",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 9,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Intradaily variability distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "1995b69ca3a26391a2e3caa55de7c58b498e935af7229cbe38063c3f3b99d85e",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 11,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "melEDI dose distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "069be4e2f3ecf89617e8eec3c2a97b2bec5dd94bf9db7f423a847023cf168e96",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 13,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Mean melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "f92fbd7538e69e8d131bb85c9eabc861370df3179887fe6292fd470803187071",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 14,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Brightest 10 h mean distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "ec4b8ab22e653dd66a1b5ac93b098f89583449cc3a788eae8b72cb2315b212d9",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 15,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Darkest 10 h mean distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "39af943cfb1e79aaf7ac068960703a5e2d3efaa6f798016740dc6bb7d22f13c0",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 17,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Melanopic daylight efficacy ratio distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "f2d9d2e2261b0a844524941bee9ab1295557359021b4c097fdb8cde4c60145a0",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 19,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Midpoint of the brightest 10 hours distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "11329f7395a14c80fa6ab7727c85c5038fa776834f537710c6b14c373d22628b",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 20,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Midpoint of the darkest 10 hours distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "6d64069c7fde2259ed7ca70b78d25bed1a95c075c8008f111cf732b25e4753fe",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 21,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "First light timing above 250 lx melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "95f9d1f3c8904b2240f1fc95623222922e7439a838142ae85ec9b88fcc3fd337",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 22,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Last light timing above 250 lx melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "7c8ffd9f29c116b0d640ccc7bd388ebae294fc782ac8727d9bdf62c5cfb80bbe",
    "image_alt": null,
    "image_aria_hidden": "true"
  },
  {
    "source_body_row": 23,
    "source_column": 14,
    "parent_tag": "td",
    "description_tag": "span",
    "description": "Mean timing of exposure above 250 lx melEDI distribution by site. Exact numerical summaries are in the adjacent cells.",
    "style": "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0",
    "image_payload_sha256": "d0279891ce0dffb1abc41c18ff07ffa920cc594bb906c543c81e946c6116daa9",
    "image_alt": null,
    "image_aria_hidden": "true"
  }
];
// END S2_SCREEN_READER_CONTRACT

function matchesS2ScreenReaderSpan(actual, expected) {
  const fields = ["source_body_row", "source_column", "parent_tag", "description_tag",
    "description", "style", "image_src", "image_alt", "image_aria_hidden"];
  const hiddenStyle = {position: "absolute", width: "1px", height: "1px", overflowX: "hidden",
    overflowY: "hidden", clip: "rect(0px,0px,0px,0px)", clipPath: "inset(50%)", whiteSpace: "nowrap"};
  return !!actual && !!expected && actual.span_count === 1 && actual.image_count === 1 &&
    actual.direct_child === true && actual.image_is_sibling === true && actual.single_text_node === true &&
    Object.entries(hiddenStyle).every(([key, value]) => actual.computed_style?.[key] === value) &&
    fields.every((key) => Object.hasOwn(actual, key) && Object.hasOwn(expected, key) && actual[key] === expected[key]);
}

function validateS2SourceDescriptions(sourceInfo) {
  if (sourceInfo.tbodyCount !== 23 || sourceInfo.columnCount !== 14 ||
      sourceInfo.s2HiddenDescriptions.length !== S2_SCREEN_READER_CONTRACT.length) {
    throw new Error("S2 source structure or screen-reader inventory changed");
  }
  return S2_SCREEN_READER_CONTRACT.map((record, index) => {
    const actual = sourceInfo.s2HiddenDescriptions[index];
    const expected = {...record, image_src: actual?.image_src};
    if (typeof actual?.image_src !== "string" ||
        createHash("sha256").update(actual.image_src, "utf8").digest("hex") !== record.image_payload_sha256 ||
        !matchesS2ScreenReaderSpan(actual, expected)) {
      throw new Error("S2 source screen-reader contract or image payload changed");
    }
    return expected;
  });
}

const { chromium } = require(
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright",
);

const [sourceUrl, outputDir, captureSubset] = process.argv.slice(2);
if (captureSubset && captureSubset !== "only-s2") throw new Error("Only the approved S2-only correction subset is supported");

if (!sourceUrl || !outputDir) {
  throw new Error(
    "Usage: capture_word_tables.mjs <rendered-html-url> <output-directory>",
  );
}

const candidateRoot = path.resolve(import.meta.dirname, "..");
if (!path.resolve(outputDir).startsWith(candidateRoot + path.sep)) {
  throw new Error("Capture output must stay inside the Order72k candidate root");
}
if (await fs.stat(outputDir).then(() => true, () => false)) {
  throw new Error("Capture destination already exists; no implicit retry");
}

const chromePath =
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const specs = [
  {
    key: "main_table_1",
    selector: "#tbl-participant-site-manuscript",
    rowRanges: [
      [0, 12],
      [12, 18],
    ],
    targetWidth: 1320,
  },
  {
    key: "main_table_2",
    selector: "#tbl-plan-brown-main-adherence",
  },
  {
    key: "main_table_3",
    selector: "#tbl-plan-h01-metric-synthesis-candidate",
    rowRanges: [
      [0, 6],
      [6, 11],
      [11, 17],
      [17, 23],
    ],
    targetWidth: 1160,
  },
  {
    key: "supp_table_s1",
    selector: "#tbl-plan-descriptive-sample-flow",
  },
  {
    key: "supp_table_s2",
    selector: "#tbl-near-eye-metrics",
    rowRanges: [
      [0, 11],
      [11, 17],
      [17, 23],
    ],
    columnSets: [
      [0, 1, 2, 3, 4, 5, 6, 7],
      [0, 1, 2, 8, 9, 10, 11, 12, 13],
    ],
  },
  {
    key: "supp_table_s3",
    selector: "#tbl-recommendation-context",
  },
  {
    key: "supp_table_s4",
    selector: "#tbl-plan-brown-cross-window-associations",
    rowRanges: [
      [0, 3],
      [3, 6],
    ],
  },
  {
    key: "supp_table_s5",
    selector: "#tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  },
  {
    key: "supp_table_s6",
    selector: "#tbl-plan-h02-chest-variation-shapley-gt-candidate",
  },
  {
    key: "supp_table_s7",
    selector: "#tbl-h01-primary-publication-summary",
    rowRanges: [
      [0, 7],
      [7, 13],
      [13, 23],
    ],
  },
  {
    key: "supp_table_s8",
    selector: "#tbl-h07-near-results",
  },
  {
    key: "supp_table_s9",
    selector: "#tbl-h06-primary-effects",
  },
  {
    key: "supp_table_s10",
    selector: "#tbl-plan-person-level-synthesis-gt-candidate",
    rowRanges: [
      [0, 4],
      [4, 7],
    ],
  },
  {
    key: "supp_table_s11a",
    selector: "#tbl-h05-near-results-a",
  },
  {
    key: "supp_table_s11b",
    selector: "#tbl-h05-near-results-b",
  },
  {
    key: "supp_table_s12",
    selector: "#tbl-h08-near-eye-results",
  },
  {
    key: "supp_table_s13",
    selector: "#tbl-h09-near-eye-results",
  },
  {
    key: "supp_table_s14",
    selector: "#tbl-h10-main-results",
  },
  {
    key: "supp_table_s15",
    selector: "#tbl-h11-global-tests",
  },
];

const figureSpecs = [
  ["supp_figure_s1", "artifacts/10_figures/descriptives/near_eye_metric_distributions.png"],
  ["supp_figure_s2", "artifacts/10_figures/descriptives/time_series_to_metrics.png"],
  ["supp_figure_s3", "artifacts/10_figures/descriptives/latitude_photoperiod_diagnostic.png"],
  ["supp_figure_s4", "audit/manuscript_nature_health/figure_table_selection_assets/brown_adherence_levels.svg"],
  ["supp_figure_s5", "audit/manuscript_nature_health/figure_table_selection_assets/brown_supplementary_figure_s5.svg"],
  ["supp_figure_s6", "manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg"],
  ["supp_figure_s7", "audit/manuscript_nature_health/figure_table_selection_assets/supplementary_figure_s6.svg"],
  ["supp_figure_s8", "artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.png"],
  ["supp_figure_s9", "artifacts/10_figures/H06/H06_paired_placement_effects.png"],
  ["supp_figure_s10", "artifacts/10_figures/H06/H06_reader_temporal_day_type.png"],
  ["supp_figure_s11", "artifacts/10_figures/H06/H06_reader_temporal_activity.png"],
  ["supp_figure_s12", "artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png"],
  ["supp_figure_s13", "artifacts/10_figures/H05/H05_reader_near_eye_effects.png"],
  ["supp_figure_s14", "artifacts/10_figures/H08/H08_near_eye_effects.png"],
  ["supp_figure_s15", "audit/manuscript_nature_health/figure_table_selection_assets/supplementary_figure_s14.svg"],
  ["supp_figure_s16", "audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png"],
  ["supp_figure_s17", "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png"],
];

// Order72k only: no broad recapture and no scientific figure rasterization.
const activeSpecs = specs.filter((s) => ["supp_table_s2", "supp_table_s5", "supp_table_s6", "supp_table_s10"].includes(s.key));
Object.assign(activeSpecs.find((s) => s.key === "supp_table_s2"), {
  rowRanges: [[0, 9], [9, 17], [17, 23]],
  columnSets: [Array.from({length: 14}, (_, i) => i)],
  targetWidth: 1490,
  fixedWidths: [200, 80, 105, 86, 86, 86, 86, 86, 86, 86, 86, 86, 100, 231],
});
for (const spec of activeSpecs) {
  if (spec.key !== "supp_table_s2") {
    spec.fontRepair = true;
    spec.targetWidth = spec.key === "supp_table_s10" ? 904 : 902;
  }
}

const browser = await chromium.launch({
  headless: true,
  executablePath: chromePath,
});
const context = await browser.newContext({
  viewport: { width: 3000, height: 2200 },
  deviceScaleFactor: 2,
});
const source = await context.newPage();
try {
await source.goto(sourceUrl, { waitUntil: "networkidle" });
await fs.mkdir(outputDir, { recursive: true });

const outputManifest = [];

for (const spec of activeSpecs.filter((s) => !captureSubset || s.key === "supp_table_s2")) {
  const sourceRoot = source.locator(spec.selector).first();
  const count = await sourceRoot.count();
  if (count !== 1) {
    throw new Error(
      `${spec.key}: expected one ${spec.selector} container, found ${count}`,
    );
  }

  const sourceInfo = await sourceRoot.evaluate((root) => {
    function collectS2ScreenReaderSpans(table, rowOffset = 0) {
      return Array.from(table.querySelectorAll("tbody tr")).flatMap((row, rowIndex) => {
        if (row.children.length !== 14) return [];
        const cell = row.children[13];
        const spans = Array.from(cell.querySelectorAll("span"));
        const images = Array.from(cell.querySelectorAll("img"));
        const img = images[0];
        return spans.map((span) => {
          const computed = getComputedStyle(span);
          return {element: span, descriptor: {
            source_body_row: rowIndex + rowOffset + 1, source_column: 14,
            parent_tag: span.parentElement?.tagName.toLowerCase(),
            description_tag: span.tagName.toLowerCase(), description: span.textContent,
            style: span.getAttribute("style"), image_src: img?.getAttribute("src"),
            image_alt: img?.getAttribute("alt"), image_aria_hidden: img?.getAttribute("aria-hidden"),
            span_count: spans.length, image_count: images.length,
            direct_child: span.parentElement === cell, image_is_sibling: img?.parentElement === cell,
            single_text_node: span.childNodes.length === 1 && span.firstChild?.nodeType === 3,
            computed_style: {position: computed.position, width: computed.width, height: computed.height,
              overflowX: computed.overflowX, overflowY: computed.overflowY,
              clip: computed.clip.replace(/\s+/g, ""), clipPath: computed.clipPath, whiteSpace: computed.whiteSpace},
          }};
        });
      });
    }
    const table = root.matches("table")
      ? root
      : root.querySelector("table.gt_table, table");
    if (!table) throw new Error("No table found in selected container");
    const headerCells = Array.from(
      table.querySelectorAll("thead tr:last-child > th, thead tr:last-child > td"),
    );
    const dataRow = Array.from(table.querySelectorAll("tbody tr")).find(
      (row) => row.children.length > 1,
    );
    const widthCells = dataRow
      ? Array.from(dataRow.children)
      : headerCells;
    return {
      outerHTML: root.outerHTML,
      tableWidth: Math.ceil(
        Math.max(table.getBoundingClientRect().width, table.scrollWidth),
      ),
      tbodyCount: table.querySelectorAll("tbody tr").length,
      columnCount: widthCells.length,
      columnWidths: widthCells.map((cell) =>
        Math.ceil(cell.getBoundingClientRect().width),
      ),
      bodyCells: Array.from(table.querySelectorAll("tbody tr")).map((row) => Array.from(row.children).map((cell) => cell.textContent)),
      s2HiddenDescriptions: root.id === "tbl-near-eye-metrics" ? collectS2ScreenReaderSpans(table).map(({descriptor}) => descriptor) : [],
    };
  });
  if (spec.selector === "#tbl-near-eye-metrics") sourceInfo.s2HiddenDescriptions = validateS2SourceDescriptions(sourceInfo);
  await fs.writeFile(path.join(outputDir, `${spec.key}_source.html`), sourceInfo.outerHTML);

  const rowRanges = spec.rowRanges ?? [[0, sourceInfo.tbodyCount]];
  const columnSets = spec.columnSets ?? [
    Array.from({ length: sourceInfo.columnCount }, (_, i) => i),
  ];
  const files = [];
  const totalParts = rowRanges.length * columnSets.length;
  let part = 0;

  for (let columnPart = 0; columnPart < columnSets.length; columnPart += 1) {
    for (let rowPart = 0; rowPart < rowRanges.length; rowPart += 1) {
      part += 1;
      const page = await context.newPage();
      await page.setContent(
        `<!doctype html><html><head><meta charset="utf-8"><base href="${sourceUrl}">
        <style>
          html, body { margin: 0; padding: 0; background: #fff; }
          body { width: max-content; color: #333; }
          .gt_table { font-size: 12px !important; max-width: none !important; }
          .gt_col_heading, .gt_group_heading, .gt_row, .gt_stub {
            font-size: 12px !important;
          }
          .gt_col_heading > *, .gt_group_heading > *, .gt_row > *, .gt_stub > * {
            font-size: inherit !important;
          }
          .gt_title { font-size: 125% !important; }
          .gt_sourcenote, .gt_footnote { font-size: 90% !important; }
          .word-table-part { margin: 0 0 5px 0; font: 600 12px/1.25 Arial, sans-serif; }
          ${spec.fontRepair ? '#word-table-capture, #word-table-capture table, #word-table-capture th, #word-table-capture td, #word-table-capture * {font-family: Arial, Helvetica, sans-serif !important;}' : ''}
        </style></head><body><div id="word-table-capture">${sourceInfo.outerHTML}</div></body></html>`,
        { waitUntil: "load" },
      );

      const [rowStart, rowEnd] = rowRanges[rowPart];
      const keepColumns = columnSets[columnPart];
      const keepFoot = rowPart === rowRanges.length - 1;
      const continuation = totalParts > 1 && part > 1;
      const requestedWidth = spec.targetWidth ?? null;

      const captureInfo = await page.evaluate(
        ({
          selector,
          rowStart,
          rowEnd,
          keepColumns,
          allColumnWidths,
          keepFoot,
          continuation,
          requestedWidth,
          fixedWidths,
          sourceHiddenDescriptions,
        }) => {
          function collectS2ScreenReaderSpans(table, rowOffset = 0) {
            return Array.from(table.querySelectorAll("tbody tr")).flatMap((row, rowIndex) => {
              if (row.children.length !== 14) return [];
              const cell = row.children[13];
              const spans = Array.from(cell.querySelectorAll("span"));
              const images = Array.from(cell.querySelectorAll("img"));
              const img = images[0];
              return spans.map((span) => {
                const computed = getComputedStyle(span);
                return {element: span, descriptor: {
                  source_body_row: rowIndex + rowOffset + 1, source_column: 14,
                  parent_tag: span.parentElement?.tagName.toLowerCase(),
                  description_tag: span.tagName.toLowerCase(), description: span.textContent,
                  style: span.getAttribute("style"), image_src: img?.getAttribute("src"),
                  image_alt: img?.getAttribute("alt"), image_aria_hidden: img?.getAttribute("aria-hidden"),
                  span_count: spans.length, image_count: images.length,
                  direct_child: span.parentElement === cell, image_is_sibling: img?.parentElement === cell,
                  single_text_node: span.childNodes.length === 1 && span.firstChild?.nodeType === 3,
                  computed_style: {position: computed.position, width: computed.width, height: computed.height,
                    overflowX: computed.overflowX, overflowY: computed.overflowY,
                    clip: computed.clip.replace(/\s+/g, ""), clipPath: computed.clipPath, whiteSpace: computed.whiteSpace},
                }};
              });
            });
          }
          
          function matchesS2ScreenReaderSpan(actual, expected) {
            const fields = ["source_body_row", "source_column", "parent_tag", "description_tag",
              "description", "style", "image_src", "image_alt", "image_aria_hidden"];
            const hiddenStyle = {position: "absolute", width: "1px", height: "1px", overflowX: "hidden",
              overflowY: "hidden", clip: "rect(0px,0px,0px,0px)", clipPath: "inset(50%)", whiteSpace: "nowrap"};
            return !!actual && !!expected && actual.span_count === 1 && actual.image_count === 1 &&
              actual.direct_child === true && actual.image_is_sibling === true && actual.single_text_node === true &&
              Object.entries(hiddenStyle).every(([key, value]) => actual.computed_style?.[key] === value) &&
              fields.every((key) => Object.hasOwn(actual, key) && Object.hasOwn(expected, key) && actual[key] === expected[key]);
          }
          
          function validateS2ScreenReaderSpans(table, expectedDescriptions, rowOffset = 0) {
            const candidates = collectS2ScreenReaderSpans(table, rowOffset);
            if (candidates.length !== expectedDescriptions.length) throw new Error("S2 screen-reader span count changed");
            for (let i = 0; i < candidates.length; i += 1) {
              if (!matchesS2ScreenReaderSpan(candidates[i].descriptor, expectedDescriptions[i])) {
                throw new Error("S2 screen-reader text/style/location/image association changed");
              }
            }
            return new Set(candidates.map(({element}) => element));
          }
          const root = document.querySelector(selector);
          const captureRoot = document.querySelector("#word-table-capture");
          const table = root?.matches("table")
            ? root
            : root?.querySelector("table.gt_table, table");
          if (!root || !table) throw new Error("Capture table not found");

          const protectedS2Spans = selector === "#tbl-near-eye-metrics"
            ? validateS2ScreenReaderSpans(table, sourceHiddenDescriptions) : new Set();

          const keep = new Set(keepColumns);
          const originalColumnCount = allColumnWidths.length;

          if (keepColumns.length !== originalColumnCount) {
            const cols = Array.from(table.querySelectorAll("colgroup col"));
            cols.forEach((col, index) => {
              if (!keep.has(index)) col.remove();
              else col.style.width = `${allColumnWidths[index]}px`;
            });

            for (const row of table.querySelectorAll("tr")) {
              const cells = Array.from(row.children).filter((cell) =>
                ["TH", "TD"].includes(cell.tagName),
              );
              if (cells.length === originalColumnCount) {
                cells.forEach((cell, index) => {
                  if (!keep.has(index)) cell.remove();
                });
              } else if (cells.length === 1 && cells[0].colSpan > 1) {
                cells[0].colSpan = keepColumns.length;
              }
            }
          }

          Array.from(table.querySelectorAll("tbody tr")).forEach((row, index) => {
            if (index < rowStart || index >= rowEnd) row.remove();
          });

          if (!keepFoot) table.querySelector("tfoot")?.remove();

          for (const element of [root, ...root.querySelectorAll("*")]) {
            if (!(element instanceof HTMLElement)) continue;
            if (protectedS2Spans.has(element)) continue;
            if (
              element.style.overflow ||
              element.style.overflowX ||
              element.style.overflowY
            ) {
              element.style.overflow = "visible";
              element.style.height = "auto";
              element.style.maxHeight = "none";
            }
          }

          let tableWidth = requestedWidth;
          if (!tableWidth) {
            tableWidth = keepColumns.reduce(
              (sum, index) => sum + allColumnWidths[index],
              0,
            );
          }
          tableWidth = Math.max(520, Math.ceil(tableWidth));
          table.style.width = `${tableWidth}px`;
          table.style.minWidth = `${tableWidth}px`;
          table.style.maxWidth = "none";
          table.style.tableLayout = "fixed";
          if (fixedWidths) {
            if (fixedWidths.length !== originalColumnCount || keepColumns.length !== originalColumnCount) throw new Error("S2 must retain all 14 columns");
            table.querySelectorAll("colgroup").forEach((node) => node.remove());
            const group = document.createElement("colgroup");
            for (const width of fixedWidths) { const col = document.createElement("col"); col.style.width = `${width}px`; group.append(col); }
            table.insertBefore(group, table.firstChild);
            for (const row of table.querySelectorAll("tr")) {
              if (row.children.length === originalColumnCount) Array.from(row.children).forEach((cell, i) => {
                cell.style.width = `${fixedWidths[i]}px`; cell.style.minWidth = "0"; cell.style.maxWidth = `${fixedWidths[i]}px`;
              });
            }
            for (const img of table.querySelectorAll("tbody img")) {
              img.style.width = "100%"; img.style.height = "auto"; img.style.maxWidth = "100%"; img.style.minWidth = "0"; img.style.objectFit = "contain";
              if (img.parentElement !== img.closest("td")) { img.parentElement.style.width = "100%"; img.parentElement.style.minWidth = "0"; }
            }
            // S2 correction: preserve every character, allowing only vertical wrapping.
            for (const cell of table.querySelectorAll("tbody tr > :nth-child(n+3):nth-child(-n+12)")) {
              for (const node of [cell, ...cell.querySelectorAll("*")]) {
                node.style.setProperty("white-space", "normal", "important");
                node.style.setProperty("overflow-wrap", "normal", "important");
                node.style.setProperty("word-break", "normal", "important");
              }
            }
          }
          root.style.width = `${tableWidth}px`;
          root.style.maxWidth = "none";
          root.style.overflow = "visible";
          captureRoot.style.display = "inline-block";
          captureRoot.style.width = `${tableWidth}px`;
          captureRoot.style.maxWidth = "none";

          if (continuation) {
            const marker = document.createElement("div");
            marker.className = "word-table-part";
            const colText =
              keepColumns.length === originalColumnCount
                ? ""
                : `, column panel ${keepColumns[0] === 0 ? "A" : "B"}`;
            marker.textContent = `Table continued${colText}`;
            root.parentNode.insertBefore(marker, root);
          }

          return {
            width: tableWidth,
            rows: table.querySelectorAll("tbody tr").length,
            columns: keepColumns.length,
          };
        },
        {
          selector: spec.selector,
          rowStart,
          rowEnd,
          keepColumns,
          allColumnWidths: sourceInfo.columnWidths,
          keepFoot,
          continuation,
          requestedWidth,
          fixedWidths: spec.fixedWidths ?? null,
          sourceHiddenDescriptions: sourceInfo.s2HiddenDescriptions,
        },
      );

      await page.waitForFunction(() =>
        Array.from(document.images).every((image) => image.complete),
      );

      const verification = await page.evaluate(({selector, fontRepair, sourceHiddenDescriptions, rowStart, rowEnd}) => {
        function collectS2ScreenReaderSpans(table, rowOffset = 0) {
          return Array.from(table.querySelectorAll("tbody tr")).flatMap((row, rowIndex) => {
            if (row.children.length !== 14) return [];
            const cell = row.children[13];
            const spans = Array.from(cell.querySelectorAll("span"));
            const images = Array.from(cell.querySelectorAll("img"));
            const img = images[0];
            return spans.map((span) => {
              const computed = getComputedStyle(span);
              return {element: span, descriptor: {
                source_body_row: rowIndex + rowOffset + 1, source_column: 14,
                parent_tag: span.parentElement?.tagName.toLowerCase(),
                description_tag: span.tagName.toLowerCase(), description: span.textContent,
                style: span.getAttribute("style"), image_src: img?.getAttribute("src"),
                image_alt: img?.getAttribute("alt"), image_aria_hidden: img?.getAttribute("aria-hidden"),
                span_count: spans.length, image_count: images.length,
                direct_child: span.parentElement === cell, image_is_sibling: img?.parentElement === cell,
                single_text_node: span.childNodes.length === 1 && span.firstChild?.nodeType === 3,
                computed_style: {position: computed.position, width: computed.width, height: computed.height,
                  overflowX: computed.overflowX, overflowY: computed.overflowY,
                  clip: computed.clip.replace(/\s+/g, ""), clipPath: computed.clipPath, whiteSpace: computed.whiteSpace},
              }};
            });
          });
        }
        
        function matchesS2ScreenReaderSpan(actual, expected) {
          const fields = ["source_body_row", "source_column", "parent_tag", "description_tag",
            "description", "style", "image_src", "image_alt", "image_aria_hidden"];
          const hiddenStyle = {position: "absolute", width: "1px", height: "1px", overflowX: "hidden",
            overflowY: "hidden", clip: "rect(0px,0px,0px,0px)", clipPath: "inset(50%)", whiteSpace: "nowrap"};
          return !!actual && !!expected && actual.span_count === 1 && actual.image_count === 1 &&
            actual.direct_child === true && actual.image_is_sibling === true && actual.single_text_node === true &&
            Object.entries(hiddenStyle).every(([key, value]) => actual.computed_style?.[key] === value) &&
            fields.every((key) => Object.hasOwn(actual, key) && Object.hasOwn(expected, key) && actual[key] === expected[key]);
        }
        
        function validateS2ScreenReaderSpans(table, expectedDescriptions, rowOffset = 0) {
          const candidates = collectS2ScreenReaderSpans(table, rowOffset);
          if (candidates.length !== expectedDescriptions.length) throw new Error("S2 screen-reader span count changed");
          for (let i = 0; i < candidates.length; i += 1) {
            if (!matchesS2ScreenReaderSpan(candidates[i].descriptor, expectedDescriptions[i])) {
              throw new Error("S2 screen-reader text/style/location/image association changed");
            }
          }
          return new Set(candidates.map(({element}) => element));
        }
        
        function s2TextRectOverflows(rect, cellBox) {
          return rect.left < cellBox.left - 0.5 || rect.right > cellBox.right + 0.5 ||
            rect.top < cellBox.top - 0.5 || rect.bottom > cellBox.bottom + 0.5;
        }
        const root = document.querySelector(selector);
        const table = root.matches("table") ? root : root.querySelector("table");
        const expectedHiddenDescriptions = selector === "#tbl-near-eye-metrics"
          ? sourceHiddenDescriptions.filter((record) => record.source_body_row > rowStart && record.source_body_row <= rowEnd) : [];
        const protectedS2Spans = selector === "#tbl-near-eye-metrics"
          ? validateS2ScreenReaderSpans(table, expectedHiddenDescriptions, rowStart) : new Set();
        const sampleSelectors = {title: ".gt_title", header: ".gt_col_heading", stub: ".gt_stub", body: "td.gt_row", note: ".gt_footnote, .gt_sourcenote"};
        const fonts = Object.fromEntries(Object.entries(sampleSelectors).map(([key, sel]) => {
          const el = table.querySelector(sel);
          if (!el && key === "note" && !table.querySelector("tfoot")) return [key, null];
          if (!el) throw new Error(`Missing font sample ${key}`);
          return [key, getComputedStyle(el).fontFamily];
        }));
        if (fontRepair && Object.values(fonts).some((family) => family !== null && !family.startsWith("Arial"))) throw new Error("Arial capture font check failed");
        const images = Array.from(table.querySelectorAll("tbody img")).map((img) => {
          const box = img.getBoundingClientRect(), cell = img.closest("td, th").getBoundingClientRect();
          return {naturalWidth: img.naturalWidth, naturalHeight: img.naturalHeight, width: box.width, height: box.height,
            contained: box.left >= cell.left - 0.5 && box.right <= cell.right + 0.5,
            ratioPreserved: Math.abs(box.width / box.height - img.naturalWidth / img.naturalHeight) < 0.01};
        });
        if (images.some((img) => !img.naturalWidth || !img.contained || !img.ratioPreserved)) throw new Error("Distribution image containment or aspect ratio failed");
        const numericalTextOverflow = [];
        if (selector === "#tbl-near-eye-metrics") {
          for (const cell of table.querySelectorAll("thead th, thead td, tbody th, tbody td, tfoot th, tfoot td")) {
            const cellBox = cell.getBoundingClientRect();
            const walker = document.createTreeWalker(cell, NodeFilter.SHOW_TEXT);
            while (walker.nextNode()) {
              if (!walker.currentNode.textContent.trim()) continue;
              if (protectedS2Spans.has(walker.currentNode.parentElement)) continue;
              const range = document.createRange(); range.selectNodeContents(walker.currentNode);
              for (const rect of range.getClientRects()) {
                if (s2TextRectOverflows(rect, cellBox)) {
                  numericalTextOverflow.push({text:walker.currentNode.textContent,left:rect.left,right:rect.right,top:rect.top,bottom:rect.bottom,cellLeft:cellBox.left,cellRight:cellBox.right,cellTop:cellBox.top,cellBottom:cellBox.bottom});
                }
              }
            }
          }
        }
        if (numericalTextOverflow.length) throw new Error(`S2 all-cell text clipping: ${JSON.stringify(numericalTextOverflow)}`);
        const screenReaderDescriptions = expectedHiddenDescriptions.map(({image_src, ...record}) => ({...record, hiddenStylePreserved: true, sourceImageMatched: true}));
        return {fonts, images, numericalTextOverflow, screenReaderDescriptions, bodyCells: Array.from(table.querySelectorAll("tbody tr")).map((row) => Array.from(row.children).map((cell) => cell.textContent))};
      }, {selector: spec.selector, fontRepair: !!spec.fontRepair, sourceHiddenDescriptions: sourceInfo.s2HiddenDescriptions, rowStart, rowEnd});
      if (JSON.stringify(verification.bodyCells) !== JSON.stringify(sourceInfo.bodyCells.slice(rowStart, rowEnd))) throw new Error("Frozen cell text changed in capture");
      await fs.writeFile(path.join(outputDir, `${spec.key}_part_${String(part).padStart(2, "0")}.html`), await page.content());

      const capture = page.locator("#word-table-capture");
      const filename = `${spec.key}_part_${String(part).padStart(2, "0")}.png`;
      const destination = path.resolve(outputDir, filename);
      await capture.screenshot({ path: destination });
      const box = await capture.boundingBox();
      files.push({
        path: destination,
        part,
        rowRange: [rowStart, rowEnd],
        columns: keepColumns,
        cssWidth: captureInfo.width,
        cssHeight: box ? Math.ceil(box.height) : null,
        verification,
      });
      await page.close();
    }
  }

  outputManifest.push({
    key: spec.key,
    selector: spec.selector,
    sourceRows: sourceInfo.tbodyCount,
    sourceColumns: sourceInfo.columnCount,
    files,
  });
  process.stdout.write(`${spec.key}: ${files.length} PNG part(s)\n`);
}

const manifestPath = path.resolve(outputDir, "word_table_png_manifest.json");
await fs.writeFile(manifestPath, `${JSON.stringify(outputManifest, null, 2)}\n`);

const figureManifest = [];
for (const [key, sourcePath] of []) {
  const absoluteSource = path.resolve(sourcePath);
  const extension = path.extname(absoluteSource).toLowerCase();
  if (![".png", ".svg"].includes(extension)) {
    throw new Error(`${key}: unsupported figure extension ${extension}`);
  }

  const figureMarkup =
    extension === ".svg"
      ? await fs.readFile(absoluteSource, "utf8")
      : `<img alt="" src="data:image/png;base64,${(
          await fs.readFile(absoluteSource)
        ).toString("base64")}">`;
  const page = await context.newPage();
  await page.setContent(
    `<!doctype html><html><head><meta charset="utf-8"><style>
      html, body { margin: 0; padding: 0; background: #fff; }
      #word-figure-capture { display: inline-block; line-height: 0; }
      #word-figure-capture svg, #word-figure-capture img {
        display: block; width: 1200px; height: auto;
      }
    </style></head><body><div id="word-figure-capture">${figureMarkup}</div></body></html>`,
    { waitUntil: "load" },
  );
  await page.waitForFunction(() =>
    Array.from(document.images).every((image) => image.complete),
  );
  const filename = `${key}.png`;
  const destination = path.resolve(outputDir, filename);
  await page.locator("#word-figure-capture").screenshot({ path: destination });
  await page.close();
  figureManifest.push({ key, source: absoluteSource, path: destination });
}

const figureManifestPath = path.resolve(
  outputDir,
  "word_figure_png_manifest.json",
);
process.stdout.write(`Manifest: ${manifestPath}\n`);
process.stdout.write("Scientific figure capture was skipped.\n");
} finally {
  await browser.close();
}
