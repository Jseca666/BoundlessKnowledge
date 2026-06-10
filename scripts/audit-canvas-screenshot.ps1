[CmdletBinding()]
param(
    [string]$ViewId = "",
    [string]$OutputDir = "system/reviews/canvas-screenshots",
    [int]$MaxWidth = 2600,
    [int]$MaxHeight = 1900,
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$OutputRoot = Join-Path $Root $OutputDir
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

Add-Type -AssemblyName System.Drawing

$Errors = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$Results = New-Object System.Collections.Generic.List[object]

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

function Get-PropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$Default = $null
    )

    if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $Name)) {
        return $Default
    }

    return $Object.PSObject.Properties[$Name].Value
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

function Get-CanvasBounds {
    param([object[]]$Nodes)

    $left = $null
    $top = $null
    $right = $null
    $bottom = $null

    foreach ($node in $Nodes) {
        $rect = Get-Rect -Node $node
        if ($null -eq $rect) {
            continue
        }

        if ($null -eq $left -or $rect.Left -lt $left) { $left = $rect.Left }
        if ($null -eq $top -or $rect.Top -lt $top) { $top = $rect.Top }
        if ($null -eq $right -or $rect.Right -gt $right) { $right = $rect.Right }
        if ($null -eq $bottom -or $rect.Bottom -gt $bottom) { $bottom = $rect.Bottom }
    }

    if ($null -eq $left) {
        return $null
    }

    $margin = 80.0
    return [pscustomobject]@{
        Left = $left - $margin
        Top = $top - $margin
        Right = $right + $margin
        Bottom = $bottom + $margin
        Width = ($right - $left) + ($margin * 2)
        Height = ($bottom - $top) + ($margin * 2)
    }
}

function Get-AnchorPoint {
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
        "left" { return [pscustomobject]@{ X = $rect.Left; Y = $centerY } }
        "right" { return [pscustomobject]@{ X = $rect.Right; Y = $centerY } }
        "top" { return [pscustomobject]@{ X = $centerX; Y = $rect.Top } }
        "bottom" { return [pscustomobject]@{ X = $centerX; Y = $rect.Bottom } }
        default { return [pscustomobject]@{ X = $centerX; Y = $centerY } }
    }
}

function Get-TokenStyle {
    param([string]$ColorToken)

    $token = $ColorToken
    if ([string]::IsNullOrWhiteSpace($token)) {
        $token = "default"
    }

    $styles = @{
        "1" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 255, 241, 242); Stroke = [System.Drawing.Color]::FromArgb(255, 251, 113, 133); Text = [System.Drawing.Color]::FromArgb(255, 70, 20, 30) }
        "2" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 255, 247, 237); Stroke = [System.Drawing.Color]::FromArgb(255, 251, 146, 60); Text = [System.Drawing.Color]::FromArgb(255, 78, 38, 10) }
        "3" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 255, 251, 235); Stroke = [System.Drawing.Color]::FromArgb(255, 245, 158, 11); Text = [System.Drawing.Color]::FromArgb(255, 66, 51, 12) }
        "4" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 236, 253, 245); Stroke = [System.Drawing.Color]::FromArgb(255, 34, 197, 94); Text = [System.Drawing.Color]::FromArgb(255, 20, 83, 45) }
        "5" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 236, 254, 255); Stroke = [System.Drawing.Color]::FromArgb(255, 6, 182, 212); Text = [System.Drawing.Color]::FromArgb(255, 22, 78, 99) }
        "6" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 245, 243, 255); Stroke = [System.Drawing.Color]::FromArgb(255, 139, 92, 246); Text = [System.Drawing.Color]::FromArgb(255, 59, 7, 100) }
        "default" = @{ Fill = [System.Drawing.Color]::FromArgb(255, 250, 250, 250); Stroke = [System.Drawing.Color]::FromArgb(255, 148, 163, 184); Text = [System.Drawing.Color]::FromArgb(255, 24, 24, 27) }
    }

    if ($styles.ContainsKey($token)) {
        return $styles[$token]
    }

    if ($token -match "^#[0-9a-fA-F]{6}$") {
        $r = [Convert]::ToInt32($token.Substring(1, 2), 16)
        $g = [Convert]::ToInt32($token.Substring(3, 2), 16)
        $b = [Convert]::ToInt32($token.Substring(5, 2), 16)
        return @{
            Fill = [System.Drawing.Color]::FromArgb(255, [math]::Min(255, $r + 36), [math]::Min(255, $g + 36), [math]::Min(255, $b + 36))
            Stroke = [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
            Text = [System.Drawing.Color]::FromArgb(255, 24, 24, 27)
        }
    }

    return $styles["default"]
}

function Get-DisplayText {
    param([object]$Node)

    $type = [string](Get-PropertyValue -Object $Node -Name "type" -Default "")
    if ($type -eq "file") {
        $filePath = [string](Get-PropertyValue -Object $Node -Name "file" -Default "")
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            return "file"
        }
        return [System.IO.Path]::GetFileName($filePath)
    }

    $text = [string](Get-PropertyValue -Object $Node -Name "text" -Default "")
    $text = $text -replace '\*\*', ''
    $text = $text -replace '`', ''
    $text = $text -replace '(?m)^\s{0,3}#{1,6}\s*', ''
    $text = $text -replace '\r', ''
    return $text.Trim()
}

function Test-TextCorruption {
    param(
        [string]$Text,
        [string]$Context
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return
    }

    if ($Text -match "[?]{4,}") {
        $Errors.Add("${Context}: rendered text source contains question-mark placeholder corruption")
    }
    if ($Text -match ([string][char]0xFFFD)) {
        $Errors.Add("${Context}: rendered text source contains replacement characters")
    }
    if ($Text.Contains([string][char]0x951F)) {
        $Errors.Add("${Context}: rendered text source contains a likely mojibake marker")
    }
}

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = [math]::Min($Radius * 2, [math]::Min($Width, $Height))
    if ($diameter -le 1) {
        $path.AddRectangle((New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)))
        return $path
    }

    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-CanvasNode {
    param(
        [System.Drawing.Graphics]$Graphics,
        [object]$Node,
        [object]$Bounds,
        [double]$Scale,
        [System.Drawing.Font]$TitleFont,
        [System.Drawing.Font]$BodyFont
    )

    $rect = Get-Rect -Node $Node
    if ($null -eq $rect) {
        return
    }

    $type = [string](Get-PropertyValue -Object $Node -Name "type" -Default "")
    $color = [string](Get-PropertyValue -Object $Node -Name "color" -Default "")
    $style = Get-TokenStyle -ColorToken $color

    $x = [float](($rect.Left - $Bounds.Left) * $Scale)
    $y = [float](($rect.Top - $Bounds.Top) * $Scale)
    $w = [float]([math]::Max(1, $rect.Width * $Scale))
    $h = [float]([math]::Max(1, $rect.Height * $Scale))
    $radius = [float]([math]::Max(3, 7 * $Scale))

    $fill = $style.Fill
    if ($type -eq "group") {
        $fill = [System.Drawing.Color]::FromArgb(42, $style.Fill.R, $style.Fill.G, $style.Fill.B)
    }

    $path = New-RoundedRectPath -X $x -Y $y -Width $w -Height $h -Radius $radius
    $fillBrush = New-Object System.Drawing.SolidBrush $fill
    $strokePen = New-Object System.Drawing.Pen $style.Stroke, ([float]([math]::Max(1.0, 2.0 * $Scale)))
    $Graphics.FillPath($fillBrush, $path)
    $Graphics.DrawPath($strokePen, $path)

    if ($type -eq "file") {
        $iconPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 100, 116, 139)), ([float]([math]::Max(1, 1.5 * $Scale)))
        $iconX = [float]($x + (12 * $Scale))
        $iconY = [float]($y + (12 * $Scale))
        $iconW = [float]([math]::Max(8, 18 * $Scale))
        $iconH = [float]([math]::Max(10, 24 * $Scale))
        $Graphics.DrawRectangle($iconPen, $iconX, $iconY, $iconW, $iconH)
        $iconPen.Dispose()
    }

    $displayText = Get-DisplayText -Node $Node
    Test-TextCorruption -Text $displayText -Context ("node '" + [string](Get-PropertyValue -Object $Node -Name "id" -Default "<missing-id>") + "'")
    if (-not [string]::IsNullOrWhiteSpace($displayText) -and $w -gt 36 -and $h -gt 26) {
        $textBrush = New-Object System.Drawing.SolidBrush $style.Text
        $format = New-Object System.Drawing.StringFormat
        $format.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
        $format.FormatFlags = $format.FormatFlags -bor [System.Drawing.StringFormatFlags]::LineLimit
        $textRect = New-Object System.Drawing.RectangleF(
            [float]($x + (12 * $Scale)),
            [float]($y + (10 * $Scale)),
            [float]([math]::Max(1, $w - (24 * $Scale))),
            [float]([math]::Max(1, $h - (20 * $Scale)))
        )
        $fontToUse = $BodyFont
        if ($displayText -match "^\s*#|\n\n") {
            $fontToUse = $BodyFont
        }
        $Graphics.DrawString($displayText, $fontToUse, $textBrush, $textRect, $format)
        $format.Dispose()
        $textBrush.Dispose()
    }

    $strokePen.Dispose()
    $fillBrush.Dispose()
    $path.Dispose()
}

function Draw-CanvasEdge {
    param(
        [System.Drawing.Graphics]$Graphics,
        [object]$Edge,
        [hashtable]$NodeById,
        [object]$Bounds,
        [double]$Scale
    )

    $fromNodeId = [string](Get-PropertyValue -Object $Edge -Name "fromNode" -Default "")
    $toNodeId = [string](Get-PropertyValue -Object $Edge -Name "toNode" -Default "")
    if (-not $NodeById.ContainsKey($fromNodeId) -or -not $NodeById.ContainsKey($toNodeId)) {
        return
    }

    $fromSide = [string](Get-PropertyValue -Object $Edge -Name "fromSide" -Default "")
    $toSide = [string](Get-PropertyValue -Object $Edge -Name "toSide" -Default "")
    $fromPoint = Get-AnchorPoint -Node $NodeById[$fromNodeId] -Side $fromSide
    $toPoint = Get-AnchorPoint -Node $NodeById[$toNodeId] -Side $toSide
    if ($null -eq $fromPoint -or $null -eq $toPoint) {
        return
    }

    $color = [string](Get-PropertyValue -Object $Edge -Name "color" -Default "")
    $style = Get-TokenStyle -ColorToken $color
    $pen = New-Object System.Drawing.Pen $style.Stroke, ([float]([math]::Max(1.4, 2.2 * $Scale)))
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor

    $x1 = [float](($fromPoint.X - $Bounds.Left) * $Scale)
    $y1 = [float](($fromPoint.Y - $Bounds.Top) * $Scale)
    $x2 = [float](($toPoint.X - $Bounds.Left) * $Scale)
    $y2 = [float](($toPoint.Y - $Bounds.Top) * $Scale)
    $Graphics.DrawLine($pen, $x1, $y1, $x2, $y2)
    $pen.Dispose()
}

function Get-NonBlankRatio {
    param([System.Drawing.Bitmap]$Bitmap)

    $sampleStep = [math]::Max(4, [math]::Floor([math]::Min($Bitmap.Width, $Bitmap.Height) / 120))
    $sampled = 0
    $nonBlank = 0

    for ($x = 0; $x -lt $Bitmap.Width; $x += $sampleStep) {
        for ($y = 0; $y -lt $Bitmap.Height; $y += $sampleStep) {
            $pixel = $Bitmap.GetPixel($x, $y)
            $distance = [math]::Abs($pixel.R - 255) + [math]::Abs($pixel.G - 255) + [math]::Abs($pixel.B - 255)
            $sampled += 1
            if ($distance -gt 18) {
                $nonBlank += 1
            }
        }
    }

    if ($sampled -eq 0) {
        return 0
    }

    return [math]::Round($nonBlank / $sampled, 4)
}

function Render-CanvasScreenshot {
    param(
        [object]$View,
        [object]$Canvas
    )

    $viewId = [string]$View.id
    $path = [string]$View.path
    $nodes = @($Canvas.nodes)
    $edges = @($Canvas.edges)
    if ($nodes.Count -eq 0) {
        $Errors.Add("${path}: cannot render screenshot for an empty canvas")
        return
    }

    $bounds = Get-CanvasBounds -Nodes $nodes
    if ($null -eq $bounds -or $bounds.Width -le 0 -or $bounds.Height -le 0) {
        $Errors.Add("${path}: invalid canvas bounds")
        return
    }

    $scaleX = $MaxWidth / $bounds.Width
    $scaleY = $MaxHeight / $bounds.Height
    $scale = [math]::Min(1.0, [math]::Min($scaleX, $scaleY))
    if ($scale -le 0) {
        $scale = 1.0
    }

    $imageWidth = [int][math]::Max(420, [math]::Ceiling($bounds.Width * $scale))
    $imageHeight = [int][math]::Max(320, [math]::Ceiling($bounds.Height * $scale))

    $bitmap = New-Object System.Drawing.Bitmap $imageWidth, $imageHeight
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear([System.Drawing.Color]::White)

    $gridPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 241, 245, 249)), 1
    $gridStep = 80.0
    $gridStartX = [math]::Floor($bounds.Left / $gridStep) * $gridStep
    for ($gx = $gridStartX; $gx -lt $bounds.Right; $gx += $gridStep) {
        $px = [float](($gx - $bounds.Left) * $scale)
        $graphics.DrawLine($gridPen, $px, 0, $px, $imageHeight)
    }
    $gridStartY = [math]::Floor($bounds.Top / $gridStep) * $gridStep
    for ($gy = $gridStartY; $gy -lt $bounds.Bottom; $gy += $gridStep) {
        $py = [float](($gy - $bounds.Top) * $scale)
        $graphics.DrawLine($gridPen, 0, $py, $imageWidth, $py)
    }
    $gridPen.Dispose()

    $nodeById = @{}
    foreach ($node in $nodes) {
        $id = [string](Get-PropertyValue -Object $node -Name "id" -Default "")
        if (-not [string]::IsNullOrWhiteSpace($id)) {
            $nodeById[$id] = $node
        }
    }

    foreach ($node in $nodes) {
        if ([string](Get-PropertyValue -Object $node -Name "type" -Default "") -eq "group") {
            $groupFont = New-Object System.Drawing.Font("Microsoft YaHei UI", ([float]([math]::Max(7, 12 * $scale))), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
            Draw-CanvasNode -Graphics $graphics -Node $node -Bounds $bounds -Scale $scale -TitleFont $groupFont -BodyFont $groupFont
            $groupFont.Dispose()
        }
    }

    foreach ($edge in $edges) {
        Draw-CanvasEdge -Graphics $graphics -Edge $edge -NodeById $nodeById -Bounds $bounds -Scale $scale
    }

    $bodyFont = New-Object System.Drawing.Font("Microsoft YaHei UI", ([float]([math]::Max(6, 13 * $scale))), [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $titleFont = New-Object System.Drawing.Font("Microsoft YaHei UI", ([float]([math]::Max(7, 15 * $scale))), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    foreach ($node in $nodes) {
        if ([string](Get-PropertyValue -Object $node -Name "type" -Default "") -ne "group") {
            Draw-CanvasNode -Graphics $graphics -Node $node -Bounds $bounds -Scale $scale -TitleFont $titleFont -BodyFont $bodyFont
        }
    }
    $titleFont.Dispose()
    $bodyFont.Dispose()

    $nonBlankRatio = Get-NonBlankRatio -Bitmap $bitmap
    $safeViewId = $viewId -replace "[^A-Za-z0-9._-]", "_"
    $pngPath = Join-Path $OutputRoot ($safeViewId + ".png")
    $bitmap.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()

    $relativePngPath = $pngPath.Substring($Root.Length + 1).Replace("\", "/")
    $fileInfo = Get-Item -LiteralPath $pngPath
    $viewWarnings = New-Object System.Collections.Generic.List[string]
    $viewErrors = New-Object System.Collections.Generic.List[string]

    if ($fileInfo.Length -lt 2500) {
        $viewErrors.Add("generated PNG is too small to be credible screenshot evidence")
    }
    if ($nonBlankRatio -lt 0.01) {
        $viewErrors.Add("generated PNG is visually close to blank")
    }

    $legendNodeId = ""
    if (($View.PSObject.Properties.Name -contains "color_semantics") -and $null -ne $View.color_semantics) {
        $legendNodeId = [string](Get-PropertyValue -Object $View.color_semantics -Name "visible_legend_node" -Default "")
    }
    if (-not [string]::IsNullOrWhiteSpace($legendNodeId) -and -not $nodeById.ContainsKey($legendNodeId)) {
        $viewWarnings.Add("registered visible color legend node is missing from rendered canvas")
    }

    foreach ($viewError in $viewErrors) {
        $Errors.Add("${path}: $viewError")
    }
    foreach ($viewWarning in $viewWarnings) {
        $Warnings.Add("${path}: $viewWarning")
    }

    $Results.Add([pscustomobject]@{
        view_id = $viewId
        canvas_path = $path
        status = [string]$View.status
        view_type = [string](Get-PropertyValue -Object $View -Name "view_type" -Default "")
        screenshot_path = $relativePngPath
        node_count = $nodes.Count
        edge_count = $edges.Count
        logical_bounds = [pscustomobject]@{
            width = [math]::Round($bounds.Width, 2)
            height = [math]::Round($bounds.Height, 2)
        }
        rendered_image = [pscustomobject]@{
            width = $imageWidth
            height = $imageHeight
            scale = [math]::Round($scale, 4)
            bytes = $fileInfo.Length
            non_blank_pixel_ratio = $nonBlankRatio
        }
        warnings = $viewWarnings.ToArray()
        errors = $viewErrors.ToArray()
    }) | Out-Null
}

$registry = Read-JsonFile "system/canvas-registry.json"
if ($null -ne $registry) {
    foreach ($view in @($registry.views)) {
        if ([string]$view.status -notin @("current", "active")) {
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($ViewId) -and [string]$view.id -ne $ViewId) {
            continue
        }

        $canvas = Read-JsonFile ([string]$view.path)
        if ($null -ne $canvas) {
            Render-CanvasScreenshot -View $view -Canvas $canvas
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($ViewId) -and $Results.Count -eq 0) {
    $Errors.Add("No current or active canvas view matched ViewId '$ViewId'")
}

$reportScope = "current-active-canvas-views"
if (-not [string]::IsNullOrWhiteSpace($ViewId)) {
    $reportScope = "single-view"
}

$report = [pscustomobject]@{
    id = "canvas-screenshot-audit-report"
    generated_at = (Get-Date).ToString("s")
    renderer = "powershell-system-drawing"
    scope = $reportScope
    output_dir = $OutputDir
    max_image_size = [pscustomobject]@{
        width = $MaxWidth
        height = $MaxHeight
    }
    checks = @(
        "registered current/active canvas can be rendered into PNG",
        "rendered PNG is non-empty",
        "rendered PNG has non-blank pixels",
        "source text has no obvious corruption markers",
        "registered color legend node exists when declared"
    )
    result = [pscustomobject]@{
        view_count = $Results.Count
        error_count = $Errors.Count
        warning_count = $Warnings.Count
        strict = $Strict.IsPresent
    }
    views = $Results.ToArray()
}

$reportPath = Join-Path $OutputRoot "latest-report.json"
$reportJson = $report | ConvertTo-Json -Depth 12
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($reportPath, $reportJson, $utf8NoBom)

if ($Warnings.Count -gt 0) {
    Write-Host "Canvas screenshot audit warnings:" -ForegroundColor Yellow
    foreach ($warning in $Warnings) {
        Write-Host "  - $warning" -ForegroundColor Yellow
    }
}

if ($Errors.Count -gt 0 -or ($Strict -and $Warnings.Count -gt 0)) {
    Write-Host "Canvas screenshot audit failed:" -ForegroundColor Red
    foreach ($errorMessage in $Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    if ($Strict -and $Warnings.Count -gt 0) {
        foreach ($warning in $Warnings) {
            Write-Host "  - strict warning: $warning" -ForegroundColor Red
        }
    }
    Write-Host "Report: $($reportPath.Substring($Root.Length + 1).Replace('\', '/'))"
    exit 1
}

Write-Host "Canvas screenshot audit passed for $($Results.Count) view(s)."
Write-Host "Report: $($reportPath.Substring($Root.Length + 1).Replace('\', '/'))"
