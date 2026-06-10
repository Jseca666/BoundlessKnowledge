[CmdletBinding()]
param(
    [string[]]$IncludeDirs = @(
        "10-sources",
        "20-notes",
        "30-maps",
        "40-synthesis",
        "50-workflows",
        "60-evals"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$IndexDir = Join-Path $Root "70-indexes"
New-Item -ItemType Directory -Force -Path $IndexDir | Out-Null

function Get-RelativePath {
    param([string]$Path)
    $rootPath = $Root
    if (-not $rootPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $rootPath = $rootPath + [System.IO.Path]::DirectorySeparatorChar
    }

    $rootUri = New-Object System.Uri($rootPath)
    $pathUri = New-Object System.Uri((Resolve-Path -LiteralPath $Path).ProviderPath)
    return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString())
}

function Get-FrontMatter {
    param([string]$Path)

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($content -notmatch "^(?s)---\r?\n(.*?)\r?\n---") {
        return $null
    }

    $frontMatter = $Matches[1] -split "\r?\n"
    $data = [ordered]@{}

    for ($i = 0; $i -lt $frontMatter.Count; $i++) {
        $line = $frontMatter[$i]
        if ($line -match "^([A-Za-z0-9_-]+):\s*(.*)$") {
            $key = $Matches[1]
            $value = $Matches[2].Trim()

            if ($value -eq "") {
                $items = @()
                $j = $i + 1
                while ($j -lt $frontMatter.Count -and $frontMatter[$j] -match "^\s*-\s*(.+)\s*$") {
                    $items += $Matches[1].Trim().Trim('"')
                    $j++
                }
                $data[$key] = $items
                $i = $j - 1
            }
            elseif ($value -eq "[]") {
                $data[$key] = @()
            }
            else {
                $data[$key] = $value.Trim('"')
            }
        }
    }

    return $data
}

$items = @()

foreach ($dir in $IncludeDirs) {
    $fullDir = Join-Path $Root $dir
    if (-not (Test-Path -LiteralPath $fullDir)) {
        continue
    }

    $files = Get-ChildItem -LiteralPath $fullDir -Recurse -File -Filter "*.md"
    foreach ($file in $files) {
        $frontMatter = Get-FrontMatter -Path $file.FullName
        if ($null -eq $frontMatter) {
            continue
        }

        $tags = @()
        if ($frontMatter.Contains("tags")) {
            $tags = @($frontMatter["tags"])
        }

        $domains = @()
        if ($frontMatter.Contains("domains")) {
            $domains = @($frontMatter["domains"])
        }

        $sources = @()
        if ($frontMatter.Contains("sources")) {
            $sources = @($frontMatter["sources"])
        }

        $items += [pscustomobject]@{
            id         = $frontMatter["id"]
            title      = $frontMatter["title"]
            type       = $frontMatter["type"]
            status     = $frontMatter["status"]
            confidence = $frontMatter["confidence"]
            updated    = $frontMatter["updated"]
            tags       = ($tags -join ";")
            domains    = ($domains -join ";")
            sources    = ($sources -join ";")
            path       = Get-RelativePath -Path $file.FullName
        }
    }
}

$items = $items | Sort-Object type, title, path

$catalogJson = Join-Path $IndexDir "catalog.json"
$catalogCsv = Join-Path $IndexDir "catalog.csv"

$items | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $catalogJson -Encoding UTF8
$items | ConvertTo-Csv -NoTypeInformation | Set-Content -LiteralPath $catalogCsv -Encoding UTF8

Write-Host "Indexed $($items.Count) knowledge items."
Write-Host "Wrote $catalogJson"
Write-Host "Wrote $catalogCsv"
