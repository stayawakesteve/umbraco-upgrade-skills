# Done checklist (v13 → v17)

The site compiles and boots. That doesn't mean it's done. Walk this list before merging `feature/v17`
into `main`.

## Build / boot

- [ ] `dotnet build` produces zero errors and zero warnings (or only known/acceptable warnings)
- [ ] No `CS8785` `RazorSourceGenerator` `hintName must be unique` warnings — if present, the
      duplicate-file fix in `umbraco-13-to-17-backend` hasn't been applied
- [ ] Site boots without errors in the log
- [ ] Backoffice loads at `/umbraco` and accepts login

## Content / DB

- [ ] uSync export from v17 produces files without errors
- [ ] All content nodes from v13 are present in v17
- [ ] Homepage renders correctly with no missing sections or blocks
- [ ] Nav state matches v13 (no stray items that should be hidden, no missing items that should be shown)
- [ ] Spot-check 5+ random content pages: all blocks render, no `"property editor cannot be found"`
      messages in backoffice
- [ ] 3rd-party data type linkages (HubSpot Form Picker, etc.) all resolved
- [ ] Templates show up in the backoffice (no fall-through to `/404`)
- [ ] MNTP filter properties resolve correctly (the UDI → GUID transform worked)
- [ ] Media library and other List View nodes open without an `orderBy` toast error

## Backoffice

- [ ] Backoffice info partials render across all block types
- [ ] RTE shows Word Count, new toolbar layout, correct max image size, Uploads folder
- [ ] Link Picker is available in TipTap
- [ ] BlockPreview is **disabled** for BlockList (check `appsettings.json`)

## Frontend

- [ ] No `<our-X>` tags remain — all migrated to `<etch-cms-X>` (or knowingly left)
- [ ] `@Umbraco.GetDictionaryValue` calls all migrated to `GetDictionaryValueOrDefault`
- [ ] `<etch-cms-img>` sizing parameters match current Etch.Cms.Umbraco.TagHelpers docs
- [ ] Nested sections render without extra wrapper divs

## CSP / security

- [ ] No CSP console errors on frontend
- [ ] YouTube embeds work in the backoffice (Referrer-Policy override present in `Program.cs`)
- [ ] CIVIC cookie banner still loads (unsafe-inline style-src kept)

## Forms

- [ ] Umbraco Forms templates merged with v13 customisations
- [ ] Test form submission end-to-end (including reCAPTCHA if enabled)

## Final

- [ ] uSync clean export committed to `feature/v17`
- [ ] PR description includes the package audit notes
- [ ] At least one team member has reviewed the diff
