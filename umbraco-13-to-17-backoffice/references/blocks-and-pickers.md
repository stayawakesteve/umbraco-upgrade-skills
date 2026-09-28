# Blocks, labels, CSP

The miscellaneous backoffice fixes that don't fit cleanly into "SCSS" or "RTE config". Mostly
small, all easy to miss.

## 1. BlockPreview off on BlockList

In v13, BlockPreview was often enabled for both BlockGrid and BlockList. In v17, **BlockPreview
must be disabled for BlockList** — the v17 backoffice BlockList editor has its own preview
behaviour that fights with BlockPreview, causing rendering artifacts.

In `appsettings.json`:

```json
"BlockPreview": {
  "BlockGrid": {
    "Enabled": true,
    "Stylesheet": "/css/blockpreview.css",
    "ViewLocations": ["~/Views/Partials/blockgrid/Components/{0}.cshtml"]
  },
  "BlockList": {
    "Enabled": false
  }
}
```

If you're seeing weird "double render" or "stuck preview" behaviour in the BlockList editor in v17,
this config is the first thing to check.

## 2. Block labels in UFM (Umbraco Flavored Markdown)

v17 introduced UFM as the syntax for block labels. v13 typically used AngularJS template syntax
like `{{ someProperty }}`.

For every Block List and Block Grid data type:

1. Open the data type
2. For each block in the config, find the "Label" field
3. Migrate AngularJS-style templates to UFM

Example:

**v13 (AngularJS):**
```
{{ heading }}
```

**v17 (UFM):**
```
{$heading}
```

Property paths use UFM dot notation, and you can call helper functions like `umbContentName`:

**v13:**
```
{{ value | ncNodeName }}
```

**v17:**
```
{umbContentName: value}
```

This is the same template transformation that needs doing in uSync content files (see
`umbraco-13-to-17-database` → `references/usync-workflow.md`). Doing the labels in the backoffice
UI is one way; mass-editing the uSync files is another. Both routes converge.

## 3. Backoffice info partials on all blocks

For older Etch.Cms sites where backoffice info partials were only applied to *some* block types
(typically just Section), v17 expects them on all blocks for consistency.

In each block component partial (e.g. `Views/Partials/blockgrid/Components/MyBlock.cshtml`):

```cshtml
@if (Context.Request.Path.StartsWithSegments("/umbraco"))
{
    <partial name="blockgrid/Components/BackofficeInfo" model="Model" />
}
```

You'll need to do this manually per block. Without it, blocks render in the backoffice without
the helpful "this is a Foo block, properties X Y Z" info that editors rely on.

## 4. YouTube backoffice CSP fix

Symptom: editors report YouTube embeds in the TipTap RTE failing in the backoffice with a CSP or
referrer error in the browser console.

The fix is in `Program.cs` — not in this skill, but listed here because the symptom is editor-facing.
See `umbraco-13-to-17-backend` → `references/program-cs-v17.md`, section "YouTube backoffice CSP
middleware".

Short version: add middleware that sets `Referrer-Policy: strict-origin-when-cross-origin` for any
request path starting with `/umbraco`. Without this override, the default tighter policy blocks the
YouTube embed's referrer-based auth.
