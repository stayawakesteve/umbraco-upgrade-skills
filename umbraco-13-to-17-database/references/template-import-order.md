# Template import order (the `_layout.config` trick)

## Symptom

On a **fresh** v17 database (rather than an upgraded v13 DB), uSync template import succeeds for
only some templates — typically just those with `Layout = null`. Every template using a master
layout silently fails to import.

The backoffice will then show:

> No template exists to render the document at URL '/'

…and content pages 404, because the templates they reference don't exist.

In the uSync log, failed templates appear as `result: false` with no exception.

**Concrete example:** `Robots.cshtml` uses `Layout = null` — it imports fine. Every other
template (e.g. `HomePage.cshtml`, `ContentPage.cshtml`) has `Layout = "Layout.cshtml"` — all of
them fail silently with `result: false`.

## Root cause

When uSync's `TemplateSerializer` imports a template, Umbraco's `TemplateService` parses the
`Layout` directive in the `.cshtml` content to resolve the master template relationship. Templates
reference the master layout as `Layout = "Layout.cshtml"`. If the `Layout` template doesn't
exist as an Umbraco template record in the database yet, the import fails.

## The fix

Add a uSync `.config` entry for the master layout template, named with a `_` prefix: uSync processes
files in alphabetical order within a folder and `_` sorts before any letter, so it is imported first
and every later `Layout = "Layout.cshtml"` reference resolves.

Copy `assets/_layout.config` to `uSync/v17/Templates/_layout.config` and replace `<new-guid>` with a
freshly-generated GUID. This is a deliberately **minimal** template
config — just enough to register the template in Umbraco so subsequent imports can reference it.
The full `.cshtml` content gets imported separately by the regular `Layout.config` file (which
sorts alphabetically after `_layout.config`).

The `Level="1"` indicates a root-level template. The `<Parent />` element is empty because the
master layout has no parent template.

## When you need this fix

- **Fresh v17 DB** — yes, you need it
- **v13 DB migrated to v17 schema** — usually not needed (the templates already exist from the v13
  install)
- **Restoring from a v13 DB backup to a v17 schema** — yes, you need it (templates may not
  re-register correctly)

If unsure, run the uSync import without the fix first and watch for the `result: false` entries
in the log. If templates are failing, add the fix.

## Alternative approaches considered

- **Importing templates in a separate pass before everything else** — uSync doesn't expose this
  as a granular option through the backoffice UI
- **Programmatically creating the Layout template before uSync runs** — possible via a startup
  composer, but the `_layout.config` trick is simpler and lives entirely in the uSync data

## Verifying

After applying the fix and re-importing:

1. Settings → Templates — confirm `Layout` is present
2. Settings → Templates → click into `Layout` — confirm the content matches your `Layout.cshtml`
3. Navigate to the homepage — should render correctly (no "No template exists" error)
4. uSync log should show all templates importing with `result: true`
