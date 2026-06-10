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

function Test-RegistryPath {
    param(
        [string]$PathValue,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        $Errors.Add("${Context}: empty path")
        return
    }

    if ($PathValue -in @("json-parse-canvas")) {
        return
    }

    $fullPath = Join-Path $Root $PathValue
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $Errors.Add("${Context}: path does not exist: $PathValue")
    }
}

function Test-RegistryPathReference {
    param(
        [string]$PathValue,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        $Errors.Add("${Context}: empty path reference")
        return
    }

    $pathOnly = ([string]$PathValue).Split("#")[0]
    Test-RegistryPath -PathValue $pathOnly -Context $Context
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

function Test-TextIntegrity {
    param(
        [string]$Text,
        [string]$Context
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return
    }

    if ($Text -match '[?]{4,}') {
        $Errors.Add("${Context}: contains question-mark placeholder corruption")
    }
    if ($Text -match '[\uE000-\uF8FF]') {
        $Errors.Add("${Context}: contains Unicode private-use characters often produced by encoding mojibake")
    }
    if ($Text -match ([string][char]0xFFFD)) {
        $Errors.Add("${Context}: contains Unicode replacement character")
    }
    if ($Text.Contains([string][char]0x951F)) {
        $Errors.Add("${Context}: contains CJK mojibake marker")
    }
    $likelyMojibakePatterns = @(
        @(0x93c1, 0x5474, 0x6bb0),
        @(0x93ba, 0x6393, 0x7161),
        @(0x93c8, 0xe101, 0x6783),
        @(0x7eeb, 0x660f),
        @(0x752f, 0x6b4c),
        @(0x9425, 0x56e9, 0x59f8),
        @(0x74ba, 0xe21a, 0x7dde),
        @(0x7eef, 0x8364, 0x7cba),
        @(0x9352, 0x55d9, 0x88ab),
        @(0x9418, 0x8235),
        @(0x7ef1, 0x3220, 0x7d29),
        @(0x9351, 0x8679, 0x5e47),
        @(0x95c2, 0xe1bc, 0x5f7f),
        @(0x9350, 0x6b0f, 0x53c6),
        @(0x7487, 0x5a43, 0x67c7),
        @(0x59af, 0x2033, 0x6f61),
        @(0x6d93, 0x5d88, 0x5158)
    )
    foreach ($likelyMojibakePatternCodepoints in $likelyMojibakePatterns) {
        $likelyMojibakePattern = -join ($likelyMojibakePatternCodepoints | ForEach-Object { [string][char]$_ })
        if ($Text.Contains($likelyMojibakePattern)) {
            $Errors.Add("${Context}: contains likely UTF-8/GBK mojibake text")
            break
        }
    }
}

function Test-StructuredTextIntegrity {
    param(
        [object]$Value,
        [string]$Context
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [string]) {
        Test-TextIntegrity -Text ([string]$Value) -Context $Context
        return
    }

    if ($Value -is [System.ValueType]) {
        return
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $index = 0
        foreach ($item in @($Value)) {
            Test-StructuredTextIntegrity -Value $item -Context "${Context}[$index]"
            $index += 1
        }
        return
    }

    foreach ($property in @($Value.PSObject.Properties)) {
        Test-StructuredTextIntegrity -Value $property.Value -Context "${Context}.$($property.Name)"
    }
}

$principles = Read-JsonFile "system/development-principles.json"
$moduleGovernancePolicy = Read-JsonFile "system/module-governance-policy.json"
$systemStructureGovernance = Read-JsonFile "system/system-structure-governance.json"
$moduleRelationshipMap = Read-JsonFile "system/module-relationship-map.json"
$moduleLayerModel = Read-JsonFile "system/module-layer-model.json"
$informationMap = Read-JsonFile "system/information-map.json"
$informationMapManifest = Read-JsonFile "system/information-map-manifest.json"
$routeRegistry = Read-JsonFile "system/route-registry.json"
$canvasRegistry = Read-JsonFile "system/canvas-registry.json"
$visualCoverageMap = Read-JsonFile "system/visual-coverage-map.json"
$canvasDocsMap = Read-JsonFile "system/canvas-docs-map.json"
$technicalDocsMap = Read-JsonFile "system/technical-docs-map.json"
$systemClosureMap = Read-JsonFile "system/system-closure-map.json"
$artifactFormPolicy = Read-JsonFile "system/artifact-form-policy.json"
$toolMap = Read-JsonFile "system/tool-map.json"
$loopRegistry = Read-JsonFile "system/loop-registry.json"
$domainTaxonomy = Read-JsonFile "30-maps/domains/domain-taxonomy.registry.json"
$domainTaxonomyDocsMap = Read-JsonFile "30-maps/domains/domain-taxonomy.docs.json"
$knowledgeIngestionSourceTypes = Read-JsonFile "system/knowledge-ingestion-source-types.json"
$knowledgeAcquisitionSystem = Read-JsonFile "system/knowledge-acquisition-system.json"
$knowledgeAcquisitionQueue = Read-JsonFile "10-sources/acquisition-queue.json"

$textIntegrityRoots = @(
    "system",
    "schemas",
    "30-maps/domains"
)
foreach ($textIntegrityRoot in $textIntegrityRoots) {
    $fullTextIntegrityRoot = Join-Path $Root $textIntegrityRoot
    if (-not (Test-Path -LiteralPath $fullTextIntegrityRoot)) {
        continue
    }

    foreach ($jsonFile in @(Get-ChildItem -LiteralPath $fullTextIntegrityRoot -Recurse -File -Filter "*.json")) {
        $relativePath = $jsonFile.FullName.Substring($Root.Length + 1).Replace("\", "/")
        $jsonValue = Read-JsonFile $relativePath
        if ($null -ne $jsonValue) {
            Test-StructuredTextIntegrity -Value $jsonValue -Context $relativePath
        }
    }
}

$rawTextIntegrityTargets = @(
    "AGENTS.md",
    "README.md",
    "docs",
    ".agents/skills",
    "scripts",
    "30-maps",
    "70-indexes"
)
$rawTextExtensions = @(".md", ".json", ".canvas", ".ps1", ".yaml", ".yml", ".csv", ".txt")
foreach ($rawTextIntegrityTarget in $rawTextIntegrityTargets) {
    $fullRawTextTarget = Join-Path $Root $rawTextIntegrityTarget
    if (-not (Test-Path -LiteralPath $fullRawTextTarget)) {
        continue
    }

    $rawTextFiles = @()
    $rawTextItem = Get-Item -LiteralPath $fullRawTextTarget
    if ($rawTextItem.PSIsContainer) {
        $rawTextFiles = @(Get-ChildItem -LiteralPath $fullRawTextTarget -Recurse -File | Where-Object { $rawTextExtensions -contains $_.Extension.ToLowerInvariant() })
    }
    else {
        $rawTextFiles = @($rawTextItem)
    }

    foreach ($rawTextFile in $rawTextFiles) {
        $relativePath = $rawTextFile.FullName.Substring($Root.Length + 1).Replace("\", "/")
        try {
            $rawText = Get-Content -LiteralPath $rawTextFile.FullName -Raw -Encoding UTF8
            Test-TextIntegrity -Text $rawText -Context $relativePath
        }
        catch {
            $Errors.Add("${relativePath}: unable to read as UTF-8 text - $($_.Exception.Message)")
        }
    }
}

if ($null -ne $principles) {
    if (-not $principles.principles -or $principles.principles.Count -lt 4) {
        $Errors.Add("system/development-principles.json: expected at least 4 principles")
    }

    $principleIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($principle in @($principles.principles)) {
        if ($principle.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$principle.id)) {
            [void]$principleIds.Add([string]$principle.id)
        }
    }
    foreach ($requiredPrincipleId in @("diagnose-before-fixing", "coordinated-system-upgrade", "information-map-and-machine-friendly-flow", "new-system-modules-inherit-legacy-responsibility", "thin-entrypoints-route-to-machine-truth")) {
        if (-not $principleIds.Contains($requiredPrincipleId)) {
            $Errors.Add("system/development-principles.json: missing principle '$requiredPrincipleId'")
        }
    }
}

if ($null -ne $moduleGovernancePolicy) {
    foreach ($fieldName in @("decision_agent", "principles", "layers", "governed_surfaces", "new_module_contract", "placement_checklist", "directory_policy", "subsystem_documentation_policy", "thin_entrypoint_policy")) {
        Test-RequiredField -Object $moduleGovernancePolicy -Field $fieldName -Context "system/module-governance-policy.json" | Out-Null
    }

    if (-not $moduleGovernancePolicy.principles -or $moduleGovernancePolicy.principles.Count -lt 5) {
        $Errors.Add("system/module-governance-policy.json: expected at least 5 principles")
    }

    foreach ($layer in @($moduleGovernancePolicy.layers)) {
        if (-not (Test-RequiredField -Object $layer -Field "id" -Context "system/module-governance-policy.json layer")) {
            continue
        }
        $layerId = [string]$layer.PSObject.Properties["id"].Value
        foreach ($fieldName in @("name", "purpose", "default_paths", "truth_policy")) {
            Test-RequiredField -Object $layer -Field $fieldName -Context "module governance layer '$layerId'" | Out-Null
        }
        foreach ($pathValue in @($layer.default_paths)) {
            Test-RegistryPath -PathValue $pathValue -Context "module governance layer '$layerId' default_paths"
        }
    }

    foreach ($surface in @($moduleGovernancePolicy.governed_surfaces)) {
        if (-not (Test-RequiredField -Object $surface -Field "surface" -Context "system/module-governance-policy.json governed_surface")) {
            continue
        }
        $surfaceId = [string]$surface.PSObject.Properties["surface"].Value
        if (Test-RequiredField -Object $surface -Field "registry_or_map" -Context "module governance surface '$surfaceId'") {
            Test-RegistryPath -PathValue ([string]$surface.PSObject.Properties["registry_or_map"].Value) -Context "module governance surface '$surfaceId' registry_or_map"
        }
        Test-RequiredField -Object $surface -Field "update_when" -Context "module governance surface '$surfaceId'" | Out-Null
    }

    if (Test-RequiredField -Object $moduleGovernancePolicy.new_module_contract -Field "required_fields" -Context "system/module-governance-policy.json new_module_contract") {
        $contractFields = @($moduleGovernancePolicy.new_module_contract.required_fields)
        if ($contractFields.Count -lt 8) {
            $Errors.Add("system/module-governance-policy.json: new_module_contract.required_fields is too small")
        }
        foreach ($requiredContractField in @("module_id", "layer", "boundary", "canonical_truth", "storage_home", "registry_entry", "route_entry", "validation", "lifecycle_status", "baseline_doc", "docs_map", "legacy_scope", "legacy_asset_audit", "legacy_asset_action", "activation_proof")) {
            if ($contractFields -notcontains $requiredContractField) {
                $Errors.Add("system/module-governance-policy.json: new_module_contract.required_fields missing '$requiredContractField'")
            }
        }
    }

    $placementStepIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($checklistStep in @($moduleGovernancePolicy.placement_checklist)) {
        if (-not (Test-RequiredField -Object $checklistStep -Field "step" -Context "system/module-governance-policy.json placement_checklist")) {
            continue
        }
        $stepId = [string]$checklistStep.PSObject.Properties["step"].Value
        [void]$placementStepIds.Add($stepId)
        foreach ($fieldName in @("question", "required_output")) {
            Test-RequiredField -Object $checklistStep -Field $fieldName -Context "module governance checklist '$stepId'" | Out-Null
        }
    }
    if (-not $placementStepIds.Contains("prove-module-activation")) {
        $Errors.Add("system/module-governance-policy.json: placement_checklist missing 'prove-module-activation'")
    }

    if (Test-RequiredField -Object $moduleGovernancePolicy -Field "thin_entrypoint_policy" -Context "system/module-governance-policy.json") {
        $thinEntrypointPolicy = $moduleGovernancePolicy.thin_entrypoint_policy
        foreach ($fieldName in @("id", "purpose", "applies_to", "allowed_content", "routed_content", "routing_rule", "internal_module_rule", "validation")) {
            Test-RequiredField -Object $thinEntrypointPolicy -Field $fieldName -Context "system/module-governance-policy.json thin_entrypoint_policy" | Out-Null
        }

        $thinEntrypointAppliesTo = @($thinEntrypointPolicy.applies_to | ForEach-Object { [string]$_ })
        foreach ($requiredThinEntrypointTarget in @("AGENTS.md", ".agents/skills/*/SKILL.md", "module baseline docs", "child-agent docs", "subsystem README entrypoints")) {
            if ($thinEntrypointAppliesTo -notcontains $requiredThinEntrypointTarget) {
                $Errors.Add("system/module-governance-policy.json: thin_entrypoint_policy.applies_to missing '$requiredThinEntrypointTarget'")
            }
        }

        foreach ($validationPath in @($thinEntrypointPolicy.validation)) {
            Test-RegistryPath -PathValue ([string]$validationPath) -Context "system/module-governance-policy.json thin_entrypoint_policy validation"
        }
    }

    if (Test-RequiredField -Object $moduleGovernancePolicy -Field "module_activation_contract" -Context "system/module-governance-policy.json") {
        $activationContract = $moduleGovernancePolicy.module_activation_contract
        foreach ($fieldName in @("rule", "required_when", "current_required_modules", "activation_status_values", "required_fields", "acceptance_rule", "validation")) {
            Test-RequiredField -Object $activationContract -Field $fieldName -Context "system/module-governance-policy.json module_activation_contract" | Out-Null
        }

        $activationRequiredFields = @($activationContract.required_fields | ForEach-Object { [string]$_ })
        foreach ($requiredActivationField in @("activation_id", "module_id", "activation_status", "activation_date", "route_registered", "information_map_registered", "closure_registered", "topology_registered", "legacy_asset_audit", "visual_coverage_decision", "validation_reports", "acceptance")) {
            if ($activationRequiredFields -notcontains $requiredActivationField) {
                $Errors.Add("system/module-governance-policy.json: module_activation_contract.required_fields missing '$requiredActivationField'")
            }
        }

        $activationStatuses = @($activationContract.activation_status_values | ForEach-Object { [string]$_ })
        foreach ($requiredActivationStatus in @("active", "partial", "blocked")) {
            if ($activationStatuses -notcontains $requiredActivationStatus) {
                $Errors.Add("system/module-governance-policy.json: module_activation_contract.activation_status_values missing '$requiredActivationStatus'")
            }
        }

        foreach ($validationPath in @($activationContract.validation)) {
            Test-RegistryPath -PathValue ([string]$validationPath) -Context "system/module-governance-policy.json module_activation_contract validation"
        }
    }

    if ($moduleGovernancePolicy.PSObject.Properties.Name -contains "minimum_system_change_validation") {
        foreach ($pathValue in @($moduleGovernancePolicy.minimum_system_change_validation)) {
            Test-RegistryPath -PathValue $pathValue -Context "module governance minimum_system_change_validation"
        }
    }

    if ($moduleGovernancePolicy.PSObject.Properties.Name -contains "conditional_validation") {
        foreach ($validationRule in @($moduleGovernancePolicy.conditional_validation)) {
            if (-not (Test-RequiredField -Object $validationRule -Field "trigger" -Context "system/module-governance-policy.json conditional_validation")) {
                continue
            }
            $trigger = [string]$validationRule.PSObject.Properties["trigger"].Value
            if (-not (Test-RequiredField -Object $validationRule -Field "validation" -Context "module governance conditional_validation '$trigger'")) {
                continue
            }
            foreach ($pathValue in @($validationRule.validation)) {
                Test-RegistryPath -PathValue $pathValue -Context "module governance conditional_validation '$trigger'"
            }
        }
    }
}

$localSkillsRoot = Join-Path $Root ".agents/skills"
if (Test-Path -LiteralPath $localSkillsRoot) {
    foreach ($skillFile in @(Get-ChildItem -LiteralPath $localSkillsRoot -Recurse -File -Filter "SKILL.md")) {
        $skillRelativePath = $skillFile.FullName.Substring($Root.Length + 1).Replace("\", "/")
        $skillText = Get-Content -LiteralPath $skillFile.FullName -Raw -Encoding UTF8
        Test-TextIntegrity -Text $skillText -Context $skillRelativePath

        $skillLines = @($skillText -split "`r?`n")
        if ($skillLines.Count -gt 60) {
            $Errors.Add("${skillRelativePath}: local SKILL.md must remain a thin entrypoint; found $($skillLines.Count) lines")
        }

        if ($skillText -notmatch "system/route-registry\.json") {
            $Errors.Add("${skillRelativePath}: thin skill entrypoint must route through system/route-registry.json")
        }

        if ($skillText -notmatch "(?i)machine truth|机器真相") {
            $Errors.Add("${skillRelativePath}: thin skill entrypoint must name machine truth")
        }

        if ($skillText -match "(?m)^##\s+(Workflow|Output|工作流|输出)\b") {
            $Errors.Add("${skillRelativePath}: SKILL.md must not own workflow or output-template sections; route those details to machine truth")
        }
    }
}

if ($null -ne $systemStructureGovernance) {
    foreach ($fieldName in @("id", "version", "updated", "role", "purpose", "owner_module", "owns", "does_not_own", "decision_workflow", "branch_decision_values", "relation_types", "canonical_outputs", "quality_gates", "validation", "legacy_asset_policy")) {
        Test-RequiredField -Object $systemStructureGovernance -Field $fieldName -Context "system/system-structure-governance.json" | Out-Null
    }

    foreach ($pathValue in @($systemStructureGovernance.canonical_outputs)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/system-structure-governance.json canonical_outputs"
    }
    foreach ($pathValue in @($systemStructureGovernance.validation)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/system-structure-governance.json validation"
    }

    $decisionValues = New-Object System.Collections.Generic.HashSet[string]
    foreach ($decisionEntry in @($systemStructureGovernance.branch_decision_values)) {
        if (-not (Test-RequiredField -Object $decisionEntry -Field "decision" -Context "system/system-structure-governance.json branch_decision_values")) {
            continue
        }
        $decisionValue = [string]$decisionEntry.PSObject.Properties["decision"].Value
        if (-not $decisionValues.Add($decisionValue)) {
            $Errors.Add("system/system-structure-governance.json: duplicate branch decision '$decisionValue'")
        }
        Test-RequiredField -Object $decisionEntry -Field "use_when" -Context "system/system-structure-governance.json branch_decision '$decisionValue'" | Out-Null
    }

    $structureWorkflowStepIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($workflowStep in @($systemStructureGovernance.decision_workflow)) {
        if (-not (Test-RequiredField -Object $workflowStep -Field "step" -Context "system/system-structure-governance.json decision_workflow")) {
            continue
        }
        $stepId = [string]$workflowStep.PSObject.Properties["step"].Value
        [void]$structureWorkflowStepIds.Add($stepId)
        foreach ($fieldName in @("required_input", "output")) {
            Test-RequiredField -Object $workflowStep -Field $fieldName -Context "system/system-structure-governance.json workflow '$stepId'" | Out-Null
        }
    }
    if (-not $structureWorkflowStepIds.Contains("audit-existing-governed-assets")) {
        $Errors.Add("system/system-structure-governance.json: decision_workflow missing 'audit-existing-governed-assets'")
    }
    if (-not $structureWorkflowStepIds.Contains("prove-module-activation")) {
        $Errors.Add("system/system-structure-governance.json: decision_workflow missing 'prove-module-activation'")
    }

    if ($systemStructureGovernance.PSObject.Properties.Name -contains "legacy_asset_policy" -and $null -ne $systemStructureGovernance.legacy_asset_policy) {
        foreach ($fieldName in @("rule", "required_when", "actions", "required_outputs")) {
            Test-RequiredField -Object $systemStructureGovernance.legacy_asset_policy -Field $fieldName -Context "system/system-structure-governance.json legacy_asset_policy" | Out-Null
        }
        $legacyActions = @($systemStructureGovernance.legacy_asset_policy.actions | ForEach-Object { [string]$_ })
        foreach ($requiredLegacyAction in @("adopt", "migrate", "deprecate", "archive", "exempt_with_reason", "queue_follow_up")) {
            if ($legacyActions -notcontains $requiredLegacyAction) {
                $Errors.Add("system/system-structure-governance.json: legacy_asset_policy.actions missing '$requiredLegacyAction'")
            }
        }
        $legacyOutputs = @($systemStructureGovernance.legacy_asset_policy.required_outputs | ForEach-Object { [string]$_ })
        foreach ($requiredLegacyOutput in @("legacy_scope", "legacy_asset_audit", "legacy_asset_action")) {
            if ($legacyOutputs -notcontains $requiredLegacyOutput) {
                $Errors.Add("system/system-structure-governance.json: legacy_asset_policy.required_outputs missing '$requiredLegacyOutput'")
            }
        }
    }
}

$moduleLayerIds = New-Object System.Collections.Generic.HashSet[string]
$moduleLayerAssignmentsById = @{}

if ($null -ne $moduleLayerModel) {
    foreach ($fieldName in @("id", "version", "updated", "role", "purpose", "axes", "layers", "module_assignments", "boundary_rules", "validation")) {
        Test-RequiredField -Object $moduleLayerModel -Field $fieldName -Context "system/module-layer-model.json" | Out-Null
    }

    foreach ($axis in @($moduleLayerModel.axes)) {
        if (-not (Test-RequiredField -Object $axis -Field "id" -Context "system/module-layer-model.json axis")) {
            continue
        }
        $axisId = [string]$axis.PSObject.Properties["id"].Value
        Test-RequiredField -Object $axis -Field "rule" -Context "system/module-layer-model.json axis '$axisId'" | Out-Null
    }

    foreach ($layer in @($moduleLayerModel.layers)) {
        if (-not (Test-RequiredField -Object $layer -Field "id" -Context "system/module-layer-model.json layer")) {
            continue
        }
        $layerId = [string]$layer.PSObject.Properties["id"].Value
        if (-not $moduleLayerIds.Add($layerId)) {
            $Errors.Add("system/module-layer-model.json: duplicate layer id '$layerId'")
        }
        foreach ($fieldName in @("order", "name", "purpose", "owns_modules", "not_for", "truth_policy")) {
            Test-RequiredField -Object $layer -Field $fieldName -Context "system/module-layer-model.json layer '$layerId'" | Out-Null
        }
    }

    foreach ($assignment in @($moduleLayerModel.module_assignments)) {
        if (-not (Test-RequiredField -Object $assignment -Field "module_id" -Context "system/module-layer-model.json module_assignment")) {
            continue
        }
        $moduleId = [string]$assignment.PSObject.Properties["module_id"].Value
        if ($moduleLayerAssignmentsById.ContainsKey($moduleId)) {
            $Errors.Add("system/module-layer-model.json: duplicate module_assignment for '$moduleId'")
        }
        else {
            $moduleLayerAssignmentsById[$moduleId] = $assignment
        }
        foreach ($fieldName in @("owner_layer", "module_kind", "reason", "cross_cutting_roles")) {
            Test-RequiredField -Object $assignment -Field $fieldName -Context "system/module-layer-model.json module_assignment '$moduleId'" | Out-Null
        }
        if ($assignment.PSObject.Properties.Name -contains "owner_layer") {
            $ownerLayer = [string]$assignment.PSObject.Properties["owner_layer"].Value
            if ($moduleLayerIds.Count -gt 0 -and -not $moduleLayerIds.Contains($ownerLayer)) {
                $Errors.Add("system/module-layer-model.json: module_assignment '$moduleId' references unknown owner_layer '$ownerLayer'")
            }
        }
    }

    foreach ($validationPath in @($moduleLayerModel.validation)) {
        Test-RegistryPath -PathValue ([string]$validationPath) -Context "system/module-layer-model.json validation"
    }

    foreach ($layer in @($moduleLayerModel.layers)) {
        if (-not ($layer.PSObject.Properties.Name -contains "id") -or -not ($layer.PSObject.Properties.Name -contains "owns_modules")) {
            continue
        }
        $layerId = [string]$layer.id
        foreach ($ownedModuleValue in @($layer.owns_modules)) {
            $ownedModule = [string]$ownedModuleValue
            if (-not $moduleLayerAssignmentsById.ContainsKey($ownedModule)) {
                $Errors.Add("system/module-layer-model.json: layer '$layerId' owns unknown module '$ownedModule'")
                continue
            }
            $assignedLayer = [string]$moduleLayerAssignmentsById[$ownedModule].owner_layer
            if ($assignedLayer -ne $layerId) {
                $Errors.Add("system/module-layer-model.json: layer '$layerId' owns module '$ownedModule' but assignment owner_layer is '$assignedLayer'")
            }
        }
    }
}

if ($null -ne $moduleGovernancePolicy -and $moduleLayerIds.Count -gt 0) {
    $governanceLayerIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($layer in @($moduleGovernancePolicy.layers)) {
        if ($layer.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$layer.id)) {
            [void]$governanceLayerIds.Add([string]$layer.id)
        }
    }

    foreach ($layerIdValue in $moduleLayerIds) {
        $layerId = [string]$layerIdValue
        if (-not $governanceLayerIds.Contains($layerId)) {
            $Errors.Add("system/module-governance-policy.json: missing layer '$layerId' from system/module-layer-model.json")
        }
    }
    foreach ($layerIdValue in $governanceLayerIds) {
        $layerId = [string]$layerIdValue
        if (-not $moduleLayerIds.Contains($layerId)) {
            $Errors.Add("system/module-governance-policy.json: layer '$layerId' is not declared in system/module-layer-model.json")
        }
    }
}

if ($null -ne $informationMap) {
    $moduleIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($module in @($informationMap.modules)) {
        if ([string]::IsNullOrWhiteSpace($module.id)) {
            $Errors.Add("system/information-map.json: module missing id")
            continue
        }
        if (-not $moduleIds.Add([string]$module.id)) {
            $Errors.Add("system/information-map.json: duplicate module id '$($module.id)'")
        }
        foreach ($modulePath in @($module.paths)) {
            Test-RegistryPath -PathValue $modulePath -Context "module '$($module.id)'"
        }

        if ($moduleLayerAssignmentsById.Count -gt 0) {
            if (-not $moduleLayerAssignmentsById.ContainsKey([string]$module.id)) {
                $Errors.Add("system/module-layer-model.json: information-map module '$($module.id)' has no module assignment")
            }
            else {
                $assignment = $moduleLayerAssignmentsById[[string]$module.id]
                foreach ($fieldName in @("owner_layer", "module_kind")) {
                    if (-not (Test-RequiredField -Object $module -Field $fieldName -Context "system/information-map.json module '$($module.id)'")) {
                        continue
                    }
                    $actualValue = [string]$module.PSObject.Properties[$fieldName].Value
                    $expectedValue = [string]$assignment.PSObject.Properties[$fieldName].Value
                    if ($actualValue -ne $expectedValue) {
                        $Errors.Add("system/information-map.json module '$($module.id)': $fieldName '$actualValue' does not match system/module-layer-model.json '$expectedValue'")
                    }
                }
            }
        }
    }

    if ($moduleLayerAssignmentsById.Count -gt 0) {
        foreach ($assignedModuleIdValue in $moduleLayerAssignmentsById.Keys) {
            $assignedModuleId = [string]$assignedModuleIdValue
            if (-not $moduleIds.Contains($assignedModuleId)) {
                $Errors.Add("system/module-layer-model.json: module_assignment '$assignedModuleId' is not registered in information-map")
            }
        }
    }

    foreach ($entrypoint in @($informationMap.entrypoints)) {
        Test-RegistryPath -PathValue $entrypoint.path -Context "entrypoint '$($entrypoint.id)'"
    }

    foreach ($flow in @($informationMap.dataflows)) {
        foreach ($from in @($flow.from)) {
            if (-not $moduleIds.Contains([string]$from)) {
                $Errors.Add("dataflow '$($flow.id)': unknown from module '$from'")
            }
        }
        foreach ($to in @($flow.to)) {
            if (-not $moduleIds.Contains([string]$to)) {
                $Errors.Add("dataflow '$($flow.id)': unknown to module '$to'")
            }
        }
    }

    if ($null -ne $informationMapManifest) {
        foreach ($fieldName in @("id", "artifact_type", "owner_module", "status", "source_map_ref", "purpose", "read_policy", "shard_index", "compatibility_refs", "validation_refs", "updated")) {
            Test-RequiredField -Object $informationMapManifest -Field $fieldName -Context "system/information-map-manifest.json" | Out-Null
        }

        if ($informationMapManifest.PSObject.Properties.Name -contains "owner_module") {
            $manifestOwner = [string]$informationMapManifest.owner_module
            if (-not $moduleIds.Contains($manifestOwner)) {
                $Errors.Add("system/information-map-manifest.json: owner_module '$manifestOwner' is not registered in information-map")
            }
        }

        if ($informationMapManifest.PSObject.Properties.Name -contains "source_map_ref") {
            Test-RegistryPathReference -PathValue ([string]$informationMapManifest.source_map_ref) -Context "system/information-map-manifest.json source_map_ref"
        }

        foreach ($compatibilityRef in @($informationMapManifest.compatibility_refs)) {
            Test-RegistryPathReference -PathValue ([string]$compatibilityRef) -Context "system/information-map-manifest.json compatibility_refs"
        }

        foreach ($validationRef in @($informationMapManifest.validation_refs)) {
            Test-RegistryPathReference -PathValue ([string]$validationRef) -Context "system/information-map-manifest.json validation_refs"
        }

        $manifestShardIds = New-Object System.Collections.Generic.HashSet[string]
        foreach ($shardEntry in @($informationMapManifest.shard_index)) {
            if (-not (Test-RequiredField -Object $shardEntry -Field "shard_id" -Context "system/information-map-manifest.json shard_index")) {
                continue
            }
            $shardId = [string]$shardEntry.PSObject.Properties["shard_id"].Value
            if (-not $manifestShardIds.Add($shardId)) {
                $Errors.Add("system/information-map-manifest.json: duplicate shard_id '$shardId'")
            }

            foreach ($fieldName in @("shard_ref", "content_scope", "read_policy")) {
                Test-RequiredField -Object $shardEntry -Field $fieldName -Context "system/information-map-manifest.json shard_index '$shardId'" | Out-Null
            }

            if (-not ($shardEntry.PSObject.Properties.Name -contains "shard_ref")) {
                continue
            }

            $shardRef = [string]$shardEntry.shard_ref
            Test-RegistryPathReference -PathValue $shardRef -Context "system/information-map-manifest.json shard_index '$shardId' shard_ref"
            $shard = Read-JsonFile $shardRef
            if ($null -eq $shard) {
                continue
            }

            foreach ($fieldName in @("id", "artifact_type", "owner_module", "parent_manifest_ref", "scope", "routing_policy", "entry_refs", "boundary_refs", "updated")) {
                Test-RequiredField -Object $shard -Field $fieldName -Context "$shardRef" | Out-Null
            }

            if ($shard.PSObject.Properties.Name -contains "id" -and [string]$shard.id -ne $shardId) {
                $Errors.Add("${shardRef}: id '$($shard.id)' does not match manifest shard_id '$shardId'")
            }

            if ($shard.PSObject.Properties.Name -contains "owner_module") {
                $shardOwner = [string]$shard.owner_module
                if (-not $moduleIds.Contains($shardOwner)) {
                    $Errors.Add("${shardRef}: owner_module '$shardOwner' is not registered in information-map")
                }
            }

            if ($shard.PSObject.Properties.Name -contains "parent_manifest_ref") {
                Test-RegistryPathReference -PathValue ([string]$shard.parent_manifest_ref) -Context "${shardRef} parent_manifest_ref"
            }

            $entryRefIds = New-Object System.Collections.Generic.HashSet[string]
            foreach ($entryRef in @($shard.entry_refs)) {
                if (-not (Test-RequiredField -Object $entryRef -Field "entry_id" -Context "${shardRef} entry_refs")) {
                    continue
                }
                $entryRefId = [string]$entryRef.PSObject.Properties["entry_id"].Value
                if (-not $entryRefIds.Add($entryRefId)) {
                    $Errors.Add("${shardRef}: duplicate entry_ref '$entryRefId'")
                }

                foreach ($fieldName in @("entry_type", "owner_module", "summary", "reference_surfaces", "related_entries")) {
                    Test-RequiredField -Object $entryRef -Field $fieldName -Context "${shardRef} entry_ref '$entryRefId'" | Out-Null
                }

                if ($entryRef.PSObject.Properties.Name -contains "owner_module") {
                    $entryOwner = [string]$entryRef.owner_module
                    if (-not $moduleIds.Contains($entryOwner)) {
                        $Errors.Add("${shardRef}: entry_ref '$entryRefId' owner_module '$entryOwner' is not registered in information-map")
                    }
                }

                foreach ($referenceSurface in @($entryRef.reference_surfaces)) {
                    Test-RegistryPathReference -PathValue ([string]$referenceSurface) -Context "${shardRef} entry_ref '$entryRefId' reference_surfaces"
                }
            }
        }
    }

    if ($null -ne $moduleRelationshipMap) {
        foreach ($fieldName in @("id", "version", "updated", "role", "purpose", "owner_module", "source_of_truth", "branches", "modules", "relationships", "branch_decision_policy", "pending_decisions", "validation", "current_layer_relationship_audit")) {
            Test-RequiredField -Object $moduleRelationshipMap -Field $fieldName -Context "system/module-relationship-map.json" | Out-Null
        }

        foreach ($pathValue in @($moduleRelationshipMap.source_of_truth)) {
            Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/module-relationship-map.json source_of_truth"
        }
        foreach ($pathValue in @($moduleRelationshipMap.validation)) {
            Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/module-relationship-map.json validation"
        }

        if ($moduleRelationshipMap.PSObject.Properties.Name -contains "owner_module") {
            $topologyOwner = [string]$moduleRelationshipMap.owner_module
            if (-not $moduleIds.Contains($topologyOwner)) {
                $Errors.Add("system/module-relationship-map.json: owner_module '$topologyOwner' is not registered in information-map")
            }
        }

        $topologyBranchIds = New-Object System.Collections.Generic.HashSet[string]
        foreach ($branch in @($moduleRelationshipMap.branches)) {
            if (-not (Test-RequiredField -Object $branch -Field "branch_id" -Context "system/module-relationship-map.json branch")) {
                continue
            }
            $branchId = [string]$branch.PSObject.Properties["branch_id"].Value
            if (-not $topologyBranchIds.Add($branchId)) {
                $Errors.Add("system/module-relationship-map.json: duplicate branch '$branchId'")
            }
            foreach ($fieldName in @("name", "purpose", "decision_owner", "module_ids", "branch_policy")) {
                Test-RequiredField -Object $branch -Field $fieldName -Context "system/module-relationship-map.json branch '$branchId'" | Out-Null
            }
            if ($moduleLayerIds.Count -gt 0 -and -not $moduleLayerIds.Contains($branchId)) {
                $Errors.Add("system/module-relationship-map.json: branch '$branchId' is not declared in system/module-layer-model.json")
            }
            if ($branch.PSObject.Properties.Name -contains "decision_owner" -and -not $moduleIds.Contains([string]$branch.decision_owner)) {
                $Errors.Add("system/module-relationship-map.json: branch '$branchId' decision_owner '$($branch.decision_owner)' is not registered in information-map")
            }
        }

        $topologyModuleIds = New-Object System.Collections.Generic.HashSet[string]
        $topologyModuleById = @{}
        foreach ($topologyModule in @($moduleRelationshipMap.modules)) {
            if (-not (Test-RequiredField -Object $topologyModule -Field "module_id" -Context "system/module-relationship-map.json module")) {
                continue
            }
            $topologyModuleId = [string]$topologyModule.PSObject.Properties["module_id"].Value
            if (-not $topologyModuleIds.Add($topologyModuleId)) {
                $Errors.Add("system/module-relationship-map.json: duplicate module '$topologyModuleId'")
            }
            else {
                $topologyModuleById[$topologyModuleId] = $topologyModule
            }
            foreach ($fieldName in @("branch_id", "module_kind", "status", "reason")) {
                Test-RequiredField -Object $topologyModule -Field $fieldName -Context "system/module-relationship-map.json module '$topologyModuleId'" | Out-Null
            }

            if (-not $moduleIds.Contains($topologyModuleId)) {
                $Errors.Add("system/module-relationship-map.json: topology module '$topologyModuleId' is not registered in information-map")
            }
            if ($topologyModule.PSObject.Properties.Name -contains "branch_id") {
                $branchId = [string]$topologyModule.branch_id
                if ($topologyBranchIds.Count -gt 0 -and -not $topologyBranchIds.Contains($branchId)) {
                    $Errors.Add("system/module-relationship-map.json: module '$topologyModuleId' references unknown branch '$branchId'")
                }
                if ($moduleLayerAssignmentsById.ContainsKey($topologyModuleId)) {
                    $expectedLayer = [string]$moduleLayerAssignmentsById[$topologyModuleId].owner_layer
                    if ($branchId -ne $expectedLayer) {
                        $Errors.Add("system/module-relationship-map.json: module '$topologyModuleId' branch_id '$branchId' does not match system/module-layer-model.json owner_layer '$expectedLayer'")
                    }
                }
            }
        }

        foreach ($moduleIdValue in $moduleIds) {
            $moduleId = [string]$moduleIdValue
            if (-not $topologyModuleIds.Contains($moduleId)) {
                $Errors.Add("system/module-relationship-map.json: information-map module '$moduleId' has no topology module entry")
            }
        }

        foreach ($branch in @($moduleRelationshipMap.branches)) {
            if (-not ($branch.PSObject.Properties.Name -contains "branch_id") -or -not ($branch.PSObject.Properties.Name -contains "module_ids")) {
                continue
            }
            $branchId = [string]$branch.branch_id
            foreach ($branchModuleValue in @($branch.module_ids)) {
                $branchModuleId = [string]$branchModuleValue
                if (-not $topologyModuleById.ContainsKey($branchModuleId)) {
                    $Errors.Add("system/module-relationship-map.json: branch '$branchId' lists unknown module '$branchModuleId'")
                    continue
                }
                $actualBranch = [string]$topologyModuleById[$branchModuleId].branch_id
                if ($actualBranch -ne $branchId) {
                    $Errors.Add("system/module-relationship-map.json: branch '$branchId' lists module '$branchModuleId' but module branch_id is '$actualBranch'")
                }
            }
        }

        $allowedRelationTypes = New-Object System.Collections.Generic.HashSet[string]
        if ($null -ne $systemStructureGovernance -and $systemStructureGovernance.PSObject.Properties.Name -contains "relation_types") {
            foreach ($relationTypeValue in @($systemStructureGovernance.relation_types)) {
                [void]$allowedRelationTypes.Add([string]$relationTypeValue)
            }
        }

        foreach ($relation in @($moduleRelationshipMap.relationships)) {
            foreach ($fieldName in @("from", "to", "relation", "reason")) {
                Test-RequiredField -Object $relation -Field $fieldName -Context "system/module-relationship-map.json relationship" | Out-Null
            }
            if (-not ($relation.PSObject.Properties.Name -contains "from") -or -not ($relation.PSObject.Properties.Name -contains "to")) {
                continue
            }
            $fromModule = [string]$relation.from
            $toModule = [string]$relation.to
            if (-not $topologyModuleIds.Contains($fromModule)) {
                $Errors.Add("system/module-relationship-map.json: relationship from '$fromModule' is not a topology module")
            }
            if (-not $topologyModuleIds.Contains($toModule)) {
                $Errors.Add("system/module-relationship-map.json: relationship to '$toModule' is not a topology module")
            }
            if ($allowedRelationTypes.Count -gt 0 -and $relation.PSObject.Properties.Name -contains "relation") {
                $relationType = [string]$relation.relation
                if (-not $allowedRelationTypes.Contains($relationType)) {
                    $Errors.Add("system/module-relationship-map.json: relationship '$fromModule' -> '$toModule' uses unknown relation type '$relationType'")
                }
            }
        }

        if ($moduleRelationshipMap.PSObject.Properties.Name -contains "current_layer_relationship_audit" -and $null -ne $moduleRelationshipMap.current_layer_relationship_audit) {
            foreach ($fieldName in @("date", "status", "trigger", "scope", "method", "module_coverage", "layer_alignment", "relationship_edge_audit", "legacy_asset_actions", "acceptance")) {
                Test-RequiredField -Object $moduleRelationshipMap.current_layer_relationship_audit -Field $fieldName -Context "system/module-relationship-map.json current_layer_relationship_audit" | Out-Null
            }

            if ($moduleRelationshipMap.current_layer_relationship_audit.PSObject.Properties.Name -contains "module_coverage" -and
                $null -ne $moduleRelationshipMap.current_layer_relationship_audit.module_coverage) {
                foreach ($fieldName in @("information_map_modules", "layer_assignments", "topology_modules", "closure_modules", "audited_modules", "mismatches")) {
                    Test-RequiredField -Object $moduleRelationshipMap.current_layer_relationship_audit.module_coverage -Field $fieldName -Context "system/module-relationship-map.json current_layer_relationship_audit.module_coverage" | Out-Null
                }
                if ($moduleRelationshipMap.current_layer_relationship_audit.module_coverage.PSObject.Properties.Name -contains "audited_modules") {
                    $auditedCount = [int]$moduleRelationshipMap.current_layer_relationship_audit.module_coverage.audited_modules
                    if ($auditedCount -ne $topologyModuleIds.Count) {
                        $Errors.Add("system/module-relationship-map.json: current_layer_relationship_audit audited_modules '$auditedCount' does not match topology module count '$($topologyModuleIds.Count)'")
                    }
                }
            }

            if ($moduleRelationshipMap.current_layer_relationship_audit.PSObject.Properties.Name -contains "relationship_edge_audit" -and
                $null -ne $moduleRelationshipMap.current_layer_relationship_audit.relationship_edge_audit) {
                foreach ($fieldName in @("total_edges", "orphan_edges", "action")) {
                    Test-RequiredField -Object $moduleRelationshipMap.current_layer_relationship_audit.relationship_edge_audit -Field $fieldName -Context "system/module-relationship-map.json current_layer_relationship_audit.relationship_edge_audit" | Out-Null
                }
                if ($moduleRelationshipMap.current_layer_relationship_audit.relationship_edge_audit.PSObject.Properties.Name -contains "total_edges") {
                    $auditedEdgeCount = [int]$moduleRelationshipMap.current_layer_relationship_audit.relationship_edge_audit.total_edges
                    if ($auditedEdgeCount -ne @($moduleRelationshipMap.relationships).Count) {
                        $Errors.Add("system/module-relationship-map.json: current_layer_relationship_audit total_edges '$auditedEdgeCount' does not match relationship count '$(@($moduleRelationshipMap.relationships).Count)'")
                    }
                }
            }

            if (@($moduleRelationshipMap.current_layer_relationship_audit.legacy_asset_actions).Count -eq 0) {
                $Errors.Add("system/module-relationship-map.json: current_layer_relationship_audit legacy_asset_actions is empty")
            }
        }
    }
}

if ($null -ne $routeRegistry) {
    $routeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($route in @($routeRegistry.routes)) {
        if ([string]::IsNullOrWhiteSpace($route.id)) {
            $Errors.Add("system/route-registry.json: route missing id")
            continue
        }
        if (-not $routeIds.Add([string]$route.id)) {
            $Errors.Add("system/route-registry.json: duplicate route id '$($route.id)'")
        }
        foreach ($pathValue in @($route.read)) {
            Test-RegistryPath -PathValue $pathValue -Context "route '$($route.id)' read"
        }
        foreach ($pathValue in @($route.update_when_changed)) {
            Test-RegistryPath -PathValue $pathValue -Context "route '$($route.id)' update_when_changed"
        }
        foreach ($pathValue in @($route.validate)) {
            Test-RegistryPath -PathValue $pathValue -Context "route '$($route.id)' validate"
        }
    }
}

if ($null -ne $systemClosureMap) {
    foreach ($fieldName in @("id", "version", "status_values", "required_facets", "closure_rule", "modules", "validation")) {
        Test-RequiredField -Object $systemClosureMap -Field $fieldName -Context "system/system-closure-map.json" | Out-Null
    }

    $allowedClosureStatuses = New-Object System.Collections.Generic.HashSet[string]
    foreach ($statusEntry in @($systemClosureMap.status_values)) {
        if (-not (Test-RequiredField -Object $statusEntry -Field "status" -Context "system/system-closure-map.json status_values")) {
            continue
        }
        $statusValue = [string]$statusEntry.PSObject.Properties["status"].Value
        if (-not $allowedClosureStatuses.Add($statusValue)) {
            $Errors.Add("system/system-closure-map.json: duplicate status '$statusValue'")
        }
        Test-RequiredField -Object $statusEntry -Field "meaning" -Context "system/system-closure-map.json status '$statusValue'" | Out-Null
    }

    $requiredClosureFacets = New-Object System.Collections.Generic.HashSet[string]
    foreach ($facet in @($systemClosureMap.required_facets)) {
        if (-not (Test-RequiredField -Object $facet -Field "id" -Context "system/system-closure-map.json required_facets")) {
            continue
        }
        $facetId = [string]$facet.PSObject.Properties["id"].Value
        if (-not $requiredClosureFacets.Add($facetId)) {
            $Errors.Add("system/system-closure-map.json: duplicate required facet '$facetId'")
        }
        Test-RequiredField -Object $facet -Field "question" -Context "system/system-closure-map.json facet '$facetId'" | Out-Null
    }

    $knownInformationModuleIds = New-Object System.Collections.Generic.HashSet[string]
    if ($null -ne $informationMap) {
        foreach ($module in @($informationMap.modules)) {
            if ($module.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$module.id)) {
                [void]$knownInformationModuleIds.Add([string]$module.id)
            }
        }
    }

    $knownRouteIds = New-Object System.Collections.Generic.HashSet[string]
    if ($null -ne $routeRegistry) {
        foreach ($route in @($routeRegistry.routes)) {
            if ($route.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$route.id)) {
                [void]$knownRouteIds.Add([string]$route.id)
            }
        }
    }

    $closureModuleIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($closureModule in @($systemClosureMap.modules)) {
        if (-not (Test-RequiredField -Object $closureModule -Field "module_id" -Context "system/system-closure-map.json module")) {
            continue
        }

        $closureModuleId = [string]$closureModule.PSObject.Properties["module_id"].Value
        if (-not $closureModuleIds.Add($closureModuleId)) {
            $Errors.Add("system/system-closure-map.json: duplicate module_id '$closureModuleId'")
        }
        if ($knownInformationModuleIds.Count -gt 0 -and -not $knownInformationModuleIds.Contains($closureModuleId)) {
            $Errors.Add("system/system-closure-map.json: module '$closureModuleId' is not registered in information-map")
        }

        foreach ($fieldName in @("owner_layer", "lifecycle_status", "overall_status", "canonical_truth", "routes", "validation", "documentation", "visual_projection", "diagnostics", "facets", "known_gaps", "next_action")) {
            Test-RequiredField -Object $closureModule -Field $fieldName -Context "system closure module '$closureModuleId'" | Out-Null
        }

        if ($moduleLayerAssignmentsById.Count -gt 0) {
            if (-not $moduleLayerAssignmentsById.ContainsKey($closureModuleId)) {
                $Errors.Add("system/module-layer-model.json: closure module '$closureModuleId' has no module assignment")
            }
            elseif ($closureModule.PSObject.Properties.Name -contains "owner_layer") {
                $expectedOwnerLayer = [string]$moduleLayerAssignmentsById[$closureModuleId].owner_layer
                $actualOwnerLayer = [string]$closureModule.owner_layer
                if ($actualOwnerLayer -ne $expectedOwnerLayer) {
                    $Errors.Add("system/system-closure-map.json module '$closureModuleId': owner_layer '$actualOwnerLayer' does not match system/module-layer-model.json '$expectedOwnerLayer'")
                }
            }
        }

        if ($closureModule.PSObject.Properties.Name -contains "overall_status") {
            $overallStatus = [string]$closureModule.PSObject.Properties["overall_status"].Value
            if ($allowedClosureStatuses.Count -gt 0 -and -not $allowedClosureStatuses.Contains($overallStatus)) {
                $Errors.Add("system closure module '$closureModuleId': invalid overall_status '$overallStatus'")
            }
            if ($overallStatus -in @("partial", "seed", "missing")) {
                if (-not ($closureModule.PSObject.Properties.Name -contains "known_gaps") -or @($closureModule.known_gaps).Count -eq 0) {
                    $Errors.Add("system closure module '$closureModuleId': $overallStatus status requires known_gaps")
                }
                if (-not ($closureModule.PSObject.Properties.Name -contains "next_action") -or [string]::IsNullOrWhiteSpace([string]$closureModule.next_action)) {
                    $Errors.Add("system closure module '$closureModuleId': $overallStatus status requires next_action")
                }
            }
        }

        foreach ($pathValue in @($closureModule.canonical_truth)) {
            Test-RegistryPath -PathValue ([string]$pathValue) -Context "system closure module '$closureModuleId' canonical_truth"
        }

        foreach ($routeReference in @($closureModule.routes)) {
            if (-not (Test-RequiredField -Object $routeReference -Field "route_id" -Context "system closure module '$closureModuleId' routes")) {
                continue
            }
            $routeId = [string]$routeReference.PSObject.Properties["route_id"].Value
            if ($knownRouteIds.Count -gt 0 -and -not $knownRouteIds.Contains($routeId)) {
                $Errors.Add("system closure module '$closureModuleId': route_id '$routeId' is not registered")
            }
            if (Test-RequiredField -Object $routeReference -Field "status" -Context "system closure module '$closureModuleId' route '$routeId'") {
                $routeStatus = [string]$routeReference.PSObject.Properties["status"].Value
                if ($allowedClosureStatuses.Count -gt 0 -and -not $allowedClosureStatuses.Contains($routeStatus)) {
                    $Errors.Add("system closure module '$closureModuleId': invalid route status '$routeStatus'")
                }
            }
        }

        foreach ($pathValue in @($closureModule.validation)) {
            Test-RegistryPath -PathValue ([string]$pathValue) -Context "system closure module '$closureModuleId' validation"
        }

        foreach ($pathValue in @($closureModule.documentation)) {
            Test-RegistryPath -PathValue ([string]$pathValue) -Context "system closure module '$closureModuleId' documentation"
        }

        if ($closureModule.PSObject.Properties.Name -contains "visual_projection" -and $null -ne $closureModule.visual_projection) {
            if (Test-RequiredField -Object $closureModule.visual_projection -Field "status" -Context "system closure module '$closureModuleId' visual_projection") {
                $visualStatus = [string]$closureModule.visual_projection.PSObject.Properties["status"].Value
                if ($allowedClosureStatuses.Count -gt 0 -and -not $allowedClosureStatuses.Contains($visualStatus)) {
                    $Errors.Add("system closure module '$closureModuleId': invalid visual_projection status '$visualStatus'")
                }
            }
            Test-RequiredField -Object $closureModule.visual_projection -Field "views" -Context "system closure module '$closureModuleId' visual_projection" | Out-Null
            foreach ($pathValue in @($closureModule.visual_projection.views)) {
                Test-RegistryPath -PathValue ([string]$pathValue) -Context "system closure module '$closureModuleId' visual view"
            }
        }

        if ($closureModule.PSObject.Properties.Name -contains "diagnostics" -and $null -ne $closureModule.diagnostics) {
            if (Test-RequiredField -Object $closureModule.diagnostics -Field "status" -Context "system closure module '$closureModuleId' diagnostics") {
                $diagnosticStatus = [string]$closureModule.diagnostics.PSObject.Properties["status"].Value
                if ($allowedClosureStatuses.Count -gt 0 -and -not $allowedClosureStatuses.Contains($diagnosticStatus)) {
                    $Errors.Add("system closure module '$closureModuleId': invalid diagnostics status '$diagnosticStatus'")
                }
            }
            Test-RequiredField -Object $closureModule.diagnostics -Field "covered_by" -Context "system closure module '$closureModuleId' diagnostics" | Out-Null
        }

        if ($closureModule.PSObject.Properties.Name -contains "facets" -and $null -ne $closureModule.facets) {
            foreach ($facetIdValue in $requiredClosureFacets) {
                $facetId = [string]$facetIdValue
                if (-not ($closureModule.facets.PSObject.Properties.Name -contains $facetId)) {
                    $Errors.Add("system closure module '$closureModuleId': missing facet '$facetId'")
                    continue
                }
                $facetStatus = [string]$closureModule.facets.PSObject.Properties[$facetId].Value
                if ($allowedClosureStatuses.Count -gt 0 -and -not $allowedClosureStatuses.Contains($facetStatus)) {
                    $Errors.Add("system closure module '$closureModuleId': invalid facet '$facetId' status '$facetStatus'")
                }
            }
        }
    }

    foreach ($moduleId in $knownInformationModuleIds) {
        if (-not $closureModuleIds.Contains([string]$moduleId)) {
            $Errors.Add("system/system-closure-map.json: information-map module '$moduleId' is missing from closure map")
        }
    }

    foreach ($pathValue in @($systemClosureMap.validation)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/system-closure-map.json validation"
    }

    if ($null -ne $moduleGovernancePolicy -and
        $moduleGovernancePolicy.PSObject.Properties.Name -contains "module_activation_contract" -and
        $null -ne $moduleGovernancePolicy.module_activation_contract) {
        $activationContract = $moduleGovernancePolicy.module_activation_contract
        $activationRequiredFields = @($activationContract.required_fields | ForEach-Object { [string]$_ })
        $allowedActivationStatuses = New-Object System.Collections.Generic.HashSet[string]
        foreach ($activationStatusValue in @($activationContract.activation_status_values)) {
            [void]$allowedActivationStatuses.Add([string]$activationStatusValue)
        }

        $closureModuleById = @{}
        foreach ($closureModule in @($systemClosureMap.modules)) {
            if ($closureModule.PSObject.Properties.Name -contains "module_id" -and -not [string]::IsNullOrWhiteSpace([string]$closureModule.module_id)) {
                $closureModuleById[[string]$closureModule.module_id] = $closureModule
            }
        }

        foreach ($activationModuleValue in @($activationContract.current_required_modules)) {
            $activationModuleId = [string]$activationModuleValue
            if (-not $closureModuleById.ContainsKey($activationModuleId)) {
                $Errors.Add("system/system-closure-map.json: activation-required module '$activationModuleId' is missing from closure map")
                continue
            }

            $activationModule = $closureModuleById[$activationModuleId]
            if (-not ($activationModule.PSObject.Properties.Name -contains "activation_proof") -or $null -eq $activationModule.activation_proof) {
                $Errors.Add("system/system-closure-map.json: activation-required module '$activationModuleId' missing activation_proof")
                continue
            }

            $activationProof = $activationModule.activation_proof
            foreach ($requiredActivationField in $activationRequiredFields) {
                Test-RequiredField -Object $activationProof -Field $requiredActivationField -Context "system/system-closure-map.json activation_proof '$activationModuleId'" | Out-Null
            }

            if ($activationProof.PSObject.Properties.Name -contains "module_id" -and [string]$activationProof.module_id -ne $activationModuleId) {
                $Errors.Add("system/system-closure-map.json activation_proof '$activationModuleId': module_id '$($activationProof.module_id)' does not match closure module")
            }

            if ($activationProof.PSObject.Properties.Name -contains "activation_status") {
                $activationStatus = [string]$activationProof.activation_status
                if ($allowedActivationStatuses.Count -gt 0 -and -not $allowedActivationStatuses.Contains($activationStatus)) {
                    $Errors.Add("system/system-closure-map.json activation_proof '$activationModuleId': invalid activation_status '$activationStatus'")
                }
            }

            if ($activationProof.PSObject.Properties.Name -contains "route_registered" -and $knownRouteIds.Count -gt 0) {
                $activationRouteId = [string]$activationProof.route_registered
                if (-not $knownRouteIds.Contains($activationRouteId)) {
                    $Errors.Add("system/system-closure-map.json activation_proof '$activationModuleId': route_registered '$activationRouteId' is not a registered route")
                }
            }

            foreach ($pathField in @("information_map_registered", "closure_registered", "topology_registered", "legacy_asset_audit", "visual_coverage_decision")) {
                if ($activationProof.PSObject.Properties.Name -contains $pathField) {
                    Test-RegistryPathReference -PathValue ([string]$activationProof.PSObject.Properties[$pathField].Value) -Context "system/system-closure-map.json activation_proof '$activationModuleId' $pathField"
                }
            }

            foreach ($validationReport in @($activationProof.validation_reports)) {
                Test-RegistryPath -PathValue ([string]$validationReport) -Context "system/system-closure-map.json activation_proof '$activationModuleId' validation_reports"
            }
        }
    }
}

$canvasViewPathById = @{}
$canvasViewById = @{}

if ($null -ne $canvasRegistry) {
    $viewIds = New-Object System.Collections.Generic.HashSet[string]
    $allowedCanvasStatus = New-Object System.Collections.Generic.HashSet[string]
    $currentByFamily = @{}

    foreach ($statusEntry in @($canvasRegistry.status_values)) {
        if ($statusEntry.status) {
            [void]$allowedCanvasStatus.Add([string]$statusEntry.status)
        }
    }

    foreach ($layout in @($canvasRegistry.storage_layout)) {
        if ([string]::IsNullOrWhiteSpace($layout.id)) {
            $Errors.Add("system/canvas-registry.json: storage_layout missing id")
            continue
        }
        Test-RegistryPath -PathValue $layout.path -Context "canvas storage_layout '$($layout.id)'"
        foreach ($fieldName in @("layer", "use_for", "naming")) {
            if ([string]::IsNullOrWhiteSpace($layout.$fieldName)) {
                $Errors.Add("system/canvas-registry.json: storage_layout '$($layout.id)' missing $fieldName")
            }
        }
    }

    foreach ($typeRule in @($canvasRegistry.view_type_rules)) {
        if ([string]::IsNullOrWhiteSpace($typeRule.view_type)) {
            $Errors.Add("system/canvas-registry.json: view_type_rules entry missing view_type")
            continue
        }
        Test-RegistryPath -PathValue $typeRule.default_dir -Context "canvas view_type '$($typeRule.view_type)' default_dir"
        foreach ($pathValue in @($typeRule.source_of_truth)) {
            Test-RegistryPath -PathValue $pathValue -Context "canvas view_type '$($typeRule.view_type)' source_of_truth"
        }
    }

    $currentView = [string]$canvasRegistry.current_view
    foreach ($view in @($canvasRegistry.views)) {
        if ([string]::IsNullOrWhiteSpace($view.id)) {
            $Errors.Add("system/canvas-registry.json: view missing id")
            continue
        }
        if (-not $viewIds.Add([string]$view.id)) {
            $Errors.Add("system/canvas-registry.json: duplicate view id '$($view.id)'")
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$view.path)) {
            $canvasViewPathById[[string]$view.id] = [string]$view.path
            $canvasViewById[[string]$view.id] = $view
        }
        Test-RegistryPath -PathValue $view.path -Context "canvas view '$($view.id)'"
        if ([string]::IsNullOrWhiteSpace($view.status)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing status")
        }
        elseif ($allowedCanvasStatus.Count -gt 0 -and -not $allowedCanvasStatus.Contains([string]$view.status)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' has invalid status '$($view.status)'")
        }
        if ([string]::IsNullOrWhiteSpace($view.layer)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing layer")
        }
        if ([string]::IsNullOrWhiteSpace($view.view_family)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing view_family")
        }
        if ([string]::IsNullOrWhiteSpace($view.view_type)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing view_type")
        }
        foreach ($pathValue in @($view.source_of_truth)) {
            Test-RegistryPath -PathValue $pathValue -Context "canvas view '$($view.id)' source_of_truth"
        }
        if ([string]$view.status -eq "current") {
            $family = [string]$view.view_family
            if (-not [string]::IsNullOrWhiteSpace($family)) {
                if ($currentByFamily.ContainsKey($family)) {
                    $Errors.Add("system/canvas-registry.json: multiple current views in view_family '$family'")
                }
                else {
                    $currentByFamily[$family] = [string]$view.id
                }
            }
        }
    }

    foreach ($exception in @($canvasRegistry.placement_exceptions)) {
        Test-RegistryPath -PathValue $exception.path -Context "canvas placement_exception"
    }

    if ([string]::IsNullOrWhiteSpace($currentView)) {
        $Errors.Add("system/canvas-registry.json: missing current_view")
    }
    elseif (-not $viewIds.Contains($currentView)) {
        $Errors.Add("system/canvas-registry.json: current_view '$currentView' is not registered")
    }
}

if ($null -ne $visualCoverageMap) {
    foreach ($fieldName in @("id", "version", "updated", "role", "purpose", "source_of_truth", "policy", "required_views", "module_decisions", "validation")) {
        Test-RequiredField -Object $visualCoverageMap -Field $fieldName -Context "system/visual-coverage-map.json" | Out-Null
    }

    foreach ($pathValue in @($visualCoverageMap.source_of_truth)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/visual-coverage-map.json source_of_truth"
    }

    foreach ($pathValue in @($visualCoverageMap.validation)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/visual-coverage-map.json validation"
    }

    $coverageInformationModuleIds = New-Object System.Collections.Generic.HashSet[string]
    if ($null -ne $informationMap) {
        foreach ($module in @($informationMap.modules)) {
            if ($module.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$module.id)) {
                [void]$coverageInformationModuleIds.Add([string]$module.id)
            }
        }
    }

    $coverageClosureModulesById = @{}
    if ($null -ne $systemClosureMap) {
        foreach ($closureModule in @($systemClosureMap.modules)) {
            if ($closureModule.PSObject.Properties.Name -contains "module_id" -and -not [string]::IsNullOrWhiteSpace([string]$closureModule.module_id)) {
                $coverageClosureModulesById[[string]$closureModule.module_id] = $closureModule
            }
        }
    }

    $requiredCoverageViewIds = New-Object System.Collections.Generic.HashSet[string]
    $requiredCoverageViewPathById = @{}
    $requiredCoverageViewIdByPath = @{}

    foreach ($coverageView in @($visualCoverageMap.required_views)) {
        if (-not (Test-RequiredField -Object $coverageView -Field "view_id" -Context "system/visual-coverage-map.json required_view")) {
            continue
        }

        $coverageViewId = [string]$coverageView.PSObject.Properties["view_id"].Value
        if (-not $requiredCoverageViewIds.Add($coverageViewId)) {
            $Errors.Add("system/visual-coverage-map.json: duplicate required view '$coverageViewId'")
        }

        foreach ($fieldName in @("path", "coverage", "owner_modules")) {
            Test-RequiredField -Object $coverageView -Field $fieldName -Context "visual coverage required view '$coverageViewId'" | Out-Null
        }

        if ($coverageView.PSObject.Properties.Name -contains "path") {
            $coveragePath = [string]$coverageView.PSObject.Properties["path"].Value
            $requiredCoverageViewPathById[$coverageViewId] = $coveragePath
            $requiredCoverageViewIdByPath[$coveragePath] = $coverageViewId
            Test-RegistryPath -PathValue $coveragePath -Context "visual coverage required view '$coverageViewId'"

            if ($canvasViewPathById.Count -gt 0) {
                if (-not $canvasViewPathById.ContainsKey($coverageViewId)) {
                    $Errors.Add("system/visual-coverage-map.json: required view '$coverageViewId' is not registered in system/canvas-registry.json")
                }
                elseif ([string]$canvasViewPathById[$coverageViewId] -ne $coveragePath) {
                    $Errors.Add("system/visual-coverage-map.json: required view '$coverageViewId' path '$coveragePath' does not match canvas registry path '$($canvasViewPathById[$coverageViewId])'")
                }
            }
        }

        $ownerModules = @()
        if ($coverageView.PSObject.Properties.Name -contains "owner_modules") {
            $ownerModules = @($coverageView.owner_modules)
        }
        if ($ownerModules.Count -eq 0) {
            $Errors.Add("system/visual-coverage-map.json: required view '$coverageViewId' has no owner_modules")
        }
        foreach ($ownerModuleValue in $ownerModules) {
            $ownerModule = [string]$ownerModuleValue
            if ($coverageInformationModuleIds.Count -gt 0 -and -not $coverageInformationModuleIds.Contains($ownerModule)) {
                $Errors.Add("system/visual-coverage-map.json: required view '$coverageViewId' references unknown owner module '$ownerModule'")
            }
        }
    }

    $allowedVisualDecisions = New-Object System.Collections.Generic.HashSet[string]
    foreach ($decisionValue in @("dedicated_required", "shared_required", "deferred", "not_applicable")) {
        [void]$allowedVisualDecisions.Add($decisionValue)
    }

    $visualDecisionModuleIds = New-Object System.Collections.Generic.HashSet[string]
    $visualDecisionByModuleId = @{}

    foreach ($decision in @($visualCoverageMap.module_decisions)) {
        if (-not (Test-RequiredField -Object $decision -Field "module_id" -Context "system/visual-coverage-map.json module_decision")) {
            continue
        }

        $decisionModuleId = [string]$decision.PSObject.Properties["module_id"].Value
        if (-not $visualDecisionModuleIds.Add($decisionModuleId)) {
            $Errors.Add("system/visual-coverage-map.json: duplicate module_decision for '$decisionModuleId'")
        }
        else {
            $visualDecisionByModuleId[$decisionModuleId] = $decision
        }

        if ($coverageInformationModuleIds.Count -gt 0 -and -not $coverageInformationModuleIds.Contains($decisionModuleId)) {
            $Errors.Add("system/visual-coverage-map.json: module_decision references unknown module '$decisionModuleId'")
        }

        foreach ($fieldName in @("decision", "visual_projection_status", "required_view_ids", "covered_by_view_ids", "reason", "review_trigger")) {
            Test-RequiredField -Object $decision -Field $fieldName -Context "visual coverage decision '$decisionModuleId'" | Out-Null
        }

        $decisionKind = ""
        if ($decision.PSObject.Properties.Name -contains "decision") {
            $decisionKind = [string]$decision.PSObject.Properties["decision"].Value
            if (-not $allowedVisualDecisions.Contains($decisionKind)) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' has invalid decision '$decisionKind'")
            }
        }

        $decisionRequiredViewIds = @()
        if ($decision.PSObject.Properties.Name -contains "required_view_ids") {
            $decisionRequiredViewIds = @($decision.required_view_ids)
        }
        $decisionCoveredByViewIds = @()
        if ($decision.PSObject.Properties.Name -contains "covered_by_view_ids") {
            $decisionCoveredByViewIds = @($decision.covered_by_view_ids)
        }

        if ($decisionKind -in @("dedicated_required", "shared_required") -and $decisionRequiredViewIds.Count -eq 0) {
            $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' requires at least one required_view_id")
        }
        if ($decisionKind -in @("deferred", "not_applicable")) {
            if ($decisionRequiredViewIds.Count -gt 0) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' is $decisionKind but still lists required_view_ids")
            }
            if ($decisionCoveredByViewIds.Count -eq 0) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' is $decisionKind and should list at least one covered_by_view_id")
            }
        }

        foreach ($requiredViewIdValue in $decisionRequiredViewIds) {
            $requiredViewId = [string]$requiredViewIdValue
            if (-not $requiredCoverageViewIds.Contains($requiredViewId)) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' references unknown required_view_id '$requiredViewId'")
            }
        }

        foreach ($coveredByViewIdValue in $decisionCoveredByViewIds) {
            $coveredByViewId = [string]$coveredByViewIdValue
            if (-not $requiredCoverageViewIds.Contains($coveredByViewId)) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' references unknown covered_by_view_id '$coveredByViewId'")
            }
        }

        if ($coverageClosureModulesById.ContainsKey($decisionModuleId)) {
            $closureModule = $coverageClosureModulesById[$decisionModuleId]
            if ($closureModule.PSObject.Properties.Name -contains "visual_projection" -and $null -ne $closureModule.visual_projection -and
                $closureModule.visual_projection.PSObject.Properties.Name -contains "status" -and
                $decision.PSObject.Properties.Name -contains "visual_projection_status") {
                $closureVisualStatus = [string]$closureModule.visual_projection.PSObject.Properties["status"].Value
                $decisionVisualStatus = [string]$decision.PSObject.Properties["visual_projection_status"].Value
                if ($closureVisualStatus -ne $decisionVisualStatus) {
                    $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' visual_projection_status '$decisionVisualStatus' does not match closure map status '$closureVisualStatus'")
                }
            }
        }
    }

    foreach ($decision in @($visualCoverageMap.module_decisions)) {
        if (-not ($decision.PSObject.Properties.Name -contains "module_id")) {
            continue
        }

        $decisionModuleId = [string]$decision.module_id
        $decisionRequiredViewIds = @()
        if ($decision.PSObject.Properties.Name -contains "required_view_ids") {
            $decisionRequiredViewIds = @($decision.required_view_ids | ForEach-Object { [string]$_ })
        }
        if ($decisionRequiredViewIds.Count -eq 0) {
            continue
        }

        foreach ($coveredByViewIdValue in @($decision.covered_by_view_ids)) {
            $coveredByViewId = [string]$coveredByViewIdValue
            if ([string]::IsNullOrWhiteSpace($coveredByViewId) -or $decisionRequiredViewIds -contains $coveredByViewId) {
                continue
            }
            if (-not $canvasViewById.ContainsKey($coveredByViewId)) {
                continue
            }

            $coveredView = $canvasViewById[$coveredByViewId]
            $navigationTargets = @($coveredView.navigation_nodes | ForEach-Object {
                if ($_.PSObject.Properties.Name -contains "target_view") { [string]$_.target_view }
            })
            $hasNavigationToRequiredView = $false
            foreach ($requiredViewId in $decisionRequiredViewIds) {
                if ($navigationTargets -contains $requiredViewId) {
                    $hasNavigationToRequiredView = $true
                    break
                }
            }

            if (-not $hasNavigationToRequiredView) {
                $Errors.Add("system/visual-coverage-map.json: module_decision '$decisionModuleId' says covered_by_view '$coveredByViewId' covers required view(s) '$($decisionRequiredViewIds -join ', ')' but the covering view has no navigation_node to any required view")
            }
        }
    }

    foreach ($moduleId in $coverageInformationModuleIds) {
        if (-not $visualDecisionModuleIds.Contains([string]$moduleId)) {
            $Errors.Add("system/visual-coverage-map.json: information-map module '$moduleId' has no visual coverage decision")
        }
    }

    foreach ($moduleIdValue in $coverageClosureModulesById.Keys) {
        $moduleId = [string]$moduleIdValue
        if (-not $visualDecisionByModuleId.ContainsKey($moduleId)) {
            $Errors.Add("system/visual-coverage-map.json: closure module '$moduleId' has no visual coverage decision")
            continue
        }

        $decision = $visualDecisionByModuleId[$moduleId]
        $decisionKind = [string]$decision.PSObject.Properties["decision"].Value
        $decisionRequiredViewIds = @()
        if ($decision.PSObject.Properties.Name -contains "required_view_ids") {
            $decisionRequiredViewIds = @($decision.required_view_ids)
        }

        $closureModule = $coverageClosureModulesById[$moduleId]
        if (-not ($closureModule.PSObject.Properties.Name -contains "visual_projection") -or $null -eq $closureModule.visual_projection) {
            continue
        }

        $closureVisualStatus = ""
        if ($closureModule.visual_projection.PSObject.Properties.Name -contains "status") {
            $closureVisualStatus = [string]$closureModule.visual_projection.PSObject.Properties["status"].Value
        }
        $closureVisualViews = @()
        if ($closureModule.visual_projection.PSObject.Properties.Name -contains "views") {
            $closureVisualViews = @($closureModule.visual_projection.views)
        }

        if ($closureVisualStatus -in @("closed", "shared") -and $closureVisualViews.Count -gt 0) {
            if ($decisionKind -notin @("dedicated_required", "shared_required")) {
                $Errors.Add("system/visual-coverage-map.json: closure module '$moduleId' has visual_projection '$closureVisualStatus' but decision is '$decisionKind'")
            }
            foreach ($visualPathValue in $closureVisualViews) {
                $visualPath = [string]$visualPathValue
                if (-not $requiredCoverageViewIdByPath.ContainsKey($visualPath)) {
                    $Errors.Add("system/visual-coverage-map.json: closure module '$moduleId' visual path is not covered by required_views: $visualPath")
                    continue
                }
                $requiredViewId = [string]$requiredCoverageViewIdByPath[$visualPath]
                if ($decisionRequiredViewIds -notcontains $requiredViewId) {
                    $Errors.Add("system/visual-coverage-map.json: closure module '$moduleId' visual path '$visualPath' maps to required view '$requiredViewId' but module_decision does not list it")
                }
            }
        }

        if ($closureVisualStatus -eq "not_applicable" -and $decisionKind -in @("dedicated_required", "shared_required")) {
            $Errors.Add("system/visual-coverage-map.json: closure module '$moduleId' is visual not_applicable but decision is '$decisionKind'")
        }
    }
}

if ($null -ne $canvasDocsMap) {
    foreach ($fieldName in @("id", "version", "baseline_doc", "machine_truth", "doc_routes", "split_policy", "validation")) {
        Test-RequiredField -Object $canvasDocsMap -Field $fieldName -Context "system/canvas-docs-map.json" | Out-Null
    }

    $docRoutePaths = New-Object System.Collections.Generic.HashSet[string]

    if ($canvasDocsMap.PSObject.Properties.Name -contains "baseline_doc" -and $null -ne $canvasDocsMap.baseline_doc) {
        if (Test-RequiredField -Object $canvasDocsMap.baseline_doc -Field "path" -Context "system/canvas-docs-map.json baseline_doc") {
            $baselinePath = [string]$canvasDocsMap.baseline_doc.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $baselinePath -Context "system/canvas-docs-map.json baseline_doc"

            $baselineFullPath = Join-Path $Root $baselinePath
            if (Test-Path -LiteralPath $baselineFullPath) {
                $baselineLineCount = @(Get-Content -LiteralPath $baselineFullPath -Encoding UTF8).Count
                if ($baselineLineCount -gt 120) {
                    $Errors.Add("system/canvas-docs-map.json: baseline_doc should stay thin; $baselinePath has $baselineLineCount lines")
                }
            }
        }
    }

    foreach ($truth in @($canvasDocsMap.machine_truth)) {
        if (-not (Test-RequiredField -Object $truth -Field "path" -Context "system/canvas-docs-map.json machine_truth")) {
            continue
        }
        Test-RegistryPath -PathValue ([string]$truth.PSObject.Properties["path"].Value) -Context "system/canvas-docs-map.json machine_truth"
        Test-RequiredField -Object $truth -Field "role" -Context "system/canvas-docs-map.json machine_truth" | Out-Null
    }

    foreach ($docRoute in @($canvasDocsMap.doc_routes)) {
        if (-not (Test-RequiredField -Object $docRoute -Field "id" -Context "system/canvas-docs-map.json doc_routes")) {
            continue
        }
        $docRouteId = [string]$docRoute.PSObject.Properties["id"].Value
        foreach ($fieldName in @("path", "role", "boundary", "not_for")) {
            Test-RequiredField -Object $docRoute -Field $fieldName -Context "canvas docs route '$docRouteId'" | Out-Null
        }
        if ($docRoute.PSObject.Properties.Name -contains "path") {
            $docRoutePath = [string]$docRoute.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $docRoutePath -Context "canvas docs route '$docRouteId'"
            if (-not $docRoutePaths.Add($docRoutePath)) {
                $Errors.Add("system/canvas-docs-map.json: duplicate doc route path '$docRoutePath'")
            }
        }
    }

    foreach ($pathValue in @($canvasDocsMap.validation)) {
        Test-RegistryPath -PathValue $pathValue -Context "system/canvas-docs-map.json validation"
    }

    $canvasDocsDir = Join-Path $Root "docs/canvas"
    if (Test-Path -LiteralPath $canvasDocsDir) {
        foreach ($docFile in @(Get-ChildItem -LiteralPath $canvasDocsDir -Filter "*.md" -File)) {
            $relativeDocPath = ($docFile.FullName.Substring($Root.Length + 1)).Replace("\", "/")
            if (-not $docRoutePaths.Contains($relativeDocPath)) {
                $Errors.Add("system/canvas-docs-map.json: docs/canvas file is not registered in doc_routes: $relativeDocPath")
            }
        }
    }
}

if ($null -ne $technicalDocsMap) {
    foreach ($fieldName in @("id", "version", "baseline_doc", "machine_truth", "doc_routes", "split_policy", "validation")) {
        Test-RequiredField -Object $technicalDocsMap -Field $fieldName -Context "system/technical-docs-map.json" | Out-Null
    }

    $technicalDocRoutePaths = New-Object System.Collections.Generic.HashSet[string]

    if ($technicalDocsMap.PSObject.Properties.Name -contains "baseline_doc" -and $null -ne $technicalDocsMap.baseline_doc) {
        if (Test-RequiredField -Object $technicalDocsMap.baseline_doc -Field "path" -Context "system/technical-docs-map.json baseline_doc") {
            $technicalBaselinePath = [string]$technicalDocsMap.baseline_doc.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $technicalBaselinePath -Context "system/technical-docs-map.json baseline_doc"

            $technicalBaselineFullPath = Join-Path $Root $technicalBaselinePath
            if (Test-Path -LiteralPath $technicalBaselineFullPath) {
                $technicalBaselineLineCount = @(Get-Content -LiteralPath $technicalBaselineFullPath -Encoding UTF8).Count
                if ($technicalBaselineLineCount -gt 120) {
                    $Errors.Add("system/technical-docs-map.json: baseline_doc should stay thin; $technicalBaselinePath has $technicalBaselineLineCount lines")
                }
            }
        }
    }

    foreach ($truth in @($technicalDocsMap.machine_truth)) {
        if (-not (Test-RequiredField -Object $truth -Field "path" -Context "system/technical-docs-map.json machine_truth")) {
            continue
        }
        Test-RegistryPath -PathValue ([string]$truth.PSObject.Properties["path"].Value) -Context "system/technical-docs-map.json machine_truth"
        Test-RequiredField -Object $truth -Field "role" -Context "system/technical-docs-map.json machine_truth" | Out-Null
    }

    foreach ($docRoute in @($technicalDocsMap.doc_routes)) {
        if (-not (Test-RequiredField -Object $docRoute -Field "id" -Context "system/technical-docs-map.json doc_routes")) {
            continue
        }
        $docRouteId = [string]$docRoute.PSObject.Properties["id"].Value
        foreach ($fieldName in @("path", "role", "boundary", "not_for")) {
            Test-RequiredField -Object $docRoute -Field $fieldName -Context "technical docs route '$docRouteId'" | Out-Null
        }
        if ($docRoute.PSObject.Properties.Name -contains "path") {
            $docRoutePath = [string]$docRoute.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $docRoutePath -Context "technical docs route '$docRouteId'"
            if (-not $technicalDocRoutePaths.Add($docRoutePath)) {
                $Errors.Add("system/technical-docs-map.json: duplicate doc route path '$docRoutePath'")
            }
        }
    }

    foreach ($pathValue in @($technicalDocsMap.validation)) {
        Test-RegistryPath -PathValue $pathValue -Context "system/technical-docs-map.json validation"
    }

    $technicalDocsDir = Join-Path $Root "docs/technical"
    if (Test-Path -LiteralPath $technicalDocsDir) {
        foreach ($docFile in @(Get-ChildItem -LiteralPath $technicalDocsDir -Filter "*.md" -File)) {
            $relativeDocPath = ($docFile.FullName.Substring($Root.Length + 1)).Replace("\", "/")
            if (-not $technicalDocRoutePaths.Contains($relativeDocPath)) {
                $Errors.Add("system/technical-docs-map.json: docs/technical file is not registered in doc_routes: $relativeDocPath")
            }
        }
    }
}

if ($null -ne $domainTaxonomyDocsMap) {
    foreach ($fieldName in @("id", "version", "baseline_doc", "machine_truth", "doc_routes", "loop_assets", "split_policy", "managed_human_docs", "visual_coverage", "validation")) {
        Test-RequiredField -Object $domainTaxonomyDocsMap -Field $fieldName -Context "30-maps/domains/domain-taxonomy.docs.json" | Out-Null
    }

    $taxonomyDocRoutePaths = New-Object System.Collections.Generic.HashSet[string]

    if ($domainTaxonomyDocsMap.PSObject.Properties.Name -contains "baseline_doc" -and $null -ne $domainTaxonomyDocsMap.baseline_doc) {
        if (Test-RequiredField -Object $domainTaxonomyDocsMap.baseline_doc -Field "path" -Context "30-maps/domains/domain-taxonomy.docs.json baseline_doc") {
            $taxonomyBaselinePath = [string]$domainTaxonomyDocsMap.baseline_doc.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $taxonomyBaselinePath -Context "30-maps/domains/domain-taxonomy.docs.json baseline_doc"

            $taxonomyBaselineFullPath = Join-Path $Root $taxonomyBaselinePath
            if (Test-Path -LiteralPath $taxonomyBaselineFullPath) {
                $taxonomyBaselineLineCount = @(Get-Content -LiteralPath $taxonomyBaselineFullPath -Encoding UTF8).Count
                if ($taxonomyBaselineLineCount -gt 120) {
                    $Errors.Add("30-maps/domains/domain-taxonomy.docs.json: baseline_doc should stay thin; $taxonomyBaselinePath has $taxonomyBaselineLineCount lines")
                }
            }
        }
    }

    foreach ($truth in @($domainTaxonomyDocsMap.machine_truth)) {
        if (-not (Test-RequiredField -Object $truth -Field "path" -Context "30-maps/domains/domain-taxonomy.docs.json machine_truth")) {
            continue
        }
        Test-RegistryPath -PathValue ([string]$truth.PSObject.Properties["path"].Value) -Context "30-maps/domains/domain-taxonomy.docs.json machine_truth"
        Test-RequiredField -Object $truth -Field "role" -Context "30-maps/domains/domain-taxonomy.docs.json machine_truth" | Out-Null
    }

    foreach ($docRoute in @($domainTaxonomyDocsMap.doc_routes)) {
        if (-not (Test-RequiredField -Object $docRoute -Field "id" -Context "30-maps/domains/domain-taxonomy.docs.json doc_routes")) {
            continue
        }
        $docRouteId = [string]$docRoute.PSObject.Properties["id"].Value
        foreach ($fieldName in @("path", "role", "boundary", "not_for")) {
            Test-RequiredField -Object $docRoute -Field $fieldName -Context "domain taxonomy docs route '$docRouteId'" | Out-Null
        }
        if ($docRoute.PSObject.Properties.Name -contains "path") {
            $docRoutePath = [string]$docRoute.PSObject.Properties["path"].Value
            Test-RegistryPath -PathValue $docRoutePath -Context "domain taxonomy docs route '$docRouteId'"
            if (-not $taxonomyDocRoutePaths.Add($docRoutePath)) {
                $Errors.Add("30-maps/domains/domain-taxonomy.docs.json: duplicate doc route path '$docRoutePath'")
            }
        }
    }

    if ($domainTaxonomyDocsMap.PSObject.Properties.Name -contains "loop_assets" -and $null -ne $domainTaxonomyDocsMap.loop_assets) {
        foreach ($fieldName in @("root", "config", "queue", "state", "runner_contract", "runs_dir", "outputs_dir")) {
            if (Test-RequiredField -Object $domainTaxonomyDocsMap.loop_assets -Field $fieldName -Context "30-maps/domains/domain-taxonomy.docs.json loop_assets") {
                Test-RegistryPath -PathValue ([string]$domainTaxonomyDocsMap.loop_assets.PSObject.Properties[$fieldName].Value) -Context "30-maps/domains/domain-taxonomy.docs.json loop_assets.$fieldName"
            }
        }
    }

    foreach ($managedDocPathValue in @($domainTaxonomyDocsMap.managed_human_docs)) {
        $managedDocPath = [string]$managedDocPathValue
        Test-RegistryPath -PathValue $managedDocPath -Context "30-maps/domains/domain-taxonomy.docs.json managed_human_docs"
        if (-not $taxonomyDocRoutePaths.Contains($managedDocPath)) {
            $Errors.Add("30-maps/domains/domain-taxonomy.docs.json: managed_human_docs path is not registered in doc_routes: $managedDocPath")
        }
    }

    if ($domainTaxonomyDocsMap.PSObject.Properties.Name -contains "visual_coverage" -and $null -ne $domainTaxonomyDocsMap.visual_coverage) {
        foreach ($fieldName in @("rule", "required_views", "validation_gate")) {
            Test-RequiredField -Object $domainTaxonomyDocsMap.visual_coverage -Field $fieldName -Context "30-maps/domains/domain-taxonomy.docs.json visual_coverage" | Out-Null
        }

        foreach ($visualView in @($domainTaxonomyDocsMap.visual_coverage.required_views)) {
            if (-not (Test-RequiredField -Object $visualView -Field "view_id" -Context "domain taxonomy visual_coverage required_view")) {
                continue
            }

            $viewId = [string]$visualView.PSObject.Properties["view_id"].Value
            foreach ($fieldName in @("path", "coverage")) {
                Test-RequiredField -Object $visualView -Field $fieldName -Context "domain taxonomy visual_coverage '$viewId'" | Out-Null
            }

            if ($visualView.PSObject.Properties.Name -contains "path") {
                $visualPath = [string]$visualView.PSObject.Properties["path"].Value
                Test-RegistryPath -PathValue $visualPath -Context "domain taxonomy visual_coverage '$viewId'"

                if ($canvasViewPathById.Count -gt 0) {
                    if (-not $canvasViewPathById.ContainsKey($viewId)) {
                        $Errors.Add("30-maps/domains/domain-taxonomy.docs.json: required visual view '$viewId' is not registered in system/canvas-registry.json")
                    }
                    elseif ([string]$canvasViewPathById[$viewId] -ne $visualPath) {
                        $Errors.Add("30-maps/domains/domain-taxonomy.docs.json: required visual view '$viewId' path '$visualPath' does not match canvas registry path '$($canvasViewPathById[$viewId])'")
                    }
                }
            }
        }
    }

    foreach ($pathValue in @($domainTaxonomyDocsMap.validation)) {
        Test-RegistryPath -PathValue $pathValue -Context "30-maps/domains/domain-taxonomy.docs.json validation"
    }
}

if ($null -ne $knowledgeIngestionSourceTypes) {
    foreach ($fieldName in @("id", "owner_module", "dynamic_update_policy", "source_types", "validation")) {
        Test-RequiredField -Object $knowledgeIngestionSourceTypes -Field $fieldName -Context "system/knowledge-ingestion-source-types.json" | Out-Null
    }

    if ([string]$knowledgeIngestionSourceTypes.owner_module -ne "knowledge-ingestion") {
        $Errors.Add("system/knowledge-ingestion-source-types.json: owner_module must be knowledge-ingestion")
    }

    foreach ($fieldName in @("rule", "add_source_type_when", "required_fields", "future_gap_rule")) {
        Test-RequiredField -Object $knowledgeIngestionSourceTypes.dynamic_update_policy -Field $fieldName -Context "system/knowledge-ingestion-source-types.json dynamic_update_policy" | Out-Null
    }

    $sourceTypeIds = New-Object System.Collections.Generic.HashSet[string]
    $sourceTypeKbTypes = New-Object System.Collections.Generic.HashSet[string]
    foreach ($sourceType in @($knowledgeIngestionSourceTypes.source_types)) {
        if (-not (Test-RequiredField -Object $sourceType -Field "id" -Context "system/knowledge-ingestion-source-types.json source_type")) {
            continue
        }

        $sourceTypeId = [string]$sourceType.id
        if (-not $sourceTypeIds.Add($sourceTypeId)) {
            $Errors.Add("system/knowledge-ingestion-source-types.json: duplicate source type id '$sourceTypeId'")
        }

        foreach ($fieldName in @("kb_type", "name", "status", "source_template", "provenance_required", "quality_focus", "review_triggers", "domain_routing_hint")) {
            Test-RequiredField -Object $sourceType -Field $fieldName -Context "source type '$sourceTypeId'" | Out-Null
        }

        if ($sourceType.PSObject.Properties.Name -contains "kb_type") {
            [void]$sourceTypeKbTypes.Add([string]$sourceType.kb_type)
        }

        if ($sourceType.PSObject.Properties.Name -contains "source_template") {
            $templatePath = [string]$sourceType.source_template
            if ($templatePath -ne "templates/") {
                Test-RegistryPath -PathValue $templatePath -Context "source type '$sourceTypeId' source_template"
            }
        }
    }

    foreach ($requiredSourceTypeId in @("paper", "book-textbook", "github-topic", "web-source", "personal-draft", "future-source-type")) {
        if (-not $sourceTypeIds.Contains($requiredSourceTypeId)) {
            $Errors.Add("system/knowledge-ingestion-source-types.json: missing required source type '$requiredSourceTypeId'")
        }
    }

    if (-not $sourceTypeKbTypes.Contains("source-book")) {
        $Errors.Add("system/knowledge-ingestion-source-types.json: missing kb_type 'source-book' for textbook/book intake")
    }

    foreach ($pathValue in @($knowledgeIngestionSourceTypes.validation)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/knowledge-ingestion-source-types.json validation"
    }
}

if ($null -ne $knowledgeAcquisitionSystem) {
    foreach ($fieldName in @("id", "version", "updated", "owner_module", "parent_module", "role", "purpose", "responsibility_boundary", "discovery_modes", "quality_value_model", "workflow", "candidate_queue_contract", "handoffs", "validation", "visual_projection")) {
        Test-RequiredField -Object $knowledgeAcquisitionSystem -Field $fieldName -Context "system/knowledge-acquisition-system.json" | Out-Null
    }

    if ([string]$knowledgeAcquisitionSystem.owner_module -ne "knowledge-acquisition") {
        $Errors.Add("system/knowledge-acquisition-system.json: owner_module must be knowledge-acquisition")
    }
    if ([string]$knowledgeAcquisitionSystem.parent_module -ne "knowledge-ingestion") {
        $Errors.Add("system/knowledge-acquisition-system.json: parent_module must be knowledge-ingestion")
    }

    foreach ($fieldName in @("owns", "does_not_own", "escalation_rule")) {
        Test-RequiredField -Object $knowledgeAcquisitionSystem.responsibility_boundary -Field $fieldName -Context "system/knowledge-acquisition-system.json responsibility_boundary" | Out-Null
    }

    $discoveryModeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($discoveryMode in @($knowledgeAcquisitionSystem.discovery_modes)) {
        if (-not (Test-RequiredField -Object $discoveryMode -Field "id" -Context "system/knowledge-acquisition-system.json discovery_mode")) {
            continue
        }
        $modeId = [string]$discoveryMode.id
        if (-not $discoveryModeIds.Add($modeId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: duplicate discovery mode '$modeId'")
        }
        foreach ($fieldName in @("trigger", "output")) {
            Test-RequiredField -Object $discoveryMode -Field $fieldName -Context "system/knowledge-acquisition-system.json discovery_mode '$modeId'" | Out-Null
        }
    }

    foreach ($requiredModeId in @("user-provided-material", "gap-driven-discovery", "project-need-backtracking", "authority-seed-search", "source-following", "github-topic-scouting", "paper-book-foundation-search", "official-docs-and-standards")) {
        if (-not $discoveryModeIds.Contains($requiredModeId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: missing discovery mode '$requiredModeId'")
        }
    }

    foreach ($fieldName in @("scoring_scale", "required_dimensions", "decision_outputs", "minimum_decision_contract")) {
        Test-RequiredField -Object $knowledgeAcquisitionSystem.quality_value_model -Field $fieldName -Context "system/knowledge-acquisition-system.json quality_value_model" | Out-Null
    }

    $dimensionIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($dimension in @($knowledgeAcquisitionSystem.quality_value_model.required_dimensions)) {
        if (-not (Test-RequiredField -Object $dimension -Field "id" -Context "system/knowledge-acquisition-system.json quality dimension")) {
            continue
        }
        $dimensionId = [string]$dimension.id
        if (-not $dimensionIds.Add($dimensionId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: duplicate quality/value dimension '$dimensionId'")
        }
        Test-RequiredField -Object $dimension -Field "question" -Context "system/knowledge-acquisition-system.json quality dimension '$dimensionId'" | Out-Null
    }

    foreach ($requiredDimensionId in @("source_authority", "evidence_strength", "foundational_value", "project_reuse_value", "recency_and_volatility", "domain_fit_and_gap_coverage", "risk_and_rights", "acquisition_cost")) {
        if (-not $dimensionIds.Contains($requiredDimensionId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: missing quality/value dimension '$requiredDimensionId'")
        }
    }

    $decisionOutputIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($decisionOutput in @($knowledgeAcquisitionSystem.quality_value_model.decision_outputs)) {
        if (-not (Test-RequiredField -Object $decisionOutput -Field "id" -Context "system/knowledge-acquisition-system.json decision_output")) {
            continue
        }
        $decisionOutputId = [string]$decisionOutput.id
        if (-not $decisionOutputIds.Add($decisionOutputId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: duplicate decision output '$decisionOutputId'")
        }
        foreach ($fieldName in @("use_when", "handoff")) {
            Test-RequiredField -Object $decisionOutput -Field $fieldName -Context "system/knowledge-acquisition-system.json decision_output '$decisionOutputId'" | Out-Null
        }
    }

    foreach ($requiredDecisionOutputId in @("register-source", "review-before-register", "continue-discovery", "watch", "reject")) {
        if (-not $decisionOutputIds.Contains($requiredDecisionOutputId)) {
            $Errors.Add("system/knowledge-acquisition-system.json: missing decision output '$requiredDecisionOutputId'")
        }
    }

    foreach ($workflowStep in @($knowledgeAcquisitionSystem.workflow)) {
        foreach ($fieldName in @("step", "action", "output")) {
            Test-RequiredField -Object $workflowStep -Field $fieldName -Context "system/knowledge-acquisition-system.json workflow" | Out-Null
        }
    }

    foreach ($fieldName in @("path", "queue_role", "status_values", "durable_rule")) {
        Test-RequiredField -Object $knowledgeAcquisitionSystem.candidate_queue_contract -Field $fieldName -Context "system/knowledge-acquisition-system.json candidate_queue_contract" | Out-Null
    }
    if ($knowledgeAcquisitionSystem.candidate_queue_contract.PSObject.Properties.Name -contains "path") {
        Test-RegistryPath -PathValue ([string]$knowledgeAcquisitionSystem.candidate_queue_contract.path) -Context "system/knowledge-acquisition-system.json candidate_queue_contract path"
    }

    foreach ($handoff in @($knowledgeAcquisitionSystem.handoffs)) {
        foreach ($fieldName in @("target", "when", "payload")) {
            Test-RequiredField -Object $handoff -Field $fieldName -Context "system/knowledge-acquisition-system.json handoff" | Out-Null
        }
    }

    foreach ($pathValue in @($knowledgeAcquisitionSystem.validation)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/knowledge-acquisition-system.json validation"
    }
    foreach ($pathValue in @($knowledgeAcquisitionSystem.visual_projection)) {
        Test-RegistryPath -PathValue ([string]$pathValue) -Context "system/knowledge-acquisition-system.json visual_projection"
    }
}

if ($null -ne $knowledgeAcquisitionQueue) {
    foreach ($fieldName in @("id", "version", "updated", "owner_module", "parent_module", "role", "purpose", "boundary", "status_values", "intake_decisions", "scoring_dimensions", "discovery_requests", "candidates")) {
        Test-RequiredField -Object $knowledgeAcquisitionQueue -Field $fieldName -Context "10-sources/acquisition-queue.json" | Out-Null
    }

    if ([string]$knowledgeAcquisitionQueue.owner_module -ne "knowledge-acquisition") {
        $Errors.Add("10-sources/acquisition-queue.json: owner_module must be knowledge-acquisition")
    }
    if ([string]$knowledgeAcquisitionQueue.parent_module -ne "knowledge-ingestion") {
        $Errors.Add("10-sources/acquisition-queue.json: parent_module must be knowledge-ingestion")
    }

    foreach ($requiredQueueStatus in @("new", "scouting", "evaluating", "ready_to_register", "review_required", "watching", "rejected", "registered", "blocked")) {
        if (@($knowledgeAcquisitionQueue.status_values) -notcontains $requiredQueueStatus) {
            $Errors.Add("10-sources/acquisition-queue.json: missing status value '$requiredQueueStatus'")
        }
    }
    foreach ($requiredDecision in @("register-source", "review-before-register", "continue-discovery", "watch", "reject")) {
        if (@($knowledgeAcquisitionQueue.intake_decisions) -notcontains $requiredDecision) {
            $Errors.Add("10-sources/acquisition-queue.json: missing intake decision '$requiredDecision'")
        }
    }
    foreach ($requiredDimensionId in @("source_authority", "evidence_strength", "foundational_value", "project_reuse_value", "recency_and_volatility", "domain_fit_and_gap_coverage", "risk_and_rights", "acquisition_cost")) {
        if (@($knowledgeAcquisitionQueue.scoring_dimensions) -notcontains $requiredDimensionId) {
            $Errors.Add("10-sources/acquisition-queue.json: missing scoring dimension '$requiredDimensionId'")
        }
    }
}

if ($null -ne $artifactFormPolicy) {
    if (-not $artifactFormPolicy.decision_agent) {
        $Errors.Add("system/artifact-form-policy.json: missing decision_agent")
    }
    if (-not $artifactFormPolicy.form_rules -or $artifactFormPolicy.form_rules.Count -lt 3) {
        $Errors.Add("system/artifact-form-policy.json: expected at least 3 form_rules")
    }
}

if ($null -ne $toolMap) {
    $toolIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($tool in @($toolMap.tools)) {
        if ([string]::IsNullOrWhiteSpace($tool.id)) {
            $Errors.Add("system/tool-map.json: tool missing id")
            continue
        }
        if (-not $toolIds.Add([string]$tool.id)) {
            $Errors.Add("system/tool-map.json: duplicate tool id '$($tool.id)'")
        }
        if ([string]::IsNullOrWhiteSpace($tool.runtime)) {
            $Errors.Add("system/tool-map.json: tool '$($tool.id)' missing runtime")
        }
        Test-RegistryPath -PathValue $tool.entry -Context "tool '$($tool.id)' entry"
        foreach ($pathValue in @($tool.inputs)) {
            if ($pathValue -notmatch "[*]") {
                Test-RegistryPath -PathValue $pathValue -Context "tool '$($tool.id)' input"
            }
        }
    }
}

if ($null -ne $loopRegistry) {
    if (-not (Test-RequiredField -Object $loopRegistry -Field "loops" -Context "system/loop-registry.json")) {
        $Errors.Add("system/loop-registry.json: no loops registered")
    }

    $loopIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($loop in @($loopRegistry.loops)) {
        if (-not (Test-RequiredField -Object $loop -Field "id" -Context "system/loop-registry.json")) {
            continue
        }

        $loopId = [string]$loop.PSObject.Properties["id"].Value
        if (-not $loopIds.Add($loopId)) {
            $Errors.Add("system/loop-registry.json: duplicate loop id '$loopId'")
        }

        $requiredPathFields = @("root", "config", "queue", "state", "runner_contract", "runs_dir", "outputs_dir")
        $hasRequiredPaths = $true
        foreach ($fieldName in $requiredPathFields) {
            if (Test-RequiredField -Object $loop -Field $fieldName -Context "loop '$loopId'") {
                Test-RegistryPath -PathValue ([string]$loop.PSObject.Properties[$fieldName].Value) -Context "loop '$loopId' $fieldName"
            }
            else {
                $hasRequiredPaths = $false
            }
        }

        if (-not $hasRequiredPaths) {
            continue
        }

        $loopConfigPath = [string]$loop.PSObject.Properties["config"].Value
        $loopQueuePath = [string]$loop.PSObject.Properties["queue"].Value
        $loopStatePath = [string]$loop.PSObject.Properties["state"].Value
        $loopRunnerPath = [string]$loop.PSObject.Properties["runner_contract"].Value
        $loopRunsDir = [string]$loop.PSObject.Properties["runs_dir"].Value

        $loopConfig = Read-JsonFile $loopConfigPath
        $loopQueue = Read-JsonFile $loopQueuePath
        $loopState = Read-JsonFile $loopStatePath
        $loopRunner = Read-JsonFile $loopRunnerPath

        if ($null -ne $loopConfig) {
            if ((Test-RequiredField -Object $loopConfig -Field "id" -Context $loopConfigPath) -and
                [string]$loopConfig.PSObject.Properties["id"].Value -ne $loopId) {
                $Errors.Add("${loopConfigPath}: id does not match loop registry id '$loopId'")
            }
            foreach ($fieldName in @("loop_type", "unit_granularity", "selection_rule")) {
                Test-RequiredField -Object $loopConfig -Field $fieldName -Context $loopConfigPath | Out-Null
            }
            if (Test-RequiredField -Object $loopConfig -Field "quality_gate" -Context $loopConfigPath) {
                if (@($loopConfig.quality_gate).Count -eq 0) {
                    $Errors.Add("${loopConfigPath}: quality_gate is empty")
                }
            }
            if (Test-RequiredField -Object $loopConfig -Field "iteration_phases" -Context $loopConfigPath) {
                if (@($loopConfig.iteration_phases).Count -eq 0) {
                    $Errors.Add("${loopConfigPath}: iteration_phases is empty")
                }
            }
            if ($loopConfig.PSObject.Properties.Name -contains "read") {
                foreach ($pathValue in @($loopConfig.read)) {
                    Test-RegistryPath -PathValue $pathValue -Context "${loopConfigPath} read"
                }
            }
            if ($loopConfig.PSObject.Properties.Name -contains "write") {
                foreach ($pathValue in @($loopConfig.write)) {
                    Test-RegistryPath -PathValue $pathValue -Context "${loopConfigPath} write"
                }
            }
            if ($loopConfig.PSObject.Properties.Name -contains "validation") {
                foreach ($pathValue in @($loopConfig.validation)) {
                    Test-RegistryPath -PathValue $pathValue -Context "${loopConfigPath} validation"
                }
            }
        }

        $queueUnitIds = New-Object System.Collections.Generic.HashSet[string]
        $queueOrderIds = New-Object System.Collections.Generic.HashSet[string]
        if ($null -ne $loopQueue) {
            if ((Test-RequiredField -Object $loopQueue -Field "loop_id" -Context $loopQueuePath) -and
                [string]$loopQueue.PSObject.Properties["loop_id"].Value -ne $loopId) {
                $Errors.Add("${loopQueuePath}: loop_id does not match loop registry id '$loopId'")
            }
            if (Test-RequiredField -Object $loopQueue -Field "units" -Context $loopQueuePath) {
                foreach ($unit in @($loopQueue.units)) {
                    if (-not (Test-RequiredField -Object $unit -Field "id" -Context "${loopQueuePath} unit")) {
                        continue
                    }
                    $unitId = [string]$unit.PSObject.Properties["id"].Value
                    if (-not $queueUnitIds.Add($unitId)) {
                        $Errors.Add("${loopQueuePath}: duplicate queue unit id '$unitId'")
                    }
                    foreach ($fieldName in @("level_1", "level_2")) {
                        Test-RequiredField -Object $unit -Field $fieldName -Context "${loopQueuePath} unit '$unitId'" | Out-Null
                    }
                }
            }
            if (Test-RequiredField -Object $loopQueue -Field "unit_order" -Context $loopQueuePath) {
                foreach ($unitIdValue in @($loopQueue.unit_order)) {
                    $unitId = [string]$unitIdValue
                    if ([string]::IsNullOrWhiteSpace($unitId)) {
                        $Errors.Add("${loopQueuePath}: unit_order contains empty unit id")
                        continue
                    }
                    if (-not $queueOrderIds.Add($unitId)) {
                        $Errors.Add("${loopQueuePath}: duplicate unit_order id '$unitId'")
                    }
                    if ($queueUnitIds.Count -gt 0 -and -not $queueUnitIds.Contains($unitId)) {
                        $Errors.Add("${loopQueuePath}: unit_order id '$unitId' not found in units")
                    }
                }
            }
            foreach ($unitId in $queueUnitIds) {
                if ($queueOrderIds.Count -gt 0 -and -not $queueOrderIds.Contains($unitId)) {
                    $Errors.Add("${loopQueuePath}: unit '$unitId' missing from unit_order")
                }
            }
        }

        if ($null -ne $loopState) {
            if ((Test-RequiredField -Object $loopState -Field "loop_id" -Context $loopStatePath) -and
                [string]$loopState.PSObject.Properties["loop_id"].Value -ne $loopId) {
                $Errors.Add("${loopStatePath}: loop_id does not match loop registry id '$loopId'")
            }
            foreach ($fieldName in @("status", "current_unit", "unit_status")) {
                Test-RequiredField -Object $loopState -Field $fieldName -Context $loopStatePath | Out-Null
            }

            if ($loopState.PSObject.Properties.Name -contains "current_unit") {
                $currentUnit = [string]$loopState.PSObject.Properties["current_unit"].Value
                if (-not [string]::IsNullOrWhiteSpace($currentUnit) -and
                    $queueUnitIds.Count -gt 0 -and
                    -not $queueUnitIds.Contains($currentUnit)) {
                    $Errors.Add("${loopStatePath}: current_unit '$currentUnit' not found in queue")
                }
            }

            if ($loopState.PSObject.Properties.Name -contains "unit_status" -and $null -ne $loopState.unit_status) {
                foreach ($statusProperty in @($loopState.unit_status.PSObject.Properties)) {
                    $unitId = [string]$statusProperty.Name
                    $unitStatus = $statusProperty.Value
                    if ($queueUnitIds.Count -gt 0 -and -not $queueUnitIds.Contains($unitId)) {
                        $Errors.Add("${loopStatePath}: unit_status '$unitId' not found in queue")
                    }
                    if (-not (Test-RequiredField -Object $unitStatus -Field "status" -Context "${loopStatePath} unit_status '$unitId'")) {
                        continue
                    }
                    $statusValue = [string]$unitStatus.PSObject.Properties["status"].Value
                    if ($statusValue -eq "completed") {
                        foreach ($fieldName in @("run_id", "result_file", "output_summary")) {
                            Test-RequiredField -Object $unitStatus -Field $fieldName -Context "${loopStatePath} completed unit '$unitId'" | Out-Null
                        }
                        if ($unitStatus.PSObject.Properties.Name -contains "result_file") {
                            Test-RegistryPath -PathValue ([string]$unitStatus.PSObject.Properties["result_file"].Value) -Context "${loopStatePath} completed unit '$unitId' result_file"
                        }
                        if ($unitStatus.PSObject.Properties.Name -contains "output_summary") {
                            Test-RegistryPath -PathValue ([string]$unitStatus.PSObject.Properties["output_summary"].Value) -Context "${loopStatePath} completed unit '$unitId' output_summary"
                        }
                        if ($unitStatus.PSObject.Properties.Name -contains "run_id") {
                            $runId = [string]$unitStatus.PSObject.Properties["run_id"].Value
                            $runPath = $loopRunsDir.TrimEnd("/", "\") + "/" + $runId + ".json"
                            Test-RegistryPath -PathValue $runPath -Context "${loopStatePath} completed unit '$unitId' run_id"
                        }
                    }
                }
            }
        }

        $requiredRunFields = @()
        if ($null -ne $loopRunner) {
            if ((Test-RequiredField -Object $loopRunner -Field "loop_id" -Context $loopRunnerPath) -and
                [string]$loopRunner.PSObject.Properties["loop_id"].Value -ne $loopId) {
                $Errors.Add("${loopRunnerPath}: loop_id does not match loop registry id '$loopId'")
            }
            if (Test-RequiredField -Object $loopRunner -Field "commands" -Context $loopRunnerPath) {
                $commandNames = New-Object System.Collections.Generic.HashSet[string]
                foreach ($command in @($loopRunner.commands)) {
                    if (Test-RequiredField -Object $command -Field "name" -Context "${loopRunnerPath} command") {
                        [void]$commandNames.Add([string]$command.PSObject.Properties["name"].Value)
                    }
                }
                foreach ($commandName in @("status", "run-one", "pause", "resume")) {
                    if (-not $commandNames.Contains($commandName)) {
                        $Errors.Add("${loopRunnerPath}: missing command '$commandName'")
                    }
                }
            }
            if (Test-RequiredField -Object $loopRunner -Field "run_record_schema" -Context $loopRunnerPath) {
                if (Test-RequiredField -Object $loopRunner.run_record_schema -Field "required_fields" -Context "${loopRunnerPath} run_record_schema") {
                    $requiredRunFields = @($loopRunner.run_record_schema.required_fields)
                    if ($requiredRunFields.Count -eq 0) {
                        $Errors.Add("${loopRunnerPath}: run_record_schema.required_fields is empty")
                    }
                }
            }
            Test-RequiredField -Object $loopRunner -Field "state_transition_contract" -Context $loopRunnerPath | Out-Null
        }

        $runsFullPath = Join-Path $Root $loopRunsDir
        if (Test-Path -LiteralPath $runsFullPath) {
            foreach ($runFile in @(Get-ChildItem -LiteralPath $runsFullPath -Filter "*.json" -File)) {
                $runRecordContext = ($runFile.FullName.Substring($Root.Length + 1)).Replace("\", "/")
                try {
                    $runRecord = Get-Content -LiteralPath $runFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                    foreach ($fieldName in $requiredRunFields) {
                        Test-RequiredField -Object $runRecord -Field ([string]$fieldName) -Context $runRecordContext | Out-Null
                    }
                    if (($runRecord.PSObject.Properties.Name -contains "loop_id") -and
                        [string]$runRecord.PSObject.Properties["loop_id"].Value -ne $loopId) {
                        $Errors.Add("${runRecordContext}: loop_id does not match loop registry id '$loopId'")
                    }
                    if ($runRecord.PSObject.Properties.Name -contains "unit_id") {
                        $runUnitId = [string]$runRecord.PSObject.Properties["unit_id"].Value
                        if ($queueUnitIds.Count -gt 0 -and -not $queueUnitIds.Contains($runUnitId)) {
                            $Errors.Add("${runRecordContext}: unit_id '$runUnitId' not found in queue")
                        }
                    }
                }
                catch {
                    $Errors.Add("${runRecordContext}: invalid JSON - $($_.Exception.Message)")
                }
            }
        }
    }
}

if ($null -ne $domainTaxonomy) {
    if (-not $domainTaxonomy.level_1 -or $domainTaxonomy.level_1.Count -eq 0) {
        $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: missing level_1")
    }

    $taxonomyIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($level1 in @($domainTaxonomy.level_1)) {
        foreach ($fieldName in @("id", "code", "name")) {
            if ([string]::IsNullOrWhiteSpace($level1.$fieldName)) {
                $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: level_1 missing $fieldName")
            }
        }
        if ($level1.id -and -not $taxonomyIds.Add([string]$level1.id)) {
            $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: duplicate id '$($level1.id)'")
        }

        foreach ($level2 in @($level1.level_2)) {
            foreach ($fieldName in @("id", "code", "name", "status")) {
                if ([string]::IsNullOrWhiteSpace($level2.$fieldName)) {
                    $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: level_2 under '$($level1.code)' missing $fieldName")
                }
            }
            if ($level2.id -and -not $taxonomyIds.Add([string]$level2.id)) {
                $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: duplicate id '$($level2.id)'")
            }

            if ([string]$level2.status -like "refined*") {
                if (-not $level2.level_3 -or $level2.level_3.Count -eq 0) {
                    $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: refined level_2 '$($level2.code)' has no level_3 entries")
                }
                foreach ($level3 in @($level2.level_3)) {
                    foreach ($fieldName in @("id", "code", "name", "scope")) {
                        if ([string]::IsNullOrWhiteSpace($level3.$fieldName)) {
                            $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: level_3 under '$($level2.code)' missing $fieldName")
                        }
                    }
                    if ($level3.id -and -not $taxonomyIds.Add([string]$level3.id)) {
                        $Errors.Add("30-maps/domains/domain-taxonomy.registry.json: duplicate id '$($level3.id)'")
                    }
                }
            }
        }
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "System validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "System validation passed."
