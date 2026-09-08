---
name: umbraco-13-to-17-backoffice-frontend
description: |
  Migrates Etch CMS backoffice and frontend customisations from Umbraco 13 to Umbraco 17. Use this skill
  for any view, SCSS, tag helper, RTE/TipTap, BlockPreview, block label, or backoffice CSP work in a
  v13→v17 upgrade. Covers the our-X to etch-cms-X tag helper rename, the latest Etch.Cms.TagHelpers,
  blockpreview.scss imports, section partials, backoffice info SCSS, the nested-section BlockGrid fix,
  RTE config (Word Count, toolbar, image sizing, Uploads folder), GetDictionaryValue replaced with
  GetDictionaryValueOrDefault, BlockPreview disabled on BlockList, UFM block labels, Link Picker prop
  for TipTap, YouTube backoffice CSP fix, and Umbraco Forms template merging. Trigger on phrases like
  "migrate our-img tags to v17", "v17 RTE config", "TipTap link picker", "BlockPreview broken on
  BlockList", "backoffice info partial", "v17 SCSS migration", "YouTube embeds blocked in backoffice",
  "Umbraco Forms v17 templates", or whenever a user mentions backoffice/frontend symptoms in a v13→v17
  context.
---

# Umbraco 13 → 17 Backoffice / Frontend Migration

This skill covers the cosmetic and editor-facing side of the v17 upgrade: tag helpers, SCSS, RTE
config, block previews, partials, and CSP. Backend (.csproj, Program.cs) is owned by
`umbraco-13-to-17-backend`. Content/DB (uSync) is owned by `umbraco-13-to-17-db-content`.

## Order of operations

These are roughly independent, but doing them in this order minimises rework:

1. **Tag helpers** — migrate `<our-X>` → `<etch-cms-X>` and update `GetDictionaryValue` calls.
   This is the biggest mechanical sweep. See `references/taghelpers-migration.md`.
2. **SCSS and partials** — `blockpreview.scss`, section partials, backoffice info SCSS, nested
   section BlockGrid fix. See `references/scss-and-partials.md`.
3. **RTE config** — Word Count, toolbar layout, max image size, Uploads folder, Link Picker
   prop for TipTap. See `references/rte-config.md`.
4. **Blocks, labels, CSP** — BlockPreview off for BlockList, UFM block labels, backoffice info
   partials applied to all blocks, YouTube CSP fix. See `references/blocks-and-pickers.md`.
5. **Umbraco Forms** — merge v13 customisations into v17 form templates. See
   `references/umbraco-forms.md`.

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
— see `references/scss-and-partials.md` for the specific change.

## YouTube backoffice CSP error

If editors report YouTube embeds failing in the backoffice TipTap RTE with a CSP/referrer error,
the fix is in `Program.cs` — see `umbraco-13-to-17-backend` → `references/program-cs-v17.md`,
section "YouTube backoffice CSP middleware". It needs adding to `Program.cs` to override the
Referrer-Policy header for `/umbraco` routes.

## Reference files

- `references/taghelpers-migration.md` — `<our-X>` → `<etch-cms-X>` and dictionary helpers
- `references/scss-and-partials.md` — blockpreview.scss, section partials, backoffice info SCSS,
  BlockGrid nested fix, picker style migration
- `references/rte-config.md` — RTE/TipTap Word Count, toolbar, image sizing, Uploads folder,
  Link Picker prop
- `references/blocks-and-pickers.md` — BlockPreview/BlockList config, UFM labels, block backoffice
  info partials
- `references/umbraco-forms.md` — Forms v17 template merge

When your response draws on one of these files, name it explicitly — e.g. "Full details in `references/taghelpers-migration.md`" — so the user knows where to look for more context.
