# Views: dictionary values and nested sections

## 1. Dictionary helpers

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

## 2. Nested section frontend bug

In v17, sections nested inside other sections render with extra wrapper markup that breaks the
intended layout. The fix is in `Views/Partials/blockgrid/Components/SectionContent.cshtml` — check
your v17 starter template or reference project's version of this file and bring across whatever
delta exists.

The fix is typically a conditional that skips outer-wrapper rendering when the current section is
already inside another section. Don't try to recreate from memory — copy from the template.

## Verifying

1. Search for `GetDictionaryValue(` — there should be no matches (the `GetDictionaryValueOrDefault(`
   form doesn't match this pattern)
2. Spot-check 5+ pages on a running v17 site for correctly-rendered dictionary values
3. Sections render without extra wrapper divs (no nested-section bug), and block grid frontend
   rendering is intact
