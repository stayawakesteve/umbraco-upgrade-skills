# `appsettings.json` (v17 conventions)

Most of `appsettings.json` is unchanged from v13. This file documents the differences, the things
worth verifying, and the canonical v17 shape for any sections that may need creating.

## Sections to verify exist / are correct

### `BlockPreview.BlockList.Enabled` = `false`

This is a v17 default the upgrade should adopt:

```json
"BlockPreview": {
  "BlockGrid": {
    "Enabled": true,
    "Stylesheet": "/css/blockpreview.css",
    "ViewLocations": ["~/Views/Partials/blockgrid/Components/{0}.cshtml"]
  },
  "BlockList": {
    "Enabled": false
  }
}
```

In v13, BlockPreview was often enabled for BlockList. In v17, it should be **off** for BlockList —
the v17 backoffice has its own preview behaviour that fights with BlockPreview. Leaving it on
causes weird double-render artifacts in the BlockList editor.

The frontend skill (`umbraco-13-to-17-backoffice-frontend`) covers this in more detail; this is
just the config side.

### `Etch.Cms.Umbraco.TagHelpers.OurIMG`

Despite the tag name moving from `<our-img>` to `<etch-cms-img>`, the **config section is still
called `OurIMG`**. Confirmed in the v17 template:

```json
"Etch.Cms.Umbraco.TagHelpers": {
  "OurIMG": {
    "MobileFirst": true,
    "UseNativeLazyLoading": true,
    "ApplyAspectRatio": false,
    "AlternativeTextMediaTypePropertyAlias": "altText"
  }
}
```

Don't try to "fix" this by renaming the key — the package looks for `OurIMG` and you'll break tag
helper config if you change it.

### `uSync.Publisher` settings

v17 uSync uses an `AppId` / `AppKey` pair instead of older auth styles:

```json
"uSync": {
  "Publisher": {
    "Settings": {
      "IncomingEnabled": true,
      "AppId": "7a2ef374-1017-4691-abbf-fac1716f8e74",
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
