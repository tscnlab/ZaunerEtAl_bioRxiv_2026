#!/usr/bin/env node

/* Formatting-only probe for the Word fallback of Supplementary Table S3. */

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require(
  "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright",
);

const [
  sourceUrl,
  outputDir,
  widthText = "1240",
  fontText = "12",
  paddingText = "5",
  columnsText = "",
] = process.argv.slice(2);
if (!sourceUrl || !outputDir) {
  throw new Error("Usage: probe_supp_table_s3_capture.mjs <html-url> <output-dir> [comma-separated-css-widths]");
}

const widths = widthText.split(",").map((value) => Number.parseInt(value, 10));
const fontSizes = fontText.split(",").map((value) => Number.parseFloat(value));
const horizontalPadding = Number.parseFloat(paddingText);
const targetColumnWidths = columnsText
  ? columnsText.split(",").map((value) => Number.parseFloat(value))
  : null;
if (widths.some((value) => !Number.isFinite(value) || value < 1000)) {
  throw new Error(`Invalid widths: ${widthText}`);
}
if (fontSizes.some((value) => !Number.isFinite(value) || value < 9 || value > 12)) {
  throw new Error(`Invalid font sizes: ${fontText}`);
}
if (!Number.isFinite(horizontalPadding) || horizontalPadding < 0 || horizontalPadding > 8) {
  throw new Error(`Invalid horizontal padding: ${paddingText}`);
}
if (targetColumnWidths && (targetColumnWidths.length !== 9 || targetColumnWidths.some((value) => !Number.isFinite(value)))) {
  throw new Error(`Invalid column widths: ${columnsText}`);
}

const browser = await chromium.launch({
  headless: true,
  executablePath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
});
const context = await browser.newContext({
  viewport: { width: 3000, height: 2200 },
  deviceScaleFactor: 2,
});
const source = await context.newPage();
await source.goto(sourceUrl, { waitUntil: "networkidle" });

const sourceInfo = await source.locator("#tbl-recommendation-context").first().evaluate((root) => {
  const table = root.querySelector("table.gt_table, table");
  if (!table) throw new Error("Supplementary Table S3 not found");
  return { outerHTML: root.outerHTML };
});

await fs.mkdir(outputDir, { recursive: true });
const report = [];
for (const width of widths) {
 for (const fontSize of fontSizes) {
  const page = await context.newPage();
  await page.setContent(
    `<!doctype html><html><head><meta charset="utf-8"><base href="${sourceUrl}">
    <style>
      html, body { margin: 0; padding: 0; background: #fff; }
      body { width: max-content; color: #333; }
      .gt_table { font-size: ${fontSize}px !important; max-width: none !important; }
      .gt_col_heading, .gt_group_heading, .gt_row, .gt_stub { font-size: ${fontSize}px !important; }
      .gt_col_heading > *, .gt_group_heading > *, .gt_row > *, .gt_stub > * { font-size: inherit !important; }
      .gt_title { font-size: 125% !important; }
      .gt_sourcenote, .gt_footnote { font-size: 90% !important; }
    </style></head><body><div id="word-table-capture">${sourceInfo.outerHTML}</div></body></html>`,
    { waitUntil: "load" },
  );

  const dimensions = await page.evaluate(({ targetWidth, horizontalPadding, targetColumnWidths }) => {
    const root = document.querySelector("#tbl-recommendation-context");
    const captureRoot = document.querySelector("#word-table-capture");
    const table = root?.querySelector("table.gt_table, table");
    if (!root || !captureRoot || !table) throw new Error("Capture table not found");

    for (const element of [root, ...root.querySelectorAll("*")]) {
      if (!(element instanceof HTMLElement)) continue;
      if (element.style.overflow || element.style.overflowX || element.style.overflowY) {
        element.style.overflow = "visible";
        element.style.height = "auto";
        element.style.maxHeight = "none";
      }
    }
    table.style.width = `${targetWidth}px`;
    table.style.minWidth = `${targetWidth}px`;
    table.style.maxWidth = "none";
    table.style.tableLayout = "fixed";
    if (targetColumnWidths) {
      const columns = [...table.querySelectorAll("colgroup col")];
      if (columns.length !== targetColumnWidths.length) throw new Error("Unexpected colgroup length");
      columns.forEach((column, index) => {
        column.style.width = `${targetColumnWidths[index]}px`;
      });
    }
    for (const cell of table.querySelectorAll("th, td")) {
      cell.style.paddingLeft = `${horizontalPadding}px`;
      cell.style.paddingRight = `${horizontalPadding}px`;
    }
    root.style.width = `${targetWidth}px`;
    root.style.maxWidth = "none";
    root.style.overflow = "visible";
    captureRoot.style.display = "inline-block";
    captureRoot.style.width = `${targetWidth}px`;
    captureRoot.style.maxWidth = "none";

    const cells = [...table.querySelectorAll("tbody th, tbody td")].map((cell) => ({
      text: (cell.textContent || "").replace(/\s+/g, " ").trim(),
      column: cell.cellIndex,
      clientWidth: cell.clientWidth,
      scrollWidth: cell.scrollWidth,
      overflow: getComputedStyle(cell).overflowX,
    }));
    const clipped = cells.filter((cell) => cell.scrollWidth > cell.clientWidth + 1);
    const columnRequirements = [...new Set(cells.map((cell) => cell.column))]
      .filter((column) => column >= 0)
      .map((column) => {
        const columnCells = cells.filter((cell) => cell.column === column);
        return {
          column,
          clientWidth: Math.min(...columnCells.map((cell) => cell.clientWidth)),
          requiredWidth: Math.max(...columnCells.map((cell) => cell.scrollWidth)),
          longestText: columnCells.sort((a, b) => b.scrollWidth - a.scrollWidth)[0].text,
        };
      });
    return {
      width: Math.ceil(captureRoot.getBoundingClientRect().width),
      height: Math.ceil(captureRoot.getBoundingClientRect().height),
      clipped,
      columnRequirements,
    };
  }, { targetWidth: width, horizontalPadding, targetColumnWidths });

  const fontLabel = String(fontSize).replace(".", "p");
  const outputPath = path.resolve(outputDir, `supp_table_s3_width_${width}_font_${fontLabel}.png`);
  await page.locator("#word-table-capture").screenshot({ path: outputPath });
  report.push({ width, fontSize, horizontalPadding, targetColumnWidths, outputPath, ...dimensions });
  await page.close();
 }
}

await fs.writeFile(
  path.resolve(outputDir, "probe_report.json"),
  `${JSON.stringify(report, null, 2)}\n`,
  "utf8",
);
process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
await browser.close();
