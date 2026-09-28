# Views and frontend CSP

The frontend fixes that don't fit cleanly into "tag helpers" or "Umbraco Forms". Small, but each
one shows up as a visible bug on the live site if missed.

## 1. Nested section frontend bug

In v17, sections nested inside other sections render with extra wrapper markup that breaks the
intended layout. The fix is in `Views/Partials/blockgrid/Components/SectionContent.cshtml` — check
the v17 Etch.Cms template's version of this file and bring across whatever delta exists.

The fix is typically a conditional that skips outer-wrapper rendering when the current section is
already inside another section. Don't try to recreate from memory — copy from the template.

## 2. CIVIC cookie banner still needs `unsafe-inline` style-src

The site's CSP needs to keep `style-src 'unsafe-inline'` for the CIVIC Cookie Control widget to
render. In `Program.cs`:

```csharp
app.UseFrontEndSecurityHeaders(configureCsp: builder =>
    // UnsafeInline required for CIVIC
    builder.AddStyleSrc()
        .UnsafeInline()
        .OverHttps()
        .Self());
```

Keep the inline comment — without it, the next person tightening CSP will remove `UnsafeInline`
and break the cookie banner. Tightening CSP further requires moving CIVIC styles into a CSP-friendly
configuration, which is a separate piece of work.

The code lives in `Program.cs`, so the full context is in `umbraco-13-to-17-backend` →
`references/program-cs-v17.md`. It's listed here because the symptom (a missing or unstyled cookie
banner) is visitor-facing.

## Verifying

Load the frontend and check:

- Sections render without extra wrapper divs (no nested-section bug)
- Block grid frontend rendering is intact
- The CIVIC cookie banner appears, styled, with no CSP errors in the browser console
