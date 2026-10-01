# ModelsBuilder fixes (`IPublishedSnapshotAccessor` → `IPublishedContentTypeCache`)

After retargeting to `net10.0` and updating packages, your first build will fail in the Models
project with errors like:

```
The type or namespace name 'IPublishedSnapshotAccessor' could not be found
```

This is because Umbraco 17 removed `IPublishedSnapshotAccessor` and the pre-existing generated
`*.generated.cs` files (output by the v13 ModelsBuilder when `ModelsMode` is `SourceCodeAuto` or
`SourceCodeManual`) reference it everywhere. Sites on `InMemoryAuto` have no committed generated files
and skip this step.

## Two ways to fix

### Option A: Mass find-and-replace

Find: `IPublishedSnapshotAccessor`
Replace: `IPublishedContentTypeCache`

Apply across all `*.generated.cs` files in the Models project.

**When to choose this:**
- Smaller sites (under ~50 doc types)
- You want to keep git history of the generated files

### Option B: Nuke and regenerate

1. Delete all `*.generated.cs` files from the Models project
2. Temporarily move all Views out of the project (cut `Views/` to a sibling folder)
3. Get the site to boot (run `dotnet run`)
4. In the v17 backoffice, trigger a ModelsBuilder rebuild (Settings → Models Builder → Generate Models)
5. Copy the new generated files back, then move Views back into the project

**When to choose this:**
- Larger sites where mass-replace risks missing edge cases
- You'd rather have models freshly regenerated against the v17 schema
- Doc types have changed significantly between when models were last generated and now

Option B is generally less painful for larger sites despite the extra steps — Views being in the
project during boot causes the most cascade-failures, so getting them out of the way until the site
is stable simplifies everything.

## ModelsBuilder configuration in `appsettings.json`

Confirm `ModelsBuilder` settings are intact (these don't change between v13 and v17 but worth
checking):

```json
"ModelsBuilder": {
  "AcceptUnsafeModelsDirectory": true,
  "DebugLevel": 0,
  "FlagOutOfDateModels": false,
  "IncludeVersionNumberInGeneratedModels": false,
  "ModelsDirectory": "~/../MySite.Models/Generated/",
  "ModelsMode": "SourceCodeAuto",
  "ModelsNamespace": "MySite.Models.Generated"
}
```

- `ModelsMode: SourceCodeAuto` — models are written to disk and regenerated automatically on schema
  changes.
- `ModelsDirectory` points to the Models project's `Generated/` folder via a relative path.
- `MySite.Models` is a placeholder — keep your site's existing Models project name and namespace.

## Verifying

After the fix, do a clean ModelsBuilder build:

```
dotnet clean
dotnet build
```

The build should succeed with no `IPublishedSnapshotAccessor` errors. If you go with Option B,
verify the new generated files are in the Models project's `Generated/` folder.

## Edge cases

- **Custom code referencing `IPublishedSnapshotAccessor` outside generated files.** Search the
  whole solution — composers, services, and helpers may also reference it. They need updating to
  `IPublishedContentTypeCache` too, but the API is similar enough that the fix is usually mechanical.
- **`IPublishedSnapshot` references.** Less common but possible. The replacement depends on what the
  code was doing — sometimes `IPublishedContentCache`, sometimes `IPublishedContentTypeCache`. Check
  the Umbraco v17 docs for the specific API.
