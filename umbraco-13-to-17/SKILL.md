---
name: umbraco-13-to-17
description: |
  End-to-end orchestrator for upgrading an Etch CMS / Umbraco site from v13 to v17. Use this skill whenever
  the user is starting, planning, or part-way through a v13→v17 upgrade and needs the big-picture sequence:
  feature branch setup, package retargeting, namespace fixes, ModelsBuilder rebuild, uSync export/fix/import,
  content republish, backoffice and frontend changes, and final verification. Trigger on phrases like "upgrade
  Umbraco 13 to 17", "v13 to v17 migration", "upgrade Etch CMS to v17", "where do I start with the Umbraco
  upgrade", or whenever a user names both v13 and v17 in the same request. Use this skill even when the user
  has only vaguely indicated they want to upgrade — it provides the routing into the four specialised
  sub-skills (`umbraco-13-to-17-backend`, `umbraco-13-to-17-database`, `umbraco-13-to-17-backoffice`,
  `umbraco-13-to-17-frontend`).
---

# Umbraco 13 → 17 Upgrade (Etch CMS)

This skill orchestrates a v13→v17 upgrade of an Etch CMS site. It is the **entry point** when someone says
"upgrade this site" — your job is to understand which stage they're at, route them to the right sub-skill,
and keep the big picture coherent.

## What this upgrade is (and isn't)

The v13→v17 jump is genuinely a **four-track migration** that happens to share a codebase:

1. **Backend** — `.csproj` retargets to `net10.0`, packages bump to v17-compatible versions, `Program.cs`
   gains new initialisations (Contentment in particular), and ModelsBuilder needs a namespace fix.
2. **Database / content** — uSync export → fix scripts → re-import, with a republish dance to work
   around content-rendering bugs introduced by the migration.
3. **Backoffice** — the v17 backoffice rewrite (Lit-based) changes the editor experience: RTE/TipTap
   config, block previews and labels, backoffice info partials and SCSS, and the backoffice CSP.
4. **Frontend** — the visitor-facing views: `<our-X>` tags become `<etch-cms-X>`, dictionary lookups
   change behaviour, Umbraco Forms templates need merging, and a couple of rendering/CSP fixes.

Doing them out of order **wastes time**: e.g. exporting uSync from a site that still won't compile
gives you stale data; running the visible-fix script *after* the v17 import is too late.

## The canonical sequence

Follow this order. Each step links to the sub-skill that owns the detail.

### Step 0 — Pre-flight (do not skip)

Before you change a line of code:

- **Fix uSync content on the v13 side first.** Run `fix-visible-property.ps1` against `uSync\v9\Content`
  (yes, "v9" — that's the historical folder name) on the v13 branch, commit, and re-import. This is the
  *only* fix that needs to happen pre-upgrade. See `umbraco-13-to-17-database` → `scripts/`.
- **Branch off `main`.** Create `feature/v17` from the current v13 `main`.
- **Audit package compatibility.** List every NuGet package in the v13 `.csproj` and check whether each has
  a v17 release. Anything without a v17 equivalent needs a replacement plan *before* you start editing
  files — there's no point retargeting the project if you'll be ripping out three packages anyway.

Read `references/pre-flight-checklist.md` for the full list.

### Step 1 — Backend retarget (gets the site compiling)

Hand off to **`umbraco-13-to-17-backend`**. That skill covers:

- Retargeting `.csproj` to `net10.0` and updating package versions
- Updating `Program.cs` to the v17 shape (Contentment registration, etc.)
- The ModelsBuilder `IPublishedSnapshotAccessor` → `IPublishedContentTypeCache` mass replace
- The `RazorSourceGenerator` duplicate-`hintName` build error
- `appsettings.json` v17 changes

**Goal of this step:** site compiles and boots against the v13 database. Don't try to fix everything else
yet — get a clean build first.

### Step 2 — Rebuild ModelsBuilder, then full uSync export

Once the site boots:

1. Do a clean ModelsBuilder build (delete `*.generated.cs` if you took that route) so models match v17.
2. Do a **clean, full uSync export** from the running v17 site against the v13 DB. This writes the latest
   uSync files into `uSync/v17/`.

This is the bridge between steps 1 and 3 — without a fresh export, the next step has nothing to fix.

### Step 3 — DB / content migration

Hand off to **`umbraco-13-to-17-database`**. That skill covers:

- The MNTP filter UDI → GUID transformation (`transform-mntp-filter-udis-to-guids.ps1`)
- The `nameTemplate` AngularJS → UFM rewrite (`{{ value | ncNodeName }}` → `{umbContentName: value}`)
- The List View `orderBy` casing fix (`fix-listview-orderby-casing.ps1`)
- Re-linking 3rd-party data types whose property editor changed (HubSpot Form Picker etc.)
- The "delete home node, force re-publish via uSync" workaround for the content-not-rendering bug
- The master template ordering gotcha (`_layout.config` prefix trick)

### Step 4 — Backoffice and frontend

These are two sub-skills that touch different files, so they can run in parallel.

**Backoffice** — hand off to **`umbraco-13-to-17-backoffice`**. That skill covers:

- `blockpreview.scss`, backoffice info partials and SCSS, picker styles, `.umb-block-grid` cleanup
- RTE config (Word Count, toolbar layout, image sizing, Uploads media folder), Link Picker prop for TipTap
- BlockPreview disabled on BlockList, UFM block labels
- YouTube backoffice CSP fix

**Frontend** — hand off to **`umbraco-13-to-17-frontend`**. That skill covers:

- `<our-X>` → `<etch-cms-X>` tag rewrites and the latest Etch.Cms.TagHelpers
- `@Umbraco.GetDictionaryValue` → `@Umbraco.GetDictionaryValueOrDefault`
- The nested-section BlockGrid frontend fix
- Umbraco Forms template merge and the CIVIC cookie banner CSP rule

You *can* run Step 4 in parallel with Step 3 if you have a second pair of hands — they touch different
files. Solo, do Step 3 first because content issues block QA. Within Step 4, do the frontend
dictionary change before any QA pass — it causes false "missing content" reports.

### Step 5 — Verify

Read `references/done-checklist.md`. The site isn't "upgraded" just because it boots — verify each of:
homepage renders correctly, nav state matches v13, all content blocks visible, forms submit, CSP
console-clean, RTE config matches design.

## When the user is mid-upgrade

If the user says something like "my templates aren't importing" or "blocks are showing as hidden",
**don't restart from Step 0**. Skip directly to the sub-skill that owns that symptom:

- Build errors, missing namespaces, package conflicts → `umbraco-13-to-17-backend`
- uSync import failures, missing content, wrong visibility, template not found, List View `orderBy` errors → `umbraco-13-to-17-database`
- Editor-facing: RTE/TipTap, block previews or labels, backoffice info, backoffice SCSS, YouTube in the RTE → `umbraco-13-to-17-backoffice`
- Visitor-facing: tag helpers, dictionary keys on the page, nested sections, Forms, cookie banner → `umbraco-13-to-17-frontend`

## Things this skill deliberately does NOT do

- **Doesn't run NuGet package updates for you.** Listing the v17-compatible version of every package
  is project-specific; the backend skill explains *which* packages and what's changed, but the actual
  versioning happens in `Directory.Packages.props` and is per-project.
- **Doesn't migrate content automatically.** uSync export/import is a manual, supervised process —
  the scripts fix specific bugs, but you still need to eyeball the diffs.
- **Doesn't cover greenfield v17 setup.** This is for *upgrading* an existing v13 site. For a new build
  use the latest Etch.Cms v17 template directly.

## Reference files

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/pre-flight-checklist.md`" — so the user knows where to look for more context.

- `references/pre-flight-checklist.md` — the full list before you start
- `references/done-checklist.md` — what to verify before merging `feature/v17` to `main`
