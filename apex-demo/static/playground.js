/*
 * apex-demo Page 1 -- Playground client script.
 *
 * Calls the page's own On-Demand: Ajax Callback process, "PLAYGROUND_RUN"
 * (PL/SQL Code: apex_ai_router_demo.ajax_run;), which internally makes the
 * gateway calls described in apex-demo/sql/demo_playground_pkg.pks. The
 * browser never talks to the gateway or holds any gateway credential.
 *
 * Attach as a page-level "File URL" (static application file). The page's
 * buttons call:
 *   apexDemoPlayground.run()              -- Send
 *   apexDemoPlayground.example('short')   -- fill a short prompt, route Auto
 *   apexDemoPlayground.example('long')    -- fill a long prompt, route Auto
 * See apex-demo/pages/01-playground.md.
 *
 * The "Routing decision" card is filled only from what the gateway
 * telemetry reports for this request id (selected target, upstream_model,
 * tokens, cost). Nothing about the routing outcome is inferred client-side.
 */
(function (apex, apexDemoPlayground) {
    "use strict";

    var $ = apex.jQuery;

    // Example prompts for the Auto route. With the repository's mock judge
    // the verdict is a word-count heuristic (<= 40 words -> "supported" ->
    // efficient backend); with a real judge model it is a content
    // decision. Either way these are ordinary prompts, not magic strings.
    var EXAMPLES = {
        short: "What is 2+2?",
        long: "Compare three strategies for migrating a legacy Oracle Forms order-entry module to Oracle APEX: " +
              "a page-by-page rewrite, a hybrid approach that keeps the PL/SQL business logic in packages and " +
              "rebuilds only the UI, and a full re-platforming with new data models. For each strategy, discuss " +
              "risk, delivery time, testing effort and the impact on end users, then recommend one."
    };

    var ROUTE_NAMES = { AUTO: "apex-auto", EFFICIENT: "apex-efficient", CAPABLE: "apex-capable" };

    // pData's numeric fields (estimated_cost, etc.) may be null when the
    // /admin/requests lookup didn't find a matching row yet (telemetry
    // write lag, or ADMIN_CREDENTIAL_STATIC_ID not configured) -- render
    // "n/a", never 0, per apex_ai_router_demo.pkb's own contract.
    function isMissing(value) {
        return value === null || value === undefined || value === "";
    }
    function text(value) {
        return isMissing(value) ? "n/a" : String(value);
    }
    function usd(value) {
        return isMissing(value) ? "n/a" : "$" + Number(value).toFixed(6);
    }
    function setText(id, value) {
        $("#" + id).text(value);
    }

    function resetDecision() {
        $("#air-decision").hide();
        $("#air-decision-empty").show();
        $("#air-flow-upstream").closest(".air-node").removeClass("air-node--efficient air-node--capable");
    }

    function showDecision(pData) {
        var route = ROUTE_NAMES[apex.item("P1_ROUTE").getValue()] || "n/a";
        var tier = pData.answered_tier || null;
        var note;

        setText("air-flow-route", route);
        setText("air-flow-target", text(pData.selected_tier));
        setText("air-flow-upstream", text(pData.upstream_model));
        $("#air-flow-upstream").closest(".air-node")
            .removeClass("air-node--efficient air-node--capable")
            .addClass(tier ? "air-node--" + tier : "");
        setText("air-d-tier", tier || "unknown");
        setText("air-d-latency", isMissing(pData.latency_ms) ? "n/a" : Math.round(Number(pData.latency_ms)) + " ms");
        setText("air-d-tokens", text(pData.input_tokens) + " / " + text(pData.output_tokens));
        setText("air-d-cost", usd(pData.estimated_cost));
        setText("air-d-baseline", usd(pData.estimated_baseline_cost));
        setText("air-d-savings", usd(pData.estimated_savings));
        setText("air-d-request", text(pData.request_id));

        if (route === "apex-auto") {
            note = tier
                ? "The NVIDIA NeMo Switchyard sidecar (llm_classifier policy) judged this prompt and forwarded it to the " +
                  tier + " backend. The backend id above is what the gateway telemetry recorded for this request id."
                : "The gateway did not record which backend answered this request.";
        } else {
            note = "Fixed route: the gateway sent this prompt straight to its " + (tier || "configured") +
                   " target; the classifier is not involved.";
        }
        setText("air-decision-note", note);
        $("#air-decision-empty").hide();
        $("#air-decision").show();
    }

    apexDemoPlayground.example = function (kind) {
        apex.item("P1_PROMPT").setValue(EXAMPLES[kind] || "");
        apex.item("P1_ROUTE").setValue("AUTO");
        apex.item("P1_PROMPT").setFocus();
    };

    apexDemoPlayground.run = function () {
        var spinner = apex.util.showSpinner($("#P1_SEND"));

        apex.server.process(
            "PLAYGROUND_RUN",
            {
                x01: apex.item("P1_PROMPT").getValue(),
                x02: apex.item("P1_ROUTE").getValue()
            },
            {
                dataType: "json",
                success: function (pData) {
                    spinner.remove();
                    if (pData && pData.success) {
                        apex.item("P1_RESULT").setValue(pData.result);
                        apex.item("P1_ERROR").setValue("");
                        showDecision(pData);
                    } else {
                        apex.item("P1_RESULT").setValue("");
                        resetDecision();
                        apex.item("P1_ERROR").setValue((pData && pData.error) || "Unknown error.");
                    }
                },
                error: function (jqXHR, textStatus) {
                    spinner.remove();
                    apex.item("P1_RESULT").setValue("");
                    resetDecision();
                    apex.item("P1_ERROR").setValue("Playground request failed (" + textStatus + ").");
                }
            }
        );
    };
})(apex, (window.apexDemoPlayground = window.apexDemoPlayground || {}));
