const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..", "..");
const htmlPath = path.join(root, "v070_smoke.html");
let html = fs.readFileSync(htmlPath, "utf8");

function replaceEmbeddedAsset(marker, closingTag, sourcePath, insertBeforeMarker) {
  const start = html.indexOf(marker);
  const source = fs.readFileSync(path.join(root, sourcePath), "utf8");
  if (start < 0) {
    if (!insertBeforeMarker) throw new Error(`Marker not found: ${marker}`);
    const insertAt = html.indexOf(insertBeforeMarker);
    if (insertAt < 0) {
      throw new Error(`Insertion marker not found: ${insertBeforeMarker}`);
    }
    html = html.slice(0, insertAt) +
      `<script>${source}</script>\n    ` +
      html.slice(insertAt);
    return;
  }
  const end = html.indexOf(closingTag, start);
  if (end < 0) throw new Error(`Closing tag not found after: ${marker}`);
  html = html.slice(0, start) + source + html.slice(end);
}

function upsertRuntimeBundle() {
  const markerStart = "/* smoke injected: report runtime start */";
  const markerEnd = "/* smoke injected: report runtime end */";
  const runtimeFiles = [
    "inst/assets/js/report_core.js",
    "inst/assets/js/report_qc.js",
    "inst/assets/js/report_umap.js",
    "inst/assets/js/report_init.js"
  ];
  const runtime = runtimeFiles.map((sourcePath) =>
    fs.readFileSync(path.join(root, sourcePath), "utf8")
  ).join("\n\n");
  const block = `<script>${markerStart}\n${runtime}\n${markerEnd}</script>\n    `;

  const existingStart = html.indexOf(`<script>${markerStart}`);
  if (existingStart >= 0) {
    const existingEnd = html.indexOf("</script>", existingStart);
    if (existingEnd < 0) {
      throw new Error("Closing tag not found for injected report runtime");
    }
    html = html.slice(0, existingStart) +
      block +
      html.slice(existingEnd + "</script>".length);
    return;
  }

  const anchor = "<script>window._PCA_COLORS = window._PCA_COLORS || {};</script>";
  const insertAt = html.indexOf(anchor);
  if (insertAt < 0) {
    throw new Error(`Runtime insertion anchor not found: ${anchor}`);
  }
  html = html.slice(0, insertAt) + block + html.slice(insertAt);
}

function syncModuleSwitcherMarkup() {
  html = html
    .replaceAll("class=\"plot-nav-item active\"",
      "class=\"plot-nav-item sr-module-view-button active\"")
    .replaceAll("class=\"plot-nav-item\"",
      "class=\"plot-nav-item sr-module-view-button\"")
    .replaceAll("class=\"feature-nav-item active\"",
      "class=\"feature-nav-item sr-module-view-button active\"")
    .replaceAll("class=\"feature-nav-item\"",
      "class=\"feature-nav-item sr-module-view-button\"")
    .replaceAll("class=\"pca-cm-btn active\" data-pca-view",
      "class=\"pca-cm-btn sr-module-view-button active\" data-pca-view")
    .replaceAll("class=\"pca-cm-btn\" data-pca-view",
      "class=\"pca-cm-btn sr-module-view-button\" data-pca-view")
    .replaceAll("<span class=\"plot-nav-dot\"></span>", "")
    .replaceAll("<span class=\"feature-nav-dot\"></span>", "");
}

function syncResolutionCapsuleMarkup() {
  const legacyId = "sr-resolution-capsule";
  const umapId = "sr-resolution-capsule-umap";
  const featureId = "sr-resolution-capsule-feature";
  const pcaId = "sr-resolution-capsule-pca";

  html = html.replace(`id="${legacyId}"`, `id="${umapId}"`);

  const sourceMatch = html.match(
    /<div class="sr-resolution-capsule" id="sr-resolution-capsule-umap">[\s\S]*?<\/div>/
  );
  if (!sourceMatch) {
    throw new Error("UMAP resolution capsule markup was not found");
  }

  function capsuleFor(id) {
    return sourceMatch[0]
      .replace(`id="${umapId}"`, `id="${id}"`)
      .replace(/class="sr-resolution-dot active"/g, "class=\"sr-resolution-dot active\"");
  }

  if (!html.includes(`id="${featureId}"`)) {
    const anchor = '<div class="feature-main" id="feature-main">';
    const insertAt = html.indexOf(anchor);
    if (insertAt < 0) throw new Error(`Feature capsule anchor not found: ${anchor}`);
    const afterAnchor = insertAt + anchor.length;
    html = html.slice(0, afterAnchor) +
      `\n                ${capsuleFor(featureId)}` +
      html.slice(afterAnchor);
  }

  if (!html.includes(`id="${pcaId}"`)) {
    const anchor = '<div class="pca-plot-area" id="pca-plot-area">';
    const insertAt = html.indexOf(anchor);
    if (insertAt < 0) throw new Error(`PCA capsule anchor not found: ${anchor}`);
    const afterAnchor = insertAt + anchor.length;
    html = html.slice(0, afterAnchor) +
      `\n                ${capsuleFor(pcaId)}` +
      html.slice(afterAnchor);
  }
}

replaceEmbeddedAsset(
  "/* scReportLite v0.7.0 fixed-shell design system */",
  "</style>",
  "inst/assets/css/report_v070.css"
);
replaceEmbeddedAsset(
  "// PCA Interactive Controls (v0.2.2)",
  "</script>",
  "inst/assets/js/report_pca.js",
  "<script>/* scReportLite v0.7.0 shared UI primitives */"
);
replaceEmbeddedAsset(
  "// Feature Diagnostics view (v0.4.0)",
  "</script>",
  "inst/assets/js/feature.js"
);
replaceEmbeddedAsset(
  "/* scReportLite v0.7.0 shared UI primitives */",
  "</script>",
  "inst/assets/js/report_design.js"
);
upsertRuntimeBundle();
syncModuleSwitcherMarkup();
syncResolutionCapsuleMarkup();

[
  "function _SR_naturalCompare",
  "function switchView",
  "var _PLOT_STATE",
  "function initPcaPlot",
  "function switchTab",
  "onPlotlyReady(function",
  "id=\"sr-resolution-capsule-feature\"",
  "id=\"sr-resolution-capsule-pca\"",
  "id=\"sr-resolution-capsule-umap\"",
  "/* smoke injected: report runtime start */",
  "/* smoke injected: report runtime end */"
].forEach((contractMarker) => {
  if (!html.includes(contractMarker)) {
    throw new Error(`Refreshed smoke report is missing: ${contractMarker}`);
  }
});

fs.writeFileSync(htmlPath, html, "utf8");
console.log(`Refreshed embedded v0.7.0 assets in ${htmlPath}`);
