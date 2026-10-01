---
name: umbraco-13-to-17-backoffice
description: |
  Migrates the editor-facing backoffice customisations of an Umbraco site from Umbraco 13 to Umbraco 17.
  Use this skill for any RTE/TipTap, BlockPreview, block label, backoffice info, backoffice SCSS, or
  backoffice CSP work in a v13→v17 upgrade. Trigger on phrases like "v17 RTE config", "TipTap link
  picker", "BlockPreview broken on BlockList", "backoffice info partial", "backoffice info showing
  grey", "block labels showing raw {{ }} syntax", "YouTube embeds blocked in backoffice", or whenever
  a user mentions editor/backoffice symptoms in a v13→v17 context. Not for views, dictionary values or Umbraco Forms (umbraco-13-to-17-frontend),
  build errors (umbraco-13-to-17-backend), or uSync/content (umbraco-13-to-17-database).
---

# Umbraco 13 → 17 Backoffice Migration

If an editor would notice it and a site visitor wouldn't, it belongs here. Other tracks are owned
elsewhere:

- Views, dictionary values, Umbraco Forms → `umbraco-13-to-17-frontend`
- `.csproj`, `Program.cs`, build errors → `umbraco-13-to-17-backend`
- uSync, content, data types → `umbraco-13-to-17-database`

## Order of operations

These are roughly independent, but doing them in this order minimises rework:

1. **Backoffice SCSS** — `blockpreview.scss`, backoffice info SCSS colours, `.stylelintcache` in
   `.gitignore`.
   See `references/scss-and-partials.md`.
2. **RTE config** — Word Count, toolbar layout, max image size, Uploads folder, Link Picker
   prop for TipTap. See `references/rte-config.md`.
3. **Blocks** — BlockPreview off for BlockList (double-render / stuck-preview in the
   BlockList editor), backoffice info partials applied to all blocks. See
   `references/blocks-and-pickers.md`.

When your response draws on one of the reference files above, name it explicitly — e.g. "Full details in `references/rte-config.md`" — so the user knows where to look for more context.

## Block labels showing raw `{{ }}` syntax

Block labels moved from AngularJS to UFM. Syntax mapping, regexes, and when to use the UI or
mass-edit the uSync files: `umbraco-13-to-17-database` → `references/nametemplate-rewrite.md`.

## YouTube backoffice CSP error

If editors report YouTube embeds failing in the backoffice TipTap RTE with a CSP/referrer error,
the fix is in `Program.cs` — see `umbraco-13-to-17-backend` → `references/program-cs-v17.md`,
section "YouTube backoffice CSP middleware". (The default, tighter Referrer-Policy blocks the YouTube
embed's referrer-based auth.)
