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
$RequiredFields = @(
    "id",
    "title",
    "type",
    "status",
    "created",
    "updated",
    "tags",
    "sources",
    "confidence"
)

$AllowedTypes = @(
    "source-paper",
    "source-github",
    "source-web",
    "source-personal",
    "atomic-note",
    "concept",
    "claim",
    "method",
    "domain-map",
    "synthesis",
    "workflow",
    "eval"
)

$AllowedStatus = @(
    "inbox",
    "draft",
    "active",
    "review",
    "seed",
    "superseded",
    "archived"
)

$AllowedConfidence = @(
    "low",
    "medium",
    "high"
)

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

$errors = New-Object System.Collections.Generic.List[string]
$ids = @{}
$checked = 0

foreach ($dir in $IncludeDirs) {
    $fullDir = Join-Path $Root $dir
    if (-not (Test-Path -LiteralPath $fullDir)) {
        continue
    }

    $files = Get-ChildItem -LiteralPath $fullDir -Recurse -File -Filter "*.md"
    foreach ($file in $files) {
        $checked++
        $relativePath = Get-RelativePath -Path $file.FullName
        $frontMatter = Get-FrontMatter -Path $file.FullName

        if ($null -eq $frontMatter) {
            $errors.Add("${relativePath}: missing YAML frontmatter")
            continue
        }

        foreach ($field in $RequiredFields) {
            if (-not $frontMatter.Contains($field)) {
                $errors.Add("${relativePath}: missing required field '$field'")
            }
        }

        if ($frontMatter.Contains("id")) {
            $id = [string]$frontMatter["id"]
            if ($id -notmatch "^[a-z0-9][a-z0-9-]*$") {
                $errors.Add("${relativePath}: id '$id' must be lowercase kebab-case")
            }
            if ($ids.ContainsKey($id)) {
                $errors.Add("${relativePath}: duplicate id '$id' also used by $($ids[$id])")
            }
            else {
                $ids[$id] = $relativePath
            }
        }

        if ($frontMatter.Contains("type") -and $AllowedTypes -notcontains $frontMatter["type"]) {
            $errors.Add("${relativePath}: invalid type '$($frontMatter["type"])'")
        }

        if ($frontMatter.Contains("status") -and $AllowedStatus -notcontains $frontMatter["status"]) {
            $errors.Add("${relativePath}: invalid status '$($frontMatter["status"])'")
        }

        if ($frontMatter.Contains("confidence") -and $AllowedConfidence -notcontains $frontMatter["confidence"]) {
            $errors.Add("${relativePath}: invalid confidence '$($frontMatter["confidence"])'")
        }

        foreach ($dateField in @("created", "updated")) {
            if ($frontMatter.Contains($dateField) -and ([string]$frontMatter[$dateField]) -notmatch "^\d{4}-\d{2}-\d{2}$") {
                $errors.Add("${relativePath}: $dateField must use YYYY-MM-DD")
            }
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "Knowledge base validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Knowledge base validation passed for $checked markdown files."
