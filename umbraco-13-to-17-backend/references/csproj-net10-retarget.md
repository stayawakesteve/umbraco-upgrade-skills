# `.csproj` retargeting (v13 → v17)

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

PackageReferences in `.csproj`:

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

If the v13 solution doesn't have one, decide whether to introduce it now (recommended) or migrate later. Keeping inline versions will
work but creates drift across projects in the solution.

## Step 3: The v17 package list (canonical)

This is the set of packages a typical v17 site pulls in. Use it as the target shape — your site
may add or drop some, but check each one it already references has a v17 version:

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
`Umbraco.Community.BlockPreview` was optional in v13, so some sites will need to add it.

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

## Step 4: Static content includes

These haven't changed but are easy to miss when comparing against a fresh v17 project:

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
