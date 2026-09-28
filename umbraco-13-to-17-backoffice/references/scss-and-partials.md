# Backoffice SCSS migration

None of these changes is hard individually; the gotcha is forgetting one and shipping a half-styled
site.

## 1. `blockpreview.scss`

Import the latest `blockpreview.scss` file from the v17 Etch.Cms template and update the imports
within it to match the project's structure.

Typical location: `wwwroot/css/src/blockpreview.scss` (or wherever the source SCSS lives in the
project). The compiled output should land at `/css/blockpreview.css`, matching
`BlockPreview:BlockGrid:Stylesheet` in `appsettings.json` (see `blocks-and-pickers.md` §1).

If the project doesn't have a `blockpreview.scss` file yet (some v13 sites didn't bother), copy it in
fresh from the v17 template instead of trying to update imports in a file that doesn't exist.

## 2. Backoffice info SCSS

If the v13 site had a `_color.scss` (or similar) defining backoffice info colour variables, those
need migrating into the v17 backoffice info styles.

Migration steps:

1. Find the v13 colour variables (commonly in `variables/_color.scss` or `_variables.scss`)
2. Locate the v17 backoffice info SCSS — it lives alongside the backoffice info partial styles
3. Migrate the colour *values* (not the variable names — the v17 version uses different names) into
   the v17 SCSS

## 3. `.stylelintcache` in `.gitignore`

v17 brings in stylelint at the project level. Add `.stylelintcache` to `.gitignore`:

```gitignore
# Stylelint cache
.stylelintcache
```

Cheap but easy to forget — if you don't add it, every developer ends up committing their local
stylelint cache file.

## 4. Picker styles migration

In v13, picker styles often lived in `editor.scss`. In v17 they move to the SCSS that compiles to the
assets referenced by `App_Plugins/Etch.Cms.Umbraco/umbraco-package.json`. The mechanics depend on how the picker is implemented; check the v17 template for the current pattern.

## 5. Remove `.umb-block-grid` styles from `editor.scss`

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
   - Backoffice info partials show with correct colours. If they're default-grey with no theme colour,
     the SCSS isn't being included: check the bundle config.
   - Pickers render with correct styling
