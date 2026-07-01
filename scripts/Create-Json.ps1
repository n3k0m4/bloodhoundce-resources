#
# Import-BloodHoundCECustomQueries.ps1
#
# Export BloodHound CE Custom Queries as JSON files
#

$markdownFilePath = "$PSScriptRoot/../custom_queries/BloodHound_CE_Custom_Queries.md"
$markdownParsed = ConvertFrom-Markdown $markdownFilePath

$outputFolder = "$PSScriptRoot/../custom_queries/json"

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

$counter = 1000
$name = ""
$query = ""
$json = ""
$category = ""

Write-Host "[*] Exporting queries to JSON..." -ForegroundColor Green

foreach ($token in $markdownParsed.Tokens) {
    if ($token.Level -eq 2) {
        $counter = [math]::Ceiling($counter / 100) * 100
        $category = $token.Inline.Content.ToString()
        Write-Host "[*] Found category [C-$counter] $category..." -ForegroundColor Green
        $json = @{
            query       = "-"
            name        = "[C-$counter] $category"
            description = ""
        } | ConvertTo-Json -Compress
        $fileName = "C-${counter}_${category}.json"
        $fileName = $fileName -replace '[<>:"/\\|?*]', '_'
        $filePath = Join-Path $outputFolder $fileName
        Set-Content -Path $filePath -Value $json
        Write-Host "[*] Wrote $fileName"
    }
    elseif ($token.Level -eq 3) {
        $counter++
        $name = $token.Inline.Content.ToString()
    }
    elseif ($token.FencedChar -eq "``") {
        $query = ""
        foreach ($line in $token.Lines) {
            $query += "$line`n"
        }
        $json = @{
            query       = $query.TrimEnd()
            name        = "[C-$counter] $name"
            description = ""
        } | ConvertTo-Json -Compress
        $fileName = "C-${counter}_${name}.json"
        # Replace invalid filename characters
        $fileName = $fileName -replace '[<>:"/\\|?*]', '_'
        $filePath = Join-Path $outputFolder $fileName
        Set-Content -Path $filePath -Value $json
        Write-Host "[*] Wrote $fileName"
    }
}
