# Script to fix the List View "orderBy" casing bug after a v13 -> v17 migration.
#
# The v14 list-view migration lower-cases the config keys and property aliases to
# camelCase (sortOrder, updateDate, creator, ...) but leaves the "orderBy" VALUE in
# its old v13 PascalCase form ("SortOrder", "Name", "VersionDate"). v17's collection
# view validates orderBy against the configured aliases CASE-SENSITIVELY, so
# "SortOrder" != "sortOrder" and the backoffice throws:
#   "Order by value is not a property on the configured collection"
# (client-side only - nothing appears in the Umbraco logs).
#
# Run this after exporting uSync from v17 but before re-importing.

$dataTypesFolder = "uSync\v17\DataTypes"
$filesProcessed = 0
$filesModified = 0

# System aliases the v17 collection view always exposes, with their correct casing.
# A custom orderBy will also match anything in the data type's includeProperties.
$systemAliases = @(
    "name", "sortOrder", "updateDate", "createDate",
    "creator", "owner", "published", "contentTypeAlias",
    "email", "username"
)

# Legacy v13 orderBy values that were renamed (not just re-cased) in v17.
$legacyRenames = @{
    "versiondate" = "updateDate"
}

$files = Get-ChildItem -Path $dataTypesFolder -Filter "*.config" -Recurse

Write-Host "Found $($files.Count) data type files to process..." -ForegroundColor Cyan

foreach ($file in $files) {
    $filesProcessed++
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    # Only touch list views that declare an orderBy value.
    $orderByMatch = [regex]::Match($content, '"orderBy":\s*"([^"]+)"')
    if (-not $orderByMatch.Success) { continue }

    $currentValue = $orderByMatch.Groups[1].Value
    $lower = $currentValue.ToLower()

    # Valid targets = this data type's own property aliases + the system aliases.
    $validAliases = @()
    foreach ($m in [regex]::Matches($content, '"alias":\s*"([^"]+)"')) {
        $validAliases += $m.Groups[1].Value
    }
    $validAliases += $systemAliases

    $newValue = $null
    if ($legacyRenames.ContainsKey($lower)) {
        $newValue = $legacyRenames[$lower]
    }
    else {
        # Case-insensitive match against a valid alias -> use that alias's casing.
        $match = $validAliases | Where-Object { $_.ToLower() -eq $lower } | Select-Object -First 1
        if ($match) { $newValue = $match }
    }

    if ($null -eq $newValue) {
        Write-Host "  Skipped:  $($file.Name) - orderBy '$currentValue' matches no known alias, please check manually" -ForegroundColor Yellow
        continue
    }

    if ($newValue -ceq $currentValue) { continue }  # already correct (case-sensitive compare)

    $updatedContent = $content -replace [regex]::Escape("`"orderBy`": `"$currentValue`""), "`"orderBy`": `"$newValue`""
    Set-Content -Path $file.FullName -Value $updatedContent -Encoding UTF8 -NoNewline
    $filesModified++
    Write-Host "  Modified: $($file.Name) - orderBy '$currentValue' -> '$newValue'" -ForegroundColor Green
}

Write-Host "`nProcessing complete!" -ForegroundColor Cyan
Write-Host "Files processed: $filesProcessed" -ForegroundColor White
Write-Host "Files modified: $filesModified" -ForegroundColor Green
