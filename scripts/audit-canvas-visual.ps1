[CmdletBinding()]
param(
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$Errors = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

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

function Get-Rect {
    param([object]$Node)

    foreach ($field in @("x", "y", "width", "height")) {
        if (-not ($Node.PSObject.Properties.Name -contains $field)) {
            return $null
        }
    }

    return [pscustomobject]@{
        Left = [double]$Node.x
        Top = [double]$Node.y
        Right = [double]$Node.x + [double]$Node.width
        Bottom = [double]$Node.y + [double]$Node.height
        Width = [double]$Node.width
        Height = [double]$Node.height
    }
}

function Get-Center {
    param([object]$Node)

    $rect = Get-Rect -Node $Node
    if ($null -eq $rect) {
        return $null
    }

    return [pscustomobject]@{
        X = ($rect.Left + $rect.Right) / 2
        Y = ($rect.Top + $rect.Bottom) / 2
    }
}

function Get-EdgeAnchorPoint {
    param(
        [object]$Node,
        [string]$Side
    )

    $rect = Get-Rect -Node $Node
    if ($null -eq $rect) {
        return $null
    }

    $centerX = ($rect.Left + $rect.Right) / 2
    $centerY = ($rect.Top + $rect.Bottom) / 2

    switch ($Side) {
        "left" {
            return [pscustomobject]@{ X = $rect.Left; Y = $centerY }
        }
        "right" {
            return [pscustomobject]@{ X = $rect.Right; Y = $centerY }
        }
        "top" {
            return [pscustomobject]@{ X = $centerX; Y = $rect.Top }
        }
        "bottom" {
            return [pscustomobject]@{ X = $centerX; Y = $rect.Bottom }
        }
        default {
            return [pscustomobject]@{ X = $centerX; Y = $centerY }
        }
    }
}

function Get-EstimatedLabelWidth {
    param([string]$Label)

    if ([string]::IsNullOrWhiteSpace($Label)) {
        return 0
    }

    $width = 28
    foreach ($character in $Label.ToCharArray()) {
        if ([int][char]$character -gt 127) {
            $width += 14
        }
        else {
            $width += 9
        }
    }

    return [math]::Max(64, $width)
}

function Get-ExpandedRect {
    param(
        [object]$Rect,
        [double]$Padding
    )

    return [pscustomobject]@{
        Left = $Rect.Left - $Padding
        Top = $Rect.Top - $Padding
        Right = $Rect.Right + $Padding
        Bottom = $Rect.Bottom + $Padding
        Width = $Rect.Width + ($Padding * 2)
        Height = $Rect.Height + ($Padding * 2)
    }
}

function Test-PointInRect {
    param(
        [object]$Point,
        [object]$Rect
    )

    return (
        $Point.X -ge $Rect.Left -and
        $Point.X -le $Rect.Right -and
        $Point.Y -ge $Rect.Top -and
        $Point.Y -le $Rect.Bottom
    )
}

function Get-Orientation {
    param(
        [object]$PointA,
        [object]$PointB,
        [object]$PointC
    )

    $value = (($PointB.Y - $PointA.Y) * ($PointC.X - $PointB.X)) - (($PointB.X - $PointA.X) * ($PointC.Y - $PointB.Y))
    if ([math]::Abs($value) -lt 0.001) {
        return 0
    }
    if ($value -gt 0) {
        return 1
    }
    return 2
}

function Test-PointOnSegment {
    param(
        [object]$PointA,
        [object]$PointB,
        [object]$PointC
    )

    return (
        $PointB.X -le [math]::Max($PointA.X, $PointC.X) -and
        $PointB.X -ge [math]::Min($PointA.X, $PointC.X) -and
        $PointB.Y -le [math]::Max($PointA.Y, $PointC.Y) -and
        $PointB.Y -ge [math]::Min($PointA.Y, $PointC.Y)
    )
}

function Test-SegmentsIntersect {
    param(
        [object]$PointA,
        [object]$PointB,
        [object]$PointC,
        [object]$PointD
    )

    $orientation1 = Get-Orientation -PointA $PointA -PointB $PointB -PointC $PointC
    $orientation2 = Get-Orientation -PointA $PointA -PointB $PointB -PointC $PointD
    $orientation3 = Get-Orientation -PointA $PointC -PointB $PointD -PointC $PointA
    $orientation4 = Get-Orientation -PointA $PointC -PointB $PointD -PointC $PointB

    if ($orientation1 -ne $orientation2 -and $orientation3 -ne $orientation4) {
        return $true
    }

    if ($orientation1 -eq 0 -and (Test-PointOnSegment -PointA $PointA -PointB $PointC -PointC $PointB)) {
        return $true
    }
    if ($orientation2 -eq 0 -and (Test-PointOnSegment -PointA $PointA -PointB $PointD -PointC $PointB)) {
        return $true
    }
    if ($orientation3 -eq 0 -and (Test-PointOnSegment -PointA $PointC -PointB $PointA -PointC $PointD)) {
        return $true
    }
    if ($orientation4 -eq 0 -and (Test-PointOnSegment -PointA $PointC -PointB $PointB -PointC $PointD)) {
        return $true
    }

    return $false
}

function Test-SegmentIntersectsRect {
    param(
        [object]$PointA,
        [object]$PointB,
        [object]$Rect
    )

    if ((Test-PointInRect -Point $PointA -Rect $Rect) -or (Test-PointInRect -Point $PointB -Rect $Rect)) {
        return $true
    }

    $topLeft = [pscustomobject]@{ X = $Rect.Left; Y = $Rect.Top }
    $topRight = [pscustomobject]@{ X = $Rect.Right; Y = $Rect.Top }
    $bottomRight = [pscustomobject]@{ X = $Rect.Right; Y = $Rect.Bottom }
    $bottomLeft = [pscustomobject]@{ X = $Rect.Left; Y = $Rect.Bottom }

    return (
        (Test-SegmentsIntersect -PointA $PointA -PointB $PointB -PointC $topLeft -PointD $topRight) -or
        (Test-SegmentsIntersect -PointA $PointA -PointB $PointB -PointC $topRight -PointD $bottomRight) -or
        (Test-SegmentsIntersect -PointA $PointA -PointB $PointB -PointC $bottomRight -PointD $bottomLeft) -or
        (Test-SegmentsIntersect -PointA $PointA -PointB $PointB -PointC $bottomLeft -PointD $topLeft)
    )
}

function Get-OverlapArea {
    param(
        [object]$RectA,
        [object]$RectB,
        [double]$Margin = 0
    )

    $left = [math]::Max($RectA.Left + $Margin, $RectB.Left + $Margin)
    $top = [math]::Max($RectA.Top + $Margin, $RectB.Top + $Margin)
    $right = [math]::Min($RectA.Right - $Margin, $RectB.Right - $Margin)
    $bottom = [math]::Min($RectA.Bottom - $Margin, $RectB.Bottom - $Margin)

    if ($right -le $left -or $bottom -le $top) {
        return 0
    }

    return ($right - $left) * ($bottom - $top)
}

function Test-EmbeddedFileLabelPair {
    param(
        [object]$NodeA,
        [object]$NodeB
    )

    $idA = if ($NodeA.PSObject.Properties.Name -contains "id") { [string]$NodeA.id } else { "" }
    $idB = if ($NodeB.PSObject.Properties.Name -contains "id") { [string]$NodeB.id } else { "" }
    $typeA = if ($NodeA.PSObject.Properties.Name -contains "type") { [string]$NodeA.type } else { "" }
    $typeB = if ($NodeB.PSObject.Properties.Name -contains "type") { [string]$NodeB.type } else { "" }

    $fileNode = $null
    $labelNode = $null
    if ($typeA -eq "file" -and $idB -eq "file-label-$idA") {
        $fileNode = $NodeA
        $labelNode = $NodeB
    }
    elseif ($typeB -eq "file" -and $idA -eq "file-label-$idB") {
        $fileNode = $NodeB
        $labelNode = $NodeA
    }
    else {
        return $false
    }

    $fileRect = Get-Rect -Node $fileNode
    $labelRect = Get-Rect -Node $labelNode
    if ($null -eq $fileRect -or $null -eq $labelRect) {
        return $false
    }

    return (
        $fileRect.Width -le 96 -and
        $fileRect.Height -le 72 -and
        $fileRect.Left -ge $labelRect.Left -and
        $fileRect.Right -le $labelRect.Right -and
        $fileRect.Top -ge $labelRect.Top -and
        $fileRect.Bottom -le $labelRect.Bottom
    )
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

function Test-CanvasVisual {
    param(
        [object]$View,
        [object]$Canvas
    )

    $viewId = [string]$View.id
    $path = [string]$View.path
    $nodes = @($Canvas.nodes)
    $edges = @($Canvas.edges)
    $nodeById = @{}

    foreach ($node in $nodes) {
        if ($node.PSObject.Properties.Name -contains "id" -and -not [string]::IsNullOrWhiteSpace([string]$node.id)) {
            $nodeById[[string]$node.id] = $node
        }
    }

    if (($View.PSObject.Properties.Name -contains "color_semantics") -and $null -ne $View.color_semantics) {
        $legendNodeId = if ($View.color_semantics.PSObject.Properties.Name -contains "visible_legend_node") { [string]$View.color_semantics.visible_legend_node } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($legendNodeId)) {
            if (-not $nodeById.ContainsKey($legendNodeId)) {
                $Warnings.Add("${path}: color semantics declares legend '$legendNodeId' but the node is missing")
            }
            else {
                $legendRect = Get-Rect -Node $nodeById[$legendNodeId]
                if ($null -ne $legendRect -and ($legendRect.Width -lt 260 -or $legendRect.Height -lt 70)) {
                    $Warnings.Add("${path}: color legend '$legendNodeId' is small ($($legendRect.Width)x$($legendRect.Height)); make the palette explanation readable")
                }
            }
        }
    }

    foreach ($node in $nodes) {
        $nodeId = if ($node.PSObject.Properties.Name -contains "id") { [string]$node.id } else { "<missing-id>" }
        $type = if ($node.PSObject.Properties.Name -contains "type") { [string]$node.type } else { "" }

        if ($type -eq "text") {
            $text = if ($node.PSObject.Properties.Name -contains "text") { [string]$node.text } else { "" }
            if ([string]::IsNullOrWhiteSpace($text)) {
                $Errors.Add("${path}: text node '$nodeId' is empty; empty visual cards create noise")
            }
        }

        $rect = Get-Rect -Node $node
        if ($null -ne $rect) {
            if ($nodeId -match "^context-(rail|corridor|port)-") {
                if ($type -ne "group" -or $rect.Width -gt 6 -or $rect.Height -gt 6) {
                    $Errors.Add("${path}: route point '$nodeId' must be a near-invisible group node no larger than 6x6; visible route cards make the canvas look like a wiring diagram")
                }
                continue
            }
            if ($rect.Width -lt 40 -or $rect.Height -lt 32) {
                $Warnings.Add("${path}: node '$nodeId' is very small ($($rect.Width)x$($rect.Height)); it may become unreadable in Obsidian")
            }
            if ($type -eq "text" -and $rect.Width -gt 1900 -and $nodeId -notmatch "title|scope|band") {
                $Warnings.Add("${path}: text node '$nodeId' is very wide; wide cards reduce scanability")
            }
        }
    }

    for ($i = 0; $i -lt $nodes.Count; $i++) {
        $nodeA = $nodes[$i]
        $idA = if ($nodeA.PSObject.Properties.Name -contains "id") { [string]$nodeA.id } else { "" }
        $rectA = Get-Rect -Node $nodeA
        if ($null -eq $rectA) {
            continue
        }

        for ($j = $i + 1; $j -lt $nodes.Count; $j++) {
            $nodeB = $nodes[$j]
            $idB = if ($nodeB.PSObject.Properties.Name -contains "id") { [string]$nodeB.id } else { "" }
            $rectB = Get-Rect -Node $nodeB
            if ($null -eq $rectB) {
                continue
            }

            if (Test-EmbeddedFileLabelPair -NodeA $nodeA -NodeB $nodeB) {
                continue
            }

            $overlapArea = Get-OverlapArea -RectA $rectA -RectB $rectB -Margin 3
            if ($overlapArea -gt 600) {
                $Errors.Add("${path}: nodes '$idA' and '$idB' visually overlap; overlap area $([math]::Round($overlapArea, 0))")
            }
        }
    }

    $navigationEndpointIds = New-Object System.Collections.Generic.HashSet[string]
    $navigationFileNodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($navigationNode in @(Get-OptionalArray -Object $View -Field "navigation_nodes")) {
        if ($navigationNode.PSObject.Properties.Name -contains "node_id" -and -not [string]::IsNullOrWhiteSpace($navigationNode.node_id)) {
            $nodeId = [string]$navigationNode.node_id
            [void]$navigationEndpointIds.Add($nodeId)
            [void]$navigationEndpointIds.Add("nav-label-$nodeId")
            [void]$navigationFileNodeIds.Add($nodeId)
        }
    }

    $isNavigationIndex = $View.PSObject.Properties.Name -contains "view_type" -and [string]$View.view_type -eq "visual-navigation-index"
    if (-not $isNavigationIndex) {
        foreach ($navigationFileNodeId in $navigationFileNodeIds) {
            if (-not $nodeById.ContainsKey($navigationFileNodeId)) {
                continue
            }

            $node = $nodeById[$navigationFileNodeId]
            $type = if ($node.PSObject.Properties.Name -contains "type") { [string]$node.type } else { "" }
            if ($type -ne "file") {
                continue
            }

            $rect = Get-Rect -Node $node
            if ($null -eq $rect) {
                continue
            }
            if ($rect.Width -gt 96 -or $rect.Height -gt 72) {
                $Warnings.Add("${path}: navigation file node '$navigationFileNodeId' is large ($($rect.Width)x$($rect.Height)); structural-view navigation targets should be compact buttons, with meaning carried by nav-label-* text and content markers")
            }
        }
    }

    $supportBindingNodeIds = New-Object System.Collections.Generic.HashSet[string]
    foreach ($binding in @(Get-OptionalArray -Object $View -Field "support_bindings")) {
        if ($binding.PSObject.Properties.Name -contains "support_node" -and -not [string]::IsNullOrWhiteSpace([string]$binding.support_node)) {
            [void]$supportBindingNodeIds.Add([string]$binding.support_node)
        }
    }

    foreach ($node in $nodes) {
        $nodeId = if ($node.PSObject.Properties.Name -contains "id") { [string]$node.id } else { "" }
        $type = if ($node.PSObject.Properties.Name -contains "type") { [string]$node.type } else { "" }
        if ($type -ne "file" -or [string]::IsNullOrWhiteSpace($nodeId)) {
            continue
        }
        if ($navigationFileNodeIds.Contains($nodeId)) {
            continue
        }

        $supportFileRect = Get-Rect -Node $node
        if ($null -ne $supportFileRect -and ($supportFileRect.Width -gt 96 -or $supportFileRect.Height -gt 72)) {
            $Warnings.Add("${path}: support file node '$nodeId' is large ($($supportFileRect.Width)x$($supportFileRect.Height)); support files should use file-label-* as the readable card and keep file nodes as compact click buttons")
        }

        $fileLabelNodeId = "file-label-$nodeId"
        if (-not $nodeById.ContainsKey($fileLabelNodeId)) {
            $Warnings.Add("${path}: support file node '$nodeId' has no human-readable file-label node '$fileLabelNodeId'; file names alone are not enough for current/active Canvas readability")
            continue
        }

        $fileLabelNode = $nodeById[$fileLabelNodeId]
        $fileLabelType = if ($fileLabelNode.PSObject.Properties.Name -contains "type") { [string]$fileLabelNode.type } else { "" }
        $fileLabelText = if ($fileLabelNode.PSObject.Properties.Name -contains "text") { [string]$fileLabelNode.text } else { "" }
        if ($fileLabelType -ne "text" -or [string]::IsNullOrWhiteSpace($fileLabelText)) {
            $Warnings.Add("${path}: support file label '$fileLabelNodeId' must be a non-empty text node explaining the file role")
        }

        if (-not $supportBindingNodeIds.Contains($fileLabelNodeId)) {
            $Warnings.Add("${path}: support file label '$fileLabelNodeId' has no support_bindings entry to an upper Canvas node; bottom machine truth must not read as loose bibliography")
        }
    }

    $mainRight = $null
    $navLeft = $null
    foreach ($node in $nodes) {
        if (-not ($node.PSObject.Properties.Name -contains "id")) {
            continue
        }
        $nodeId = [string]$node.id
        $rect = Get-Rect -Node $node
        if ($null -eq $rect) {
            continue
        }

        if ($navigationEndpointIds.Contains($nodeId)) {
            if ($null -eq $navLeft -or $rect.Left -lt $navLeft) {
                $navLeft = $rect.Left
            }
            continue
        }
        if ($nodeId -match "right-nav|navigation-panel|^bridge-anchor-|^color-legend$") {
            continue
        }

        if ($null -eq $mainRight -or $rect.Right -gt $mainRight) {
            $mainRight = $rect.Right
        }
    }

    if (-not $isNavigationIndex -and $null -ne $mainRight -and $null -ne $navLeft) {
        $mainNavigationGap = $navLeft - $mainRight
        if ($mainNavigationGap -lt 200) {
            $Warnings.Add("${path}: right-side navigation is too close to main content ($([math]::Round($mainNavigationGap, 0))px); leave at least 200px of clear gutter so interpretation lines do not crowd the main structure")
        }
    }

    foreach ($node in $nodes) {
        if (-not ($node.PSObject.Properties.Name -contains "id")) {
            continue
        }
        $nodeId = [string]$node.id
        if (-not $nodeId.StartsWith("bridge-anchor-")) {
            continue
        }

        $rect = Get-Rect -Node $node
        if ($null -eq $rect) {
            continue
        }
        if ($null -ne $mainRight -and $rect.Left -lt ($mainRight + 8)) {
            $Warnings.Add("${path}: bridge anchor '$nodeId' is close to main content; move it into the clear gutter if lines feel cramped")
        }
        if ($null -ne $navLeft -and $rect.Right -gt ($navLeft - 8)) {
            $Warnings.Add("${path}: bridge anchor '$nodeId' is too close to navigation labels; leave a visible gutter")
        }
    }

    $contextRouteEdges = @($edges | Where-Object {
        $_.PSObject.Properties.Name -contains "id" -and
        ([string]$_.id).StartsWith("context-route-")
    })
    if ($contextRouteEdges.Count -gt 0) {
        $Warnings.Add("${path}: uses $($contextRouteEdges.Count) context-route edge(s); prefer one direct nav-label-to-content bridge line for navigation-to-content correspondence, and keep routed lines as explicit exceptions")
    }

    foreach ($edge in $edges) {
        if (-not ($edge.PSObject.Properties.Name -contains "id")) {
            continue
        }

        $edgeId = [string]$edge.id
        $isContextRoute = $edgeId.StartsWith("context-route-")
        $fromNodeId = if ($edge.PSObject.Properties.Name -contains "fromNode") { [string]$edge.fromNode } else { "" }
        $toNodeId = if ($edge.PSObject.Properties.Name -contains "toNode") { [string]$edge.toNode } else { "" }

        if (-not $nodeById.ContainsKey($fromNodeId) -or -not $nodeById.ContainsKey($toNodeId)) {
            continue
        }

        $fromCenter = Get-Center -Node $nodeById[$fromNodeId]
        $toCenter = Get-Center -Node $nodeById[$toNodeId]
        if ($null -eq $fromCenter -or $null -eq $toCenter) {
            continue
        }

        $dx = $toCenter.X - $fromCenter.X
        $dy = $toCenter.Y - $fromCenter.Y
        $distance = [math]::Sqrt(($dx * $dx) + ($dy * $dy))

        $fromSide = if ($edge.PSObject.Properties.Name -contains "fromSide") { [string]$edge.fromSide } else { "" }
        $toSide = if ($edge.PSObject.Properties.Name -contains "toSide") { [string]$edge.toSide } else { "" }
        $fromAnchor = Get-EdgeAnchorPoint -Node $nodeById[$fromNodeId] -Side $fromSide
        $toAnchor = Get-EdgeAnchorPoint -Node $nodeById[$toNodeId] -Side $toSide
        $anchorDistance = $distance
        if ($null -ne $fromAnchor -and $null -ne $toAnchor) {
            $anchorDx = $toAnchor.X - $fromAnchor.X
            $anchorDy = $toAnchor.Y - $fromAnchor.Y
            $anchorDistance = [math]::Sqrt(($anchorDx * $anchorDx) + ($anchorDy * $anchorDy))
        }

        $label = if ($edge.PSObject.Properties.Name -contains "label") { [string]$edge.label } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($label) -and -not $edgeId.StartsWith("bridge-")) {
            $Warnings.Add("${path}: primary flow edge '$edgeId' has label '$label'; current/active structural views should keep primary-flow edges unlabeled and put semantics in cards, section titles or local notes")
        }

        if (-not [string]::IsNullOrWhiteSpace($label) -and
            -not $edgeId.StartsWith("bridge-") -and
            $label.Length -gt 4 -and
            $null -ne $fromAnchor -and
            $null -ne $toAnchor) {
            $horizontalClearance = [math]::Abs($toAnchor.X - $fromAnchor.X)
            $verticalDrift = [math]::Abs($toAnchor.Y - $fromAnchor.Y)
            $isHorizontalLabelRun = $horizontalClearance -gt 0 -and $verticalDrift -le 24 -and
                $fromSide -in @("left", "right") -and $toSide -in @("left", "right")

            if ($isHorizontalLabelRun) {
                $requiredLabelClearance = Get-EstimatedLabelWidth -Label $label
                if ($horizontalClearance -lt $requiredLabelClearance) {
                    $Warnings.Add("${path}: edge '$edgeId' label '$label' has only $([math]::Round($horizontalClearance, 0))px horizontal clearance; leave at least $([math]::Round($requiredLabelClearance, 0))px between cards or remove the edge label")
                }
            }
        }

        if ($null -ne $fromAnchor -and $null -ne $toAnchor) {
            foreach ($node in $nodes) {
                if (-not ($node.PSObject.Properties.Name -contains "id")) {
                    continue
                }

                $nodeId = [string]$node.id
                if ($nodeId -eq $fromNodeId -or $nodeId -eq $toNodeId) {
                    continue
                }
                if ($nodeId -eq "file-label-$fromNodeId" -or $nodeId -eq "file-label-$toNodeId") {
                    continue
                }
                if ($isContextRoute -and ($nodeId -match "^context-(rail|corridor|port)-")) {
                    continue
                }

                $rect = Get-Rect -Node $node
                if ($null -eq $rect) {
                    continue
                }

                $expandedRect = Get-ExpandedRect -Rect $rect -Padding 4
                if (Test-SegmentIntersectsRect -PointA $fromAnchor -PointB $toAnchor -Rect $expandedRect) {
                    $Errors.Add("${path}: edge '$edgeId' crosses unrelated node '$nodeId'; reroute the line, shorten it, remove low-value reference edges, or use a nearby anchor")
                    break
                }
            }
        }

        if (-not $edgeId.StartsWith("bridge-") -and [math]::Abs($dx) -gt 120 -and [math]::Abs($dy) -gt 120 -and $distance -gt 620) {
            $Warnings.Add("${path}: edge '$edgeId' is a long diagonal ($([math]::Round($distance, 0))px); diagonal routing should be replaced by grouping, a local note, or an anchor when it reduces scanability")
        }

        if ($edgeId.StartsWith("bridge-")) {
            $usesBridgeAnchor = $fromNodeId.StartsWith("bridge-anchor-") -or $toNodeId.StartsWith("bridge-anchor-")
            if ($usesBridgeAnchor -and $anchorDistance -gt 360) {
                $Errors.Add("${path}: bridge edge '$edgeId' is too long ($([math]::Round($anchorDistance, 0))px); keep bridge-anchor gutter lines short or use one direct nav-label-to-content interpretation line")
            }
            elseif (-not $usesBridgeAnchor -and $anchorDistance -gt 1900) {
                $Warnings.Add("${path}: direct navigation interpretation edge '$edgeId' is very long ($([math]::Round($anchorDistance, 0))px); keep only if it is a single high-signal line that does not duplicate a content marker")
            }
        }
        elseif (-not $isContextRoute -and $distance -gt 1500) {
            $Warnings.Add("${path}: edge '$edgeId' is long ($([math]::Round($distance, 0))px); consider replacing it with a note or anchor")
        }
    }
}

$registry = Read-JsonFile "system/canvas-registry.json"
if ($null -ne $registry) {
    foreach ($view in @($registry.views)) {
        if ([string]$view.status -notin @("current", "active")) {
            continue
        }

        $canvas = Read-JsonFile ([string]$view.path)
        if ($null -ne $canvas) {
            Test-CanvasVisual -View $view -Canvas $canvas
        }
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "Canvas visual audit warnings:" -ForegroundColor Yellow
    foreach ($warning in $Warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

if ($Errors.Count -gt 0 -or ($Strict -and $Warnings.Count -gt 0)) {
    Write-Host "Canvas visual audit failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    if ($Strict -and $Warnings.Count -gt 0) {
        foreach ($warning in $Warnings) {
            Write-Host "  - strict warning: $warning" -ForegroundColor Red
        }
    }
    exit 1
}

Write-Host "Canvas visual audit passed with $($Warnings.Count) warning(s)."
