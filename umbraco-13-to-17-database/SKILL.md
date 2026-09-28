---
name: umbraco-13-to-17-database
description: |
  Migrates the database and content side of an Etch CMS site from Umbraco 13 to Umbraco 17. Use this
  skill for any uSync, content migration, content republish, MNTP/data type, or template-import issue
  in a v13→v17 upgrade. Covers the MNTP filter UDI → GUID transformation (with bundled PowerShell
  script), the nameTemplate AngularJS → UFM rewrite, re-linking 3rd-party data types whose property
  editor changed (HubSpot Form Picker etc.), the visible block migration bug (with bundled fix script),
  the content-rendering bug workaround (delete home → uSync re-import to force republish), the List View
  orderBy casing bug (with bundled fix script), and the master template ordering gotcha (_layout.config
  prefix trick for "template not found" errors).
  Trigger on phrases like "uSync import failing", "templates not found after v17 upgrade", "blocks
  hidden on v17", "content not rendering after Umbraco upgrade", "MNTP filter broken", "HubSpot Form
  Picker missing", "umbContentName UFM", "Order by value is not a property on the configured collection",
  "orderBy property is not part of the collection configuration", "media library error after v17 upgrade",
  or whenever a user mentions content/uSync symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Database / Content Migration

This skill covers the uSync export/fix/import workflow and the content-side bugs that the v13→v17
migration triggers. Backend (.csproj, Program.cs, namespaces) is owned by `umbraco-13-to-17-backend`;
backoffice and frontend changes are owned by `umbraco-13-to-17-backoffice` and
`umbraco-13-to-17-frontend`.

## The canonical workflow

Once the site is **compiling and booting** (backend skill is done):

1. **Pre-flight fix on the v13 side** — run `fix-visible-property.ps1` against v13 `uSync\v9\Content`,
   re-import, commit. This is the only fix that must happen *before* the upgrade.
2. **Rebuild ModelsBuilder** in v17 against the v13 DB
3. **Full uSync export** from v17 → writes fresh files to `uSync/v17/`
4. **Run UDI → GUID transform** (`transform-mntp-filter-udis-to-guids.ps1`) against `uSync/v17/Content`
5. **Fix `nameTemplate` syntax** — `{{ value | ncNodeName }}` → `{umbContentName: value}`
6. **Fix List View `orderBy` casing** — run `fix-listview-orderby-casing.ps1` against `uSync/v17/DataTypes`
7. **Re-link 3rd-party data types** (HubSpot Form Picker etc.) whose property editor changed
8. **Re-import uSync** with the fixes applied
9. **Force-republish workaround** — delete the home node, run uSync import to recreate, which forces
   a republish of every node and resolves the content-rendering bug
10. **Fix master template ordering** if templates fail to import on a fresh DB (`_layout.config` trick)

## Bundled scripts

This skill ships three PowerShell scripts in `scripts/`:

### `scripts/fix-visible-property.ps1` (v13-side, pre-flight)

**Run this on the v13 branch, before starting the upgrade.**

In the v13 database, blocks can have a `"visible"` property value of `""`, `"1"`, or `"0"`:
- `""` and `"1"` → block is visible
- `"0"` → block is hidden

When migrated to v17, **`""` is treated as hidden** (not visible). So blocks that look fine on v13
disappear on v17 unless you explicitly set `"1"` first.

The script:
- Walks `uSync\v9\Content` recursively (folder name is historical; that's correct for our setup)
- Finds `.config` files containing `"visible": ""`
- Replaces with `"visible": "1"`
- Reports modified files

Run it, re-import the uSync content on v13, commit, then start the upgrade.

### `scripts/transform-mntp-filter-udis-to-guids.ps1` (v17-side, post-export)

**Run this after exporting uSync from v17 but before re-importing.**

The custom repository-based MNTP property editor stored node references as Umbraco UDIs
(`umb://document/<32-char-hex>`) in v13. The v17 document picker uses plain GUIDs in dashed format
(`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

The script:
- Walks `uSync\v17\Content` recursively
- For each `.config` file, finds `<filters>...</filters>` sections
- Within those sections only, converts `umb://document/<hex>` references to dashed GUIDs
- Reports number of UDIs transformed per file

The "only within `<filters>`" scoping is important — other UDI references in the file (e.g. for
content pickers using the standard editor) shouldn't be touched.

### `scripts/fix-listview-orderby-casing.ps1` (v17-side, post-export)

**Run this after exporting uSync from v17 but before re-importing.**

The v14 List View migration lower-cases the config keys and property aliases to camelCase
(`sortOrder`, `updateDate`, `creator`, …) but leaves the **`orderBy` value** in its old v13
PascalCase form (`SortOrder`, `Name`, `VersionDate`). v17's collection view validates `orderBy`
against the configured aliases **case-sensitively**, so `SortOrder` ≠ `sortOrder` and the backoffice
throws when you open the affected node list (e.g. the Media library):

> Order by value is not a property on the configured collection

This is a **client-side** validation error — nothing appears in the Umbraco logs, which makes it
easy to misdiagnose. It affects *every* migrated List View data type, not just Media.

The script:
- Walks `uSync\v17\DataTypes` recursively
- For each `.config` with an `"orderBy"` value, re-cases it to match a configured alias
  (the data type's own `includeProperties` aliases + the system aliases like `name`, `sortOrder`,
  `updateDate`, `creator`)
- Applies the one legacy rename (`VersionDate` → `updateDate`) that isn't just a casing change
- Warns (and leaves untouched) any `orderBy` it can't match, so you can inspect it manually
- Reports each `old → new` change

## The content rendering bug (and its workaround)

After the first v17 boot against a v13 DB, content rendering misbehaves:

- First page load: homepage looks "almost right" but renders extra items in the nav that should
  be hidden
- After restart: homepage renders with most content **missing**
- Manual re-publish of each page: it then renders correctly

This is a one-time migration bug. The fix is to force a republish of every node:

1. From v17, do a full uSync export
2. **Delete the home node** (and clear it from the recycle bin)
3. Run **uSync import** — this recreates the home node and every descendant, forcing a fresh
   save/republish of every node in the site
4. Verify the site renders correctly

This is heavy-handed but it's the cleanest workaround. Doing it page-by-page through the backoffice
is a thousand-click slog on a real site.

## Template not found on fresh DB

If you're migrating to a **fresh** v17 database (rather than letting v17 migrate the v13 schema),
you'll hit a uSync template import gotcha: templates with a `Layout` directive silently fail to
import unless the layout template is imported first.

See `references/template-import-order.md` for the `_layout.config` prefix trick. The fix is to name
the layout's uSync config file with a `_` prefix so it sorts ahead of everything else.

## 3rd-party data types whose property editor changed

Some 3rd-party data types (HubSpot Form Picker is the canonical example) ship a different property
editor alias in v17 than they did in v13. After uSync import, these data types will show:

> Property editor with alias 'X' is not available

…in the backoffice when you open the data type.

For each affected data type:

1. Note the data type name and which property editor it should now point at (check the package's
   v17 release notes / docs)
2. In the uSync `.config` for that data type, update the `EditorAlias` element to the new alias
3. Re-import

If the FE shows missing content for properties of that type, that's a downstream symptom of the
data type mis-linkage. Fixing the data type usually fixes the content too, though sometimes the
property values themselves need migrating (depends on the package).

## Reference files

- `references/usync-workflow.md` — full uSync export/fix/import workflow with command examples
- `references/content-migration-gotchas.md` — the visible-state bug, the republish workaround,
  3rd-party data types
- `references/template-import-order.md` — the `_layout.config` prefix trick for fresh DBs
- `references/nametemplate-rewrite.md` — UFM template syntax migration

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/usync-workflow.md`" — so the user knows where to look for more context.
