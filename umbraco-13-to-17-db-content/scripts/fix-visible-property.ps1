# Script to fix missing visible property values in uSync content files
# Replaces instances of "visible": "" with "visible": "1"

$contentFolder = "uSync\v9\Content"
$filesProcessed = 0
$filesModified = 0

# Get all .config files in the uSync\v9\Content folder
$files = Get-ChildItem -Path $contentFolder -Filter "*.config" -Recurse

Write-Host "Found $($files.Count) config files to process..." -ForegroundColor Cyan

foreach ($file in $files) {
    $filesProcessed++
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    if ($content -match '"visible": ""') {
        $updatedContent = $content -replace '"visible": ""', '"visible": "1"'
        Set-Content -Path $file.FullName -Value $updatedContent -Encoding UTF8 -NoNewline
        $filesModified++
        Write-Host "  Modified: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Cyan
Write-Host "Files processed: $filesProcessed" -ForegroundColor White
Write-Host "Files modified: $filesModified" -ForegroundColor Green
