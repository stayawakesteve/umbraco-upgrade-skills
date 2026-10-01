# uSync workflow (v13 → v17)

The full export → fix → import dance. This is supervised — don't try to script the whole thing
end-to-end; you need eyes on each step.

## Prerequisites

- v17 site is compiling and booting (see `umbraco-13-to-17-backend`)
- v17 site has a clean ModelsBuilder build against the v13 DB
- v13-side fix script (`fix-visible-property.ps1`) has been run on v13 main and committed

## Step 1: Initial v17 export

With the v17 site running against the v13 DB:

1. Log into `/umbraco`
2. Navigate to Settings → uSync
3. Run **Export** with all sections selected (Content, Settings, Forms, etc.)

This writes uSync files to `uSync/v17/`. Inspect the output — if any export step errored, fix that
before continuing (usually a specific data type is causing issues; check the log).

## Step 2: Fix the exported files

### `nameTemplate` UFM rewrite

Not a bundled script — see `references/nametemplate-rewrite.md` for the find/replace patterns and the
recommended files-then-backoffice approach.

### List View `orderBy` casing

Run it from the folder that contains `uSync\` — its target, `uSync\v17\DataTypes`, is hardcoded and
relative to the current directory (confirm yours matches before running):

```powershell
& <path-to-this-skill>\scripts\fix-listview-orderby-casing.ps1
```

It re-cases each List View `orderBy` value to match a configured alias (`SortOrder` → `sortOrder`)
and renames the legacy `VersionDate` to `updateDate`.

Any line reported as `Skipped` is an `orderBy` the script couldn't match to a known alias — check
those data types by hand. See `references/content-migration-gotchas.md` §4 for the full background.

## Step 3: 3rd-party data type re-linkage

For each data type whose property editor alias changed in v17 (HubSpot Form Picker is the canonical
example):

1. Open `uSync/v17/DataTypes/<datatype-name>.config`
2. Find the `<EditorAlias>` element
3. Update to the new alias (how to find it: `references/content-migration-gotchas.md` §3, "Discovery
   process")

## Step 4: Re-import

Back in the backoffice:

1. Navigate to Settings → uSync
2. Run **Import** with all sections selected

Watch the log carefully. Any import that reports `result: false` is a silent failure — investigate
before proceeding.

If templates fail to import on a **fresh** DB, you're hitting the master template ordering bug —
see `references/template-import-order.md`.

## Step 5: Force-republish via uSync (the homepage workaround)

This step works around the content-not-rendering bug after migration. See
`references/content-migration-gotchas.md` §2 for context.

1. From v17, do another full uSync export (capturing the current state including the fixes above)
2. In the backoffice, **delete the home node** and clear it from the Recycle Bin
3. Run uSync **Import** — this recreates the home node and forces a save/republish of every
   descendant
4. Verify pages render correctly on the frontend

## Step 6: Final commit

Once everything imports cleanly and the site renders correctly:

1. Run one more uSync export to capture the final state
2. Commit the `uSync/v17/` folder to the `feature/v17` branch
3. The `uSync/v9/` (or older) folder can stay until the upgrade is merged — useful reference during
   code review

## Verifying

Walk the "Content / DB" section of `umbraco-13-to-17/references/done-checklist.md` after the
workflow is complete.
