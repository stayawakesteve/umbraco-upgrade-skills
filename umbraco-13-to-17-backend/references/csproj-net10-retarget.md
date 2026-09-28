# `.csproj` retargeting (v13 → v17)

The target framework jumps from `net8.0` to `net10.0`. Packages change to v17-compatible versions
(and the v17 template uses centralised package management, so versions live in
`Directory.Packages.props`).

## Step 1: Retarget framework

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <ImplicitUsings>enable</ImplicitUsings>
  <Nullable>enable</Nullable>
  <IsPackable>false</IsPackable>
  <!-- ... -->
  <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
</PropertyGroup>
```

Notes:
- `ImplicitUsings` and `Nullable` should both be `enable` — they typically already were in v13.
- `RestorePackagesWithLockFile` adds a `packages.lock.json` to the project. Commit it.

## Step 2: Drop `Version` attributes if centralising

v17 template uses `Directory.Packages.props`. PackageReferences in `.csproj`:

```xml
<PackageReference Include="Umbraco.Cms" />
<PackageReference Include="Umbraco.Community.Contentment" />
```

No version. The version comes from `Directory.Packages.props` at the solution root:

```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms" Version="17.x.x" />
    <PackageVersion Include="Umbraco.Community.Contentment" Version="..." />
    <!-- ... -->
  </ItemGroup>
</Project>
```

If the v13 solution doesn't have one, decide whether to introduce it now or migrate later. The v17
Etch template *expects* it — keeping inline versions will work but creates drift.

## Step 3: The v17 package list (canonical)

This is the set of packages a vanilla v17 Etch.Cms.Umbraco.Template project pulls in. Use it as
the target shape — your site may add more, but it should at least include these:

### Core Umbraco + community

```xml
<PackageReference Include="Umbraco.Cms" />
<PackageReference Include="Umbraco.Cms.DevelopmentMode.Backoffice" />
<PackageReference Include="Umbraco.Community.BlockPreview" />
<PackageReference Include="Umbraco.Community.Contentment" />
<PackageReference Include="Umbraco.Forms" />
```

`Umbraco.Cms.DevelopmentMode.Backoffice` is new in v17 — it powers the dev-mode backoffice. Include
it on dev/staging builds; can be conditionalised for production via `Condition="'$(Configuration)' != 'Release'"`.

### Umbraco AI suite (new in v17)

```xml
<PackageReference Include="Umbraco.AI" />
<PackageReference Include="Umbraco.AI.Agent" />
<PackageReference Include="Umbraco.AI.Agent.Copilot" />
<PackageReference Include="Umbraco.AI.Anthropic" />
<PackageReference Include="Umbraco.AI.Google" />
<PackageReference Include="Umbraco.AI.MicrosoftFoundry" />
<PackageReference Include="Umbraco.AI.OpenAI" />
<PackageReference Include="Umbraco.AI.Prompt" />
```

Include the providers the client is using — you can drop unused ones, but the base `Umbraco.AI` and
`Umbraco.AI.Agent` packages are baseline.

### uSync

```xml
<PackageReference Include="uSync" />
<PackageReference Include="uSync.Complete" />
<PackageReference Include="uSync.Forms" />
<PackageReference Include="uSync.PeopleEdition" />
```

### Etch CMS libraries

For consumed-via-NuGet sites:

```xml
<PackageReference Include="Etch.Cms.Umbraco.Blog" />
<PackageReference Include="Etch.Cms.Umbraco.Civic" />
<PackageReference Include="Etch.Cms.Umbraco.ContentBlocks" />
<PackageReference Include="Etch.Cms.Umbraco.Core" />
<PackageReference Include="Etch.Cms.Umbraco.Core.Mvc" />
<PackageReference Include="Etch.Cms.Umbraco.Core.Mvc.StaticGeneration" />
<PackageReference Include="Etch.Cms.Umbraco.Listings" />
<PackageReference Include="Etch.Cms.Umbraco.Middleware" />
<PackageReference Include="Etch.Cms.Umbraco.Robots" />
<PackageReference Include="Etch.Cms.Umbraco.Schema" />
<PackageReference Include="Etch.Cms.Umbraco.SecurityHeaders" />
<PackageReference Include="Etch.Cms.Umbraco.Sitemap" />
<PackageReference Include="Etch.Cms.Umbraco.TagHelpers" />
```

For solutions consuming Etch.Cms.Libraries via ProjectReference, the section above is commented out
and a block of `<ProjectReference Include="..\..\..\..\..\Etch.Cms.Libraries\src\...\*.csproj" />`
entries are present instead. Pick one model — don't mix.

### Other commonly-needed packages

```xml
<PackageReference Include="Boxed.AspNetCore.TagHelpers" />
<PackageReference Include="Humanizer.Core" />
<PackageReference Include="NSwag.AspNetCore" />
<PackageReference Include="NetEscapades.AspNetCore.SecurityHeaders" />
<PackageReference Include="NetEscapades.AspNetCore.SecurityHeaders.TagHelpers" />
<PackageReference Include="Our.Umbraco.TheDashboard" />
<PackageReference Include="Scrutor" />
<PackageReference Include="Skybrud.Umbraco.Redirects" />
<PackageReference Include="Vite.AspNetCore" />
```

### Hosting (conditional)

For Azure:

```xml
<PackageReference Include="Microsoft.ApplicationInsights.AspNetCore" />
<PackageReference Include="Umbraco.StorageProviders.AzureBlob" />
```

For AWS:

```xml
<PackageReference Include="Our.Umbraco.StorageProviders.AWSS3" />
```

Plus the nginx config files:

```xml
<ItemGroup>
  <None Include=".platform\nginx\conf.d\elasticbeanstalk\00_application.conf">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
  </None>
  <None Include=".platform\nginx\conf.d\elasticbeanstalk\upload.conf">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
  </None>
</ItemGroup>
```

## Step 4: Etch.Cms.PropertyEditors

If the v13 site used the custom repository-based MNTP property editor, keep these (and remember
the UDI → GUID transform in `umbraco-13-to-17-database`):

```xml
<PackageReference Include="Etch.Cms.Umbraco.PropertyEditors.RepositoryBasedMntp" />
<PackageReference Include="Etch.Cms.Umbraco.PropertyEditors.RepositoryBasedMntp.Usync" />
```

## Step 5: Static content includes

These haven't changed but are easy to miss when copying from the v17 template:

```xml
<ItemGroup>
  <Content Include="App_Plugins/**" CopyToOutputDirectory="Always" />
</ItemGroup>

<ItemGroup>
  <!-- Don't remove this line or your manifest.json won't be copied on publish -->
  <Content Include="wwwroot\.vite\**" />
</ItemGroup>

<PropertyGroup>
  <!-- Razor files are needed for the backoffice to work correctly -->
  <CopyRazorGenerateFilesToPublishDirectory>true</CopyRazorGenerateFilesToPublishDirectory>
</PropertyGroup>
```

## What changes from v13

The big diffs vs. a v13 `.csproj`:

- `TargetFramework` `net8.0` → `net10.0`
- New `Umbraco.AI.*` package family (entirely new in v17)
- `Umbraco.Cms.DevelopmentMode.Backoffice` is new
- `Umbraco.Community.BlockPreview` may be new for some v13 sites (was optional)
- Version attributes likely removed in favour of `Directory.Packages.props`
- Any custom v13 packages without a v17 release need to be dropped — these should have been flagged
  in the package audit during pre-flight
