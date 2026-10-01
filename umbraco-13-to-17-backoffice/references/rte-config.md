# RTE / TipTap config (v17)

v17 ships TipTap as the default rich text editor (replacing TinyMCE in v13).

## Per-RTE config to apply

For every Rich Text data type in the site (Settings → Data Types → filter by Richtext editor):

### 1. Enable Word Count

Tick the "Word Count" option in the data type config. Editors expect this — it's off by default in
v17 even though it was usually on in v13.

### 2. Use one standard toolbar layout

The toolbar layout differs between TinyMCE (v13) and TipTap (v17). A good baseline v17 toolbar
includes:

- Format selector (paragraph, headings)
- Bold, italic
- Bullet list, numbered list
- Link
- Image
- HR (horizontal rule)
- Source code view

The principle: **don't try to recreate v13's TinyMCE toolbar one-for-one** — some controls don't map
cleanly, and TipTap has different idioms. Pick one standard layout and apply it to every RTE data
type.

### 3. Maximum size for inserted images: `1280`

1280 is a sensible default — it balances quality against page weight. If the site's own responsive
image sizes go larger, match its largest size instead.

### 4. Image Upload Folder = "Uploads"

Create a folder in the Media section called `Uploads` (top-level). Configure the data type to upload
to that folder.

Without this set, images uploaded via the RTE land in the Media root, which clutters Media for content
editors.

## Project-wide RTE additions

### Link Picker prop for TipTap

To enable buttons (well-styled CTA-style links) inside TipTap, the project needs a Link Picker
property registered. Refer to your v17 starter template or reference project for the
implementation — it involves a custom property editor manifest.

Without this, editors can't insert anything richer than a plain `<a>` link. Buttons in body content
revert to looking like raw links.

## Sanity check: `SanitizeTinyMce`

Despite the move to TipTap, `appsettings.json` may still have:

```json
"Umbraco": {
  "CMS": {
    "Global": {
      "SanitizeTinyMce": true
    }
  }
}
```

Leave this set to `true`. It controls HTML sanitisation on content saved from any rich text editor
(the setting name is historical) — turning it off opens XSS surface area.

## Migrating existing RTE content

Most v13 → v17 RTE content migrates cleanly — TipTap parses the existing HTML. But these patterns
need watching:

- **TinyMCE plugin output** that produced non-standard HTML (e.g. custom shortcodes via plugins) may
  render as literal text in TipTap. Audit by visiting 5+ pages with rich content after the migration.
- **Inline styles** were sometimes added by TinyMCE; TipTap is stricter. Editors may need to redo
  styling once.
- **Embedded media** (YouTube, Twitter) embedded via TinyMCE oEmbed plugin: confirm they still
  render.

## Verifying

For each RTE data type:

1. Open the data type config and confirm: Word Count on, standard toolbar layout, max image size
   per §3, Uploads folder set
2. Open a content node using that data type and verify the editor loads with the expected toolbar
3. Try inserting an image — confirm it lands in the `Uploads` folder
4. Try inserting a button (if Link Picker is registered)
5. Save and check the page renders on the frontend
