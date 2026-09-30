---
name: umbraco-13-to-17-frontend
description: |
  Migrates the visitor-facing views of an Umbraco site from Umbraco 13 to Umbraco 17. Use this skill for
  any Razor view, dictionary value or Umbraco Forms template work in a v13→v17 upgrade. Covers
  dictionary keys rendering verbatim (GetDictionaryValue → GetDictionaryValueOrDefault), the
  nested-section BlockGrid rendering fix, and Umbraco Forms template merging.
  Trigger on phrases like "dictionary keys showing on the page", "GetDictionaryValue v17", "nested
  sections broken on the frontend", "Umbraco Forms v17 templates", "form not submitting after upgrade",
  or whenever a user mentions visitor-facing rendering symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Frontend Migration

If a site visitor would notice it, it belongs here. Other tracks are owned elsewhere:

- RTE, block previews and labels, backoffice info, backoffice SCSS → `umbraco-13-to-17-backoffice`
- `.csproj`, `Program.cs`, build errors → `umbraco-13-to-17-backend`
- uSync, content, data types → `umbraco-13-to-17-database`

## Order of operations

1. **Views** — replace `GetDictionaryValue` calls and apply the nested-section BlockGrid fix. See
   `references/views.md`.
2. **Umbraco Forms** — merge v13 customisations into the v17 form templates. See
   `references/umbraco-forms.md`.

Do step 1 **before any QA pass**. The dictionary change in particular makes pages look broken in
ways that generate false "missing content" bug reports.

When your response draws on one of the reference files above, name it explicitly — e.g. "Full details in `references/views.md`" — so the user knows where to look for more context.
