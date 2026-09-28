# Tag helpers migration (`<our-X>` → `<etch-cms-X>`)

The Etch.Cms.Umbraco.TagHelpers package renamed its tag prefix from `our-` to `etch-cms-` (the rename aligns
the prefix with the package's actual ownership; `our-` was a holdover from the Umbraco community
convention). This is a project-wide rewrite that's mechanical but easy to miss instances of.

## Step 1: Upgrade the package

Make sure `Etch.Cms.Umbraco.TagHelpers` is on its latest v17-compatible release (updated with the
rest of the `.csproj` in `umbraco-13-to-17-backend` → `references/csproj-net10-retarget.md`). Old
`our-` tags continue to work during a transitional period — the package supports both — but the
convention going forward is `etch-cms-`. Doing the find/replace as part of the upgrade is much
easier than half-migrating later.

## Step 2: Find and replace

Tag-by-tag, across all `.cshtml` files. The common renames:

| v13 tag                   | v17 tag                        | Notes                                |
|---------------------------|--------------------------------|--------------------------------------|
| `<our-img>`               | `<etch-cms-img>`               | **Sizing parameters also changed — see below** |
| `<our-link>`              | `<etch-cms-link>`              |                                      |
| `<our-rich-text>`         | `<etch-cms-rich-text>`         |                                      |
| `<our-block-list>`        | `<etch-cms-block-list>`        |                                      |
| `<our-block-grid>`        | `<etch-cms-block-grid>`        |                                      |

There are others (depending on which Etch tag helpers the site uses) — check the package's
GitHub readme for the canonical list.

Use a regex find:

```
<(/?)our-(img|link|rich-text|block-list|block-grid)
```

Replace:

```
<$1etch-cms-$2
```

**The migration is bidirectional** — opening and closing tags. The capture group `$1` handles `/`
for closing tags.

## Step 3: `<etch-cms-img>` sizing parameters

The image sizing API changed. Check current Etch.Cms.Umbraco.TagHelpers docs for the precise schema —
this is the kind of thing that drifts between releases — but v13 used:

- `width-mobile`, `width-tablet`, `width-desktop` style attributes

Don't migrate from memory. **Find a single `<etch-cms-img>` you've already updated and confirm it
renders correctly before doing a bulk migration**, otherwise you risk replicating a mistake across
the whole site.

## Step 4: Dictionary helpers

`@Umbraco.GetDictionaryValue` is **not** removed in v17 but its behaviour with missing keys changed:
where it used to return empty, it now returns the literal key, which renders verbatim on the page.

Replace project-wide:

```cshtml
@Umbraco.GetDictionaryValue("key")
```

→

```cshtml
@Umbraco.GetDictionaryValueOrDefault("key", "")
```

…or use a sensible fallback string instead of `""` where appropriate.

This is one of those changes where the v13 behaviour was a bug-disguised-as-a-feature — pages would
silently render empty for missing keys, which masked content gaps. The v17 behaviour is more honest
but means any page with a typo'd dictionary key now displays "missing-key-typo" to end users.

## Step 5: `OurIMG` config (do not rename)

Despite the tag rename, the JSON config section in `appsettings.json` is still called `OurIMG`:

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

The package looks for `OurIMG` internally. Don't rename this — you'll break image rendering across
the site with no warning.

## Verifying

After the migration:

1. Search the codebase for `our-` — any remaining `<our-…>` tags need migrating (or are intentional
   non-Etch tags using `our-` for other reasons; rare but possible)
2. Search for `GetDictionaryValue(` — there should be no matches (the `GetDictionaryValueOrDefault(` form
   doesn't match this pattern)
3. Spot-check 5+ pages on a running v17 site for correctly-rendered images, links, and dictionary
   values
