import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import assert from "node:assert/strict";
import {createHash} from "node:crypto";

const base = import.meta.dirname;
const proposed = fs.readFileSync(path.join(base, "capture_word_tables.mjs"), "utf8");
const before = fs.readFileSync(path.join(base, "capture_word_tables.preimage.mjs"), "utf8");
const checks = [];
function test(name, callback) { callback(); checks.push({check: name, pass: true}); }
function functionCopies(name) {
  const marker = `function ${name}(`;
  const copies = [];
  let from = 0;
  while (true) {
    const start = proposed.indexOf(marker, from);
    if (start < 0) break;
    let cursor = proposed.indexOf("{", start), depth = 0, quote = null, escaped = false;
    for (; cursor < proposed.length; cursor += 1) {
      const char = proposed[cursor];
      if (quote) {
        if (escaped) escaped = false;
        else if (char === "\\") escaped = true;
        else if (char === quote) quote = null;
        continue;
      }
      if (char === '"' || char === "'") { quote = char; continue; }
      if (char === "{") depth += 1;
      if (char === "}" && --depth === 0) { copies.push(proposed.slice(start, cursor + 1)); from = cursor + 1; break; }
    }
    assert.ok(cursor < proposed.length, `Unclosed function ${name}`);
  }
  return copies;
}
const names = {matchesS2ScreenReaderSpan: 3, collectS2ScreenReaderSpans: 3,
  validateS2ScreenReaderSpans: 2, s2TextRectOverflows: 1, validateS2SourceDescriptions: 1};
const functions = {};
for (const [name, count] of Object.entries(names)) {
  const copies = functionCopies(name);
  test(`identical extracted copies: ${name}`, () => {
    assert.equal(copies.length, count);
    const normalized = copies.map((code) => code.split("\n").map((line) => line.trim()).join("\n"));
    assert.equal(new Set(normalized).size, 1);
  });
  functions[name] = copies[0];
}
const prefix = "const S2_SCREEN_READER_CONTRACT = ";
const first = proposed.indexOf(prefix) + prefix.length;
const last = proposed.indexOf("// END S2_SCREEN_READER_CONTRACT", first);
const contract = JSON.parse(proposed.slice(first, last).trim().replace(/;$/, ""));
const syntheticComputed = {position: "absolute", width: "1px", height: "1px", overflowX: "hidden",
  overflowY: "hidden", clip: "rect(0px,0px,0px,0px)", clipPath: "inset(50%)", whiteSpace: "nowrap"};
const fixture = JSON.parse(fs.readFileSync(path.join(base, "source_descriptor_fixtures.json"), "utf8"));
for (const item of fixture.s2HiddenDescriptions) item.computed_style = {...syntheticComputed};
const context = vm.createContext({createHash, S2_SCREEN_READER_CONTRACT: contract,
  getComputedStyle: (node) => node.computed});
vm.runInContext(Object.values(functions).join("\n"), context);
const api = vm.runInContext(`({${Object.keys(functions).join(",")}})`, context);
let expected;
test("17 exact R-source descriptors and image payload hashes accepted with synthetic computed styles", () => {
  expected = api.validateS2SourceDescriptions(fixture);
  assert.equal(expected.length, 17);
  assert.equal(new Set(expected.map((item) => item.description)).size, 17);
});
const mutations = {
  description: (value) => value + " changed", style: (value) => value + ";height:auto",
  source_body_row: (value) => value + 1, source_column: () => 2,
  parent_tag: () => "div", description_tag: () => "b", image_src: (value) => value + "changed",
  image_alt: () => "changed", image_aria_hidden: () => "false", span_count: () => 2,
  image_count: () => 2, direct_child: () => false, image_is_sibling: () => false, single_text_node: () => false,
};
for (let index = 0; index < 17; index += 1) {
  for (const [key, mutate] of Object.entries(mutations)) test(`reject source row ${index + 1}: tampered ${key}`, () => {
    const changed = structuredClone(fixture);
    changed.s2HiddenDescriptions[index][key] = mutate(changed.s2HiddenDescriptions[index][key]);
    assert.throws(() => api.validateS2SourceDescriptions(changed));
  });
  for (const key of Object.keys(syntheticComputed)) test(`reject source row ${index + 1}: changed computed ${key}`, () => {
    const changed = structuredClone(fixture);
    changed.s2HiddenDescriptions[index].computed_style[key] = "changed";
    assert.throws(() => api.validateS2SourceDescriptions(changed));
  });
}
for (const change of ["missing", "additional", "reordered"]) test(`reject ${change} hidden-span inventory`, () => {
  const changed = structuredClone(fixture);
  if (change === "missing") changed.s2HiddenDescriptions.pop();
  if (change === "additional") changed.s2HiddenDescriptions.push(structuredClone(changed.s2HiddenDescriptions[0]));
  if (change === "reordered") changed.s2HiddenDescriptions.reverse();
  assert.throws(() => api.validateS2SourceDescriptions(changed));
});

class FakeElement {
  constructor(tagName, attrs = {}) { this.tagName = tagName; this.attrs = {...attrs}; this.style = {}; this.children = []; }
  getAttribute(name) { return Object.hasOwn(this.attrs, name) ? this.attrs[name] : null; }
}
function fakeTable(records, start, end) {
  const rows = [], spans = [], cells = [];
  for (let rowIndex = start; rowIndex < end; rowIndex += 1) {
    const record = records.find((entry) => entry.source_body_row === rowIndex + 1);
    const row = new FakeElement("TR");
    row.children = Array.from({length: record ? 14 : 1}, () => new FakeElement("TD"));
    if (record) {
      const cell = row.children[13];
      const span = new FakeElement("SPAN", {style: record.style});
      span.parentElement = cell; span.textContent = record.description;
      span.childNodes = [{nodeType: 3, parentElement: span}]; span.firstChild = span.childNodes[0];
      span.style = {overflow: "hidden", height: "1px", maxHeight: "", ...syntheticComputed};
      span.computed = span.style;
      const imgAttrs = {src: record.image_src, "aria-hidden": record.image_aria_hidden};
      if (record.image_alt !== null) imgAttrs.alt = record.image_alt;
      const img = new FakeElement("IMG", imgAttrs); img.parentElement = cell;
      cell.spans = [span]; cell.images = [img]; cell.children = [img, span];
      cell.querySelectorAll = (selector) => selector === "span" ? cell.spans : selector === "img" ? cell.images : [];
      spans.push(span); cells.push(cell);
    }
    rows.push(row);
  }
  return {rows, spans, cells, querySelectorAll: (selector) => selector === "tbody tr" ? rows : []};
}
const all = fakeTable(expected, 0, 23);
let protectedSet;
test("only 17 exact full-table element identities qualify", () => {
  protectedSet = api.validateS2ScreenReaderSpans(all, expected);
  assert.equal(protectedSet.size, 17);
  for (const span of all.spans) assert.equal(protectedSet.has(span), true);
  for (const cell of all.cells) assert.equal(protectedSet.has(cell), false);
});
for (const [start, end, count] of [[0, 9, 7], [9, 17, 5], [17, 23, 5]]) test(`exact ${count}-span partition [${start},${end})`, () => {
  const wanted = expected.filter((item) => item.source_body_row > start && item.source_body_row <= end);
  assert.equal(api.validateS2ScreenReaderSpans(fakeTable(wanted, start, end), wanted, start).size, count);
});
for (const change of ["style", "text", "column", "image", "extra-span", "computed-hidden-style"]) test(`reject tampered cloned ${change}`, () => {
  const table = fakeTable(expected, 0, 23);
  if (change === "style") table.spans[0].attrs.style += ";overflow:visible;height:auto";
  if (change === "text") table.spans[0].textContent += " changed";
  if (change === "column") { table.rows[1].children[1] = table.cells[0]; table.rows[1].children[13] = {querySelectorAll: () => []}; }
  if (change === "image") table.cells[0].images[0].attrs.src = table.cells[1].images[0].attrs.src;
  if (change === "extra-span") table.cells[0].spans.push(table.spans[0]);
  if (change === "computed-hidden-style") table.spans[0].computed.height = "auto";
  assert.throws(() => api.validateS2ScreenReaderSpans(table, expected));
});
test("exact generic overflow loop preserves proven spans only", () => {
  const start = proposed.indexOf('for (const element of [root, ...root.querySelectorAll("*")])');
  const end = proposed.indexOf("\n\n          let tableWidth", start);
  assert.ok(start > 0 && end > start);
  const visible = new FakeElement("DIV"); visible.style = {overflow: "hidden", height: "99px", maxHeight: "99px"};
  const root = new FakeElement("DIV"); root.querySelectorAll = () => [...all.spans, visible];
  vm.runInNewContext(proposed.slice(start, end), {root, HTMLElement: FakeElement, protectedS2Spans: protectedSet});
  for (const span of all.spans) { assert.equal(span.style.overflow, "hidden"); assert.equal(span.style.height, "1px"); }
  assert.equal(visible.style.overflow, "visible"); assert.equal(visible.style.height, "auto");
  assert.equal(api.validateS2ScreenReaderSpans(all, expected).size, 17);
});
const cellBox = {left: 0, right: 100, top: 0, bottom: 20};
for (const role of ["Unit", "Scaling", "Distribution-visible-text", "header", "note"]) test(`visible ${role} still checked on all four edges`, () => {
  const parent = new FakeElement("SPAN");
  assert.equal(protectedSet.has(parent), false);
  assert.equal(api.s2TextRectOverflows({left: 0, right: 100, top: 0, bottom: 20}, cellBox), false);
  for (const [edge, outside, tolerance] of [["left", -0.5001, -0.5], ["right", 100.5001, 100.5], ["top", -0.5001, -0.5], ["bottom", 20.5001, 20.5]]) {
    assert.equal(api.s2TextRectOverflows({...cellBox, [edge]: outside}, cellBox), true);
    assert.equal(api.s2TextRectOverflows({...cellBox, [edge]: tolerance}, cellBox), false);
  }
});
const section = (text, start, end) => text.slice(text.indexOf(start), text.indexOf(end, text.indexOf(start)));
test("all active specs and fixed widths unchanged", () => assert.equal(
  section(proposed, "// Order72k only:", "const browser ="), section(before, "// Order72k only:", "const browser =")));
test("browser launch, context settings and target navigation unchanged", () => assert.equal(
  section(proposed, "const browser =", "const outputManifest ="), section(before, "const browser =", "const outputManifest =")));
test("scientific figure loop remains disabled and identical", () => assert.equal(
  proposed.slice(proposed.indexOf("const figureManifest = []")), before.slice(before.indexOf("const figureManifest = []"))));
test("all visible-cell selectors and exact body-cell comparison retained", () => {
  assert.ok(proposed.includes('table.querySelectorAll("thead th, thead td, tbody th, tbody td, tfoot th, tfoot td")'));
  assert.ok(proposed.includes('if (protectedS2Spans.has(walker.currentNode.parentElement)) continue;'));
  assert.ok(proposed.includes('if (JSON.stringify(verification.bodyCells) !== JSON.stringify(sourceInfo.bodyCells.slice(rowStart, rowEnd))) throw new Error("Frozen cell text changed in capture");'));
  assert.ok(proposed.indexOf('if (numericalTextOverflow.length) throw') < proposed.indexOf('await capture.screenshot({ path: destination })'));
});
test("no additional browser, navigation or capture invocations", () => {
  for (const call of ["chromium.launch(", ".newPage(", ".goto(", ".setContent(", ".screenshot("]) {
    assert.equal(proposed.split(call).length, before.split(call).length, call);
  }
});
fs.writeFileSync(path.join(base, "static_test_results.json"), JSON.stringify({status: "PASS", checks,
  node: process.version, browser_launched: false, computed_styles: "Synthetic canonical fixtures only; actual computed styles remain a required future capture gate."}, null, 2) + "\n");
console.log(`STATIC_GUARD_TESTS=PASS checks=${checks.length} exact_descriptions=17 partitions=7/5/5 browser_runs=0`);
