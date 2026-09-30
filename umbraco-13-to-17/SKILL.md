---
name: umbraco-13-to-17
description: |
  End-to-end orchestrator for upgrading an Umbraco site from v13 to v17. Use this skill whenever
  the user is starting, planning, or part-way through a v13→v17 upgrade and needs the big-picture sequence,
  or doesn't yet know which stage-specific sub-skill applies. Trigger on phrases like "upgrade Umbraco 13
  to 17", "v13 to v17 migration", "where do I start with the Umbraco upgrade", or whenever a user names
  both v13 and v17 in the same request. Use this skill even when the user has only vaguely indicated
  they want to upgrade — it provides the routing into the four specialised sub-skills
  (`umbraco-13-to-17-backend`, `umbraco-13-to-17-database`, `umbraco-13-to-17-backoffice`,
  `umbraco-13-to-17-frontend`).
---

# Umbraco 13 → 17 Upgrade

Your job: work out which stage the user is at, route them to the right sub-skill, and keep the big
picture coherent.

## The canonical sequence

Follow this order. Each step links to the sub-skill that owns the detail. Doing them out of order
**wastes time**: e.g. exporting uSync from a site that still won't compile gives you stale data;
running the visible-fix script *after* the v17 import is too late.

### Step 0 — Pre-flight (do not skip)

Before you change a line of code, walk every item in `references/pre-flight-checklist.md`. §1 (running
`fix-visible-property.ps1` on v13) is the one item that can't be done later.

### Step 1 — Backend retarget (gets the site compiling)

Hand off to **`umbraco-13-to-17-backend`**. That skill covers:

- Retargeting `.csproj` to `net10.0` and updating package versions
- Updating `Program.cs` to the v17 shape (Contentment registration, etc.)
- The ModelsBuilder `IPublishedSnapshotAccessor` → `IPublishedContentTypeCache` mass replace
- The `RazorSourceGenerator` duplicate-`hintName` build error
- `appsettings.json` v17 changes

**Goal of this step:** site compiles and boots against the v13 database. Don't try to fix everything else
yet — get a clean build first.

### Step 2 — Rebuild ModelsBuilder

Once the site boots, do a clean ModelsBuilder build using the approach you chose in pre-flight §7. Then
go to Step 3, whose workflow starts with the full uSync export from the v17 site against the v13 DB.
Without that fresh export, Step 3 has nothing to fix.

### Step 3 — DB / content migration

Hand off to **`umbraco-13-to-17-database`**. That skill covers:

- The `nameTemplate` AngularJS → UFM rewrite
- The List View `orderBy` casing fix (`fix-listview-orderby-casing.ps1`)
- Re-linking 3rd-party data types whose property editor changed (HubSpot Form Picker etc.)
- The "delete home node, force re-publish via uSync" workaround for the content-not-rendering bug
- The master template ordering gotcha (`_layout.config` prefix trick)

### Step 4 — Backoffice and frontend

**Backoffice** (the v17 backoffice is a Lit-based rewrite of the v13 editor UI) — hand off to
**`umbraco-13-to-17-backoffice`**. That skill covers:

- `blockpreview.scss`, backoffice info partials and SCSS
- RTE config (Word Count, toolbar layout, image sizing, Uploads media folder), Link Picker prop for TipTap
- BlockPreview disabled on BlockList, UFM block labels
- YouTube backoffice CSP fix

**Frontend** — hand off to **`umbraco-13-to-17-frontend`**. That skill covers:

- `@Umbraco.GetDictionaryValue` → `@Umbraco.GetDictionaryValueOrDefault`
- The nested-section BlockGrid frontend fix
- Umbraco Forms template merge

Steps 3 and 4, and the two halves of Step 4, all touch different files, so with a second pair of hands
they can run in parallel. Solo, do Step 3 first because content issues block QA. Within Step 4, do the frontend
dictionary change before any QA pass — it causes false "missing content" reports.

### Step 5 — Verify

Read `references/done-checklist.md` and walk every item — the site isn't "upgraded" just because it boots.

## When the user is mid-upgrade

If the user says something like "my templates aren't importing" or "blocks are showing as hidden",
**don't restart from Step 0**. Skip directly to the sub-skill that owns that symptom:

- Build errors, missing namespaces, package conflicts → `umbraco-13-to-17-backend`
- uSync import failures, missing content, wrong visibility, template not found, List View `orderBy` errors → `umbraco-13-to-17-database`
- Editor-facing: RTE/TipTap, block previews or labels, backoffice info, backoffice SCSS, YouTube in the RTE → `umbraco-13-to-17-backoffice`
- Visitor-facing: dictionary keys on the page, nested sections, Forms → `umbraco-13-to-17-frontend`

## Things this skill deliberately does NOT do

- **Doesn't run NuGet package updates for you.** Listing the v17-compatible version of every package
  is project-specific; the backend skill explains *which* packages and what's changed, but the actual
  versioning happens in `Directory.Packages.props` and is per-project.
- **Doesn't migrate content automatically.** uSync export/import is a manual, supervised process —
  the scripts fix specific bugs, but you still need to eyeball the diffs.
- **Doesn't cover greenfield v17 setup.** This is for *upgrading* an existing v13 site. For a new build
  start from a fresh Umbraco 17 install.

## Reference files

When your response draws on `references/pre-flight-checklist.md` (Step 0) or `references/done-checklist.md` (Step 5), name it explicitly so the user knows where to look for more context.
