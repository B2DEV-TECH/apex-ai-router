# Example usage

Once the plug-in is installed (see `apex-plugin/README.md`), using it
requires no JavaScript from the application developer -- spec section 19's
explicit requirement for "no JavaScript code required for basic usage."

## Example 1 -- static prompt, auto routing

A button `P10_SEND` with a Dynamic Action:

```text
Event:  Click
Action: APEX AI Router - Generate

Prompt Source Type:   Page Item
Prompt Source Value:  P10_PROMPT
Route:                Auto
Result Page Item:     P10_RESULT
Show Processing Indicator: Yes
Error Page Item:      P10_ERROR
```

Also set the Dynamic Action's own **Page Items to Submit** to `P10_PROMPT`
(and `P10_SESSION_ID` / any item your JS Expression reads, if used) so the
current, unsaved value reaches the page's session state that the ajax
callback runs in -- standard APEX behavior, not specific to this plug-in.

## Example 2 -- capable route with a session id for gateway telemetry

```text
Event:  Click
Action: APEX AI Router - Generate

Prompt Source Type:   Page Item
Prompt Source Value:  P20_QUESTION
Route:                Capable
Result Page Item:     P20_ANSWER
Session ID Page Item: P20_CHAT_SESSION_ID
Temperature:          0.2
```

`P20_CHAT_SESSION_ID` is any page item your application already uses to
identify a conversation -- it is written to `AIR_REQUEST_LOG.session_id`
(see `database/README.md`) instead of the ambient APEX session id, so
usage across a multi-page or multi-tab conversation can be correlated by
your own identifier.

## Reacting to success/error declaratively

Add a second Dynamic Action on the same triggering element:

```text
Event:  apexairouter:success   (Custom Event)
Action: (whatever the app needs -- e.g. Show P10_RESULT)
```

```text
Event:  apexairouter:error     (Custom Event)
Action: (e.g. Show P10_ERROR, or a Notification with &P10_ERROR.)
```

matching spec section 19's "include: success event, error event."
