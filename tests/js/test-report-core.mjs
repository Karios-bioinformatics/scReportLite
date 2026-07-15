import fs from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const source = fs.readFileSync(
  new URL("../../inst/assets/js/report_core.js", import.meta.url),
  "utf8"
);
const makeClassList = () => ({
  active: false,
  add(value) { if (value === "active") this.active = true; },
  remove(value) { if (value === "active") this.active = false; }
});
const ids = ["plot", "feature", "pca", "umap"];
const views = ids.map((id) => ({
  id: `sr-view-${id}`,
  style: { display: "none" },
  classList: makeClassList()
}));
const tabs = ids.map((id) => ({
  id: `view-tab-${id}`,
  dataset: { reportView: id },
  classList: makeClassList()
}));
const nodes = views.concat(tabs);
const document = {
  querySelectorAll(selector) {
    if (selector === ".sr-report-view") return views;
    if (selector === "[data-report-view]") return tabs;
    return [];
  },
  getElementById(id) {
    return nodes.find((node) => node.id === id) || null;
  },
  querySelector(selector) {
    const match = selector.match(/\[data-report-view="([^"]+)"\]/);
    return match
      ? tabs.find((node) => node.dataset.reportView === match[1]) || null
      : null;
  }
};
const context = {
  window: { _SR_INITIAL_VIEW: "plot", dispatchEvent() {} },
  document,
  Set,
  Array,
  String,
  Number,
  Math,
  isFinite,
  console,
  setTimeout(callback) { callback(); },
  Event: function Event(type) { this.type = type; }
};
vm.createContext(context);
vm.runInContext(source, context, { filename: "report_core.js" });

assert.deepEqual(
  ["Sample10", "Sample2", "Sample1", "Reference2", "Reference"]
    .sort(context._SR_naturalCompare),
  ["Reference", "Reference2", "Sample1", "Sample2", "Sample10"]
);
assert.equal(typeof context.switchView, "function");
context.switchView("pca");
assert.equal(views.find((view) => view.id === "sr-view-pca").style.display, "");
assert.equal(tabs.find((tab) => tab.id === "view-tab-pca").classList.active, true);
assert.equal(views.find((view) => view.id === "sr-view-plot").style.display, "none");

console.log("report_core production behavior: PASS");
