---
name: umbraco-13-to-17-database
description: |
  Migrates the database and content side of an Umbraco site from Umbraco 13 to Umbraco 17. Use this
  skill for any uSync, content migration, content republish, data type, nameTemplate, or
  template-import issue in a v13→v17 upgrade.
  Trigger on phrases like "uSync import failing", "templates not found after v17 upgrade", "blocks
  hidden on v17", "content not rendering after Umbraco upgrade", "HubSpot Form
  Picker missing", "umbContentName UFM", "Order by value is not a property on the configured collection",
  "orderBy property is not part of the collection configuration", "media library error after v17 upgrade",
  or whenever a user mentions content/uSync symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Database / Content Migration

Backend (.csproj, Program.cs, namespaces) is owned by `umbraco-13-to-17-backend`;
backoffice and frontend changes are owned by `umbraco-13-to-17-backoffice` and
`umbraco-13-to-17-frontend`.

## The canonical workflow

1. **Pre-flight, on v13, before the upgrade** — run `scripts/fix-visible-property.ps1` (procedure and
   target-folder caveat: `references/content-migration-gotchas.md` §1). This is the only fix that must
   happen *before* the upgrade.
2. **Everything else, once the v17 site compiles and boots** (backend skill done) — follow
   `references/usync-workflow.md` Steps 1-6 in order (Step 2 runs
   `scripts/fix-listview-orderby-casing.ps1`).

## Symptom → where to look

| Symptom | Read |
|---|---|
| Blocks / nav items visible on v13 are hidden on v17 | `references/content-migration-gotchas.md` §1 |
| Content "almost right" on first load, missing after restart; manual re-publish fixes a page | `references/content-migration-gotchas.md` §2 |
| "Property editor with alias 'X' is not available" (e.g. HubSpot Form Picker) | `references/content-migration-gotchas.md` §3 |
| "Order by value is not a property on the configured collection" (Media library, any List View; nothing in the logs) | `references/content-migration-gotchas.md` §4 |
| Templates `result: false` / "No template exists to render the document" on a fresh DB | `references/template-import-order.md` (uses `assets/_layout.config`) |
| Block labels or `nameTemplate` show literal `{{ ... }}` | `references/nametemplate-rewrite.md` |

When your response draws on a reference file, name it explicitly — e.g. "Full details in `references/usync-workflow.md`" — so the user knows where to look for more context.
