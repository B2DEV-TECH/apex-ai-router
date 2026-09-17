/*
 * apex-demo Page 1 -- Playground client script.
 *
 * Calls the page's own On-Demand: Ajax Callback process, "PLAYGROUND_RUN"
 * (PL/SQL Code: apex_ai_router_demo.ajax_run;), which internally makes the
 * gateway calls described in apex-demo/sql/demo_playground_pkg.pks. The
 * browser never talks to the gateway or holds any gateway credential.
 *
 * Attach as a page-level "File URL" (static application file) and wire the
 * Send button to it, e.g. a Dynamic Action:
 *   Event: Click, Selector: #P1_SEND
 *   Action: Execute JavaScript Code: apexDemoPlayground.run();
 * or call apexDemoPlayground.run() directly from a button's "Execute
 * JavaScript Code" action -- see apex-demo/pages/01-playground.md.
 */
(function (apex, apexDemoPlayground) {
    "use strict";

    var FIELDS = [
        "P1_SELECTED_TIER",
        "P1_SELECTED_MODEL",
        "P1_LATENCY_MS",
        "P1_INPUT_TOKENS",
        "P1_OUTPUT_TOKENS",
        "P1_ESTIMATED_COST",
        "P1_ESTIMATED_BASELINE_COST",
        "P1_ESTIMATED_SAVINGS",
        "P1_REQUEST_ID"
    ];

    function clearResultItems() {
        apex.item("P1_RESULT").setValue("");
        apex.item("P1_ERROR").setValue("");
        FIELDS.forEach(function (itemName) {
            apex.item(itemName).setValue("");
        });
    }

    // pData's numeric fields (estimated_cost, etc.) may be null when the
    // /admin/requests lookup didn't find a matching row yet (telemetry
    // write lag, or ADMIN_CREDENTIAL_STATIC_ID not configured) -- render
    // "n/a", never 0, per apex_ai_router_demo.pkb's own contract.
    function displayValue(value) {
        return (value === null || value === undefined || value === "") ? "n/a" : value;
    }

    apexDemoPlayground.run = function () {
        var spinner = apex.util.showSpinner(apex.jQuery("#P1_SEND"));

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
                        apex.item("P1_SELECTED_TIER").setValue(displayValue(pData.selected_tier));
                        apex.item("P1_SELECTED_MODEL").setValue(displayValue(pData.selected_model));
                        apex.item("P1_LATENCY_MS").setValue(displayValue(pData.latency_ms));
                        apex.item("P1_INPUT_TOKENS").setValue(displayValue(pData.input_tokens));
                        apex.item("P1_OUTPUT_TOKENS").setValue(displayValue(pData.output_tokens));
                        apex.item("P1_ESTIMATED_COST").setValue(displayValue(pData.estimated_cost));
                        apex.item("P1_ESTIMATED_BASELINE_COST").setValue(displayValue(pData.estimated_baseline_cost));
                        apex.item("P1_ESTIMATED_SAVINGS").setValue(displayValue(pData.estimated_savings));
                        apex.item("P1_REQUEST_ID").setValue(displayValue(pData.request_id));
                    } else {
                        clearResultItems();
                        apex.item("P1_ERROR").setValue((pData && pData.error) || "Unknown error.");
                    }
                },
                error: function (jqXHR, textStatus) {
                    spinner.remove();
                    clearResultItems();
                    apex.item("P1_ERROR").setValue("Playground request failed (" + textStatus + ").");
                }
            }
        );
    };
})(apex, (window.apexDemoPlayground = window.apexDemoPlayground || {}));
