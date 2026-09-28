---
name: umbraco-13-to-17-backend
description: |
  Migrates the backend/codebase of an Etch CMS site from Umbraco 13 (.NET 8) to Umbraco 17 (.NET 10).
  Use this skill for any C# / project-file / configuration work in a v13→v17 upgrade: retargeting the
  .csproj to net10.0, updating NuGet packages to v17-compatible versions, rewriting Program.cs (including
  the new Contentment registration), fixing ModelsBuilder generated files that reference
  IPublishedSnapshotAccessor, resolving RazorSourceGenerator duplicate hintName build errors, and
  updating appsettings.json for v17. Trigger on phrases like "Umbraco 17 won't build", "migrate
  Program.cs to v17", "IPublishedSnapshotAccessor errors", "RazorSourceGenerator hintName must be
  unique", "Contentment not initialising in v17", "retarget Umbraco to .NET 10", or whenever a user
  shows a v13 .csproj/Program.cs and asks for help making it v17-compatible.
---

# Umbraco 13 → 17 Backend Migration

The goal of this skill is to get a v13 codebase compiling and booting on v17 (`net10.0`). That's it.
Backoffice details belong in `umbraco-13-to-17-backoffice`, frontend views in
`umbraco-13-to-17-frontend`, and content/DB in `umbraco-13-to-17-database`.

## Order of operations

Do these in order:

1. **Retarget `.csproj`** to `net10.0` and update package references → `references/csproj-net10-retarget.md`
2. **Update `Program.cs`** to the v17 shape → `references/program-cs-v17.md`
3. **Fix ModelsBuilder generated files** → `references/modelsbuilder-fixes.md`
4. **Update `appsettings.json`** for v17 conventions → `references/appsettings-v17.md`
5. **Resolve the `RazorSourceGenerator` hintName error** if it appears → `references/razor-source-generator-fix.md`

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/modelsbuilder-fixes.md`" — so the user knows where to look for more context.

If you see a build error not covered by one of the above, search the v17 Etch.Cms.Umbraco.Template
files (Program.cs, .csproj, appsettings.json) — there's likely a pattern you're missing.

## The four breaking changes most likely to catch you

### 1. ModelsBuilder generated files use `IPublishedSnapshotAccessor`

v17 removed this, so every v13 `*.generated.cs` file in the Models project fails to compile. Either
mass-replace it with `IPublishedContentTypeCache` or delete and regenerate the models —
`references/modelsbuilder-fixes.md` has the trade-off.

### 2. Contentment now requires Program.cs registration

In v13, adding the Contentment package was enough. In v17 you must chain `.AddContentment(...)` onto
the Umbraco builder in `Program.cs`. Skip it and Contentment silently breaks at runtime (data types
using it can't be resolved). The Etch-standard options are in `references/program-cs-v17.md` §1.

This is the **canonical example** of "updated packages may have different requirements". Treat it as
a warning sign: when you see a package version jump, check the release notes for new registration
requirements before assuming the package is drop-in.

### 3. `RazorSourceGenerator` duplicate `hintName`

A build warning `CS8785: Generator 'RazorSourceGenerator' failed … The hintName '…_cshtml.g.cs' …
must be unique within a generator` means a local view duplicates one shipped by a NuGet package.
Usually you delete the local copy; if it's a deliberate customisation, rename or move it instead.
`references/razor-source-generator-fix.md` covers which files most commonly clash, decoding the
hintName, finding the source package, and the override options.

### 4. Some 3rd-party packages have no v17 release

The package audit in the router skill (`umbraco-13-to-17` → `references/pre-flight-checklist.md`)
should have flagged these. When you hit a NuGet restore error, double-check it's listed in the audit.
If a package genuinely has no v17 path, the upgrade *for that site* is blocked until you find an
alternative — don't try to force the version.

## What "done" looks like for this skill

- `dotnet build` succeeds with no errors and only acceptable warnings
- Site boots when you run it: backoffice loads at `/umbraco`, no boot errors in the log
- ModelsBuilder rebuilds cleanly (no `IPublishedSnapshotAccessor` errors)

You'll still have content issues, missing tag helpers, broken styles — that's expected.
