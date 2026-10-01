# Content migration gotchas

## 1. The "visible state" bug

**Symptom:** After migration, blocks that were visible on v13 render as hidden on v17. Common
example: nav items disappear, sidebar widgets vanish, hero sections don't show.

**Root cause:** In v13, a block's `"visible"` property could be `""`, `"1"`, or `"0"`:
- `""` (empty) → treated as visible
- `"1"` → visible
- `"0"` → hidden

In v17, `""` is treated as hidden. So any v13 block with `"visible": ""` migrates to a hidden state.

**Fix:** Run the v13-side `fix-visible-property.ps1` script **before** starting the upgrade.
Run it from the folder that contains `uSync\`
(`& <path-to-this-skill>\scripts\fix-visible-property.ps1`) — its target, `uSync\v9\Content`, is
hardcoded and relative to the current directory (the folder name is historical — confirm it matches
where your v13 uSync content lives before running). It replaces `"visible": ""` with
`"visible": "1"`; then re-import uSync on v13 and commit.

This is a **pre-flight** fix, not a post-upgrade fix. If you missed it and you're already on v17,
your options are:

- Manually toggle every affected block in the v17 backoffice (slow, error-prone)
- Roll back to v13, run the script, re-import, commit, then redo the v17 upgrade
- Write a v17-side equivalent of the script that targets the v17 uSync export and re-import

The pre-flight approach is by far the cleanest.

## 2. The content-rendering bug

**Symptom:** After the v17 site first boots against a v13 DB:

- First page load: homepage "almost looks right" but has visible/hidden items wrong (nav contains
  items that should be hidden, or vice versa)
- After site restart: most content is missing entirely
- Manually re-publishing each page fixes it for that page

**Root cause:** Something in the v17 migration pipeline is leaving published content in a stale
state. Re-saving each node forces it to re-publish into the v17 schema.

**Workaround:** force a republish of every node by deleting the home node and re-importing via
uSync — steps in `usync-workflow.md` Step 5.

This is heavy-handed but reliable. The manual alternative — re-publishing each page through the
backoffice — works on small sites but is impractical on anything with 100+ pages.

**Why not just re-publish from the root?** Re-publishing the root in the backoffice publishes the
home node but doesn't reliably cascade. Deleting + re-importing via uSync is what actually triggers
a fresh save on each individual node.

## 3. The 3rd-party data type re-link

**Symptom:** A data type shows the error "Property editor with alias 'X' is not available" in the
backoffice. Properties using that data type don't render on the frontend.

**Root cause:** The 3rd-party package shipped a new property editor alias in its v17 release.
Existing data types still reference the old alias.

**Canonical example:** HubSpot Form Picker.

**Fix:** update the data type's `<EditorAlias>` in its uSync `.config` to the new alias and
re-import — steps in `usync-workflow.md` Step 3.

After re-import, the data type resolves correctly. Fixing it usually fixes the frontend content too,
though sometimes the property values themselves need migrating (depends on the package).

**Discovery process for unknown packages:** Open the package's NuGet release notes for v17 — they
usually call out alias renames. If not documented, install the package on a fresh v17 site and
inspect the data type it creates.

## 4. The List View `orderBy` casing bug

**Symptom:** Opening a node list in the backoffice — most visibly the **Media library** — throws a
toast error:

> An error occurred
> Order by value is not a property on the configured collection
> The specified orderBy property is not part of the collection configuration

Nothing appears in the Umbraco logs, because it's a **client-side** validation error thrown by the
collection view UI, not a server exception. That makes it easy to misdiagnose.

**Root cause:** The v14 List View migration lower-cases the config keys and property aliases to
camelCase (`sortOrder`, `updateDate`, `creator`, …) but leaves the `orderBy` **value** in its old
v13 PascalCase form (`SortOrder`, `Name`, `VersionDate`). v17's collection view validates `orderBy`
against the configured aliases **case-sensitively**, so `SortOrder` no longer matches `sortOrder`.
It affects *every* migrated List View data type, not just Media — you'd hit it on Content, Members,
News Index, etc. as soon as you open each list.

**Fix:** run `fix-listview-orderby-casing.ps1` after export, before re-import (or restart the site if
you have a startup import) — steps in `usync-workflow.md` Step 2.

## Cross-cutting principle

§1 and §4 share a pattern: **what worked silently in v13 breaks in v17 because of stricter
handling** — empty strings become hidden, case-insensitive `orderBy` matching becomes
case-sensitive.

When troubleshooting other "looks fine on v13, breaks on v17" symptoms, look for the same shape:
some convention in v13 that depended on lenient interpretation now needs to be made explicit.
