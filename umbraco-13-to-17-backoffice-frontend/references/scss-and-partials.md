# SCSS and partials migration

The v17 backoffice/frontend SCSS changes are the cosmetic side of the upgrade. Most are mechanical
— bring across a file, update imports, move some styles to a different location. None are hard
individually; the gotcha is forgetting one and shipping a half-styled site.

## 1. `blockpreview.scss`

Import the latest `blockpreview.scss` file from the v17 Etch.Cms template and update the imports
within it to match the project's structure.

Typical location: `wwwroot/css/src/blockpreview.scss` (or wherever the source SCSS lives in the
project). The compiled output should land at `/css/blockpreview.css` to match the `appsettings.json`
config:

```json
"BlockPreview": {
  "BlockGrid": {
    "Stylesheet": "/css/blockpreview.css"
  }
}
```

If the project doesn't have a `blockpreview.scss` file yet (some v13 sites didn't bother), copy it
in fresh from the v17 template.

## 2. Section partials

Section partials live at `Views/Partials/blockgrid/Components/Section.cshtml` (and related). Bring
them up to v17 standards by:

1. Including the **backoffice info partial** if it's missing — v17 backoffice expects it
2. Fixing the **nested section issue** — see below

### Including backoffice info partial

Each section partial should include something like:

```cshtml
@if (Context.Request.Path.StartsWithSegments("/umbraco"))
{
    <partial name="blockgrid/Components/BackofficeInfo" model="Model" />
}
```

Older Etch.Cms sites may not have this — without it, editors see less context about the section in
the backoffice. Apply to all block partials, not just sections.

### Nested section frontend bug

In v17, sections nested inside other sections render with extra wrapper markup that breaks the
intended layout. The fix is in `Views/Partials/blockgrid/Components/SectionContent.cshtml` — check
the v17 Etch.Cms template's version of this file and bring across whatever delta exists.

The fix is typically a conditional that skips outer-wrapper rendering when the current section is
already inside another section. Don't try to recreate from memory — copy from the template.

## 3. Backoffice info SCSS

If the v13 site had a `_color.scss` (or similar) defining backoffice info colour variables, those
need migrating into the v17 backoffice info styles.

Migration steps:

1. Find the v13 colour variables (commonly in `variables/_color.scss` or `_variables.scss`)
2. Locate the v17 backoffice info SCSS — it lives alongside the backoffice info partial styles
3. Migrate the colour *values* (not the variable names — the v17 version uses different names) into
   the v17 SCSS

### Ensure backoffice info SCSS is rendering correctly

After migration, load a content page in the backoffice and confirm the backoffice info blocks render
with the right colours. If they look wrong (default-grey, no theme colour), the SCSS isn't being
included — check the bundle config.

## 4. `.stylelintcache` in `.gitignore`

v17 brings in stylelint at the project level. Add `.stylelintcache` to `.gitignore`:

```gitignore
# Stylelint cache
.stylelintcache
```

Cheap but easy to forget — if you don't add it, every developer ends up committing their local
stylelint cache file.

## 5. Picker styles migration

In v13, picker styles often lived in `editor.scss` (alongside other backoffice editor styles). In
v17, picker styles need to move to:

```
App_Plugins/Etch.Cms.Umbraco/umbraco-package.json
```

…or rather, the SCSS that compiles to assets referenced by that `umbraco-package.json`. The
mechanics depend on how the picker is implemented; check the v17 template for the current pattern.

## 6. Remove `.umb-block-grid` styles from `editor.scss`

In v13, `.umb-block-grid` styling was custom in `editor.scss`. In v17, those styles ship as part
of the Etch CMS Umbraco backoffice package, at:

```
App_Plugins/Etch.Cms.Umbraco/src/block-grid-shadow.css
```

So: **remove `.umb-block-grid` rules from `editor.scss`**. If you don't, the local rules conflict
with the package-shipped ones and the backoffice block grid renders incorrectly.

## Verifying

After all SCSS / partial work:

1. Run the SCSS build and confirm `blockpreview.css` is produced
2. Load the backoffice and check:
   - Block grid editor renders correctly
   - Backoffice info partials show with correct colours
   - Pickers render with correct styling
3. Load the frontend and check:
   - Sections render without extra wrapper divs (no nested-section bug)
   - Block grid frontend rendering is intact
