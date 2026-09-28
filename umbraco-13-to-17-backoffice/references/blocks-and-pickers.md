# Blocks and labels

## 1. BlockPreview off on BlockList

In v13, BlockPreview was often enabled for both BlockGrid and BlockList. In v17, **BlockPreview
must be disabled for BlockList** — the v17 backoffice BlockList editor has its own preview
behaviour that fights with BlockPreview, causing double-render or stuck-preview artifacts.

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

## 2. Backoffice info partials on all blocks

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

The nested-section rendering fix in `SectionContent.cshtml` is a frontend change — see
`umbraco-13-to-17-frontend` → `references/views-and-csp.md`.
