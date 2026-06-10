[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("atomic", "concept", "paper", "github", "web", "personal", "domain-map", "workflow", "synthesis")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [string]$Slug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath

function ConvertTo-Slug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant()
    $slug = $slug -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "Could not create a slug from title '$Value'. Pass -Slug explicitly."
    }
    return $slug
}

$date = Get-Date -Format "yyyy-MM-dd"
$idDate = Get-Date -Format "yyyyMMdd"

if ([string]::IsNullOrWhiteSpace($Slug)) {
    $Slug = ConvertTo-Slug -Value $Title
}
else {
    $Slug = ConvertTo-Slug -Value $Slug
}

$config = @{
    "atomic"     = @{ Template = "atomic-note.md"; Dir = "20-notes/atomic"; Prefix = "note" }
    "concept"    = @{ Template = "concept-card.md"; Dir = "20-notes/concepts"; Prefix = "concept" }
    "paper"      = @{ Template = "paper-source.md"; Dir = "10-sources/papers"; Prefix = "paper" }
    "github"     = @{ Template = "github-topic.md"; Dir = "10-sources/github"; Prefix = "github" }
    "web"        = @{ Template = "web-source.md"; Dir = "10-sources/web"; Prefix = "web" }
    "personal"   = @{ Template = "personal-draft.md"; Dir = "10-sources/personal"; Prefix = "personal" }
    "domain-map" = @{ Template = "domain-map.md"; Dir = "30-maps/domains"; Prefix = "domain-map" }
    "workflow"   = @{ Template = "workflow-pack.md"; Dir = "50-workflows/codex"; Prefix = "workflow" }
    "synthesis"  = @{ Template = "synthesis-brief.md"; Dir = "40-synthesis/briefs"; Prefix = "synthesis" }
}

$entry = $config[$Type]
$id = "$($entry.Prefix)-$idDate-$Slug"
$templatePath = Join-Path (Join-Path $Root "templates") $entry.Template
$targetDir = Join-Path $Root $entry.Dir
$targetPath = Join-Path $targetDir "$Slug.md"

if (Test-Path -LiteralPath $targetPath) {
    throw "Target already exists: $targetPath"
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$content = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$content = $content.Replace("{{id}}", $id).Replace("{{title}}", $Title).Replace("{{date}}", $date)
Set-Content -LiteralPath $targetPath -Value $content -Encoding UTF8

Write-Host "Created $targetPath"
Write-Host "id: $id"
