import fs from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const sharp = require("/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp");
const record = import.meta.dirname;
const owner = path.resolve(record, "..");
const destination = path.join(record, "intended_word_size");
await fs.mkdir(destination);
const manifest = JSON.parse(await fs.readFile(path.join(owner, "capture_s2_attempt5/word_table_png_manifest.json"), "utf8"));
if (manifest.length !== 1 || manifest[0].files.length !== 3) throw Error("Unexpected S2 capture membership");
const results = [];
for (const item of manifest[0].files) {
  const meta = await sharp(item.path).metadata();
  const inchPerPixel = Math.min(15.55 / meta.width, 8.90 / meta.height);
  const widthInches = meta.width * inchPerPixel;
  const heightInches = meta.height * inchPerPixel;
  const width = Math.round(widthInches * 96);
  const height = Math.round(heightInches * 96);
  const target = path.join(destination, path.basename(item.path));
  await sharp(item.path).resize({width, height, fit: "inside", kernel: "lanczos3"}).png().toFile(target);
  results.push({source: item.path, sourceWidth: meta.width, sourceHeight: meta.height,
    maximumWidthInches: 15.55, maximumHeightInches: 8.90, displayWidthInches: widthInches,
    displayHeightInches: heightInches, previewDpi: 96, preview: target,
    previewWidth: width, previewHeight: height, aspectRatioPreserved: true,
    qualification: "Display-only size surrogate for visual inspection, not a native Word page or replacement capture; source PNG unchanged"});
}
await fs.writeFile(path.join(record, "intended_word_size_geometry.json"), JSON.stringify(results, null, 2) + "\n");
process.stdout.write(JSON.stringify(results, null, 2) + "\n");
