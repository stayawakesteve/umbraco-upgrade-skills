# Pre-flight checklist (v13 → v17)

Run through this list **before** changing any files for the v17 upgrade. Skipping these costs hours
later — most of them are quick to do now, painful to backtrack to.

## On the v13 side

### 1. Fix the `"visible": ""` content bug

v17 treats `"visible": ""` as **hidden**, so this must be fixed in the v13 data before export; after
the v17 import is too late. Run `fix-visible-property.ps1` on v13 `main`, re-import uSync on v13, then
commit. Root cause, script location and target-folder caveat: `umbraco-13-to-17-database` →
`references/content-migration-gotchas.md` §1.

### 2. Decide on the feature branch model

Create `feature/v17` from current v13 `main`. Do **not** rebase against `main` part-way through —
the v17 upgrade touches so many files that any merge conflict in the middle is more work than
just letting `feature/v17` diverge until it's ready to merge.

## Package audit

### 3. List every NuGet package and confirm v17 availability

Open the v13 `.csproj` and for each `PackageReference`:

1. Check the package's NuGet page for a v17-compatible release.
2. For packages with no v17 release, decide *now*: drop, replace, or block the upgrade. There's no
   point retargeting the project if you'll be ripping out three packages anyway. Common cases:
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

The fix scripts in `umbraco-13-to-17-database/scripts/` are PowerShell, not bash. Make sure whoever's running the upgrade has PowerShell installed.

### 8. ModelsBuilder strategy

Decide upfront which fix you'll use when `IPublishedSnapshotAccessor` references break the build —
mass-replace in the generated files, or delete and regenerate. The options and when to pick each are
in `umbraco-13-to-17-backend/references/modelsbuilder-fixes.md`.
