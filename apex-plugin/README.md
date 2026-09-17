# apex-plugin

Optional APEX Dynamic Action plug-in, "APEX AI Router - Generate". Not
implemented yet — planned for Phase 6.

The plug-in is optional by design: the gateway's OpenAI-compatible API works
today with a native `APEX_AI` Generative AI Service pointed directly at it.
The plug-in adds low-code UX (route controls, page-item binding, optional
metrics display) on top of that, not a second way to reach a model provider.
The browser will never call an upstream model provider directly — only a
server-side APEX Ajax callback that in turn calls the gateway.

Distributable plugin SQL will be generated into `dist/` once built.
