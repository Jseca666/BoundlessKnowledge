[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$Errors = New-Object System.Collections.Generic.List[string]

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

function Get-OptionalArray {
    param(
        [object]$Object,
        [string]$Field
    )

    if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $Field)) {
        return @()
    }

    return @($Object.PSObject.Properties[$Field].Value)
}

function Test-ObjectField {
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
    if ($Text -match ([string][char]0xFFFD)) {
        $Errors.Add("${Context}: contains Unicode replacement character")
    }
    if ($Text.Contains([string][char]0x951F)) {
        $Errors.Add("${Context}: contains CJK mojibake marker")
    }
}

function Test-CanvasTextIntegrity {
    param(
        [object]$Canvas,
        [string]$Context
    )

    if ($null -eq $Canvas) {
        return
    }

    foreach ($node in @($Canvas.nodes)) {
        $nodeId = if ($node.PSObject.Properties.Name -contains "id") { [string]$node.id } else { "unknown-node" }
        if ($node.PSObject.Properties.Name -contains "text") {
            Test-TextIntegrity -Text ([string]$node.text) -Context "${Context} node '$nodeId' text"
        }
    }

    foreach ($edge in @($Canvas.edges)) {
        $edgeId = if ($edge.PSObject.Properties.Name -contains "id") { [string]$edge.id } else { "unknown-edge" }
        if ($edge.PSObject.Properties.Name -contains "label") {
            Test-TextIntegrity -Text ([string]$edge.label) -Context "${Context} edge '$edgeId' label"
        }
    }
}

function ConvertTo-StringSet {
    param([object[]]$Values)

    $set = New-Object System.Collections.Generic.HashSet[string]
    foreach ($value in @($Values)) {
        $stringValue = [string]$value
        if (-not [string]::IsNullOrWhiteSpace($stringValue)) {
            [void]$set.Add($stringValue)
        }
    }
    return $set
}

function Test-CanvasColorToken {
    param(
        [string]$Color,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Color)) {
        return
    }

    $isPreset = $Color -match "^[1-6]$"
    $isHex = $Color -match "^#[0-9A-Fa-f]{6}$"
    if (-not ($isPreset -or $isHex)) {
        $Errors.Add("${Context}: color '$Color' must use an Obsidian-compatible preset token 1-6 or a hex color")
    }
}

function Test-SameStringSet {
    param(
        [object[]]$ActualValues,
        [object[]]$ExpectedValues,
        [string]$Context
    )

    $actualSet = ConvertTo-StringSet -Values $ActualValues
    $expectedSet = ConvertTo-StringSet -Values $ExpectedValues

    foreach ($expected in $expectedSet) {
        if (-not $actualSet.Contains($expected)) {
            $Errors.Add("${Context}: missing '$expected'")
        }
    }
    foreach ($actual in $actualSet) {
        if (-not $expectedSet.Contains($actual)) {
            $Errors.Add("${Context}: unexpected '$actual'")
        }
    }
}

function Test-ViewBoundaryFields {
    param(
        [object]$View,
        [object[]]$RequiredFields,
        [System.Collections.Generic.HashSet[string]]$AllowedLevels,
        [System.Collections.Generic.HashSet[string]]$AllowedCategories
    )

    if ($null -eq $View) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    foreach ($fieldName in $RequiredFields) {
        if (-not (Test-ObjectField -Object $View -Field ([string]$fieldName) -Context "system/canvas-registry.json view '$($View.id)'")) {
            continue
        }

        if ([string]$fieldName -eq "not_for" -and @(Get-OptionalArray -Object $View -Field "not_for").Count -eq 0) {
            $Errors.Add("system/canvas-registry.json view '$($View.id)': not_for must list at least one boundary exclusion")
        }
    }

    if ($View.PSObject.Properties.Name -contains "view_level") {
        $viewLevel = [string]$View.view_level
        if ($AllowedLevels.Count -gt 0 -and -not $AllowedLevels.Contains($viewLevel)) {
            $Errors.Add("system/canvas-registry.json view '$($View.id)': unknown view_level '$viewLevel'")
        }
    }

    if ($View.PSObject.Properties.Name -contains "view_category") {
        $viewCategory = [string]$View.view_category
        if ($AllowedCategories.Count -gt 0 -and -not $AllowedCategories.Contains($viewCategory)) {
            $Errors.Add("system/canvas-registry.json view '$($View.id)': unknown view_category '$viewCategory'")
        }
    }
}

function Test-RightSideNavigationLayout {
    param(
        [object]$View,
        [object]$Canvas,
        [hashtable]$NodeById
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    $viewType = [string]$View.view_type
    if ($viewType -in @("visual-navigation-index", "draft-map", "system-architecture-detailed-draft", "archived-map")) {
        return
    }

    $navigationNodes = @(Get-OptionalArray -Object $View -Field "navigation_nodes")
    if ($navigationNodes.Count -eq 0) {
        return
    }

    $navigationNodeIds = New-Object System.Collections.Generic.HashSet[string]
    $navigationPanelLeftValues = New-Object System.Collections.Generic.List[double]
    foreach ($navigationNode in $navigationNodes) {
        if ($navigationNode.PSObject.Properties.Name -contains "node_id" -and -not [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
            $nodeId = [string]$navigationNode.node_id
            [void]$navigationNodeIds.Add($nodeId)
            if ($NodeById.ContainsKey($nodeId) -and $NodeById[$nodeId].PSObject.Properties.Name -contains "x") {
                [void]$navigationPanelLeftValues.Add([double]$NodeById[$nodeId].x)
            }
        }
    }

    $mainRight = $null
    foreach ($node in @($Canvas.nodes)) {
        if (-not ($node.PSObject.Properties.Name -contains "id")) {
            continue
        }
        if ($navigationNodeIds.Contains([string]$node.id)) {
            continue
        }
        if ([string]$node.id -match "navigation|right-nav|^nav-label-|^color-legend$") {
            continue
        }
        if (-not ($node.PSObject.Properties.Name -contains "x") -or -not ($node.PSObject.Properties.Name -contains "width")) {
            continue
        }
        $nodeLeft = [double]$node.x
        $inNavigationColumn = $false
        foreach ($panelLeft in $navigationPanelLeftValues) {
            if ([math]::Abs($nodeLeft - $panelLeft) -le 5) {
                $inNavigationColumn = $true
                break
            }
        }
        if ($inNavigationColumn) {
            continue
        }

        $rightEdge = [double]$node.x + [double]$node.width
        if ($null -eq $mainRight -or $rightEdge -gt $mainRight) {
            $mainRight = $rightEdge
        }
    }

    if ($null -eq $mainRight) {
        return
    }

    $minGap = 20
    $navLeftValues = New-Object System.Collections.Generic.List[double]
    foreach ($navigationNode in $navigationNodes) {
        if (-not ($navigationNode.PSObject.Properties.Name -contains "node_id") -or [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
            continue
        }

        $nodeId = [string]$navigationNode.node_id
        if (-not $NodeById.ContainsKey($nodeId)) {
            continue
        }

        $node = $NodeById[$nodeId]
        if (-not ($node.PSObject.Properties.Name -contains "x")) {
            continue
        }

        $navLeft = [double]$node.x
        [void]$navLeftValues.Add($navLeft)
        if ($navLeft -lt ($mainRight + $minGap)) {
            $Errors.Add("system/canvas-registry.json: current/active structural view '$($View.id)' navigation node '$nodeId' should be in the right-side navigation panel; node x=$navLeft, main right edge=$mainRight")
        }
    }

    if ($navLeftValues.Count -gt 1) {
        $minNavLeft = ($navLeftValues | Measure-Object -Minimum).Minimum
        $maxNavLeft = ($navLeftValues | Measure-Object -Maximum).Maximum
        if (($maxNavLeft - $minNavLeft) -gt 180) {
            $Errors.Add("system/canvas-registry.json: current/active structural view '$($View.id)' navigation nodes should form one vertical right-side panel; x spread is $($maxNavLeft - $minNavLeft)")
        }
    }
}

function Test-RegisteredCanvasFileNodes {
    param(
        [object]$View,
        [object]$Canvas,
        [hashtable]$ViewIdByPath,
        [hashtable]$ViewsById
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    $nodeById = @{}
    foreach ($node in @($Canvas.nodes)) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace($node.id)) {
            $nodeById[[string]$node.id] = $node
        }
    }

    $isNavigationView = [string]$View.view_type -eq "visual-navigation-index"
    $navigationNodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($navigationNode in @(Get-OptionalArray -Object $View -Field "navigation_nodes")) {
        if ($navigationNode.PSObject.Properties.Name -contains "node_id" -and -not [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
            $navigationNodeId = [string]$navigationNode.node_id
            [void]$navigationNodeIds.Add($navigationNodeId)

            $labelNodeId = "nav-label-$navigationNodeId"
            if (-not $nodeById.ContainsKey($labelNodeId)) {
                $Errors.Add("system/canvas-registry.json: view '$($View.id)' navigation node '$navigationNodeId' is missing visible label node '$labelNodeId'")
            }
            else {
                $labelNode = $nodeById[$labelNodeId]
                if (-not ($labelNode.PSObject.Properties.Name -contains "type") -or [string]$labelNode.type -ne "text") {
                    $Errors.Add("system/canvas-registry.json: view '$($View.id)' navigation label '$labelNodeId' should be a text node")
                }
                if (-not ($labelNode.PSObject.Properties.Name -contains "text") -or [string]::IsNullOrWhiteSpace([string]$labelNode.text)) {
                    $Errors.Add("system/canvas-registry.json: view '$($View.id)' navigation label '$labelNodeId' must contain human-readable destination text")
                }
                elseif ($isNavigationView -and $navigationNode.PSObject.Properties.Name -contains "target_view") {
                    $targetViewId = [string]$navigationNode.target_view
                    if ($ViewsById.ContainsKey($targetViewId)) {
                        $targetView = $ViewsById[$targetViewId]
                        if ($targetView.PSObject.Properties.Name -contains "view_level") {
                            $targetViewLevel = [string]$targetView.view_level
                            if (-not [string]::IsNullOrWhiteSpace($targetViewLevel) -and -not ([string]$labelNode.text).Contains($targetViewLevel)) {
                                $Errors.Add("system/canvas-registry.json: L0 navigation view '$($View.id)' label '$labelNodeId' must expose target view_level '$targetViewLevel'")
                            }
                        }
                    }
                }
            }
        }
    }

    foreach ($node in @($Canvas.nodes)) {
        if (-not ($node.PSObject.Properties.Name -contains "type") -or [string]$node.type -ne "file") {
            continue
        }
        if (-not ($node.PSObject.Properties.Name -contains "id") -or [string]::IsNullOrWhiteSpace($node.id)) {
            continue
        }
        if (-not ($node.PSObject.Properties.Name -contains "file") -or [string]::IsNullOrWhiteSpace($node.file)) {
            continue
        }

        $nodeId = [string]$node.id
        $filePath = [string]$node.file
        $isCanvasFile = $filePath.EndsWith(".canvas")

        if ($isNavigationView -and -not $isCanvasFile) {
            $Errors.Add("system/canvas-registry.json: navigation view '$($View.id)' file node '$nodeId' must point to a registered .canvas view, not '$filePath'")
            continue
        }

        if ($isCanvasFile -and $ViewIdByPath.ContainsKey($filePath) -and -not $navigationNodeIds.Contains($nodeId)) {
            $Errors.Add("system/canvas-registry.json: current/active view '$($View.id)' canvas file node '$nodeId' points to registered view '$($ViewIdByPath[$filePath])' but is not listed in navigation_nodes")
        }

        if ($isNavigationView -and $isCanvasFile -and -not $ViewIdByPath.ContainsKey($filePath)) {
            $Errors.Add("system/canvas-registry.json: navigation view '$($View.id)' file node '$nodeId' points to unregistered canvas '$filePath'")
        }
    }

    if ($isNavigationView) {
        foreach ($edge in @($Canvas.edges)) {
            if (-not ($edge.PSObject.Properties.Name -contains "id")) {
                continue
            }

            $fromNode = if ($edge.PSObject.Properties.Name -contains "fromNode") { [string]$edge.fromNode } else { "" }
            $toNode = if ($edge.PSObject.Properties.Name -contains "toNode") { [string]$edge.toNode } else { "" }
            if (-not ($navigationNodeIds.Contains($fromNode) -or $navigationNodeIds.Contains($toNode))) {
                $Errors.Add("system/canvas-registry.json: navigation view '$($View.id)' edge '$($edge.id)' must connect to a registered navigation file node")
            }
        }
    }
}

function Test-ContextBridgeEdges {
    param(
        [object]$View,
        [object]$Canvas
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    $nodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($node in @($Canvas.nodes)) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace($node.id)) {
            [void]$nodeIds.Add([string]$node.id)
        }
    }

    $navigationEndpointIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($navigationNode in @(Get-OptionalArray -Object $View -Field "navigation_nodes")) {
        if ($navigationNode.PSObject.Properties.Name -contains "node_id" -and -not [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
            $navigationNodeId = [string]$navigationNode.node_id
            [void]$navigationEndpointIds.Add($navigationNodeId)
            [void]$navigationEndpointIds.Add("nav-label-$navigationNodeId")
        }
    }

    foreach ($edge in @($Canvas.edges)) {
        if (-not ($edge.PSObject.Properties.Name -contains "id") -or [string]::IsNullOrWhiteSpace($edge.id)) {
            continue
        }

        $edgeId = [string]$edge.id
        if (-not $edgeId.StartsWith("bridge-")) {
            continue
        }

        if ([string]$View.view_type -eq "visual-navigation-index") {
            $Errors.Add("system/canvas-registry.json: navigation view '$($View.id)' must not contain context bridge edge '$edgeId'")
        }

        foreach ($fieldName in @("fromNode", "toNode", "label")) {
            if (-not ($edge.PSObject.Properties.Name -contains $fieldName) -or [string]::IsNullOrWhiteSpace([string]$edge.$fieldName)) {
                $Errors.Add("system/canvas-registry.json: context bridge edge '$edgeId' in view '$($View.id)' missing $fieldName")
            }
        }

        $contextBridgeLabelToken = ([string][char]0x5BF9) + ([string][char]0x5E94)
        if (($edge.PSObject.Properties.Name -contains "label") -and [string]$edge.label -notmatch [regex]::Escape($contextBridgeLabelToken)) {
            $Errors.Add("system/canvas-registry.json: context bridge edge '$edgeId' in view '$($View.id)' label must include the Chinese token for context correspondence")
        }

        $fromNode = if ($edge.PSObject.Properties.Name -contains "fromNode") { [string]$edge.fromNode } else { "" }
        $toNode = if ($edge.PSObject.Properties.Name -contains "toNode") { [string]$edge.toNode } else { "" }
        foreach ($endpoint in @($fromNode, $toNode)) {
            if (-not [string]::IsNullOrWhiteSpace($endpoint) -and -not $nodeIds.Contains($endpoint)) {
                $Errors.Add("system/canvas-registry.json: context bridge edge '$edgeId' in view '$($View.id)' references missing node '$endpoint'")
            }
        }

        $navigationEndpointCount = 0
        foreach ($endpoint in @($fromNode, $toNode)) {
            if ($navigationEndpointIds.Contains($endpoint)) {
                $navigationEndpointCount += 1
            }
        }

        if ($navigationEndpointCount -ne 1) {
            $Errors.Add("system/canvas-registry.json: context bridge edge '$edgeId' in view '$($View.id)' must connect exactly one navigation label/file node to one main-content node")
        }
    }
}

function Test-SupportSemantics {
    param(
        [object]$View,
        [object]$Canvas
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    $viewType = if ($View.PSObject.Properties.Name -contains "view_type") { [string]$View.view_type } else { "" }
    if ($viewType -eq "visual-navigation-index") {
        return
    }

    $nodeById = @{}
    foreach ($node in @($Canvas.nodes)) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$node.id)) {
            $nodeById[[string]$node.id] = $node
        }
    }

    $edgeById = @{}
    foreach ($edge in @($Canvas.edges)) {
        if ($edge.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$edge.id)) {
            $edgeById[[string]$edge.id] = $edge
        }
    }

    $navigationFileNodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($navigationNode in @(Get-OptionalArray -Object $View -Field "navigation_nodes")) {
        if ($navigationNode.PSObject.Properties.Name -contains "node_id" -and -not [string]::IsNullOrWhiteSpace([string]$navigationNode.node_id)) {
            [void]$navigationFileNodeIds.Add([string]$navigationNode.node_id)
        }
    }

    $supportLabelIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($node in @($Canvas.nodes)) {
        $nodeId = if ($node.PSObject.Properties.Name -contains "id") { [string]$node.id } else { "" }
        $nodeType = if ($node.PSObject.Properties.Name -contains "type") { [string]$node.type } else { "" }
        if ($nodeType -ne "file" -or [string]::IsNullOrWhiteSpace($nodeId) -or $navigationFileNodeIds.Contains($nodeId)) {
            continue
        }

        $labelId = "file-label-$nodeId"
        if (-not $nodeById.ContainsKey($labelId)) {
            $Errors.Add("$($View.path): support file node '$nodeId' has no readable support label '$labelId'")
            continue
        }
        [void]$supportLabelIds.Add($labelId)
    }

    $bindingSupportIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($binding in @(Get-OptionalArray -Object $View -Field "support_bindings")) {
        $context = "system/canvas-registry.json: view '$($View.id)' support_bindings"
        foreach ($fieldName in @("binding_id", "support_node", "target_node", "label")) {
            if (-not ($binding.PSObject.Properties.Name -contains $fieldName) -or [string]::IsNullOrWhiteSpace([string]$binding.$fieldName)) {
                $Errors.Add("${context}: entry missing $fieldName")
            }
        }

        $supportNode = if ($binding.PSObject.Properties.Name -contains "support_node") { [string]$binding.support_node } else { "" }
        $targetNode = if ($binding.PSObject.Properties.Name -contains "target_node") { [string]$binding.target_node } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($supportNode)) {
            [void]$bindingSupportIds.Add($supportNode)
            if (-not $supportNode.StartsWith("file-label-")) {
                $Errors.Add("${context}: support_node '$supportNode' must be a file-label-* node")
            }
            if (-not $supportLabelIds.Contains($supportNode)) {
                $Errors.Add("${context}: support_node '$supportNode' is not a non-navigation support file label in the Canvas")
            }
        }
        foreach ($endpoint in @($supportNode, $targetNode)) {
            if (-not [string]::IsNullOrWhiteSpace($endpoint) -and -not $nodeById.ContainsKey($endpoint)) {
                $Errors.Add("${context}: references missing node '$endpoint'")
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($targetNode) -and $targetNode.StartsWith("file-label-")) {
            $Errors.Add("${context}: target_node '$targetNode' should be an upper workflow, gate, status, boundary or module node, not another support file label")
        }

        if ($binding.PSObject.Properties.Name -contains "visual_edge_id" -and -not [string]::IsNullOrWhiteSpace([string]$binding.visual_edge_id)) {
            $edgeId = [string]$binding.visual_edge_id
            if (-not $edgeById.ContainsKey($edgeId)) {
                $Errors.Add("${context}: visual_edge_id '$edgeId' is not present in the Canvas")
            }
            else {
                $edge = $edgeById[$edgeId]
                $fromNode = if ($edge.PSObject.Properties.Name -contains "fromNode") { [string]$edge.fromNode } else { "" }
                $toNode = if ($edge.PSObject.Properties.Name -contains "toNode") { [string]$edge.toNode } else { "" }
                $matchesForward = ($fromNode -eq $supportNode -and $toNode -eq $targetNode)
                $matchesReverse = ($fromNode -eq $targetNode -and $toNode -eq $supportNode)
                if (-not ($matchesForward -or $matchesReverse)) {
                    $Errors.Add("${context}: visual_edge_id '$edgeId' must connect '$supportNode' and '$targetNode'")
                }
            }
        }
    }

    foreach ($labelId in $supportLabelIds) {
        if (-not $bindingSupportIds.Contains($labelId)) {
            $Errors.Add("$($View.path): support label '$labelId' has no support_bindings entry to an upper Canvas node")
        }
    }

    foreach ($relation in @(Get-OptionalArray -Object $View -Field "support_relations")) {
        $context = "system/canvas-registry.json: view '$($View.id)' support_relations"
        foreach ($fieldName in @("relation_id", "from_node", "to_node", "label")) {
            if (-not ($relation.PSObject.Properties.Name -contains $fieldName) -or [string]::IsNullOrWhiteSpace([string]$relation.$fieldName)) {
                $Errors.Add("${context}: entry missing $fieldName")
            }
        }

        $fromNode = if ($relation.PSObject.Properties.Name -contains "from_node") { [string]$relation.from_node } else { "" }
        $toNode = if ($relation.PSObject.Properties.Name -contains "to_node") { [string]$relation.to_node } else { "" }
        foreach ($endpoint in @($fromNode, $toNode)) {
            if ([string]::IsNullOrWhiteSpace($endpoint)) {
                continue
            }
            if (-not $endpoint.StartsWith("file-label-")) {
                $Errors.Add("${context}: endpoint '$endpoint' must be a file-label-* support node")
            }
            if (-not $supportLabelIds.Contains($endpoint)) {
                $Errors.Add("${context}: endpoint '$endpoint' is not a support file label in the Canvas")
            }
        }

        if ($relation.PSObject.Properties.Name -contains "visual_edge_id" -and -not [string]::IsNullOrWhiteSpace([string]$relation.visual_edge_id)) {
            $edgeId = [string]$relation.visual_edge_id
            if (-not $edgeById.ContainsKey($edgeId)) {
                $Errors.Add("${context}: visual_edge_id '$edgeId' is not present in the Canvas")
            }
            else {
                $edge = $edgeById[$edgeId]
                $edgeFrom = if ($edge.PSObject.Properties.Name -contains "fromNode") { [string]$edge.fromNode } else { "" }
                $edgeTo = if ($edge.PSObject.Properties.Name -contains "toNode") { [string]$edge.toNode } else { "" }
                if (-not (($edgeFrom -eq $fromNode -and $edgeTo -eq $toNode) -or ($edgeFrom -eq $toNode -and $edgeTo -eq $fromNode))) {
                    $Errors.Add("${context}: visual_edge_id '$edgeId' must connect '$fromNode' and '$toNode'")
                }
            }
        }
    }
}

function Test-ViewColorSemantics {
    param(
        [object]$View,
        [object]$Canvas,
        [hashtable]$PaletteById
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $status = [string]$View.status
    if ($status -notin @("current", "active")) {
        return
    }

    if (-not ($View.PSObject.Properties.Name -contains "color_semantics") -or $null -eq $View.color_semantics) {
        $Errors.Add("system/canvas-registry.json: current/active view '$($View.id)' missing color_semantics")
        return
    }

    $colorSemantics = $View.color_semantics
    foreach ($fieldName in @("palette_id", "semantic_mode", "visible_legend_node")) {
        if (-not ($colorSemantics.PSObject.Properties.Name -contains $fieldName) -or [string]::IsNullOrWhiteSpace([string]$colorSemantics.$fieldName)) {
            $Errors.Add("system/canvas-registry.json: view '$($View.id)' color_semantics missing $fieldName")
        }
    }

    $paletteId = if ($colorSemantics.PSObject.Properties.Name -contains "palette_id") { [string]$colorSemantics.palette_id } else { "" }
    $palette = $null
    if (-not [string]::IsNullOrWhiteSpace($paletteId)) {
        if (-not $PaletteById.ContainsKey($paletteId)) {
            $Errors.Add("system/canvas-registry.json: view '$($View.id)' color_semantics references unknown palette_id '$paletteId'")
        }
        else {
            $palette = $PaletteById[$paletteId]
        }
    }

    $nodeById = @{}
    foreach ($node in @($Canvas.nodes)) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$node.id)) {
            $nodeById[[string]$node.id] = $node
        }
    }

    $legendNodeId = if ($colorSemantics.PSObject.Properties.Name -contains "visible_legend_node") { [string]$colorSemantics.visible_legend_node } else { "" }
    if (-not [string]::IsNullOrWhiteSpace($legendNodeId)) {
        if (-not $nodeById.ContainsKey($legendNodeId)) {
            $Errors.Add("$($View.path): color_semantics visible legend node '$legendNodeId' not found")
        }
        else {
            $legendNode = $nodeById[$legendNodeId]
            if (-not ($legendNode.PSObject.Properties.Name -contains "type") -or [string]$legendNode.type -ne "text") {
                $Errors.Add("$($View.path): color legend node '$legendNodeId' must be a text node")
            }
            if (-not ($legendNode.PSObject.Properties.Name -contains "text") -or [string]::IsNullOrWhiteSpace([string]$legendNode.text)) {
                $Errors.Add("$($View.path): color legend node '$legendNodeId' must contain readable legend text")
            }
            else {
                $legendTitleToken = ([string][char]0x989C) + ([string][char]0x8272) + ([string][char]0x56FE) + ([string][char]0x4F8B)
                if (-not ([string]$legendNode.text).Contains($legendTitleToken)) {
                    $Errors.Add("$($View.path): color legend node '$legendNodeId' must include the Chinese color legend title token")
                }
            }
        }
    }

    $allowedColors = New-Object System.Collections.Generic.HashSet[string]
    $roleColorByRole = @{}
    if ($null -ne $palette) {
        foreach ($role in @(Get-OptionalArray -Object $palette -Field "roles")) {
            if ($role.PSObject.Properties.Name -contains "color" -and -not [string]::IsNullOrWhiteSpace([string]$role.color)) {
                Test-CanvasColorToken -Color ([string]$role.color) -Context "system/canvas-registry.json palette '$paletteId' role '$($role.role)'"
                [void]$allowedColors.Add([string]$role.color)
            }
            if (($role.PSObject.Properties.Name -contains "role") -and ($role.PSObject.Properties.Name -contains "color") -and -not [string]::IsNullOrWhiteSpace([string]$role.role)) {
                $roleColorByRole[[string]$role.role] = [string]$role.color
            }
        }
        foreach ($color in @(Get-OptionalArray -Object $palette -Field "allowed_colors")) {
            if (-not [string]::IsNullOrWhiteSpace([string]$color)) {
                Test-CanvasColorToken -Color ([string]$color) -Context "system/canvas-registry.json palette '$paletteId' allowed_colors"
                [void]$allowedColors.Add([string]$color)
            }
        }
    }

    if ($allowedColors.Count -gt 0) {
        foreach ($node in @($Canvas.nodes)) {
            if (-not ($node.PSObject.Properties.Name -contains "color") -or [string]::IsNullOrWhiteSpace([string]$node.color)) {
                continue
            }
            $nodeId = if ($node.PSObject.Properties.Name -contains "id") { [string]$node.id } else { "unknown-node" }
            $nodeColor = [string]$node.color
            Test-CanvasColorToken -Color $nodeColor -Context "$($View.path): node '$nodeId'"
            if (-not $allowedColors.Contains($nodeColor)) {
                $Errors.Add("$($View.path): node '$nodeId' uses color '$nodeColor' outside palette '$paletteId'")
            }
        }

        foreach ($edge in @($Canvas.edges)) {
            if (-not ($edge.PSObject.Properties.Name -contains "color") -or [string]::IsNullOrWhiteSpace([string]$edge.color)) {
                continue
            }
            $edgeId = if ($edge.PSObject.Properties.Name -contains "id") { [string]$edge.id } else { "unknown-edge" }
            $edgeColor = [string]$edge.color
            Test-CanvasColorToken -Color $edgeColor -Context "$($View.path): edge '$edgeId'"
            if (-not $allowedColors.Contains($edgeColor)) {
                $Errors.Add("$($View.path): edge '$edgeId' uses color '$edgeColor' outside palette '$paletteId'")
            }
        }
    }

    if ($colorSemantics.PSObject.Properties.Name -contains "role_node_ids" -and $null -ne $colorSemantics.role_node_ids) {
        foreach ($roleProperty in @($colorSemantics.role_node_ids.PSObject.Properties)) {
            $roleName = [string]$roleProperty.Name
            $expectedColor = if ($roleColorByRole.ContainsKey($roleName)) { [string]$roleColorByRole[$roleName] } else { "" }
            foreach ($nodeIdValue in @($roleProperty.Value)) {
                $nodeId = [string]$nodeIdValue
                if ([string]::IsNullOrWhiteSpace($nodeId)) {
                    continue
                }
                if (-not $nodeById.ContainsKey($nodeId)) {
                    $Errors.Add("system/canvas-registry.json: view '$($View.id)' color role '$roleName' references missing node '$nodeId'")
                    continue
                }
                if (-not [string]::IsNullOrWhiteSpace($expectedColor)) {
                    $node = $nodeById[$nodeId]
                    $actualColor = if ($node.PSObject.Properties.Name -contains "color") { [string]$node.color } else { "" }
                    if ($actualColor -ne $expectedColor) {
                        $Errors.Add("system/canvas-registry.json: view '$($View.id)' color role '$roleName' expects color '$expectedColor' but node '$nodeId' uses '$actualColor'")
                    }
                }
            }
        }
    }
}

function Test-ArchiveCanvasView {
    param(
        [object]$View,
        [object]$Canvas,
        [hashtable]$ViewsById
    )

    if ($null -eq $View -or $null -eq $Canvas) {
        return
    }

    $viewPath = [string]$View.path
    $status = [string]$View.status
    $isArchivePath = $viewPath.StartsWith("30-maps/canvas/90-archive/")
    $isLegacyStatus = $status -in @("legacy-draft", "superseded", "archived")

    if (-not $isArchivePath -and -not $isLegacyStatus) {
        return
    }

    if ($isArchivePath -and -not $isLegacyStatus) {
        $Errors.Add("system/canvas-registry.json: archived Canvas view '$($View.id)' must use a legacy/archive status, not '$status'")
    }

    $nodeById = @{}
    foreach ($node in @($Canvas.nodes)) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace($node.id)) {
            $nodeById[[string]$node.id] = $node
        }
    }

    if (-not $nodeById.ContainsKey("archive-status-note")) {
        $Errors.Add("${viewPath}: legacy/archive Canvas view '$($View.id)' must include visible text node 'archive-status-note'")
    }
    else {
        $archiveNode = $nodeById["archive-status-note"]
        if (-not ($archiveNode.PSObject.Properties.Name -contains "type") -or [string]$archiveNode.type -ne "text") {
            $Errors.Add("${viewPath}: archive-status-note must be a text node")
        }
        if (-not ($archiveNode.PSObject.Properties.Name -contains "text") -or [string]::IsNullOrWhiteSpace([string]$archiveNode.text)) {
            $Errors.Add("${viewPath}: archive-status-note must explain that the view is archived or legacy")
        }
    }

    if (-not ($View.PSObject.Properties.Name -contains "replaced_by") -or [string]::IsNullOrWhiteSpace([string]$View.replaced_by)) {
        $Errors.Add("system/canvas-registry.json: legacy/archive view '$($View.id)' must declare replaced_by")
        return
    }

    $replacementViewId = [string]$View.replaced_by
    if (-not $ViewsById.ContainsKey($replacementViewId)) {
        $Errors.Add("system/canvas-registry.json: legacy/archive view '$($View.id)' replaced_by references unknown view '$replacementViewId'")
        return
    }

    $replacementView = $ViewsById[$replacementViewId]
    $replacementPath = [string]$replacementView.path
    $replacementNavigationNodes = @(Get-OptionalArray -Object $View -Field "navigation_nodes" | Where-Object {
        $_.PSObject.Properties.Name -contains "target_view" -and [string]$_.target_view -eq $replacementViewId
    })

    if ($replacementNavigationNodes.Count -eq 0) {
        $Errors.Add("system/canvas-registry.json: legacy/archive view '$($View.id)' must register a navigation node to replaced_by view '$replacementViewId'")
        return
    }

    foreach ($navigationNode in $replacementNavigationNodes) {
        if (-not ($navigationNode.PSObject.Properties.Name -contains "node_id") -or [string]::IsNullOrWhiteSpace([string]$navigationNode.node_id)) {
            $Errors.Add("system/canvas-registry.json: legacy/archive view '$($View.id)' replacement navigation entry missing node_id")
            continue
        }

        $nodeId = [string]$navigationNode.node_id
        if (-not $nodeById.ContainsKey($nodeId)) {
            $Errors.Add("${viewPath}: replacement navigation node '$nodeId' not found")
            continue
        }

        $node = $nodeById[$nodeId]
        if (-not ($node.PSObject.Properties.Name -contains "type") -or [string]$node.type -ne "file") {
            $Errors.Add("${viewPath}: replacement navigation node '$nodeId' must be a file node")
        }
        if (-not ($node.PSObject.Properties.Name -contains "file") -or [string]$node.file -ne $replacementPath) {
            $Errors.Add("${viewPath}: replacement navigation node '$nodeId' must point to '$replacementPath'")
        }

        $labelNodeId = "nav-label-$nodeId"
        if (-not $nodeById.ContainsKey($labelNodeId)) {
            $Errors.Add("${viewPath}: replacement navigation node '$nodeId' must have label '$labelNodeId'")
        }
        else {
            $labelNode = $nodeById[$labelNodeId]
            if (-not ($labelNode.PSObject.Properties.Name -contains "type") -or [string]$labelNode.type -ne "text") {
                $Errors.Add("${viewPath}: replacement label '$labelNodeId' must be a text node")
            }
            if (-not ($labelNode.PSObject.Properties.Name -contains "text") -or [string]::IsNullOrWhiteSpace([string]$labelNode.text)) {
                $Errors.Add("${viewPath}: replacement label '$labelNodeId' must contain human-readable destination text")
            }
        }
    }
}

$registry = Read-JsonFile "system/canvas-registry.json"
if ($null -eq $registry) {
    Write-Host "Canvas validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

$viewGraph = Read-JsonFile "system/canvas-view-graph.json"

$registeredPaths = New-Object System.Collections.Generic.HashSet[string]
$currentByFamily = @{}
$layoutById = @{}
$viewTypeDefaultDir = @{}
$viewIds = New-Object System.Collections.Generic.HashSet[string]
$viewsById = @{}
$viewIdByPath = @{}
$boundaryRequiredFields = @("view_level", "view_category", "primary_subject", "boundary", "not_for")
$allowedViewLevels = New-Object System.Collections.Generic.HashSet[string]
$allowedViewCategories = New-Object System.Collections.Generic.HashSet[string]
$paletteById = @{}

if ($registry.PSObject.Properties.Name -contains "view_boundary_policy" -and $null -ne $registry.view_boundary_policy) {
    if ($registry.view_boundary_policy.PSObject.Properties.Name -contains "required_fields") {
        $boundaryRequiredFields = @($registry.view_boundary_policy.required_fields | ForEach-Object { [string]$_ })
    }
    if ($registry.view_boundary_policy.PSObject.Properties.Name -contains "view_levels") {
        foreach ($levelEntry in @($registry.view_boundary_policy.view_levels)) {
            if ($levelEntry.PSObject.Properties.Name -contains "level" -and -not [string]::IsNullOrWhiteSpace($levelEntry.level)) {
                [void]$allowedViewLevels.Add([string]$levelEntry.level)
            }
        }
    }
    if ($registry.view_boundary_policy.PSObject.Properties.Name -contains "view_categories") {
        foreach ($category in @($registry.view_boundary_policy.view_categories)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$category)) {
                [void]$allowedViewCategories.Add([string]$category)
            }
        }
    }
}

if ($registry.PSObject.Properties.Name -contains "color_semantics_policy" -and $null -ne $registry.color_semantics_policy) {
    foreach ($palette in @(Get-OptionalArray -Object $registry.color_semantics_policy -Field "palettes")) {
        if ($palette.PSObject.Properties.Name -contains "palette_id" -and -not [string]::IsNullOrWhiteSpace([string]$palette.palette_id)) {
            $paletteById[[string]$palette.palette_id] = $palette
        }
    }
}

foreach ($view in @($registry.views)) {
    if ([string]::IsNullOrWhiteSpace($view.id)) {
        continue
    }

    $viewId = [string]$view.id
    if (-not $viewIds.Add($viewId)) {
        $Errors.Add("system/canvas-registry.json: duplicate view id '$viewId'")
    }
    else {
        $viewsById[$viewId] = $view
        if ($view.PSObject.Properties.Name -contains "path" -and -not [string]::IsNullOrWhiteSpace($view.path)) {
            $viewIdByPath[[string]$view.path] = $viewId
        }
    }
}

foreach ($layout in @($registry.storage_layout)) {
    if ([string]::IsNullOrWhiteSpace($layout.path)) {
        $Errors.Add("system/canvas-registry.json: storage_layout entry missing path")
        continue
    }

    if (-not [string]::IsNullOrWhiteSpace($layout.id)) {
        $layoutById[[string]$layout.id] = $layout
    }

    $fullLayoutPath = Join-Path $Root ([string]$layout.path)
    if (-not (Test-Path -LiteralPath $fullLayoutPath)) {
        $Errors.Add("system/canvas-registry.json: storage layout path does not exist: $($layout.path)")
    }
}

foreach ($typeRule in @($registry.view_type_rules)) {
    if (-not [string]::IsNullOrWhiteSpace($typeRule.view_type) -and -not [string]::IsNullOrWhiteSpace($typeRule.default_dir)) {
        $viewTypeDefaultDir[[string]$typeRule.view_type] = [string]$typeRule.default_dir
    }
}

function Get-CanvasLayout {
    param([string]$RelativePath)

    $best = $null
    foreach ($layout in @($registry.storage_layout)) {
        $layoutPath = [string]$layout.path
        if ($RelativePath.StartsWith($layoutPath)) {
            if ($null -eq $best -or $layoutPath.Length -gt ([string]$best.path).Length) {
                $best = $layout
            }
        }
    }

    return $best
}

foreach ($view in @($registry.views)) {
    if ([string]::IsNullOrWhiteSpace($view.id)) {
        $Errors.Add("system/canvas-registry.json: view missing id")
        continue
    }

    if ([string]::IsNullOrWhiteSpace($view.path)) {
        $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing path")
        continue
    }

    [void]$registeredPaths.Add([string]$view.path)
    $viewPath = [string]$view.path
    $layout = Get-CanvasLayout -RelativePath $viewPath
    if ($null -eq $layout) {
        $Errors.Add("system/canvas-registry.json: view '$($view.id)' path is not under a registered Canvas directory: $viewPath")
    }
    else {
        $fileName = [System.IO.Path]::GetFileName($viewPath)
        if ($layout.filename_prefix -and -not $fileName.StartsWith([string]$layout.filename_prefix)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' filename must start with '$($layout.filename_prefix)' for directory '$($layout.id)'")
        }
        if ($layout.allowed_status -and @($layout.allowed_status).Count -gt 0 -and @($layout.allowed_status) -notcontains [string]$view.status) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' status '$($view.status)' is not allowed in directory '$($layout.id)'")
        }
        if ($layout.allowed_view_types -and @($layout.allowed_view_types).Count -gt 0 -and @($layout.allowed_view_types) -notcontains [string]$view.view_type) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' view_type '$($view.view_type)' is not allowed in directory '$($layout.id)'")
        }
    }

    if ($viewTypeDefaultDir.ContainsKey([string]$view.view_type)) {
        $defaultDir = [string]$viewTypeDefaultDir[[string]$view.view_type]
        if (-not $viewPath.StartsWith($defaultDir)) {
            $Errors.Add("system/canvas-registry.json: view '$($view.id)' view_type '$($view.view_type)' should live under '$defaultDir'")
        }
    }

    if ([string]$view.status -eq "current") {
        $family = [string]$view.view_family
        if ([string]::IsNullOrWhiteSpace($family)) {
            $Errors.Add("system/canvas-registry.json: current view '$($view.id)' missing view_family")
        }
        elseif ($currentByFamily.ContainsKey($family)) {
            $Errors.Add("system/canvas-registry.json: multiple current views for view_family '$family'")
        }
        else {
            $currentByFamily[$family] = [string]$view.id
        }
    }

    if (-not $view.source_of_truth -or @($view.source_of_truth).Count -eq 0) {
        $Errors.Add("system/canvas-registry.json: view '$($view.id)' missing source_of_truth")
    }

    Test-ViewBoundaryFields -View $view -RequiredFields $boundaryRequiredFields -AllowedLevels $allowedViewLevels -AllowedCategories $allowedViewCategories

    foreach ($relationField in @("parent_views", "child_views", "related_views")) {
        foreach ($targetViewIdValue in @(Get-OptionalArray -Object $view -Field $relationField)) {
            $targetViewId = [string]$targetViewIdValue
            if ([string]::IsNullOrWhiteSpace($targetViewId)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' has empty $relationField entry")
                continue
            }
            if (-not $viewIds.Contains($targetViewId)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' $relationField references unknown view '$targetViewId'")
            }
        }
    }

    $canvas = Read-JsonFile ([string]$view.path)
    if ($null -ne $canvas) {
        if (-not ($canvas.PSObject.Properties.Name -contains "nodes")) {
            $Errors.Add("$($view.path): missing nodes array")
        }
        if (-not ($canvas.PSObject.Properties.Name -contains "edges")) {
            $Errors.Add("$($view.path): missing edges array")
        }

        $nodeById = @{}
        if ($canvas.PSObject.Properties.Name -contains "nodes") {
            foreach ($node in @($canvas.nodes)) {
                if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace($node.id)) {
                    $nodeById[[string]$node.id] = $node
                }
            }
        }

        foreach ($navigationNode in @(Get-OptionalArray -Object $view -Field "navigation_nodes")) {
            if (-not ($navigationNode.PSObject.Properties.Name -contains "node_id") -or [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' navigation_nodes entry missing node_id")
                continue
            }

            $nodeId = [string]$navigationNode.node_id
            if (-not $nodeById.ContainsKey($nodeId)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' navigation node '$nodeId' not found in canvas file")
            }
            elseif (($nodeById[$nodeId].PSObject.Properties.Name -contains "type") -and [string]$nodeById[$nodeId].type -ne "file") {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' navigation node '$nodeId' should be a file node")
            }

            if (-not ($navigationNode.PSObject.Properties.Name -contains "target_view") -or [string]::IsNullOrWhiteSpace($navigationNode.target_view)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' navigation node '$nodeId' missing target_view")
                continue
            }

            $targetViewId = [string]$navigationNode.target_view
            if (-not $viewIds.Contains($targetViewId)) {
                $Errors.Add("system/canvas-registry.json: view '$($view.id)' navigation node '$nodeId' targets unknown view '$targetViewId'")
            }
        }

        $viewLevel = if ($view.PSObject.Properties.Name -contains "view_level") { [string]$view.view_level } else { "" }
        $viewLayer = if ($view.PSObject.Properties.Name -contains "layer") { [string]$view.layer } else { "" }
        $viewType = if ($view.PSObject.Properties.Name -contains "view_type") { [string]$view.view_type } else { "" }
        $viewStatus = if ($view.PSObject.Properties.Name -contains "status") { [string]$view.status } else { "" }
        if ($viewStatus -in @("current", "active") -and $viewType -eq "visual-navigation-index" -and $viewLevel -eq "L0") {
            foreach ($childViewIdValue in @(Get-OptionalArray -Object $view -Field "child_views")) {
                $childViewId = [string]$childViewIdValue
                if (-not $viewsById.ContainsKey($childViewId)) {
                    continue
                }
                $childLevel = if ($viewsById[$childViewId].PSObject.Properties.Name -contains "view_level") { [string]$viewsById[$childViewId].view_level } else { "" }
                if ($childLevel -ne "L1") {
                    $Errors.Add("system/canvas-registry.json: L0 navigation view '$($view.id)' child_views may only contain L1 trunk views; '$childViewId' is '$childLevel'")
                }
            }
        }

        if ($viewStatus -in @("current", "active") -and $viewLayer -eq "system-subsystem" -and $viewLevel -eq "L2") {
            $parentViews = @(Get-OptionalArray -Object $view -Field "parent_views")
            if ($parentViews -contains "kb-navigation-index") {
                $Errors.Add("system/canvas-registry.json: L2 system-subsystem view '$($view.id)' must not use L0 kb-navigation-index as canonical parent")
            }
            if ($parentViews -notcontains "knowledge-base-system-architecture-map") {
                $Errors.Add("system/canvas-registry.json: L2 system-subsystem view '$($view.id)' must use L1 knowledge-base-system-architecture-map as canonical parent")
            }
        }

        Test-RightSideNavigationLayout -View $view -Canvas $canvas -NodeById $nodeById
        Test-RegisteredCanvasFileNodes -View $view -Canvas $canvas -ViewIdByPath $viewIdByPath -ViewsById $viewsById
        Test-ContextBridgeEdges -View $view -Canvas $canvas
        Test-SupportSemantics -View $view -Canvas $canvas
        Test-ViewColorSemantics -View $view -Canvas $canvas -PaletteById $paletteById
        Test-ArchiveCanvasView -View $view -Canvas $canvas -ViewsById $viewsById
    }
}

foreach ($view in @($registry.views)) {
    if ([string]::IsNullOrWhiteSpace($view.id)) {
        continue
    }

    $viewId = [string]$view.id
    foreach ($childViewIdValue in @(Get-OptionalArray -Object $view -Field "child_views")) {
        $childViewId = [string]$childViewIdValue
        if ([string]::IsNullOrWhiteSpace($childViewId) -or -not $viewsById.ContainsKey($childViewId)) {
            continue
        }
        $childParents = @(Get-OptionalArray -Object $viewsById[$childViewId] -Field "parent_views")
        if ($childParents -notcontains $viewId) {
            $Errors.Add("system/canvas-registry.json: view '$viewId' lists child '$childViewId', but child does not list '$viewId' in parent_views")
        }
    }

    foreach ($parentViewIdValue in @(Get-OptionalArray -Object $view -Field "parent_views")) {
        $parentViewId = [string]$parentViewIdValue
        if ([string]::IsNullOrWhiteSpace($parentViewId) -or -not $viewsById.ContainsKey($parentViewId)) {
            continue
        }
        $parentChildren = @(Get-OptionalArray -Object $viewsById[$parentViewId] -Field "child_views")
        if ($parentChildren -notcontains $viewId) {
            $Errors.Add("system/canvas-registry.json: view '$viewId' lists parent '$parentViewId', but parent does not list '$viewId' in child_views")
        }
    }

    foreach ($relatedViewIdValue in @(Get-OptionalArray -Object $view -Field "related_views")) {
        $relatedViewId = [string]$relatedViewIdValue
        if ([string]::IsNullOrWhiteSpace($relatedViewId) -or -not $viewsById.ContainsKey($relatedViewId)) {
            continue
        }
        $relatedPeers = @(Get-OptionalArray -Object $viewsById[$relatedViewId] -Field "related_views")
        if ($relatedPeers -notcontains $viewId) {
            $Errors.Add("system/canvas-registry.json: view '$viewId' lists related view '$relatedViewId', but relation is not reciprocal")
        }
    }
}

if ($null -ne $viewGraph) {
    foreach ($fieldName in @("nodes", "edges", "data_boundary")) {
        Test-ObjectField -Object $viewGraph -Field $fieldName -Context "system/canvas-view-graph.json" | Out-Null
    }

    $forbiddenMachineFields = @("x", "y", "width", "height", "text", "color")
    if ($viewGraph.PSObject.Properties.Name -contains "data_boundary" -and
        $null -ne $viewGraph.data_boundary -and
        $viewGraph.data_boundary.PSObject.Properties.Name -contains "forbidden_machine_fields") {
        $forbiddenMachineFields = @($viewGraph.data_boundary.forbidden_machine_fields | ForEach-Object { [string]$_ })
    }

    $graphNodeById = @{}
    $graphNodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($graphNode in @($viewGraph.nodes)) {
        if (-not (Test-ObjectField -Object $graphNode -Field "view_id" -Context "system/canvas-view-graph.json node")) {
            continue
        }

        $graphViewId = [string]$graphNode.view_id
        if (-not $graphNodeIds.Add($graphViewId)) {
            $Errors.Add("system/canvas-view-graph.json: duplicate node view_id '$graphViewId'")
        }
        else {
            $graphNodeById[$graphViewId] = $graphNode
        }

        foreach ($forbiddenField in $forbiddenMachineFields) {
            if ($graphNode.PSObject.Properties.Name -contains $forbiddenField) {
                $Errors.Add("system/canvas-view-graph.json node '$graphViewId': forbidden machine field '$forbiddenField'")
            }
        }

        foreach ($fieldName in @("status", "view_family", "view_type", "layer", "canvas_path", "parent_view_ids", "child_view_ids", "related_view_ids", "source_of_truth")) {
            Test-ObjectField -Object $graphNode -Field $fieldName -Context "system/canvas-view-graph.json node '$graphViewId'" | Out-Null
        }

        if (-not $viewsById.ContainsKey($graphViewId)) {
            $Errors.Add("system/canvas-view-graph.json node '$graphViewId': not found in canvas registry views")
            continue
        }

        $registryView = $viewsById[$graphViewId]
        if ([string]$graphNode.canvas_path -ne [string]$registryView.path) {
            $Errors.Add("system/canvas-view-graph.json node '$graphViewId': canvas_path does not match registry path")
        }
        foreach ($fieldName in @("status", "view_family", "view_type", "layer")) {
            if ([string]$graphNode.$fieldName -ne [string]$registryView.$fieldName) {
                $Errors.Add("system/canvas-view-graph.json node '$graphViewId': $fieldName does not match canvas registry")
            }
        }
        Test-SameStringSet -ActualValues @(Get-OptionalArray -Object $graphNode -Field "parent_view_ids") -ExpectedValues @(Get-OptionalArray -Object $registryView -Field "parent_views") -Context "system/canvas-view-graph.json node '$graphViewId' parent_view_ids"
        Test-SameStringSet -ActualValues @(Get-OptionalArray -Object $graphNode -Field "child_view_ids") -ExpectedValues @(Get-OptionalArray -Object $registryView -Field "child_views") -Context "system/canvas-view-graph.json node '$graphViewId' child_view_ids"
        Test-SameStringSet -ActualValues @(Get-OptionalArray -Object $graphNode -Field "related_view_ids") -ExpectedValues @(Get-OptionalArray -Object $registryView -Field "related_views") -Context "system/canvas-view-graph.json node '$graphViewId' related_view_ids"
        Test-SameStringSet -ActualValues @(Get-OptionalArray -Object $graphNode -Field "source_of_truth") -ExpectedValues @(Get-OptionalArray -Object $registryView -Field "source_of_truth") -Context "system/canvas-view-graph.json node '$graphViewId' source_of_truth"
    }

    foreach ($viewId in $viewIds) {
        if (-not $graphNodeIds.Contains($viewId)) {
            $Errors.Add("system/canvas-view-graph.json: missing registry view '$viewId'")
        }
    }

    foreach ($graphEdge in @($viewGraph.edges)) {
        $hasFrom = Test-ObjectField -Object $graphEdge -Field "from_view" -Context "system/canvas-view-graph.json edge"
        $hasTo = Test-ObjectField -Object $graphEdge -Field "to_view" -Context "system/canvas-view-graph.json edge"
        $hasRelation = Test-ObjectField -Object $graphEdge -Field "relation" -Context "system/canvas-view-graph.json edge"
        Test-ObjectField -Object $graphEdge -Field "navigation_node_id" -Context "system/canvas-view-graph.json edge" | Out-Null

        if (-not ($hasFrom -and $hasTo -and $hasRelation)) {
            continue
        }

        $fromView = [string]$graphEdge.from_view
        $toView = [string]$graphEdge.to_view
        $relation = [string]$graphEdge.relation
        $navigationNodeId = [string]$graphEdge.navigation_node_id
        $edgeContext = "system/canvas-view-graph.json edge '$fromView' -> '$toView'"

        if (-not $graphNodeIds.Contains($fromView)) {
            $Errors.Add("${edgeContext}: unknown from_view")
            continue
        }
        if (-not $graphNodeIds.Contains($toView)) {
            $Errors.Add("${edgeContext}: unknown to_view")
            continue
        }

        if ($relation -notin @("parent", "child", "related")) {
            $Errors.Add("${edgeContext}: invalid relation '$relation'")
        }

        $fromNode = $graphNodeById[$fromView]
        $toNode = $graphNodeById[$toView]
        if ($relation -eq "child") {
            if (@(Get-OptionalArray -Object $fromNode -Field "child_view_ids") -notcontains $toView) {
                $Errors.Add("${edgeContext}: child edge is not listed in from node child_view_ids")
            }
            if (@(Get-OptionalArray -Object $toNode -Field "parent_view_ids") -notcontains $fromView) {
                $Errors.Add("${edgeContext}: child edge is not reciprocated in to node parent_view_ids")
            }
        }
        elseif ($relation -eq "parent") {
            if (@(Get-OptionalArray -Object $fromNode -Field "parent_view_ids") -notcontains $toView) {
                $Errors.Add("${edgeContext}: parent edge is not listed in from node parent_view_ids")
            }
            if (@(Get-OptionalArray -Object $toNode -Field "child_view_ids") -notcontains $fromView) {
                $Errors.Add("${edgeContext}: parent edge is not reciprocated in to node child_view_ids")
            }
        }
        elseif ($relation -eq "related") {
            if (@(Get-OptionalArray -Object $fromNode -Field "related_view_ids") -notcontains $toView) {
                $Errors.Add("${edgeContext}: related edge is not listed in from node related_view_ids")
            }
            if (@(Get-OptionalArray -Object $toNode -Field "related_view_ids") -notcontains $fromView) {
                $Errors.Add("${edgeContext}: related edge is not reciprocal")
            }
        }

        if ($viewsById.ContainsKey($fromView)) {
            $navigationMatches = @($viewsById[$fromView].navigation_nodes | Where-Object {
                [string]$_.target_view -eq $toView -and [string]$_.node_id -eq $navigationNodeId
            })
            if ($navigationMatches.Count -eq 0) {
                $Errors.Add("${edgeContext}: navigation_node_id '$navigationNodeId' is not registered on from view")
            }
        }
    }
}

$canvasRoot = Join-Path $Root "30-maps/canvas"
$canvasFiles = Get-ChildItem -LiteralPath $canvasRoot -Recurse -File -Filter "*.canvas"
foreach ($file in $canvasFiles) {
    $relativePath = (Get-RelativePath -Path $file.FullName).Replace("\", "/")
    $relativeParent = (Split-Path -Parent $relativePath).Replace("\", "/")
    if ($relativeParent -eq "30-maps/canvas") {
        $Errors.Add("${relativePath}: root canvas directory must not contain .canvas files")
    }

    $canvas = Read-JsonFile $relativePath
    if ($null -ne $canvas) {
        if (-not ($canvas.PSObject.Properties.Name -contains "nodes")) {
            $Errors.Add("${relativePath}: missing nodes array")
        }
        if (-not ($canvas.PSObject.Properties.Name -contains "edges")) {
            $Errors.Add("${relativePath}: missing edges array")
        }
        Test-CanvasTextIntegrity -Canvas $canvas -Context $relativePath
    }

    $isDraft = $relativePath.StartsWith("30-maps/canvas/80-drafts/")
    $isArchive = $relativePath.StartsWith("30-maps/canvas/90-archive/")
    if (-not $registeredPaths.Contains($relativePath) -and -not $isDraft -and -not $isArchive) {
        $Errors.Add("${relativePath}: canvas file is not registered in system/canvas-registry.json")
    }
    elseif (-not $registeredPaths.Contains($relativePath) -and $isDraft) {
        $fileName = [System.IO.Path]::GetFileName($relativePath)
        if (-not $fileName.StartsWith("draft-")) {
            $Errors.Add("${relativePath}: unregistered draft canvas filename must start with 'draft-'")
        }
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "Canvas validation failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Canvas validation passed for $($canvasFiles.Count) canvas files."
