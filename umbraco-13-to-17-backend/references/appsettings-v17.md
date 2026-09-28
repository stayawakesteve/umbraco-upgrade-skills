# `appsettings.json` (v17 conventions)

## Sections to verify exist / are correct

### `BlockPreview.BlockList.Enabled` = `false`

Must be `false` in v17 (BlockGrid stays enabled). The config block and the reason live in
`umbraco-13-to-17-backoffice` → `references/blocks-and-pickers.md` §1.

### `Etch.Cms.Umbraco.TagHelpers.OurIMG`

Keep the key named `OurIMG` despite the `<our-img>` → `<etch-cms-img>` rename, because the package
looks it up by that name — renaming it breaks tag helper config. The config block is in
`umbraco-13-to-17-frontend` → `references/taghelpers-migration.md` Step 5.

### `uSync.Publisher` settings

v17 uSync uses an `AppId` / `AppKey` pair instead of older auth styles:

```json
"uSync": {
  "Publisher": {
    "Settings": {
      "IncomingEnabled": true,
      "AppId": "<unique-guid-per-environment>",
      "AppKey": "!!! Use dotnet user-secrets !!!"
    }
  },
  "Settings": {
    "ExportOnSave": "Settings",
    "ShowVersionCheckWarning": false
  },
  "People": {
    "EnabledDefault": true
  }
}
```

Notes:
- `AppId` is per-environment — generate a fresh GUID for each site
- `AppKey` should be set via `dotnet user-secrets`, never committed
- `ExportOnSave: "Settings"` exports settings (doc types, data types, templates) on save but not
  content — content is exported on demand

### Umbraco Forms RichText data type

```json
"Umbraco": {
  "Forms": {
    "FieldTypes": {
      "Recaptcha3": {
        "SiteKey": "",
        "PrivateKey": ""
      },
      "RichText": {
        "DataTypeId": "43d21f90-63e4-4f82-a685-1e19307c9b2b"
      }
    }
  }
}
```

The `RichText.DataTypeId` is a specific GUID pointing at the data type used for Forms rich text
fields. This GUID is the same across Etch v17 installs (it's the Etch-curated TipTap config).

## Sections that are unchanged from v13

These work identically in v17 — no migration needed, but worth confirming they're present:

- `Serilog` minimum levels and `UmbracoFile` write target
- `Etch.TrailingSlashes.Keep: true`
- `Umbraco.CMS.Content.LoginBackgroundImage`, `LoginLogoImage`, `LoginLogoImageAlternative`
- `Umbraco.CMS.Examine.LuceneDirectoryFactory: "SyncedTempFileSystemDirectoryFactory"` —
  required for Azure App Service deployments
- `Umbraco.CMS.Global.MainDomLock: "FileSystemMainDomLock"`
- `Umbraco.CMS.Global.UseHttps: true`
- `Umbraco.CMS.Hosting.LocalTempStorageLocation: "EnvironmentTemp"`
- `Umbraco.CMS.RequestHandler.AddTrailingSlash: false`
- `Umbraco.CMS.Security.AllowConcurrentLogins: true`
- `Umbraco.CMS.TypeFinder.AdditionalAssemblyExclusionEntries` — the NSwag/dotnet-nswag exclusions
- `ModelsBuilder` settings (covered separately in `modelsbuilder-fixes.md`)
- `Umbraco.Storage.AzureBlob.Media` connection string config

## Sections to confirm are present (template-specific)

The v17 Etch template sets these — older v13 sites may not have them:

```json
"Umbraco": {
  "CMS": {
    "Global": {
      "Id": "<unique-guid-per-site>"
    },
    "Content": {
      "AllowEditInvariantFromNonDefault": true,
      "ContentVersionCleanupPolicy": {
        "EnableCleanup": true
      }
    }
  }
}
```

`Global.Id` should be a unique GUID per environment — used internally for telemetry / version checks.
Generate one if it's missing.

`ContentVersionCleanupPolicy.EnableCleanup: true` keeps the database from bloating with old content
versions. New default in v13+; some v13 sites may have it disabled — turn it on.

## Schema reference

The `$schema` at the top of the file is worth keeping — it gives editor autocomplete:

```json
{
  "$schema": "appsettings-schema.json"
}
```

The schema file ships with Umbraco — don't try to download or commit it manually.
