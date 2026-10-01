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
- [ ] After a site restart, the homepage still renders correctly with no missing sections or blocks
      (the content-rendering bug only shows after a restart)
- [ ] Nav state matches v13 (no stray items that should be hidden, no missing items that should be shown)
- [ ] Spot-check 5+ random content pages: all blocks render, and the backoffice shows no
      `"Property editor with alias '…' is not available"` messages
- [ ] 3rd-party data type linkages (HubSpot Form Picker, etc.) all resolved
- [ ] Block labels / `nameTemplate` show real values in the editor, with no literal `{{ ... }}`
      (search `uSync/v17/DataTypes/` for `{{` — no matches)
- [ ] Templates show up in the backoffice (no fall-through to `/404`)
- [ ] Media library and other List View nodes open without an `orderBy` toast error

## Backoffice

- [ ] Backoffice info partials render across all block types, in the site's theme colours (not default
      grey)
- [ ] SCSS build produces `blockpreview.css`, the block grid editor preview renders styled, and (if
      the project runs stylelint) `.stylelintcache` is in `.gitignore`
- [ ] RTE shows Word Count, new toolbar layout, correct max image size, Uploads folder
- [ ] Link Picker is available in TipTap
- [ ] BlockPreview is **disabled** for BlockList (check `appsettings.json`)
- [ ] YouTube embeds work in the backoffice (Referrer-Policy override present in `Program.cs`)

## Frontend

- [ ] `@Umbraco.GetDictionaryValue` calls all migrated to `GetDictionaryValueOrDefault`
- [ ] Nested sections render without extra wrapper divs

## Forms

- [ ] Umbraco Forms templates merged with v13 customisations
- [ ] `Umbraco:Forms:FieldTypes:RichText:DataTypeId` in `appsettings.json` matches the key of an existing
      TipTap data type (check after the final uSync import)
- [ ] Test form submission end-to-end (including reCAPTCHA if enabled)

## Final

- [ ] uSync clean export committed to `feature/v17`
- [ ] PR description includes the package audit notes
- [ ] At least one team member has reviewed the diff
