# Pre-flight checklist (v13 → v17)

Run through this list **before** changing any files for the v17 upgrade. Skipping these costs hours
later — most of them are quick to do now, painful to backtrack to.

## On the v13 side

### 1. Fix the `"visible": ""` content bug

In v13, blocks with a visible state of `""` or `"1"` both render correctly. After the v17 migration,
`""` is treated as **hidden**. Mass-replace before exporting:

```powershell
# From the project root, on the v13 main branch
.\Scripts\fix-visible-property.ps1
```

The script lives in `umbraco-13-to-17-database/scripts/fix-visible-property.ps1`. It targets
`uSync\v9\Content` — that hardcoded path is correct for our setup despite the version number; check
your project's folder before running.

After running, re-import uSync content on the v13 side and commit. This ensures every block has an
explicit `"1"` or `"0"`.

### 2. Decide on the feature branch model

Create `feature/v17` from current v13 `main`. Do **not** rebase against `main` part-way through —
the v17 upgrade touches so many files that any merge conflict in the middle is more work than
just letting `feature/v17` diverge until it's ready to merge.

## Package audit

### 3. List every NuGet package and confirm v17 availability

Open the v13 `.csproj` and for each `PackageReference`:

1. Check the package's NuGet page for a v17-compatible release.
2. For packages with no v17 release, decide *now*: drop, replace, or block the upgrade. Common cases:
   - **Dropped:** anything Umbraco-specific that the author abandoned
   - **Replaced:** community packages where a newer alternative emerged (e.g. some image processors)
   - **Block:** rare, but if a critical package has no v17 path, the upgrade can't proceed yet
3. For packages that *do* have v17 releases, check the changelog for breaking changes (new init
   requirements, removed APIs, renamed configuration sections). **Contentment now needs
   `.AddContentment(...)` in `Program.cs`** — that's the canonical example.

Write the audit down somewhere visible (PR description, Notion page). You will refer back to it.

### 4. Confirm Etch CMS package versions

The internal `Etch.Cms.Umbraco.*` packages all have v17 releases. Note the version you're targeting
and confirm the `Etch.Cms.Libraries` checkout (if using ProjectReferences) is on the right branch.

## Environment

### 5. Confirm `.NET 10` SDK is installed

v17 targets `net10.0`. `dotnet --list-sdks` should show a 10.x SDK. If not, install before retargeting
or every build will fail mysteriously.

### 6. Backup the database

Even with uSync handling content migration, take a SQL backup of the v13 DB *before* you point a v17
build at it. The v17 boot will perform schema migrations that cannot be reversed.

## Tooling

### 7. PowerShell available

The two fix scripts (`fix-visible-property.ps1`, `transform-mntp-filter-udis-to-guids.ps1`) are
PowerShell, not bash. Make sure whoever's running the upgrade has PowerShell installed.

### 8. ModelsBuilder strategy

Decide upfront which path to take when `IPublishedSnapshotAccessor` references break the build:

- **Option A:** Mass-replace `IPublishedSnapshotAccessor` with `IPublishedContentTypeCache` across
  all `*.generated.cs` files. Quick, keeps history.
- **Option B:** Delete all generated files, temporarily move Views out of the project, get the site
  booting, then rebuild models from the DB and put Views back. Cleaner end state, more steps.

Option B is generally less painful for larger sites.
