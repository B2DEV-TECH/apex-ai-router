# apex-plugin

An optional APEX Dynamic Action plug-in, **"APEX AI Router - Generate"**
(spec sections 18-19). Optional by design: the gateway's OpenAI-compatible
API already works today via a native `APEX_AI` Generative AI Service
pointed directly at it (`docs/apex-ai-setup.md`) or via the
`APEX_AI_ROUTER` PL/SQL package (`database/`) -- this plug-in adds
low-code UX (declarative route/temperature/result-item controls, no
JavaScript required for basic usage) on top of those, not a second way to
reach a model provider. The browser never calls an upstream AI provider
directly; it only calls this plug-in's own server-side Ajax callback,
which calls the gateway.

```text
Browser
  -> apex.server.plugin() [apex-plugin/static/apex_ai_router_generate.js]
  -> APEX Ajax Callback    [apex-plugin/src/apex_ai_router_da.pkb: ajax()]
  -> apex_ai_router.generate() [database/packages/apex_ai_router.pkb]
  -> gateway -> Switchyard -> model -> gateway
  -> Ajax Callback -> Browser (Result Page Item / Error Page Item)
```

> **Status:** the plug-in's real source (PL/SQL callbacks + client JS) is
> written and hand-verified against the documented, stable APEX plug-in
> framework (`APEX_PLUGIN` types, `apex.server.plugin`,
> `apex.util.showSpinner`). It has **not** been built or exported from a
> live APEX Builder in this repository -- no Oracle/APEX instance was
> available while building this project (same caveat as `database/`, see
> `HANDOFF.md`). This means `apex-plugin/dist/` has no machine-generated
> export SQL yet, and the exact client-side `pThis` object contract for a
> Dynamic Action plug-in's `javascript_function` (see
> `apex_ai_router_da.pkb`'s render() comment) should be confirmed against
> the APEX Plug-In Developer's Guide for your installed version before
> production use.

## Files

| Path | Purpose |
|---|---|
| `src/apex_ai_router_da.pks` / `.pkb` | The plug-in's render() and ajax() PL/SQL callbacks. Requires `database/` (specifically `apex_ai_router` package) already installed. |
| `static/apex_ai_router_generate.js` | Client-side action handler: resolves the prompt, calls the ajax callback, updates the Result/Error page items, fires `apexairouter:success` / `apexairouter:error` custom events. |
| `sql/install_plugin_package.sql` | Compiles `src/` in your schema. Run before creating the plug-in in Builder. |
| `examples/dynamic_action_example.md` | Declarative usage examples -- no PL/SQL or JS to write. |
| `dist/` | Where the real APEX Builder plug-in export SQL goes once built (empty for now -- see `dist/README.md`). |

## Building the plug-in in APEX Builder

Run `sql/install_plugin_package.sql` first, then in APEX Builder:

1. **Shared Components > Plug-ins > Create.**
2. Type: **Dynamic Action**. Name: `APEX AI Router - Generate` (Internal
   Name is up to you, e.g. `AIR.DYNAMIC_ACTION.GENERATE`).
3. **PL/SQL Code** (render function): reference `apex_ai_router_da.render`
   -- either set "PL/SQL Code" to call it, or, if your APEX version's
   Plug-in edit page has a direct "Render Function Name" field, point it
   at `apex_ai_router_da.render`. Verify which field your version exposes
   (this has varied across APEX releases; do not assume the field name
   below is exact).
4. **Ajax Callback Function**: `apex_ai_router_da.ajax`.
5. **File URLs**: add `static/apex_ai_router_generate.js` (upload it as a
   plug-in file, or reference it as a static application/workspace file --
   whichever your deployment convention prefers).
6. Add the attributes below exactly in this order (the PL/SQL callbacks
   reference them positionally as `attribute_01`..`attribute_08`):

   | # | Label | Type | Required | Notes |
   |---|---|---|---|---|
   | 01 | Prompt Source Type | Select List: Static Text=`STATIC`, Page Item=`ITEM`, JavaScript Expression=`JS_EXPRESSION` | Yes | |
   | 02 | Prompt Source Value | Text | Yes | Literal text, a page item name, or a JS expression body, depending on #01. |
   | 03 | Route | Select List: Auto=`AUTO`, Efficient=`EFFICIENT`, Capable=`CAPABLE` | Yes | Default `AUTO`. |
   | 04 | Result Page Item | Page Item | No | |
   | 05 | Temperature | Number | No | Forwarded to the gateway only when set. |
   | 06 | Session ID Page Item | Page Item | No | Written to `AIR_REQUEST_LOG.session_id` in place of the ambient APEX session. |
   | 07 | Show Processing Indicator | Checkbox (Y/N) | No | Default `Y`. |
   | 08 | Error Page Item | Page Item | No | |

7. **Standard Events**: none required -- the plug-in triggers plain custom
   jQuery events (`apexairouter:success`, `apexairouter:error`) that any
   other Dynamic Action can listen for via Event type "Custom", rather than
   registering them as first-class Plug-in Events. If your APEX version
   supports declaring Plug-in Events, adding one for each is a reasonable
   enhancement (see `HANDOFF.md`).
8. Save, then **Export** the plug-in (Shared Components > Plug-ins >
   select it > Export) and commit the resulting SQL file under
   `apex-plugin/dist/`.

## Using it (no JavaScript required)

See `examples/dynamic_action_example.md`. In short:

```text
Dynamic Action
  Event: Click
  Action: APEX AI Router - Generate

  Prompt Source Type: Page Item
  Prompt Source Value: P10_PROMPT
  Route: Auto
  Result Page Item: P10_RESULT
```

The plug-in does not persist prompts anywhere by itself (spec section 18)
-- if your application needs a prompt/response audit trail, add that
explicitly (e.g. a page process writing to your own table), separate from
this plug-in and separate from `AIR_REQUEST_LOG`, which never stores
content either (see `database/README.md`).

## Manual QA checklist

These mirror the "Plug-in tests" the spec calls out (section under Testing
Strategy) and require a live APEX Builder + workspace to execute -- none of
them have been run in this repository:

- [ ] **Import SQL generated**: exporting the plug-in from Builder produces
      a SQL file that imports cleanly into a second, empty workspace.
- [ ] **Server-side callback successful**: with a real gateway reachable
      and `AIR_CONFIG`/Web Credential configured, clicking a button wired
      to this Dynamic Action returns a result within the configured
      timeout.
- [ ] **Configured result item updated**: the Result Page Item's DOM value
      reflects the gateway's response after a successful call.
- [ ] **Controlled error behavior**: pointing `AIR_CONFIG.GATEWAY_BASE_URL`
      at an unreachable host, or using an unknown route, surfaces a clean
      `{"success":false,"error":"..."}` response (never a raw HTML error
      page or an uncaught JS exception), and the Error Page Item (if
      configured) is populated.
