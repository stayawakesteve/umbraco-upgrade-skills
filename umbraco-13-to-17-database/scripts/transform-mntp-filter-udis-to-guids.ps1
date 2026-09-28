# Script to transform UDI references to GUIDs in uSync content files
# ONLY transforms UDIs within <filters>...</filters> sections

$contentFolder = "uSync\v17\Content"
$filesProcessed = 0
$filesModified = 0
$udisTransformed = 0

# Function to format a 32-character hex string as a GUID with dashes
function Format-Guid {
    param([string]$hexString)
    
    # Add dashes in GUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    $formatted = $hexString.Substring(0, 8) + "-" +
                 $hexString.Substring(8, 4) + "-" +
                 $hexString.Substring(12, 4) + "-" +
                 $hexString.Substring(16, 4) + "-" +
                 $hexString.Substring(20, 12)
    
    return $formatted
}

# Get all .config files in the uSync\v17\Content folder
$files = Get-ChildItem -Path $contentFolder -Filter "*.config" -Recurse

Write-Host "Found $($files.Count) config files to process..." -ForegroundColor Cyan

foreach ($file in $files) {
    $filesProcessed++
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    # Check if the file contains a <filters> section
    if ($content -match '<filters>[\s\S]*?</filters>') {
        $originalContent = $content
        $fileUdiCount = 0
        
        # Use a callback to replace only within <filters> sections
        $content = [regex]::Replace($content, '(<filters>)([\s\S]*?)(</filters>)', {
            param($match)
            
            $openingTag = $match.Groups[1].Value
            $filtersContent = $match.Groups[2].Value
            $closingTag = $match.Groups[3].Value
            
            # Transform UDIs only within the filters content
            $transformedContent = [regex]::Replace($filtersContent, 'umb://document/([0-9a-f]{32})', {
                param($innerMatch)
                $script:fileUdiCount++
                $guid = $innerMatch.Groups[1].Value
                $formattedGuid = Format-Guid $guid
                return $formattedGuid
            })
            
            return $openingTag + $transformedContent + $closingTag
        })
        
        # Only write back if content changed
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            $filesModified++
            $udisTransformed += $fileUdiCount
            Write-Host "  Modified: $($file.Name) - $fileUdiCount UDI(s) transformed" -ForegroundColor Green
        }
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Cyan
Write-Host "Files processed: $filesProcessed" -ForegroundColor White
Write-Host "Files modified: $filesModified" -ForegroundColor Green
Write-Host "UDIs transformed: $udisTransformed" -ForegroundColor Green
