# `Program.cs` (v17 shape)

## Canonical structure

```csharp
using Microsoft.AspNetCore.HttpOverrides;
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

// ... conditional registrations (see below) ...

umbracobuilder.Build();
```

Keep any site-specific registrations your v13 `Program.cs` had (custom composers, extension
methods from your own or third-party packages) — check each package's v17 release notes for
changed registration calls.

## The four things to get right

### 1. `.AddContentment(...)` on the Umbraco builder

This is new in v17. Without it, Contentment data types silently fail at runtime — the backoffice
will show "Property editor with alias … not found" for any data type that uses Contentment. It's the
most common source of "data type missing" errors after migration.

The options in the canonical structure above:

- `DisableTree = false` — keep the Contentment tree visible in Settings
- `DisableTelemetry = true` — opt out of usage telemetry

This sits in the same fluent chain as `AddBackOffice()`, `AddWebsite()`, etc. — not in a separate
`services.AddX()` call.

### 2. Azure Blob Storage gating

Register Azure Blob media conditionally, so local development keeps using the local file system:

```csharp
if (!env.IsDevelopment())
{
    umbracobuilder.AddAzureBlobMediaFileSystem();
}
```

If your v13 site had a more specific condition (e.g. a prod-like local environment that opts out
unless a storage emulator is configured), carry it across unchanged.

### 3. YouTube backoffice CSP middleware

Without this, YouTube embeds in the backoffice TipTap RTE fail with a CSP/referrer error. Add it
after any middleware that sets security headers (e.g. a CSP / security-headers package), otherwise
the referrer override has no effect:

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

### 4. ForwardedHeaders + ApplicationInsights

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
}
else
{
    services.AddOpenApiDocument(document =>
    {
        document.DocumentName = "My Site API";
        document.Title = "My Site API";
    });
}
```

The OpenApi block (NSwag) runs only in dev so Swagger is available at `/swagger`. Rename the
document to suit the site.

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
app.UseHttpsRedirection();
app.UseHsts();

// (Any security-headers / CSP middleware your site uses goes here)

// (Backoffice referrer policy middleware here — see #3 above)

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
