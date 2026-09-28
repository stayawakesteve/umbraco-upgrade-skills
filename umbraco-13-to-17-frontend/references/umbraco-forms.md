# Umbraco Forms v17 template merge

Umbraco Forms v17 ships updated default templates. Any v13 customisations of Forms templates need
merging into the v17 versions — you can't just overwrite (you'd lose your customisations) or just
keep the v13 versions (they'll break against v17 Forms APIs).

## What changes between v13 and v17 Forms templates

The v17 templates have:

- Updated HTML structure (some wrapper element changes)
- New accessibility attributes
- Tweaks to client-side validation hooks
- Field type rendering adjustments for new field types

Diffing a clean v17 install's `Views/Partials/Forms/Themes/default/` against the v13 versions shows
the deltas. Most are small.

## The merge process

For each customised v13 template:

1. **Identify the customisation.** What's different from the stock v13 template? (Custom classes,
   additional markup, restructured layout, etc.)
2. **Get the v17 stock version** from the v17 Forms package (search NuGet packages for
   `Umbraco.Forms` and find the templates folder).
3. **Apply the same customisation** to the v17 stock version — don't try to apply v17 changes to
   the customised v13 version; that direction loses things.
4. **Replace** the customised v13 template with your newly-customised v17 version.

## Common customisations to watch for

- **Custom wrapper classes** on form/field elements — easy to bring across, just re-add
- **Custom field type partials** (e.g. a custom Date field renderer) — check that the v17 Forms
  field type interface hasn't changed; if it has, you may need to rewrite the partial
- **JavaScript hooks** attached to specific class names — verify the class names still match in
  v17, since some have changed

## Where Forms templates live

```
Views/Partials/Forms/Themes/default/
├── Form.cshtml
├── Fields/
│   ├── FieldType.Checkbox.cshtml
│   ├── FieldType.Date.cshtml
│   ├── FieldType.FileUpload.cshtml
│   ├── ...
│   └── FieldType.Textarea.cshtml
├── Page.cshtml
└── ...
```

If the site has a custom Forms theme (e.g. `Views/Partials/Forms/Themes/etch-default/`), apply the
same merge process to that theme's templates.

## Verifying

After the merge:

1. Open the backoffice and rebuild any forms (just to flush caches)
2. On the frontend, load a page containing a form and verify:
   - Form renders correctly
   - All fields show with expected styling
   - Client-side validation works (try submitting an invalid form)
   - Submission succeeds (test end-to-end including any reCAPTCHA)
3. Check the form's submission appears correctly in the backoffice Entries view

## Common bugs after migration

- **Submissions silently failing** — usually a JavaScript error in client-side validation; check
  the browser console
- **reCAPTCHA not appearing** — confirm the SiteKey/PrivateKey are still set in `appsettings.json`
  under `Umbraco.Forms.FieldTypes.Recaptcha3`
- **Custom field types rendering as plain text** — the field type partial's `@model` declaration
  may have changed in v17; check against the v17 Forms package interface
