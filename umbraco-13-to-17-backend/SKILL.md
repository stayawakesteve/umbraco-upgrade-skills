---
name: umbraco-13-to-17-backend
description: |
  Migrates the backend/codebase of an Etch CMS site from Umbraco 13 (.NET 8) to Umbraco 17 (.NET 10).
  Use this skill for any C# / project-file / configuration work in a v13→v17 upgrade: retargeting the
  .csproj to net10.0, updating NuGet packages to v17-compatible versions, rewriting Program.cs (including
  the new Contentment registration), fixing ModelsBuilder generated files (IPublishedSnapshotAccessor →
  IPublishedContentTypeCache), resolving RazorSourceGenerator duplicate hintName build errors, and
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

Do these in order. Each step gets you closer to a green build:

1. **Retarget `.csproj`** to `net10.0` and update package references → `references/csproj-net10-retarget.md`
2. **Update `Program.cs`** to the v17 shape → `references/program-cs-v17.md`
3. **Fix ModelsBuilder generated files** → `references/modelsbuilder-fixes.md`
4. **Update `appsettings.json`** for v17 conventions → `references/appsettings-v17.md`
5. **Resolve the `RazorSourceGenerator` hintName error** if it appears → `references/razor-source-generator-fix.md`

If you see a build error not covered by one of the above, search the v17 Etch.Cms.Umbraco.Template
files (Program.cs, .csproj, appsettings.json) — there's likely a pattern you're missing.

## The four breaking changes most likely to catch you

Most v13→v17 codebase issues fall into one of these buckets:

### 1. ModelsBuilder generated files use `IPublishedSnapshotAccessor`

v17 removed this. The fix is mechanical:

```
Find:    IPublishedSnapshotAccessor
Replace: IPublishedContentTypeCache
```

Apply across all `*.generated.cs` files in the Models project. Two viable approaches; see
`references/modelsbuilder-fixes.md` for the trade-off.

### 2. Contentment now requires Program.cs registration

In v13, adding the Contentment package was enough. In v17 you must explicitly initialise it on
the Umbraco builder:

```csharp
var umbracobuilder = builder.CreateUmbracoBuilder()
    .AddBackOffice()
    .AddWebsite()
    .AddDeliveryApi()
    .AddComposers()
    .AddContentment(x => { x.DisableTree = false; x.DisableTelemetry = true; });
```

The `DisableTelemetry = true` part is the Etch standard. If you skip this step, Contentment
silently breaks at runtime (data types using it can't be resolved).

This is the **canonical example** of "updated packages may have different requirements". Treat it as
a warning sign: when you see a package version jump, check the release notes for new registration
requirements before assuming the package is drop-in.

### 3. `RazorSourceGenerator` duplicate `hintName`

During build, you may see:

```
CSC : warning CS8785: Generator 'RazorSourceGenerator' failed to generate source.
Exception was of type 'ArgumentException' with message
'The hintName 'Views_Partials_CookieBar_cshtml.g.cs' of the added source file must be unique
within a generator. (Parameter 'hintName')'
```

This happens when a local view duplicates a view shipped by a NuGet package. The fix is to delete
the local file. See `references/razor-source-generator-fix.md` for which files most commonly clash
and how to identify the source package.

### 4. Some 3rd-party packages have no v17 release

The package audit in the router skill (`umbraco-13-to-17` → `references/pre-flight-checklist.md`)
should have flagged these. When you hit a NuGet restore error, double-check it's listed in the audit.
If a package genuinely has no v17 path, the upgrade *for that site* is blocked until you find an
alternative — don't try to force the version.

## Centralised package versions

The v17 Etch.Cms template uses **centralised package management** — package versions live in
`Directory.Packages.props`, not the `.csproj`. PackageReferences in `.csproj` look like:

```xml
<PackageReference Include="Umbraco.Cms" />
```

with **no `Version=` attribute**. If the v13 site you're migrating doesn't use centralised packages,
decide whether to introduce it now (recommended — better consistency across the solution) or keep
inline versions for the upgrade and migrate later.

## What "done" looks like for this skill

- `dotnet build` succeeds with no errors and only acceptable warnings
- Site boots when you run it: backoffice loads at `/umbraco`, no boot errors in the log
- ModelsBuilder rebuilds cleanly (no `IPublishedSnapshotAccessor` errors)

You'll still have content issues, missing tag helpers, broken styles — that's expected. Those are
handled by the other three sub-skills. Don't try to fix everything in one pass.

## Reference files

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/modelsbuilder-fixes.md`" — so the user knows where to look for more context.

- `references/csproj-net10-retarget.md` — `.csproj` target framework and package list
- `references/program-cs-v17.md` — Program.cs structure with v17 conventions
- `references/modelsbuilder-fixes.md` — ModelsBuilder `IPublishedSnapshotAccessor` fix
- `references/appsettings-v17.md` — appsettings.json v17 changes
- `references/razor-source-generator-fix.md` — `hintName must be unique` resolution
