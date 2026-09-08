# RTE / TipTap config (v17)

v17 ships TipTap as the default rich text editor (replacing TinyMCE in v13). All RTE data types in
the site need their configuration updated.

## Per-RTE config to apply

For every Rich Text data type in the site (Settings → Data Types → filter by Richtext editor):

### 1. Enable Word Count

Tick the "Word Count" option in the data type config. Editors expect this — it's off by default in
v17 even though it was usually on in v13.

### 2. Use the standard Etch toolbar layout

The toolbar layout differs between TinyMCE (v13) and TipTap (v17). The canonical Etch v17 toolbar
includes:

- Format selector (paragraph, headings)
- Bold, italic
- Bullet list, numbered list
- Link
- Image
- HR (horizontal rule)
- Source code view

The exact layout is documented in screenshots in the Notion v17 upgrade notes. The principle:
**don't try to recreate v13's TinyMCE toolbar one-for-one** — some controls don't map cleanly, and
TipTap has different idioms. Pick the Etch standard layout and apply it everywhere.

### 3. Maximum size for inserted images: `1280`

Set in the data type config under "Image upload size". 1280 is the Etch standard — it balances quality
against page weight, and matches the largest breakpoint in the standard responsive image set.

### 4. Image Upload Folder = "Uploads"

Create a folder in the Media section called `Uploads` (top-level). Configure the data type to upload
to that folder.

Without this set, images uploaded via the RTE land in the Media root, which clutters Media for content
editors. The `Uploads` folder is the agreed staging area for RTE-uploaded media.

## Project-wide RTE additions

### Link Picker prop for TipTap

To enable buttons (well-styled CTA-style links) inside TipTap, the project needs a Link Picker
property registered. Refer to the v17 Etch.Cms template for the canonical implementation — it
involves a custom property editor manifest.

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
  render. If not, see the YouTube CSP fix in `blocks-and-pickers.md`.

## Verifying

For each RTE data type:

1. Open the data type config and confirm: Word Count on, Etch toolbar layout, max image 1280,
   Uploads folder set
2. Open a content node using that data type and verify the editor loads with the expected toolbar
3. Try inserting an image — confirm it lands in the `Uploads` folder
4. Try inserting a button (if Link Picker is registered)
5. Save and check the page renders on the frontend
