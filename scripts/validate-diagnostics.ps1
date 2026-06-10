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

function Test-RequiredArrayField {
    param(
        [object]$Object,
        [string]$Field,
        [string]$Context
    )

    if (-not (Test-RequiredField -Object $Object -Field $Field -Context $Context)) {
        return $false
    }

    $value = @($Object.PSObject.Properties[$Field].Value)
    if ($value.Count -lt 1) {
        $Errors.Add("${Context}: empty $Field")
        return $false
    }

    return $true
}

$diagnosticSystem = Read-JsonFile "system/diagnostics/diagnostic-system.json"
$queue = Read-JsonFile "system/diagnostics/issue-repair-queue.json"
$schema = Read-JsonFile "schemas/diagnostic-issue.schema.json"
$layerMatrix = Read-JsonFile "system/diagnostics/diagnostic-layer-matrix.json"
$failureLearningLoop = Read-JsonFile "system/diagnostics/failure-learning-loop.json"

if ($null -ne $diagnosticSystem) {
    foreach ($fieldName in @("id", "version", "role", "purpose", "core_workflow", "issue_record_contract", "quality_gates", "storage_policy")) {
        Test-RequiredField -Object $diagnosticSystem -Field $fieldName -Context "system/diagnostics/diagnostic-system.json" | Out-Null
    }

    $workflowSteps = New-Object System.Collections.Generic.HashSet[string]
    foreach ($workflowStep in @($diagnosticSystem.core_workflow)) {
        if ($workflowStep.PSObject.Properties.Name -contains "step" -and -not [string]::IsNullOrWhiteSpace([string]$workflowStep.step)) {
            [void]$workflowSteps.Add([string]$workflowStep.step)
        }
    }
    if (-not $workflowSteps.Contains("audit-diagnostic-performance")) {
        $Errors.Add("system/diagnostics/diagnostic-system.json: core_workflow missing 'audit-diagnostic-performance'")
    }
    if (-not $workflowSteps.Contains("scan-same-class-and-sibling-surfaces")) {
        $Errors.Add("system/diagnostics/diagnostic-system.json: core_workflow missing 'scan-same-class-and-sibling-surfaces'")
    }
    if (-not $workflowSteps.Contains("decide-failure-learning-loop")) {
        $Errors.Add("system/diagnostics/diagnostic-system.json: core_workflow missing 'decide-failure-learning-loop'")
    }
    if (-not $workflowSteps.Contains("open-controlled-learning-loop")) {
        $Errors.Add("system/diagnostics/diagnostic-system.json: core_workflow missing 'open-controlled-learning-loop'")
    }

    foreach ($pathValue in @($diagnosticSystem.storage_policy.agent_entry)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic storage_policy.agent_entry"
    }
    foreach ($pathValue in @($diagnosticSystem.storage_policy.machine_truth)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic storage_policy.machine_truth"
    }
    foreach ($pathValue in @($diagnosticSystem.storage_policy.human_explanation)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic storage_policy.human_explanation"
    }
    foreach ($pathValue in @($diagnosticSystem.storage_policy.visual_projection)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic storage_policy.visual_projection"
    }
    foreach ($pathValue in @($diagnosticSystem.storage_policy.validation)) {
        Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic storage_policy.validation"
    }

    if (Test-RequiredField -Object $diagnosticSystem -Field "method_surfaces" -Context "system/diagnostics/diagnostic-system.json") {
        Test-RequiredArrayField -Object $diagnosticSystem.method_surfaces -Field "surfaces" -Context "system/diagnostics/diagnostic-system.json method_surfaces" | Out-Null
        foreach ($surface in @($diagnosticSystem.method_surfaces.surfaces)) {
            foreach ($fieldName in @("id", "path", "role")) {
                Test-RequiredField -Object $surface -Field $fieldName -Context "diagnostic method_surfaces.surfaces" | Out-Null
            }
            if ($surface.PSObject.Properties.Name -contains "path") {
                Test-PathValue -PathValue ([string]$surface.path) -Context "diagnostic method surface '$($surface.id)'"
            }
        }
    }

    if (Test-RequiredField -Object $diagnosticSystem -Field "failure_learning_policy" -Context "system/diagnostics/diagnostic-system.json") {
        foreach ($fieldName in @("id", "machine_truth", "rule", "open_when", "not_for", "required_decision")) {
            Test-RequiredField -Object $diagnosticSystem.failure_learning_policy -Field $fieldName -Context "system/diagnostics/diagnostic-system.json failure_learning_policy" | Out-Null
        }
        if ($diagnosticSystem.failure_learning_policy.PSObject.Properties.Name -contains "machine_truth") {
            Test-PathValue -PathValue ([string]$diagnosticSystem.failure_learning_policy.machine_truth) -Context "diagnostic failure_learning_policy.machine_truth"
        }
    }

    if (Test-RequiredField -Object $diagnosticSystem -Field "self_audit_policy" -Context "system/diagnostics/diagnostic-system.json") {
        foreach ($fieldName in @("id", "rule", "trigger_when", "required_outputs", "acceptance_rule", "validation")) {
            Test-RequiredField -Object $diagnosticSystem.self_audit_policy -Field $fieldName -Context "system/diagnostics/diagnostic-system.json self_audit_policy" | Out-Null
        }
        foreach ($requiredOutput in @("diagnostic_self_audit.trigger", "diagnostic_self_audit.missed_issue_pattern", "diagnostic_self_audit.missed_layer", "diagnostic_self_audit.corrective_contract", "diagnostic_self_audit.recurrence_gate")) {
            if (@($diagnosticSystem.self_audit_policy.required_outputs | ForEach-Object { [string]$_ }) -notcontains $requiredOutput) {
                $Errors.Add("system/diagnostics/diagnostic-system.json: self_audit_policy.required_outputs missing '$requiredOutput'")
            }
        }
        foreach ($pathValue in @($diagnosticSystem.self_audit_policy.validation)) {
            Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic self_audit_policy.validation"
        }
    }

    if (Test-RequiredField -Object $diagnosticSystem -Field "generalization_scan_policy" -Context "system/diagnostics/diagnostic-system.json") {
        foreach ($fieldName in @("id", "rule", "trigger_when", "required_outputs", "acceptance_rule", "validation")) {
            Test-RequiredField -Object $diagnosticSystem.generalization_scan_policy -Field $fieldName -Context "system/diagnostics/diagnostic-system.json generalization_scan_policy" | Out-Null
        }
        foreach ($requiredOutput in @("generalization_scan.observed_instance", "generalization_scan.failure_class", "generalization_scan.same_class_assets_checked", "generalization_scan.sibling_surfaces_checked", "generalization_scan.affected_modules", "generalization_scan.exemptions", "generalization_scan.recurrence_gate")) {
            if (@($diagnosticSystem.generalization_scan_policy.required_outputs | ForEach-Object { [string]$_ }) -notcontains $requiredOutput) {
                $Errors.Add("system/diagnostics/diagnostic-system.json: generalization_scan_policy.required_outputs missing '$requiredOutput'")
            }
        }
        foreach ($pathValue in @($diagnosticSystem.generalization_scan_policy.validation)) {
            Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic generalization_scan_policy.validation"
        }
    }

    if (Test-RequiredField -Object $diagnosticSystem -Field "root_problem_policy" -Context "system/diagnostics/diagnostic-system.json") {
        foreach ($fieldName in @("id", "rule", "trigger_when", "required_outputs", "acceptance_rule", "validation")) {
            Test-RequiredField -Object $diagnosticSystem.root_problem_policy -Field $fieldName -Context "system/diagnostics/diagnostic-system.json root_problem_policy" | Out-Null
        }
        foreach ($requiredOutput in @("incident_manifestation.observed_incident", "incident_manifestation.evidence_surface", "incident_manifestation.why_it_is_not_root_problem", "root_problem.problem_statement", "root_problem.recurrence_mechanism", "root_problem.owning_system_model", "system_regulation_target.target_surface", "system_regulation_target.update_mode", "system_regulation_target.acceptance_gate")) {
            if (@($diagnosticSystem.root_problem_policy.required_outputs | ForEach-Object { [string]$_ }) -notcontains $requiredOutput) {
                $Errors.Add("system/diagnostics/diagnostic-system.json: root_problem_policy.required_outputs missing '$requiredOutput'")
            }
        }
        foreach ($pathValue in @($diagnosticSystem.root_problem_policy.validation)) {
            Test-PathValue -PathValue ([string]$pathValue) -Context "diagnostic root_problem_policy.validation"
        }
    }
}

if ($null -ne $schema) {
    foreach ($requiredField in @("issue_id", "title", "status", "repair_class", "failure_packet", "lower_evidence_track", "upper_principle_track", "failed_mindset", "immediate_root_cause", "owning_repair_layer", "positive_model_repair", "constraint_decision", "affected_surfaces", "capture_paths", "validation", "diagnosis_acceptance")) {
        if (@($schema.required) -notcontains $requiredField) {
            $Errors.Add("schemas/diagnostic-issue.schema.json: required missing '$requiredField'")
        }
    }

    foreach ($legacyOrGuardrailField in @("positive_rule", "forbidden_pattern", "quality_gate")) {
        if (-not ($schema.properties.PSObject.Properties.Name -contains $legacyOrGuardrailField)) {
            $Errors.Add("schemas/diagnostic-issue.schema.json: optional guardrail property missing '$legacyOrGuardrailField'")
        }
    }

    if (-not ($schema.properties.PSObject.Properties.Name -contains "diagnostic_self_audit")) {
        $Errors.Add("schemas/diagnostic-issue.schema.json: optional diagnostic_self_audit property missing")
    }
    if (-not ($schema.properties.PSObject.Properties.Name -contains "generalization_scan")) {
        $Errors.Add("schemas/diagnostic-issue.schema.json: optional generalization_scan property missing")
    }
    if (-not ($schema.properties.PSObject.Properties.Name -contains "generalization_scan_exemption")) {
        $Errors.Add("schemas/diagnostic-issue.schema.json: optional generalization_scan_exemption property missing")
    }
    foreach ($rootProblemField in @("incident_manifestation", "root_problem", "system_regulation_target")) {
        if (-not ($schema.properties.PSObject.Properties.Name -contains $rootProblemField)) {
            $Errors.Add("schemas/diagnostic-issue.schema.json: optional root-problem separation property missing '$rootProblemField'")
        }
    }
    foreach ($learningField in @("failure_learning_decision", "failure_postmortem_ref", "evolution_proposal_ref", "regression_guard_ref", "promotion_decision_ref")) {
        if (-not ($schema.properties.PSObject.Properties.Name -contains $learningField)) {
            $Errors.Add("schemas/diagnostic-issue.schema.json: optional failure-learning property missing '$learningField'")
        }
    }
}

if ($null -ne $layerMatrix) {
    foreach ($fieldName in @("id", "version", "status", "purpose", "trace_rule", "bottom_up_steps", "constitutional_root_layers", "meta_root_layers", "symptom_to_owner", "repair_classification", "closure_questions")) {
        Test-RequiredField -Object $layerMatrix -Field $fieldName -Context "system/diagnostics/diagnostic-layer-matrix.json" | Out-Null
    }
    if (@($layerMatrix.bottom_up_steps).Count -lt 6) {
        $Errors.Add("system/diagnostics/diagnostic-layer-matrix.json: bottom_up_steps should cover at least six diagnostic layers")
    }
    foreach ($step in @($layerMatrix.bottom_up_steps)) {
        foreach ($fieldName in @("step", "lower_evidence_question", "upper_principle_question")) {
            Test-RequiredField -Object $step -Field $fieldName -Context "diagnostic-layer-matrix bottom_up_steps" | Out-Null
        }
    }
}

if ($null -ne $failureLearningLoop) {
    foreach ($fieldName in @("id", "version", "status", "purpose", "activation_policy", "pipeline", "object_contracts", "domain_specs", "risk_policy", "storage_policy")) {
        Test-RequiredField -Object $failureLearningLoop -Field $fieldName -Context "system/diagnostics/failure-learning-loop.json" | Out-Null
    }
    foreach ($requiredStep in @("telemetry_or_issue", "failure_postmortem", "improvement_proposal", "regression_guard", "promotion_decision")) {
        if (@($failureLearningLoop.pipeline | ForEach-Object { [string]$_.step }) -notcontains $requiredStep) {
            $Errors.Add("system/diagnostics/failure-learning-loop.json: pipeline missing '$requiredStep'")
        }
    }
    foreach ($contractName in @("failure_postmortem", "evolution_proposal", "regression_guard_result", "promotion_decision")) {
        if (-not ($failureLearningLoop.object_contracts.PSObject.Properties.Name -contains $contractName)) {
            $Errors.Add("system/diagnostics/failure-learning-loop.json: object_contracts missing '$contractName'")
        }
        elseif (-not ($failureLearningLoop.object_contracts.$contractName.PSObject.Properties.Name -contains "required_fields") -or @($failureLearningLoop.object_contracts.$contractName.required_fields).Count -lt 1) {
            $Errors.Add("system/diagnostics/failure-learning-loop.json: object_contracts.$contractName missing required_fields")
        }
    }
    if (@($failureLearningLoop.domain_specs).Count -lt 3) {
        $Errors.Add("system/diagnostics/failure-learning-loop.json: domain_specs should contain multiple owner domains")
    }
}

$requiredIssueFields = @()
if ($null -ne $diagnosticSystem -and
    $diagnosticSystem.PSObject.Properties.Name -contains "issue_record_contract" -and
    $diagnosticSystem.issue_record_contract.PSObject.Properties.Name -contains "required_fields") {
    $requiredIssueFields = @($diagnosticSystem.issue_record_contract.required_fields | ForEach-Object { [string]$_ } | Where-Object { $_ -notin @("generalization_scan", "incident_manifestation", "root_problem", "system_regulation_target") })
}

if ($null -ne $queue) {
    foreach ($fieldName in @("schema_version", "id", "system_id", "execution_policy", "issues")) {
        Test-RequiredField -Object $queue -Field $fieldName -Context "system/diagnostics/issue-repair-queue.json" | Out-Null
    }

    $effectiveGeneralizationIssueId = $null
    if ($queue.PSObject.Properties.Name -contains "execution_policy" -and $queue.execution_policy.PSObject.Properties.Name -contains "generalization_scan_required_from_issue_id") {
        $effectiveGeneralizationIssueId = [string]$queue.execution_policy.generalization_scan_required_from_issue_id
    }
    else {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: execution_policy missing generalization_scan_required_from_issue_id")
    }

    $effectiveRootProblemIssueId = $null
    if ($queue.PSObject.Properties.Name -contains "execution_policy" -and $queue.execution_policy.PSObject.Properties.Name -contains "root_problem_required_from_issue_id") {
        $effectiveRootProblemIssueId = [string]$queue.execution_policy.root_problem_required_from_issue_id
    }
    else {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: execution_policy missing root_problem_required_from_issue_id")
    }

    $effectiveFailureLearningIssueId = $null
    if ($queue.PSObject.Properties.Name -contains "execution_policy" -and $queue.execution_policy.PSObject.Properties.Name -contains "failure_learning_required_from_issue_id") {
        $effectiveFailureLearningIssueId = [string]$queue.execution_policy.failure_learning_required_from_issue_id
    }
    else {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: execution_policy missing failure_learning_required_from_issue_id")
    }

    $issueIds = New-Object System.Collections.Generic.HashSet[string]
    $generalizationScanRequired = $false
    $foundEffectiveGeneralizationIssue = $false
    $rootProblemRequired = $false
    $foundEffectiveRootProblemIssue = $false
    $failureLearningRequired = $false
    $foundEffectiveFailureLearningIssue = $false
    foreach ($issue in @($queue.issues)) {
        $context = "diagnostic issue"
        if ($issue.PSObject.Properties.Name -contains "issue_id") {
            $context = "diagnostic issue '$($issue.issue_id)'"
            if (-not $issueIds.Add([string]$issue.issue_id)) {
                $Errors.Add("system/diagnostics/issue-repair-queue.json: duplicate issue_id '$($issue.issue_id)'")
            }
            if (-not [string]::IsNullOrWhiteSpace($effectiveGeneralizationIssueId) -and [string]$issue.issue_id -eq $effectiveGeneralizationIssueId) {
                $generalizationScanRequired = $true
                $foundEffectiveGeneralizationIssue = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($effectiveRootProblemIssueId) -and [string]$issue.issue_id -eq $effectiveRootProblemIssueId) {
                $rootProblemRequired = $true
                $foundEffectiveRootProblemIssue = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($effectiveFailureLearningIssueId) -and [string]$issue.issue_id -eq $effectiveFailureLearningIssueId) {
                $failureLearningRequired = $true
                $foundEffectiveFailureLearningIssue = $true
            }
        }

        foreach ($fieldName in $requiredIssueFields) {
            Test-RequiredField -Object $issue -Field $fieldName -Context $context | Out-Null
        }

        $owningRepairLayers = @()
        if ($issue.PSObject.Properties.Name -contains "owning_repair_layer") {
            $owningRepairLayers = @($issue.owning_repair_layer | ForEach-Object { [string]$_ })
        }
        if ($owningRepairLayers -contains "diagnostic-system") {
            if (Test-RequiredField -Object $issue -Field "diagnostic_self_audit" -Context $context) {
                foreach ($fieldName in @("trigger", "missed_issue_pattern", "missed_layer", "corrective_contract", "recurrence_gate")) {
                    Test-RequiredField -Object $issue.diagnostic_self_audit -Field $fieldName -Context "$context diagnostic_self_audit" | Out-Null
                }
            }
        }

        if ($issue.PSObject.Properties.Name -contains "capture_paths") {
            foreach ($pathValue in @($issue.capture_paths)) {
                Test-PathValue -PathValue ([string]$pathValue) -Context "$context capture_paths"
            }
        }

        if ($issue.PSObject.Properties.Name -contains "validation" -and $null -ne $issue.validation) {
            if ($issue.validation.PSObject.Properties.Name -contains "reports") {
                foreach ($pathValue in @($issue.validation.reports)) {
                    Test-PathValue -PathValue ([string]$pathValue) -Context "$context validation.reports"
                }
            }
        }

        if ($issue.PSObject.Properties.Name -contains "status" -and [string]$issue.status -eq "captured") {
            if (-not ($issue.PSObject.Properties.Name -contains "diagnosis_acceptance") -or
                [string]::IsNullOrWhiteSpace([string]$issue.diagnosis_acceptance)) {
                $Errors.Add("${context}: captured issue requires diagnosis_acceptance")
            }
            if (-not ($issue.PSObject.Properties.Name -contains "validation") -or
                $null -eq $issue.validation -or
                [string]$issue.validation.status -ne "pass") {
                $Errors.Add("${context}: captured issue requires validation.status=pass")
            }
        }

        if ($generalizationScanRequired -and
            $issue.PSObject.Properties.Name -contains "status" -and [string]$issue.status -eq "captured" -and
            $issue.PSObject.Properties.Name -contains "repair_class" -and [string]$issue.repair_class -eq "system_upgrade") {
            if (Test-RequiredField -Object $issue -Field "generalization_scan" -Context $context) {
                foreach ($fieldName in @("observed_instance", "failure_class", "recurrence_gate")) {
                    Test-RequiredField -Object $issue.generalization_scan -Field $fieldName -Context "$context generalization_scan" | Out-Null
                }
                foreach ($fieldName in @("same_class_assets_checked", "sibling_surfaces_checked", "affected_modules", "exemptions")) {
                    Test-RequiredArrayField -Object $issue.generalization_scan -Field $fieldName -Context "$context generalization_scan" | Out-Null
                }
            }
        }

        if ($rootProblemRequired -and
            $issue.PSObject.Properties.Name -contains "status" -and [string]$issue.status -eq "captured" -and
            $issue.PSObject.Properties.Name -contains "repair_class" -and [string]$issue.repair_class -eq "system_upgrade") {
            if (Test-RequiredField -Object $issue -Field "incident_manifestation" -Context $context) {
                foreach ($fieldName in @("observed_incident", "why_it_is_not_root_problem")) {
                    Test-RequiredField -Object $issue.incident_manifestation -Field $fieldName -Context "$context incident_manifestation" | Out-Null
                }
                Test-RequiredArrayField -Object $issue.incident_manifestation -Field "evidence_surface" -Context "$context incident_manifestation" | Out-Null
            }
            if (Test-RequiredField -Object $issue -Field "root_problem" -Context $context) {
                foreach ($fieldName in @("problem_statement", "recurrence_mechanism", "owning_system_model")) {
                    Test-RequiredField -Object $issue.root_problem -Field $fieldName -Context "$context root_problem" | Out-Null
                }
            }
            if (Test-RequiredField -Object $issue -Field "system_regulation_target" -Context $context) {
                Test-RequiredArrayField -Object $issue.system_regulation_target -Field "target_surface" -Context "$context system_regulation_target" | Out-Null
                foreach ($fieldName in @("update_mode", "acceptance_gate")) {
                    Test-RequiredField -Object $issue.system_regulation_target -Field $fieldName -Context "$context system_regulation_target" | Out-Null
                }
            }
        }

        if ($failureLearningRequired -and
            $issue.PSObject.Properties.Name -contains "status" -and [string]$issue.status -eq "captured" -and
            $issue.PSObject.Properties.Name -contains "repair_class" -and [string]$issue.repair_class -eq "system_upgrade") {
            if (Test-RequiredField -Object $issue -Field "failure_learning_decision" -Context $context) {
                foreach ($fieldName in @("status", "reason")) {
                    Test-RequiredField -Object $issue.failure_learning_decision -Field $fieldName -Context "$context failure_learning_decision" | Out-Null
                }
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($effectiveGeneralizationIssueId) -and -not $foundEffectiveGeneralizationIssue) {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: generalization_scan_required_from_issue_id not found: $effectiveGeneralizationIssueId")
    }
    if (-not [string]::IsNullOrWhiteSpace($effectiveRootProblemIssueId) -and -not $foundEffectiveRootProblemIssue) {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: root_problem_required_from_issue_id not found: $effectiveRootProblemIssueId")
    }
    if (-not [string]::IsNullOrWhiteSpace($effectiveFailureLearningIssueId) -and -not $foundEffectiveFailureLearningIssue) {
        $Errors.Add("system/diagnostics/issue-repair-queue.json: failure_learning_required_from_issue_id not found: $effectiveFailureLearningIssueId")
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "Diagnostics validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Diagnostics validation passed."
