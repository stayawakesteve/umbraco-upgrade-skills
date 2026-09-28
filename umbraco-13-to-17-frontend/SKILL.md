---
name: umbraco-13-to-17-frontend
description: |
  Migrates the visitor-facing views of an Etch CMS site from Umbraco 13 to Umbraco 17. Use this skill for
  any Razor view, tag helper, dictionary value, Umbraco Forms template, or frontend CSP work in a v13→v17
  upgrade. Covers the our-X to etch-cms-X tag helper rename, the latest Etch.Cms.TagHelpers,
  <etch-cms-img> sizing parameters, the OurIMG config key that must not be renamed, GetDictionaryValue
  replaced with GetDictionaryValueOrDefault, the nested-section BlockGrid rendering fix
  (SectionContent.cshtml), Umbraco Forms template merging, and the CIVIC cookie banner style-src rule.
  Trigger on phrases like "migrate our-img tags to v17", "etch-cms-img sizing", "dictionary keys showing
  on the page", "GetDictionaryValue v17", "nested sections broken on the frontend", "Umbraco Forms v17
  templates", "form not submitting after upgrade", "cookie banner missing after v17", or whenever a user
  mentions visitor-facing rendering symptoms in a v13→v17 context.
---

# Umbraco 13 → 17 Frontend Migration

This skill covers the visitor-facing side of the v17 upgrade: Razor views, tag helpers, dictionary
values, Umbraco Forms templates, and the frontend CSP. If a site visitor would notice it, it belongs
here.

Other tracks are owned elsewhere:

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

## The thing most people miss

`@Umbraco.GetDictionaryValue` is **not** removed in v17 but it now behaves differently when the key
doesn't exist — returns the literal key instead of empty. The correct method is now:

```cshtml
@Umbraco.GetDictionaryValueOrDefault("key-name", "fallback")
```

This is a project-wide find/replace. Don't skip — it makes pages render dictionary keys verbatim
when the value is empty, which is rarely what you want.

## Tag rewrites: `<our-X>` → `<etch-cms-X>`

The Etch.Cms.TagHelpers package renamed its prefix from `our-` to `etch-cms-` to align with the
package's actual ownership (the `our-` prefix was a holdover from the Umbraco community convention).

Common renames:

| v13                       | v17                            |
|---------------------------|--------------------------------|
| `<our-img>`               | `<etch-cms-img>`               |
| `<our-link>`              | `<etch-cms-link>`              |
| `<our-rich-text>`         | `<etch-cms-rich-text>`         |
| `<our-block-list>`        | `<etch-cms-block-list>`        |
| `<our-block-grid>`        | `<etch-cms-block-grid>`        |

**The migration of these tags is optional in the sense that the old tags still work** during a
transitional period, but the convention going forward is `etch-cms-`. Doing the find/replace as
part of the upgrade is much easier than half-migrating later.

**Sizing parameters on `<etch-cms-img>` changed.** Check the current Etch.Cms.TagHelpers docs and
update any `<etch-cms-img>` instances using old sizing attributes. The schema is documented in the
package readme — don't try to migrate from memory.

**One config gotcha:** the JSON config section is still called `OurIMG`, not `EtchCmsIMG`. This is
the package looking for `OurIMG` internally — don't try to "fix" it.

```json
"Etch.Cms.Umbraco.TagHelpers": {
  "OurIMG": {              // <-- stays as "OurIMG" despite the tag rename
    "MobileFirst": true,
    "UseNativeLazyLoading": true,
    "ApplyAspectRatio": false,
    "AlternativeTextMediaTypePropertyAlias": "altText"
  }
}
```

## The BlockGrid nested section frontend bug

After upgrading, sections nested inside other sections may render incorrectly on the frontend (extra
wrapper divs, broken layout). The fix is in `Views/Partials/blockgrid/Components/SectionContent.cshtml`
— see `references/views-and-csp.md` for the specific change.

## Reference files

- `references/taghelpers-migration.md` — `<our-X>` → `<etch-cms-X>`, `<etch-cms-img>` sizing,
  dictionary helpers, `OurIMG` config
- `references/views-and-csp.md` — nested-section BlockGrid fix, CIVIC cookie banner CSP
- `references/umbraco-forms.md` — Forms v17 template merge

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/taghelpers-migration.md`" — so the user knows where to look for more context.
