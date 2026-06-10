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

function Test-PathValue {
    param(
        [string]$PathValue,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        $Errors.Add("${Context}: empty path")
        return
    }

    $candidate = Join-Path $Root $PathValue
    if (-not (Test-Path -LiteralPath $candidate)) {
        $Errors.Add("${Context}: path does not exist: $PathValue")
    }
}

function Test-RequiredField {
    param(
        [object]$Object,
        [string]$Field,
        [string]$Context
    )

    if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $Field)) {
        $Errors.Add("${Context}: missing $Field")
        return $false
    }

    $value = $Object.PSObject.Properties[$Field].Value
    if ($null -eq $value) {
        $Errors.Add("${Context}: missing $Field")
        return $false
    }

    if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
        $Errors.Add("${Context}: empty $Field")
        return $false
    }

    return $true
}

$reviewSystem = Read-JsonFile "system/reviews/review-system.json"
$queue = Read-JsonFile "system/reviews/review-queue.json"
$docsMap = Read-JsonFile "system/reviews/review-docs-map.json"
$schema = Read-JsonFile "schemas/review-record.schema.json"

if ($null -ne $reviewSystem) {
    foreach ($fieldName in @("id", "version", "role", "purpose", "responsibility_boundary", "review_classes", "specialized_review_modules", "finding_status_values", "handoff_targets", "core_workflow", "review_record_contract", "criteria_sets", "storage_policy", "quality_gates")) {
        Test-RequiredField -Object $reviewSystem -Field $fieldName -Context "system/reviews/review-system.json" | Out-Null
    }

    $reviewClassIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($reviewClass in @($reviewSystem.review_classes)) {
        if (Test-RequiredField -Object $reviewClass -Field "id" -Context "review class") {
            [void]$reviewClassIds.Add([string]$reviewClass.id)
        }
    }

    $criteriaSetIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($criteriaSet in @($reviewSystem.criteria_sets)) {
        if (Test-RequiredField -Object $criteriaSet -Field "id" -Context "review criteria_set") {
            [void]$criteriaSetIds.Add([string]$criteriaSet.id)
        }
    }

    foreach ($specializedModule in @($reviewSystem.specialized_review_modules)) {
        $moduleContext = "review specialized module"
        if (Test-RequiredField -Object $specializedModule -Field "id" -Context $moduleContext) {
            $moduleContext = "review specialized module '$($specializedModule.id)'"
        }

        foreach ($fieldName in @("name", "parent_review_class", "role", "owns", "criteria_set", "audit_tool", "docs", "handoff_rule")) {
            Test-RequiredField -Object $specializedModule -Field $fieldName -Context $moduleContext | Out-Null
        }

        if ($specializedModule.PSObject.Properties.Name -contains "parent_review_class") {
            $parentReviewClass = [string]$specializedModule.parent_review_class
            if (-not $reviewClassIds.Contains($parentReviewClass)) {
                $Errors.Add("${moduleContext}: parent_review_class references unknown review class '$parentReviewClass'")
            }
        }

        if ($specializedModule.PSObject.Properties.Name -contains "criteria_set") {
            $criteriaSetId = [string]$specializedModule.criteria_set
            if (-not $criteriaSetIds.Contains($criteriaSetId)) {
                $Errors.Add("${moduleContext}: criteria_set references unknown criteria set '$criteriaSetId'")
            }
        }

        if ($specializedModule.PSObject.Properties.Name -contains "audit_tool") {
            Test-PathValue -PathValue ([string]$specializedModule.audit_tool) -Context "$moduleContext audit_tool"
        }

        if ($specializedModule.PSObject.Properties.Name -contains "docs") {
            foreach ($pathValue in @($specializedModule.docs)) {
                Test-PathValue -PathValue ([string]$pathValue) -Context "$moduleContext docs"
            }
        }
    }

    foreach ($pathValue in @($reviewSystem.storage_policy.agent_entry)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review storage_policy.agent_entry"
    }
    foreach ($pathValue in @($reviewSystem.storage_policy.machine_truth)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review storage_policy.machine_truth"
    }
    foreach ($pathValue in @($reviewSystem.storage_policy.human_explanation)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review storage_policy.human_explanation"
    }
    foreach ($pathValue in @($reviewSystem.storage_policy.visual_projection)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review storage_policy.visual_projection"
    }
    foreach ($pathValue in @($reviewSystem.storage_policy.validation)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review storage_policy.validation"
    }
}

if ($null -ne $schema) {
    foreach ($requiredField in @("review_id", "title", "status", "review_class", "trigger", "scope", "evidence_paths", "criteria", "findings", "risk_assessment", "handoff_decision", "capture_paths", "validation", "review_acceptance")) {
        if (@($schema.required) -notcontains $requiredField) {
            $Errors.Add("schemas/review-record.schema.json: required missing '$requiredField'")
        }
    }
}

$requiredReviewFields = @()
if ($null -ne $reviewSystem -and
    $reviewSystem.PSObject.Properties.Name -contains "review_record_contract" -and
    $reviewSystem.review_record_contract.PSObject.Properties.Name -contains "required_fields") {
    $requiredReviewFields = @($reviewSystem.review_record_contract.required_fields | ForEach-Object { [string]$_ })
}

if ($null -ne $queue) {
    foreach ($fieldName in @("schema_version", "id", "system_id", "execution_policy", "reviews")) {
        Test-RequiredField -Object $queue -Field $fieldName -Context "system/reviews/review-queue.json" | Out-Null
    }

    $reviewIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($review in @($queue.reviews)) {
        $context = "review record"
        if ($review.PSObject.Properties.Name -contains "review_id") {
            $context = "review record '$($review.review_id)'"
            if (-not $reviewIds.Add([string]$review.review_id)) {
                $Errors.Add("system/reviews/review-queue.json: duplicate review_id '$($review.review_id)'")
            }
        }

        foreach ($fieldName in $requiredReviewFields) {
            Test-RequiredField -Object $review -Field $fieldName -Context $context | Out-Null
        }

        if ($review.PSObject.Properties.Name -contains "evidence_paths") {
            foreach ($pathValue in @($review.evidence_paths)) {
                Test-PathValue -PathValue ([string]$pathValue) -Context "$context evidence_paths"
            }
        }

        if ($review.PSObject.Properties.Name -contains "capture_paths") {
            foreach ($pathValue in @($review.capture_paths)) {
                Test-PathValue -PathValue ([string]$pathValue) -Context "$context capture_paths"
            }
        }

        if ($review.PSObject.Properties.Name -contains "validation" -and $null -ne $review.validation) {
            if ($review.validation.PSObject.Properties.Name -contains "reports") {
                foreach ($pathValue in @($review.validation.reports)) {
                    Test-PathValue -PathValue ([string]$pathValue) -Context "$context validation.reports"
                }
            }
        }

        if ($review.PSObject.Properties.Name -contains "status" -and [string]$review.status -eq "captured") {
            if (-not ($review.PSObject.Properties.Name -contains "review_acceptance") -or
                [string]::IsNullOrWhiteSpace([string]$review.review_acceptance)) {
                $Errors.Add("${context}: captured review requires review_acceptance")
            }
            if (-not ($review.PSObject.Properties.Name -contains "validation") -or
                $null -eq $review.validation -or
                [string]$review.validation.status -ne "pass") {
                $Errors.Add("${context}: captured review requires validation.status=pass")
            }
        }
    }
}

if ($null -ne $docsMap) {
    foreach ($fieldName in @("id", "version", "module", "baseline_doc", "doc_routes", "managed_human_docs", "machine_truth", "visual_coverage", "validation")) {
        Test-RequiredField -Object $docsMap -Field $fieldName -Context "system/reviews/review-docs-map.json" | Out-Null
    }

    Test-PathValue -PathValue ([string]$docsMap.baseline_doc) -Context "review docs baseline_doc"

    foreach ($docRoute in @($docsMap.doc_routes)) {
        if (-not (Test-RequiredField -Object $docRoute -Field "path" -Context "review docs doc_routes")) {
            continue
        }
        Test-PathValue -PathValue ([string]$docRoute.path) -Context "review docs doc_route"
        Test-RequiredField -Object $docRoute -Field "role" -Context "review docs doc_route '$($docRoute.path)'" | Out-Null
        Test-RequiredField -Object $docRoute -Field "boundary" -Context "review docs doc_route '$($docRoute.path)'" | Out-Null
    }

    foreach ($pathValue in @($docsMap.managed_human_docs)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review docs managed_human_docs"
    }
    foreach ($pathValue in @($docsMap.machine_truth)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review docs machine_truth"
    }
    foreach ($pathValue in @($docsMap.validation)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "review docs validation"
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "Reviews validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Reviews validation passed."
