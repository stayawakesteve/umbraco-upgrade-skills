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

## Step 2: Apply the fix scripts to the exported files

### UDI → GUID for MNTP filters

```powershell
.\scripts\transform-mntp-filter-udis-to-guids.ps1
```

The script targets `uSync\v17\Content` (hardcoded path — confirm yours matches before running).
It only touches references inside `<filters>...</filters>` sections; other UDI references are left
alone.

After running, you'll see output like:

```
Modified: HomePage.config - 3 UDI(s) transformed
Modified: AboutPage.config - 1 UDI(s) transformed
Processing complete!
```

Spot-check a few of the modified files to confirm the transformation looks right — the regex
expects 32-char hex UDIs, so anomalous inputs (e.g. broken UDIs in the source data) may not match.

### `nameTemplate` UFM rewrite

This isn't a bundled script (it's small enough to do by hand or with a one-liner). See
`references/nametemplate-rewrite.md` for the regex patterns. The short version:

```
Find:    "nameTemplate":\s*"\{\{\s*value\s*\|\s*ncNodeName\s*\}\}"
Replace: "nameTemplate": "{umbContentName: value}"
```

…plus similar patterns for other AngularJS template helpers. Doing this *in the uSync files* (rather
than in the backoffice after import) is faster because you can mass-replace across all data types
at once.

## Step 3: 3rd-party data type re-linkage

For each data type whose property editor alias changed in v17 (HubSpot Form Picker is the canonical
example):

1. Open `uSync/v17/DataTypes/<datatype-name>.config`
2. Find the `<EditorAlias>` element
3. Update to the new alias (consult the package's v17 docs for the correct alias)

Save and continue.

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
`references/content-migration-gotchas.md` for context.

1. From v17, do another full uSync export (capturing the current state including the fixes above)
2. In the backoffice, **delete the home node** and clear it from the Recycle Bin
3. Run uSync **Import** — this recreates the home node and forces a save/republish of every
   descendant
4. Verify pages render correctly on the frontend

This is the heavy-handed "nuke and restore" approach. It's reliable; manual page-by-page republishing
is unreliable on a large site.

## Step 6: Final commit

Once everything imports cleanly and the site renders correctly:

1. Run one more uSync export to capture the final state
2. Commit the `uSync/v17/` folder to the `feature/v17` branch
3. The `uSync/v9/` (or older) folder can stay until the upgrade is merged — useful reference during
   code review

## What can go wrong

- **Export step errors** — usually a specific data type. Look at the log, fix the data type, re-export.
- **Import errors but no obvious cause** — uSync logs `result: false` without an exception. Check
  the dependency order; templates with `Layout` directives need their layout imported first.
- **Content imports but renders empty** — the content-rendering bug. Do the delete-home workaround.
- **Visible state wrong** — you forgot to run the v13-side fix script before exporting. Roll back
  to v13, run the script, commit, then redo the upgrade.
- **MNTP filters return no results** — the UDI → GUID transform didn't run, or the filter is using
  the standard MNTP (not the repository-based one). The script only fixes filters inside
  `<filters>...</filters>` sections.

## Verifying

Walk the "Content / DB" section of `umbraco-13-to-17/references/done-checklist.md` after the
workflow is complete.
