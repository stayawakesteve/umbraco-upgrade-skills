---
name: umbraco-13-to-17-backoffice
description: |
  Migrates the editor-facing backoffice customisations of an Etch CMS site from Umbraco 13 to Umbraco 17.
  Use this skill for any RTE/TipTap, BlockPreview, block label, backoffice info, backoffice SCSS, or
  backoffice CSP work in a v13→v17 upgrade. Covers blockpreview.scss imports, backoffice info partials
  and SCSS colours, picker style migration, removing .umb-block-grid styles from editor.scss, RTE config
  (Word Count, toolbar, image sizing, Uploads folder), Link Picker prop for TipTap, BlockPreview disabled
  on BlockList, UFM block labels, and the YouTube backoffice CSP fix. Trigger on phrases like "v17 RTE
  config", "TipTap link picker", "BlockPreview broken on BlockList", "backoffice info partial",
  "backoffice info showing grey", "block labels showing raw {{ }} syntax", "block grid looks wrong in
  the editor", "YouTube embeds blocked in backoffice", or whenever a user mentions editor/backoffice
  symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Backoffice Migration

This skill covers the editor-facing side of the v17 upgrade: RTE config, block previews and labels,
backoffice info partials, backoffice SCSS, and the backoffice CSP fix. If an editor would notice it
and a site visitor wouldn't, it belongs here.

Other tracks are owned elsewhere:

- Views, tag helpers, dictionary values, Umbraco Forms, frontend CSP → `umbraco-13-to-17-frontend`
- `.csproj`, `Program.cs`, build errors → `umbraco-13-to-17-backend`
- uSync, content, data types → `umbraco-13-to-17-database`

## Order of operations

These are roughly independent, but doing them in this order minimises rework:

1. **Backoffice SCSS and partials** — `blockpreview.scss`, backoffice info partial on sections,
   backoffice info SCSS colours, picker styles, removing `.umb-block-grid` from `editor.scss`.
   See `references/scss-and-partials.md`.
2. **RTE config** — Word Count, toolbar layout, max image size, Uploads folder, Link Picker
   prop for TipTap. See `references/rte-config.md`.
3. **Blocks, labels, CSP** — BlockPreview off for BlockList, UFM block labels, backoffice info
   partials applied to all blocks, YouTube CSP fix. See `references/blocks-and-pickers.md`.

## The thing most people miss

**`.umb-block-grid` rules in `editor.scss` must be removed.** In v17 those styles ship inside the
Etch CMS Umbraco backoffice package (`App_Plugins/Etch.Cms.Umbraco/src/block-grid-shadow.css`).
Local rules left over from v13 conflict with the package's own and the block grid editor renders
incorrectly — which looks like a v17 bug rather than a leftover. See
`references/scss-and-partials.md`.

## BlockPreview must be off for BlockList

The v17 BlockList editor has its own preview behaviour that fights with BlockPreview, causing
double-render or stuck-preview artifacts. Keep BlockPreview enabled for BlockGrid only:

```json
"BlockPreview": {
  "BlockGrid": { "Enabled": true, "Stylesheet": "/css/blockpreview.css" },
  "BlockList": { "Enabled": false }
}
```

Full config in `references/blocks-and-pickers.md`.

## Block labels: AngularJS → UFM

Block labels moved from AngularJS templates to UFM (Umbraco Flavored Markdown):
`{{ heading }}` → `{$heading}`, `{{ value | ncNodeName }}` → `{umbContentName: value}`. It's the
same rewrite the database skill applies to uSync `nameTemplate` fields — for more than a handful of
blocks, mass-edit the uSync files instead of clicking through each data type. See
`references/blocks-and-pickers.md` and `umbraco-13-to-17-database` →
`references/nametemplate-rewrite.md`.

## YouTube backoffice CSP error

If editors report YouTube embeds failing in the backoffice TipTap RTE with a CSP/referrer error,
the fix is in `Program.cs` — see `umbraco-13-to-17-backend` → `references/program-cs-v17.md`,
section "YouTube backoffice CSP middleware". It needs adding to `Program.cs` to override the
Referrer-Policy header for `/umbraco` routes.

## Reference files

- `references/scss-and-partials.md` — blockpreview.scss, section partials, backoffice info SCSS,
  picker style migration, `.umb-block-grid` removal, `.stylelintcache`
- `references/rte-config.md` — RTE/TipTap Word Count, toolbar, image sizing, Uploads folder,
  Link Picker prop
- `references/blocks-and-pickers.md` — BlockPreview/BlockList config, UFM labels, block backoffice
  info partials, YouTube CSP

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/rte-config.md`" — so the user knows where to look for more context.
