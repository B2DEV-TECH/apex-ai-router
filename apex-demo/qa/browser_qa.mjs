// Browser QA of the demo application against a live gateway and a running
// NeMo Switchyard sidecar. This is the script behind the screenshots in
// docs/images/ and the validation record in docs/live-validation-walkthrough.md.
//
//   cd apex-demo/qa && npm install
//   APEX_USER=<workspace user> APEX_PASSWORD=<password> APP_ID=<app id> node browser_qa.mjs
//
// Environment:
//   APEX_BASE_URL   ORDS base URL, default http://localhost:8080/ords
//   APEX_USER       APEX workspace user that can run the application (required)
//   APEX_PASSWORD   its password (required -- pass it through the environment, never commit it)
//   APP_ID          application id of the imported demo (required)
//   SCREENSHOT_DIR  optional; when set, the six documentation screenshots are written there
//   CHROME_PATH     optional; explicit Chrome/Chromium executable. Without it the
//                   installed Google Chrome is used (playwright-core "chrome" channel).
//
// Prints a JSON report and exits 1 when any expectation fails. Screenshots
// mask the navigation bar (user name) and the gateway base URL (local host/port).
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";

for (const name of ["APEX_USER", "APEX_PASSWORD", "APP_ID"]) {
  if (!process.env[name]) {
    console.error(`${name} is not set -- see the header of this script.`);
    process.exit(2);
  }
}
const appId = process.env.APP_ID;
const baseUrl = (process.env.APEX_BASE_URL || "http://localhost:8080/ords").replace(/\/+$/, "");
const shotDir = process.env.SCREENSHOT_DIR || "";
const browser = await chromium.launch(
  process.env.CHROME_PATH
    ? { executablePath: process.env.CHROME_PATH, headless: true }
    : { channel: "chrome", headless: true }
);
const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
const consoleErrors = [];
page.on("console", (message) => { if (message.type() === "error") consoleErrors.push(message.text()); });
page.on("pageerror", (error) => consoleErrors.push(error.message));

const failures = [];
const expect = (condition, label) => { if (!condition) failures.push(label); };
const itemValue = (name) => page.evaluate((itemName) => window.apex.item(itemName).getValue(), name);
const textOf = (selector) => page.locator(selector).first().innerText();

async function shot(name) {
  if (!shotDir) return;
  fs.mkdirSync(shotDir, { recursive: true });
  // Full-page capture with the sticky header at the top, not mid-page.
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(400);
  await page.screenshot({
    path: path.join(shotDir, `${name}.png`),
    fullPage: true,
    mask: [page.locator(".t-NavigationBar"), page.locator("#air-gateway-base")],
    maskColor: "#cbd5e1",
  });
}

async function navigate(aliasFragment, readySelector) {
  await page.locator(`a[href*="/${aliasFragment}?"]`).first().evaluate((link) => link.click());
  await page.waitForURL(new RegExp(aliasFragment));
  await page.locator(readySelector).first().waitFor({ timeout: 60000 });
}

// -- Login -------------------------------------------------------------------
await page.goto(`${baseUrl}/f?p=${appId}:1`, { waitUntil: "networkidle" });
await page.locator("#P9999_USERNAME").fill(process.env.APEX_USER);
await page.locator("#P9999_PASSWORD").fill(process.env.APEX_PASSWORD);
await page.getByRole("button", { name: "Sign In" }).click();
await page.waitForURL(/playground/);
await page.locator("#P1_PROMPT").waitFor();

// -- Page 1: Playground ------------------------------------------------------
async function send(expectedFragment) {
  await page.evaluate(() => window.apex.item("P1_RESULT").setValue(""));
  await page.locator("#P1_SEND").click();
  await page.waitForFunction(
    (fragment) => document.querySelector("#P1_RESULT")?.value.includes(fragment),
    expectedFragment,
    { timeout: 60000 }
  );
  return {
    prompt: await itemValue("P1_PROMPT"),
    routeItem: await itemValue("P1_ROUTE"),
    result: await page.locator("#P1_RESULT").inputValue(),
    error: await itemValue("P1_ERROR"),
    route: await textOf("#air-flow-route"),
    target: await textOf("#air-flow-target"),
    upstream: await textOf("#air-flow-upstream"),
    tier: await textOf("#air-d-tier"),
    latency: await textOf("#air-d-latency"),
    tokens: await textOf("#air-d-tokens"),
    cost: await textOf("#air-d-cost"),
    requestId: await textOf("#air-d-request"),
    decisionVisible: await page.locator("#air-decision").isVisible(),
  };
}

await page.locator("#P1_EXAMPLE_SHORT").click();
const autoShort = await send("mock:");
expect(autoShort.routeItem === "AUTO", "short example sets route AUTO");
expect(autoShort.route === "apex-auto" && autoShort.target === "switchyard", "short example goes through switchyard");
expect(autoShort.tier === "efficient" && autoShort.result.includes("mock:efficient"), "short prompt answered by the efficient tier");
expect(autoShort.decisionVisible && autoShort.requestId !== "n/a", "decision card filled with a request id");
await shot("01-playground-auto-efficient");

await page.locator("#P1_EXAMPLE_LONG").click();
const autoLong = await send("mock:");
expect(autoLong.target === "switchyard", "long example goes through switchyard");
expect(autoLong.tier === "capable" && autoLong.result.includes("mock:capable"), "long prompt answered by the capable tier");
await shot("02-playground-auto-capable");

await page.locator("#P1_PROMPT").fill("browser playground validation");
await page.locator("#P1_ROUTE").selectOption("EFFICIENT");
const fixed = await send("mock:");
expect(fixed.route === "apex-efficient" && fixed.target === "efficient" && fixed.tier === "efficient", "fixed efficient route bypasses the classifier");

// Plug-in Dynamic Action buttons (reusable plug-in, three prompt sources).
await page.evaluate(() => {
  window.__airQa = { spinnerCount: 0, successCount: 0, errorCount: 0 };
  const originalShowSpinner = window.apex.util.showSpinner;
  window.apex.util.showSpinner = function (...args) {
    window.__airQa.spinnerCount += 1;
    return originalShowSpinner.apply(this, args);
  };
  window.apex.jQuery("#P1_PLUGIN_STATIC,#P1_PLUGIN_ITEM,#P1_PLUGIN_JS").on("apexairouter:success", () => { window.__airQa.successCount += 1; });
  window.apex.jQuery("#P1_PLUGIN_STATIC,#P1_PLUGIN_ITEM,#P1_PLUGIN_JS").on("apexairouter:error", () => { window.__airQa.errorCount += 1; });
});
const qa = () => page.evaluate(() => window.__airQa);
async function pluginClick(buttonId, expectedFragment) {
  await page.evaluate(() => window.apex.item("P1_RESULT").setValue(""));
  await page.locator(`#${buttonId}`).click();
  await page.waitForFunction(
    (fragment) => document.querySelector("#P1_RESULT")?.value.includes(fragment),
    expectedFragment,
    { timeout: 60000 }
  );
  return { result: await page.locator("#P1_RESULT").inputValue(), error: await itemValue("P1_ERROR"), ...(await qa()) };
}
const pluginItem = await pluginClick("P1_PLUGIN_ITEM", "mock:efficient");
const spinnerAfterItem = pluginItem.spinnerCount;
const pluginJs = await pluginClick("P1_PLUGIN_JS", "mock:capable");
const spinnerAfterJs = pluginJs.spinnerCount;
const pluginStatic = await pluginClick("P1_PLUGIN_STATIC", "mock:");
const spinnerAfterStatic = pluginStatic.spinnerCount;
expect(spinnerAfterItem >= 1, "plug-in Item source shows a spinner (attribute_07 = Y)");
expect(spinnerAfterJs === spinnerAfterItem, "plug-in JS source shows no spinner (attribute_07 = N)");
expect(spinnerAfterStatic === spinnerAfterJs + 1, "plug-in Static source shows a spinner (attribute_07 = Y)");
expect(pluginStatic.successCount === 3 && pluginStatic.errorCount === 0, "all three plug-in sources succeed");
expect(pluginStatic.result.includes("mock:efficient"), "static Auto prompt (3 words) answered by the efficient tier");
await shot("03-playground-plugin-checks");

// -- Page 2: Dashboard -------------------------------------------------------
await navigate("dashboard", ".air-tiles");
await page.waitForFunction(() => document.querySelectorAll(".oj-chart svg").length >= 4, null, { timeout: 60000 });
const dashboard = {
  health: await textOf("#air-health"),
  ready: await textOf("#air-ready"),
  tiles: await page.locator(".air-tile").evaluateAll((nodes) => nodes.map((node) => ({
    label: node.querySelector(".air-tile-label")?.textContent.trim(),
    value: node.querySelector(".air-tile-value")?.textContent.trim(),
  }))),
  charts: await page.locator(".oj-chart").count(),
  chartSvgs: await page.locator(".oj-chart svg").count(),
  backendRows: await page.locator(".air-backends tbody tr, #air-backends tbody tr").count(),
  errors: await page.locator(".air-error").allInnerTexts(),
};
expect(dashboard.health === "ok" && dashboard.ready === "ready", "dashboard health/readiness pills");
expect(dashboard.tiles.length >= 6 && dashboard.tiles.every((tile) => tile.value && tile.value !== "n/a"), "KPI tiles populated");
expect(dashboard.charts === 4 && dashboard.chartSvgs >= 4, "four native JET charts rendered");
expect(dashboard.errors.length === 0, "no gateway errors on the dashboard");
await shot("04-dashboard");

// -- Page 3: Request History -------------------------------------------------
await navigate("request-history", ".a-IRR-table");
const history = {
  rows: await page.locator(".a-IRR-table tr:has(td)").count(),
  badges: await page.locator(".a-IRR-table .air-badge").count(),
  efficientBadges: await page.locator(".a-IRR-table .air-badge--efficient").count(),
  capableBadges: await page.locator(".a-IRR-table .air-badge--capable").count(),
  headers: await page.locator(".a-IRR-table .a-IRR-header").allInnerTexts(),
  errors: await page.locator(".air-error").allInnerTexts(),
};
expect(history.rows > 0 && history.badges === history.rows, "every history row carries a backend badge");
expect(history.efficientBadges > 0 && history.capableBadges > 0, "history shows both tiers");
expect(history.errors.length === 0, "no gateway errors on request history");
await shot("05-request-history");

// -- Page 4: Configuration Help ----------------------------------------------
await navigate("configuration-help", "#air-routes");
await page.waitForFunction(() => document.querySelectorAll("#air-routes tr").length >= 3, null, { timeout: 60000 });
const config = {
  gatewayBase: await textOf("#air-gateway-base"),
  health: await textOf("#air-health"),
  ready: await textOf("#air-ready"),
  routes: await page.locator("#air-routes tr").allInnerTexts(),
  targets: await page.locator("#air-targets tr").allInnerTexts(),
  error: await textOf("#air-config-error"),
  docLinks: await page.locator(".air-steps ~ p a, a[href*='live-validation-walkthrough']").count(),
};
expect(config.health === "ok" && config.ready === "ready", "config page health/readiness");
expect(config.routes.some((row) => row.includes("apex-auto") && row.includes("llm_classifier")), "apex-auto shows llm_classifier");
expect(config.targets.some((row) => row.includes("switchyard")), "switchyard target listed");
expect(config.error === "", "no config error");
await shot("06-configuration-help");

await browser.close();

const report = {
  appId,
  playground: { autoShort, autoLong, fixed },
  plugin: { spinnerAfterItem, spinnerAfterJs, spinnerAfterStatic, successCount: pluginStatic.successCount, errorCount: pluginStatic.errorCount },
  dashboard,
  history: { ...history, headers: history.headers.slice(0, 20) },
  config: { ...config, gatewayBase: config.gatewayBase ? "<masked>" : "" },
  consoleErrors,
  failures,
};
console.log(JSON.stringify(report, null, 2));
process.exit(failures.length === 0 ? 0 : 1);
