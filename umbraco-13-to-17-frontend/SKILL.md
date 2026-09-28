---
name: umbraco-13-to-17-frontend
description: |
  Migrates the visitor-facing views of an Etch CMS site from Umbraco 13 to Umbraco 17. Use this skill for
  any Razor view, tag helper, dictionary value, Umbraco Forms template, or frontend CSP work in a v13→v17
  upgrade. Covers the our-X to etch-cms-X tag helper rename, <etch-cms-img> sizing parameters,
  dictionary keys rendering verbatim, the nested-section BlockGrid rendering fix, Umbraco Forms template
  merging, and the CIVIC cookie banner style-src rule.
  Trigger on phrases like "migrate our-img tags to v17", "etch-cms-img sizing", "dictionary keys showing
  on the page", "GetDictionaryValue v17", "nested sections broken on the frontend", "Umbraco Forms v17
  templates", "form not submitting after upgrade", "cookie banner missing after v17", or whenever a user
  mentions visitor-facing rendering symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Frontend Migration

If a site visitor would notice it, it belongs here. Other tracks are owned elsewhere:

- RTE, block previews and labels, backoffice info, backoffice SCSS → `umbraco-13-to-17-backoffice`
- `.csproj`, `Program.cs`, build errors → `umbraco-13-to-17-backend`
- uSync, content, data types → `umbraco-13-to-17-database`

## Order of operations

1. **Tag helpers and dictionary values** — migrate `<our-X>` → `<etch-cms-X>`, update
   `<etch-cms-img>` sizing, and replace `GetDictionaryValue` calls. This is the biggest mechanical
   sweep. See `references/taghelpers-migration.md`.
2. **Views and CSP** — nested-section BlockGrid fix, CIVIC cookie banner `style-src`. See
   `references/views-and-csp.md`.
3. **Umbraco Forms** — merge v13 customisations into the v17 form templates. See
   `references/umbraco-forms.md`.

Do step 1 **before any QA pass**. The dictionary change in particular makes pages look broken in
ways that generate false "missing content" bug reports.

When your response draws on one of the reference files above, name it explicitly — e.g. "Full details in `references/taghelpers-migration.md`" — so the user knows where to look for more context.
