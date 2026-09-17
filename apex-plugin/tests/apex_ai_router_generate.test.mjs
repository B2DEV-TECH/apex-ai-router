// Regression tests for apex-plugin/static/apex_ai_router_generate.js.
//
// The plug-in script only depends on four pieces of the APEX JavaScript API
// (apex.item, apex.server.plugin, apex.util.showSpinner, apex.event.trigger),
// so it is loaded into an isolated vm context with small fakes for them and
// exercised exactly the way APEX's Dynamic Action framework calls it: with
// the action context as `this` and no arguments.
//
//   node --test "apex-plugin/tests/*.test.mjs"
//
// Node's built-in test runner is enough; there is no package.json or
// third-party dependency to install.
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const source = fs.readFileSync(path.join(here, "..", "static", "apex_ai_router_generate.js"), "utf8");

// Loads a fresh copy of the plug-in script with recording fakes for the APEX API.
function loadPlugin() {
    const calls = { plugin: [], spinners: [], events: [] };
    const items = new Map();
    const apex = {
        item(name) {
            if (!items.has(name)) {
                items.set(name, { value: "" });
            }
            const entry = items.get(name);
            return {
                getValue: () => entry.value,
                setValue: (value) => { entry.value = value; }
            };
        },
        server: {
            plugin(ajaxIdentifier, data, options) {
                calls.plugin.push({ ajaxIdentifier, data, options });
            }
        },
        util: {
            showSpinner(target) {
                const spinner = { target, removed: 0, remove() { this.removed += 1; } };
                calls.spinners.push(spinner);
                return spinner;
            }
        },
        event: {
            trigger(element, name, data) {
                calls.events.push({ element, name, data });
            }
        }
    };
    const window = {};
    vm.runInContext(source, vm.createContext({ apex, window }), { filename: "apex_ai_router_generate.js" });
    return { generate: window.apexAiRouter.generate, apex, calls, items };
}

// The eight plug-in attributes as APEX hands them to the action handler.
function action(overrides = {}) {
    return {
        ajaxIdentifier: "AJAX-IDENTIFIER-123",
        attribute01: "STATIC",              // Prompt Source Type
        attribute02: "Summarise this page", // Prompt Source Value
        attribute03: "EFFICIENT",           // Route
        attribute04: "P1_RESULT",           // Result Page Item
        attribute05: "0.2",                 // Temperature
        attribute06: "",                    // Session Id Item
        attribute07: "Y",                   // Show Processing Indicator
        attribute08: "P1_ERROR",            // Error Page Item
        ...overrides
    };
}

function lastPluginCall(calls) {
    assert.equal(calls.plugin.length, 1, "exactly one apex.server.plugin call");
    return calls.plugin[0];
}

// Objects the plug-in builds live in the vm realm, whose Object.prototype is
// not this file's, and strict deep equality compares prototypes. A JSON round
// trip strips the realm so the values can be compared as plain data.
const plain = (value) => JSON.parse(JSON.stringify(value));

test("runs with the native Dynamic Action context passed as `this` and no arguments", () => {
    const { generate, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };

    generate.call({ action: action(), triggeringElement });

    const call = lastPluginCall(calls);
    assert.equal(call.ajaxIdentifier, "AJAX-IDENTIFIER-123", "Ajax identifier forwarded verbatim");
    assert.deepEqual(plain(call.data), { x01: "Summarise this page", x02: "EFFICIENT", x03: "0.2", x04: "" });
    assert.equal(call.options.dataType, "json");
});

test("also accepts the context as an explicit argument (direct integrations)", () => {
    const { generate, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };

    generate({ action: action({ attribute02: "explicit" }), triggeringElement });

    assert.equal(lastPluginCall(calls).data.x01, "explicit");
});

test("reads an ITEM prompt source and the session id item from the page", () => {
    const { generate, apex, calls } = loadPlugin();
    apex.item("P1_PROMPT").setValue("prompt typed by the user");
    apex.item("P1_SESSION").setValue("session-42");

    generate.call({
        action: action({ attribute01: "ITEM", attribute02: "P1_PROMPT", attribute06: "P1_SESSION" }),
        triggeringElement: {}
    });

    const { data } = lastPluginCall(calls);
    assert.equal(data.x01, "prompt typed by the user");
    assert.equal(data.x04, "session-42");
});

test("evaluates a JS_EXPRESSION prompt source with the triggering element as `this`", () => {
    const { generate, calls } = loadPlugin();
    const triggeringElement = { dataset: { topic: "Oracle APEX" } };

    generate.call({
        action: action({ attribute01: "JS_EXPRESSION", attribute02: "'Write one line about ' + this.dataset.topic" }),
        triggeringElement
    });

    assert.equal(lastPluginCall(calls).data.x01, "Write one line about Oracle APEX");
});

test("defaults the route to AUTO and sends the temperature as a string", () => {
    const { generate, calls } = loadPlugin();

    generate.call({ action: action({ attribute03: "", attribute05: undefined }), triggeringElement: {} });

    const { data } = lastPluginCall(calls);
    assert.equal(data.x02, "AUTO");
    assert.equal(data.x03, "");
    assert.equal(typeof data.x03, "string");
});

test("shows the processing indicator on the triggering element only when attribute_07 is Y", () => {
    const on = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };
    on.generate.call({ action: action({ attribute07: "Y" }), triggeringElement });
    assert.equal(on.calls.spinners.length, 1);
    assert.equal(on.calls.spinners[0].target, triggeringElement);
    assert.equal(on.calls.spinners[0].removed, 0, "spinner stays until the callback answers");

    const off = loadPlugin();
    off.generate.call({ action: action({ attribute07: "N" }), triggeringElement });
    assert.equal(off.calls.spinners.length, 0);
});

test("success: fills the result item, clears the error item, removes the spinner, fires apexairouter:success", () => {
    const { generate, apex, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };
    apex.item("P1_ERROR").setValue("stale error from a previous call");

    generate.call({ action: action(), triggeringElement });
    const pData = { success: true, result: "[mock:efficient:mock-efficient-v1] response to: success" };
    lastPluginCall(calls).options.success(pData);

    assert.equal(apex.item("P1_RESULT").getValue(), pData.result);
    assert.equal(apex.item("P1_ERROR").getValue(), "");
    assert.equal(calls.spinners[0].removed, 1);
    assert.deepEqual(plain(calls.events), [{ element: triggeringElement, name: "apexairouter:success", data: pData }]);
});

test("application error (success:false): fills the error item, keeps the result, fires apexairouter:error", () => {
    const { generate, apex, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };
    apex.item("P1_RESULT").setValue("previous answer");

    generate.call({ action: action(), triggeringElement });
    const pData = { success: false, error: "Gateway returned HTTP 503 (provider_unavailable)." };
    lastPluginCall(calls).options.success(pData);

    assert.equal(apex.item("P1_ERROR").getValue(), pData.error);
    assert.equal(apex.item("P1_RESULT").getValue(), "previous answer", "result item is not overwritten on failure");
    assert.equal(calls.spinners[0].removed, 1);
    assert.deepEqual(plain(calls.events), [{ element: triggeringElement, name: "apexairouter:error", data: pData }]);
});

test("transport error: readable message in the error item, spinner removed, apexairouter:error fired", () => {
    const { generate, apex, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };

    generate.call({ action: action(), triggeringElement });
    lastPluginCall(calls).options.error({ status: 0 }, "timeout");

    const message = "APEX AI Router request failed (timeout).";
    assert.equal(apex.item("P1_ERROR").getValue(), message);
    assert.equal(calls.spinners[0].removed, 1);
    assert.deepEqual(plain(calls.events), [{ element: triggeringElement, name: "apexairouter:error", data: { success: false, error: message } }]);
});

test("works with no result or error item configured (events only)", () => {
    const { generate, items, calls } = loadPlugin();
    const triggeringElement = { id: "P1_SEND" };

    generate.call({ action: action({ attribute04: "", attribute08: "" }), triggeringElement });
    lastPluginCall(calls).options.success({ success: true, result: "answer" });
    calls.plugin[0].options.error({}, "error");

    assert.equal(items.has(""), false, "apex.item is never called with an empty item name");
    assert.deepEqual(calls.events.map((event) => event.name), ["apexairouter:success", "apexairouter:error"]);
});
