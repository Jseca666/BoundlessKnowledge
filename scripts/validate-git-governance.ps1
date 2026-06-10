[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$Errors = New-Object System.Collections.Generic.List[string]

function Read-JsonFile {
    param([string]$RelativePath)

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $Errors.Add("${RelativePath}: file does not exist")
        return $null
    }

    try {
        return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $Errors.Add("${RelativePath}: invalid JSON - $($_.Exception.Message)")
        return $null
    }
}

function Test-PathExists {
    param([string]$RelativePath, [string]$Context)
    $pathOnly = ([string]$RelativePath).Split("#")[0]
    if (-not (Test-Path -LiteralPath (Join-Path $Root $pathOnly))) {
        $Errors.Add("${Context}: path does not exist: $RelativePath")
    }
}

$expectedRemote = "https://github.com/Jseca666/BoundlessKnowledge.git"

$system = Read-JsonFile "system/git-governance-system.json"
$docsMap = Read-JsonFile "system/git-governance-docs-map.json"
$closureMap = Read-JsonFile "system/system-closure-map.json"

$inside = & git -C $Root rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $inside.Trim() -ne "true") {
    $Errors.Add("git: workspace is not inside a Git worktree")
}

$origin = & git -C $Root remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    $Errors.Add("git: remote 'origin' is not configured")
}
elseif ($origin.Trim() -ne $expectedRemote) {
    $Errors.Add("git: remote origin expected '$expectedRemote' but found '$($origin.Trim())'")
}

if ($null -ne $system) {
    foreach ($fieldName in @("id", "owner_module", "repository", "responsibility_boundary", "core_workflow", "cycle_management", "quality_gates", "managed_surfaces", "status")) {
        if (-not ($system.PSObject.Properties.Name -contains $fieldName)) {
            $Errors.Add("system/git-governance-system.json: missing $fieldName")
        }
    }

    if ($system.repository.remote_url -ne $expectedRemote) {
        $Errors.Add("system/git-governance-system.json: repository.remote_url must be $expectedRemote")
    }

    if ($system.repository.remote_action_boundary -notmatch "approval") {
        $Errors.Add("system/git-governance-system.json: remote_action_boundary must mention approval")
    }

    if (-not ($system.PSObject.Properties.Name -contains "cycle_management")) {
        $Errors.Add("system/git-governance-system.json: missing cycle_management")
    }
    else {
        if ($system.cycle_management.status -ne "active") {
            $Errors.Add("system/git-governance-system.json: cycle_management.status must be active")
        }
        foreach ($fieldName in @("triggers", "state_model", "required_loop", "closure_outputs", "system_closure_contract")) {
            if (-not ($system.cycle_management.PSObject.Properties.Name -contains $fieldName)) {
                $Errors.Add("system/git-governance-system.json: cycle_management missing $fieldName")
            }
        }
        if (@($system.cycle_management.required_loop).Count -lt 5) {
            $Errors.Add("system/git-governance-system.json: cycle_management.required_loop must describe the full version cycle")
        }
        if (@($system.cycle_management.closure_outputs) -notcontains "remote_sync_result_when_authorized_and_executed") {
            $Errors.Add("system/git-governance-system.json: cycle_management.closure_outputs must include authorized remote sync result")
        }
    }

    foreach ($pathValue in @($system.managed_surfaces.machine_truth + $system.managed_surfaces.human_docs + $system.managed_surfaces.validation + $system.managed_surfaces.visual_projection)) {
        Test-PathExists -RelativePath ([string]$pathValue) -Context "system/git-governance-system.json managed surface"
    }
}

if ($null -ne $closureMap) {
    $gitClosure = @($closureMap.modules | Where-Object { $_.module_id -eq "git-governance" }) | Select-Object -First 1
    if ($null -eq $gitClosure) {
        $Errors.Add("system/system-closure-map.json: missing git-governance module")
    }
    elseif (-not ($gitClosure.PSObject.Properties.Name -contains "cycle_management")) {
        $Errors.Add("system/system-closure-map.json: git-governance missing cycle_management")
    }
    elseif ($gitClosure.cycle_management.status -ne "closed") {
        $Errors.Add("system/system-closure-map.json: git-governance cycle_management.status must be closed")
    }
}

if ($null -ne $docsMap) {
    foreach ($docRoute in @($docsMap.doc_routes)) {
        Test-PathExists -RelativePath ([string]$docRoute.path) -Context "system/git-governance-docs-map.json doc_route"
    }
    foreach ($pathValue in @($docsMap.validation)) {
        Test-PathExists -RelativePath ([string]$pathValue) -Context "system/git-governance-docs-map.json validation"
    }
}

$gitignorePath = Join-Path $Root ".gitignore"
if (-not (Test-Path -LiteralPath $gitignorePath)) {
    $Errors.Add(".gitignore: missing")
}
else {
    $gitignore = Get-Content -LiteralPath $gitignorePath -Raw -Encoding UTF8
    foreach ($requiredPattern in @(".env", ".obsidian/workspace.json", ".cache/")) {
        if ($gitignore -notmatch [regex]::Escape($requiredPattern)) {
            $Errors.Add(".gitignore: missing required pattern '$requiredPattern'")
        }
    }
}

$gitattributesPath = Join-Path $Root ".gitattributes"
if (-not (Test-Path -LiteralPath $gitattributesPath)) {
    $Errors.Add(".gitattributes: missing")
}
else {
    $gitattributes = Get-Content -LiteralPath $gitattributesPath -Raw -Encoding UTF8
    foreach ($requiredPattern in @("*.md text eol=lf", "*.json text eol=lf", "*.canvas text eol=lf", "*.ps1 text eol=lf", "*.png binary")) {
        if ($gitattributes -notmatch [regex]::Escape($requiredPattern)) {
            $Errors.Add(".gitattributes: missing required pattern '$requiredPattern'")
        }
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "Git governance validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Git governance validation passed."
