# `RazorSourceGenerator` duplicate `hintName` fix

If your build is producing a warning like:

```
CSC : warning CS8785: Generator 'RazorSourceGenerator' failed to generate source. It will not
contribute to the output and compilation errors may occur as a result. Exception was of type
'ArgumentException' with message 'The hintName 'Views_Partials_Sitemap_cshtml.g.cs' of the
added source file must be unique within a generator. (Parameter 'hintName')'
```

…it's because **two `.cshtml` files with the same name and path exist** — one in your project and one
shipped by a NuGet package. The Razor source generator tries to generate both and trips over the
collision.

## Why this didn't break v13

In v13, Razor compilation worked differently and would silently use one or the other (usually the
project-local file). In v17, the new source-generator-based Razor compilation refuses to disambiguate
— the generator throws, which surfaces only as the non-fatal warning above, but that view is not
generated, which usually cascades into runtime "template not found" errors.

## The fix

The version from the NuGet package is the canonical one — your project is duplicating it (usually because
someone copied a partial out of a package to override it long ago, then never cleaned up).

### Step 1: Identify the offending file

The warning includes the hintName, e.g. `Views_Partials_Sitemap_cshtml.g.cs`. Decode it:

- Replace `_` with `/` between the path segments (but keep the file name's underscores intact)
- `Views_Partials_Sitemap_cshtml` → `Views/Partials/Sitemap.cshtml`

So the offender is `Views/Partials/Sitemap.cshtml`.

### Step 2: Confirm the duplicate

Check whether your project has that file. If it does:

1. Search NuGet packages in your `~/.nuget/packages/` for the same path — typically inside a
   `content/` or `staticwebassets/` folder of an Umbraco-related package.
2. If you find a match, the NuGet copy is shipping it and your local one is the duplicate.

### Step 3: Delete the local file

Check git blame first — if the local copy is a deliberate customisation that's still needed, go to
"When you actually want to override the package's view" instead. Otherwise, delete the project-local
file. **Don't** delete the one in the NuGet package — it gets restored on every build.

After deletion, rebuild. The warning should go away.

## Common offenders

The views most likely to clash are partials that ship with packages — for example:

- `Views/Partials/Forms/...` — ships with `Umbraco.Forms`
- Any cookie banner, sitemap or navigation partial that ships with a package the site uses

## When you actually want to override the package's view

If the local file exists deliberately (customised cookie banner, custom sitemap, etc.), you can't keep
the duplicate. Three options:

1. **Rename it.** Change `Sitemap.cshtml` → `_SitemapOverride.cshtml` and update any references.
   The hintName collision goes away because the path is now different.
2. **Move it.** Same idea but a different folder, e.g. `Views/Partials/Custom/Sitemap.cshtml`.
3. **Configure the package to not ship its view.** Some packages have an option to suppress their
   default views; check the package docs. Less common.

The rename approach is usually quickest.
