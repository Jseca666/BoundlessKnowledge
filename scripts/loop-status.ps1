[CmdletBinding()]
param(
    [string]$LoopId = "taxonomy-refinement",
    [switch]$AsText
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath

function Read-JsonFile {
    param([string]$RelativePath)

    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing file: $RelativePath"
    }

    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-UnitInfo {
    param(
        [hashtable]$UnitsById,
        [string]$UnitId
    )

    if ([string]::IsNullOrWhiteSpace($UnitId) -or -not $UnitsById.ContainsKey($UnitId)) {
        return $null
    }

    $unit = $UnitsById[$UnitId]
    return [ordered]@{
        id = $UnitId
        level_1 = [string]$unit.level_1
        level_2 = [string]$unit.level_2
    }
}

$registry = Read-JsonFile "system/loop-registry.json"
$loop = @($registry.loops | Where-Object { [string]$_.id -eq $LoopId } | Select-Object -First 1)
if ($loop.Count -eq 0) {
    throw "Loop not registered: $LoopId"
}

$loopRecord = $loop[0]
$queue = Read-JsonFile ([string]$loopRecord.queue)
$state = Read-JsonFile ([string]$loopRecord.state)

$unitsById = @{}
foreach ($unit in @($queue.units)) {
    $unitsById[[string]$unit.id] = $unit
}

$statusByUnit = @{}
foreach ($statusProperty in @($state.unit_status.PSObject.Properties)) {
    $statusByUnit[[string]$statusProperty.Name] = $statusProperty.Value
}

$completed = @()
$blocked = @()
$active = @()
foreach ($unitId in @($queue.unit_order)) {
    $id = [string]$unitId
    $status = "pending"
    if ($statusByUnit.ContainsKey($id)) {
        $status = [string]$statusByUnit[$id].status
    }

    if ($status -eq "completed") {
        $completed += $id
    }
    elseif ($status -eq "blocked") {
        $blocked += $id
    }
    elseif ($status -eq "in_progress") {
        $active += $id
    }
}

$nextUnitId = $null
foreach ($unitId in @($queue.unit_order)) {
    $id = [string]$unitId
    $status = "pending"
    if ($statusByUnit.ContainsKey($id)) {
        $status = [string]$statusByUnit[$id].status
    }

    if ($status -ne "completed" -and $status -ne "blocked") {
        $nextUnitId = $id
        break
    }
}

$currentUnitId = [string]$state.current_unit
$result = [ordered]@{
    loop_id = [string]$loopRecord.id
    status = [string]$state.status
    current_unit = Get-UnitInfo -UnitsById $unitsById -UnitId $currentUnitId
    current_phase = [string]$state.current_phase
    next_unit = Get-UnitInfo -UnitsById $unitsById -UnitId $nextUnitId
    completed_count = $completed.Count
    blocked_count = $blocked.Count
    active_count = $active.Count
    total_units = @($queue.unit_order).Count
    completed_units = $completed
    blocked_units = $blocked
    active_units = $active
    last_run_id = [string]$state.last_run_id
}

if ($AsText) {
    Write-Output "Loop: $($result.loop_id)"
    Write-Output "Status: $($result.status)"
    Write-Output "Current: $($result.current_unit.id) $($result.current_unit.level_2)"
    Write-Output "Phase: $($result.current_phase)"
    Write-Output "Progress: $($result.completed_count)/$($result.total_units) completed, $($result.blocked_count) blocked"
    Write-Output "Last run: $($result.last_run_id)"
}
else {
    $result | ConvertTo-Json -Depth 8
}
