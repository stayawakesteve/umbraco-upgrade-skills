# `Program.cs` (v17 shape)

The v17 `Program.cs` looks broadly familiar but has several specific shape changes that catch people
out. Use the v17 Etch.Cms template as the canonical reference, and pay attention to these specifics.

## Canonical structure

```csharp
using Etch.Cms.Umbraco.Blog.Extensions;
using Etch.Cms.Umbraco.Civic.Extensions;
using Etch.Cms.Umbraco.ContentBlocks.Extensions;
using Etch.Cms.Umbraco.Core.Extensions;
using Etch.Cms.Umbraco.Core.Features.ApplicationInsights;
using Etch.Cms.Umbraco.Core.Mvc.Extensions;
using Etch.Cms.Umbraco.Core.Mvc.StaticGeneration.Models;
using Etch.Cms.Umbraco.Listings.Extensions;
using Etch.Cms.Umbraco.Middleware.Middlewares;
using Etch.Cms.Umbraco.SecurityHeaders.DeveloperPageExceptionFilters;
using Etch.Cms.Umbraco.SecurityHeaders.Extensions;
using Etch.Cms.Umbraco.Sitemap.Extensions;
using Etch.CMS.Umbraco.Template.Core.Constants;
using Etch.CMS.Umbraco.Template.Models.Generated;
using Microsoft.AspNetCore.Diagnostics;
using OpenTelemetry.Trace;
using Microsoft.AspNetCore.HttpOverrides;
using System.Globalization;
using Vite.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

var umbracobuilder = builder.CreateUmbracoBuilder()
    .AddBackOffice()
    .AddWebsite()
    .AddDeliveryApi()
    .AddComposers()
    .AddContentment(x => { x.DisableTree = false; x.DisableTelemetry = true; });

var services = umbracobuilder.Services;
var env = builder.Environment;
var configuration = builder.Configuration;
```

## The five things to get right

### 1. `.AddContentment(...)` on the Umbraco builder

This is new in v17. Without it, Contentment data types silently fail at runtime — the backoffice
will show "Property editor with alias … not found" for any data type that uses Contentment.

The Etch standard config is:

```csharp
.AddContentment(x => { x.DisableTree = false; x.DisableTelemetry = true; });
```

- `DisableTree = false` — keep the Contentment tree visible in Settings
- `DisableTelemetry = true` — opt out of usage telemetry

This sits in the same fluent chain as `AddBackOffice()`, `AddWebsite()`, etc. — not in a separate
`services.AddX()` call.

### 2. Azure Blob Storage gating

The condition for adding Azure Blob media is environment-aware:

```csharp
if (!env.IsDevelopment() && (!env.IsEnvironment(EnvironmentsConstants.LocalProd)
    || configuration.GetSection("Etch:StorageEmulator").Value == "true"))
{
    umbracobuilder.AddAzureBlobMediaFileSystem();
}
```

In plain English: enable Azure Blob unless we're in Development, OR we're in LocalProd without the
storage emulator. The LocalProd carve-out lets devs test prod-like config without needing real Azure.

### 3. `EtchCmsCore` configuration

The fluent `.AddEtchCmsCore(...)` block is where most Etch-specific setup goes:

```csharp
umbracobuilder.AddEtchCmsCore(configure =>
{
    configure.ConfigureExamine(examine => examine.Exclude("content"));
    configure.AddSitemap(configureSitemap => { });
    configure.AddListings(configureListings =>
    {
        configureListings.AddBlog(configurator => { });
        configureListings.UseUmbracoRepositoryFilterService();
    });
    configure.AddCivic(civic => { });
    configure.AddContentBlocks();
    configure.AddStaticGeneration(staticGenerationConfigurator =>
        staticGenerationConfigurator.AddStaticGeneratedDocumentType(
            nameof(ThemeSettings).ToLower(CultureInfo.InvariantCulture),
            new StaticGenerationDefinition() { Extension = "css", ViewName = $"{nameof(ThemeSettings)}Static" }));
    configure.AddMVC(env.IsDevelopment());
});
```

Items to verify when migrating from v13:

- `ConfigureExamine` excludes `"content"` — keeps the content index off (Etch convention)
- `UseUmbracoRepositoryFilterService()` is the repository-based filter for listings — required if
  the site uses repository-based MNTP filtering
- `AddStaticGeneration` registers ThemeSettings static CSS generation; keep this exactly as shown
  unless the site doesn't use ThemeSettings
- `AddMVC(env.IsDevelopment())` — passing the env flag toggles dev-only routes

### 4. YouTube backoffice CSP middleware

This is the fix for YouTube embeds in the backoffice TipTap RTE — add it after `UseFrontEndSecurityHeaders`:

```csharp
// Override referrer policy for backoffice to allow YouTube embeds
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/umbraco"))
    {
        context.Response.OnStarting(() =>
        {
            context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
            return Task.CompletedTask;
        });
    }
    await next();
});
```

Without this, YouTube embeds fail with a CSP/referrer error in the backoffice TipTap editor.

### 5. ForwardedHeaders + ApplicationInsights + OpenTelemetry

```csharp
services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedHost
        | ForwardedHeaders.XForwardedFor
        | ForwardedHeaders.XForwardedProto;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

if (!env.IsDevelopment())
{
    services.AddApplicationInsightsTelemetry();
    services.AddOpenTelemetry().WithTracing(b => b.AddProcessor<NotFoundTelemetryProcessor>());
}
else
{
    services.AddOpenApiDocument(document =>
    {
        document.DocumentName = "Etch.CMS.Umbraco.Template API";
        document.Title = "Etch.CMS.Umbraco.Template API";
        document.Description = "Etch.CMS.Umbraco.Template API";
    });
}
```

`NotFoundTelemetryProcessor` filters 404s out of OpenTelemetry traces — comes from
`Etch.Cms.Umbraco.Core.Features.ApplicationInsights`. The OpenApi block runs only in dev so Swagger
is available at `/swagger`.

## The pipeline

After `var app = builder.Build();`:

```csharp
await app.BootUmbracoAsync();

if (env.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseOpenApi();
    app.UseSwaggerUi(options => { });
}

app.UseForwardedHeaders();
app.UseMiddleware<ManageTrailingSlashMiddleware>();
app.UseHttpsRedirection();
app.UseHsts();

app.UseFrontEndSecurityHeaders(configureCsp: builder =>
    // UnsafeInline required for CIVIC
    builder.AddStyleSrc()
        .UnsafeInline()
        .OverHttps()
        .Self());

// (Backoffice referrer policy middleware here — see #4 above)

app.UseUmbraco()
    .WithMiddleware(u =>
    {
        u.UseBackOffice();
        u.UseWebsite();
    })
    .WithEndpoints(u =>
    {
        u.UseBackOfficeEndpoints();
        u.UseWebsiteEndpoints();
    });

if (env.IsDevelopment())
{
    // Must come after app.UseUmbraco() —
    // https://github.com/Eptagone/Vite.AspNetCore/issues/37#issuecomment-1637403136
    app.UseViteDevelopmentServer(true);
}

await app.RunAsync();
```

The `UseViteDevelopmentServer` placement is non-obvious — it has to be *after* `UseUmbraco()` or Vite
HMR doesn't intercept correctly. There's a GitHub issue linked in the inline comment that explains
why; preserve that comment when migrating.

## Common migration mistakes

- **Forgetting `AddContentment`** — most common source of "data type missing" errors after migration
- **Wrong order of CSP middleware** — `UseFrontEndSecurityHeaders` must come before the backoffice
  referrer middleware, or the referrer override has no effect
- **Vite middleware in the wrong place** — see comment above
- **`AddOpenTelemetry().WithTracing(...)` without the NotFoundTelemetryProcessor** — works but floods
  App Insights with 404 noise
