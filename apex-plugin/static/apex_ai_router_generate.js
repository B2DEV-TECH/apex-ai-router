/*
 * APEX AI Router - Generate -- Dynamic Action plug-in client script.
 *
 * Registered as the plug-in's "File URL" / JavaScript File attribute and
 * invoked by APEX's Dynamic Action framework via the render function's
 * javascript_function ("apexAiRouter.generate"), see
 * apex-plugin/src/apex_ai_router_da.pkb.
 *
 * This file only ever talks to APEX's own Ajax Callback (apex.server.plugin)
 * -- never to a model provider directly, per spec section 18.
 *
 * APEX invokes a Dynamic Action JavaScript function with its action context
 * as `this`. Accepting an explicit argument as well keeps the function easy
 * to exercise in isolation and compatible with direct integrations.
 */
(function (apex, apexAiRouter) {
    "use strict";

    // attribute_01: Prompt Source Type -- STATIC | ITEM | JS_EXPRESSION
    // attribute_02: Prompt Source Value -- literal text | item name | JS expression body
    function resolvePrompt(pThis) {
        var type = pThis.action.attribute01;
        var value = pThis.action.attribute02;

        if (type === "ITEM") {
            return apex.item(value).getValue();
        }
        if (type === "JS_EXPRESSION") {
            // Evaluated in an isolated function scope, never string-eval'd
            // into the global scope. The developer configuring this
            // attribute is trusted app-builder input, the same trust level
            // APEX itself grants "Execute JavaScript Code" Dynamic Actions.
            /* eslint-disable no-new-func */
            return new Function(
                "return (" + value + ");"
            ).call(pThis.triggeringElement);
            /* eslint-enable no-new-func */
        }
        // STATIC (default): the literal attribute value itself.
        return value;
    }

    apexAiRouter.generate = function (pContext) {
        var pThis = pContext && pContext.action ? pContext : this;
        var resultItem = pThis.action.attribute04;
        var errorItem = pThis.action.attribute08;
        var showSpinner = pThis.action.attribute07 === "Y";
        var sessionIdItem = pThis.action.attribute06;

        var prompt = resolvePrompt(pThis);
        var route = pThis.action.attribute03 || "AUTO";
        var temperature = pThis.action.attribute05 || "";
        var sessionId = sessionIdItem ? apex.item(sessionIdItem).getValue() : "";

        var spinner = null;
        if (showSpinner) {
            spinner = apex.util.showSpinner(pThis.triggeringElement);
        }

        function cleanup() {
            if (spinner) {
                spinner.remove();
                spinner = null;
            }
        }

        apex.server.plugin(
            pThis.action.ajaxIdentifier,
            {
                x01: prompt,
                x02: route,
                x03: String(temperature),
                x04: sessionId
            },
            {
                dataType: "json",
                success: function (pData) {
                    cleanup();
                    if (pData && pData.success) {
                        if (resultItem) {
                            apex.item(resultItem).setValue(pData.result);
                        }
                        if (errorItem) {
                            apex.item(errorItem).setValue("");
                        }
                        apex.event.trigger(
                            pThis.triggeringElement,
                            "apexairouter:success",
                            pData
                        );
                    } else {
                        if (errorItem) {
                            apex.item(errorItem).setValue(pData && pData.error);
                        }
                        apex.event.trigger(
                            pThis.triggeringElement,
                            "apexairouter:error",
                            pData
                        );
                    }
                },
                error: function (jqXHR, textStatus) {
                    cleanup();
                    var message = "APEX AI Router request failed (" + textStatus + ").";
                    if (errorItem) {
                        apex.item(errorItem).setValue(message);
                    }
                    apex.event.trigger(
                        pThis.triggeringElement,
                        "apexairouter:error",
                        { success: false, error: message }
                    );
                }
            }
        );
    };
})(apex, (window.apexAiRouter = window.apexAiRouter || {}));
