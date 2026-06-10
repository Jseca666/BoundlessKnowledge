[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath

function Invoke-Git {
    param([string[]]$Arguments)
    $output = & git @Arguments 2>&1
    [PSCustomObject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

$inside = Invoke-Git @("rev-parse", "--is-inside-work-tree")
$remote = Invoke-Git @("remote", "get-url", "origin")
$branch = Invoke-Git @("branch", "--show-current")
$status = Invoke-Git @("status", "--short")

$result = [PSCustomObject]@{
    repository_root = $Root
    inside_work_tree = ($inside.ExitCode -eq 0 -and $inside.Output.Trim() -eq "true")
    origin_url = if ($remote.ExitCode -eq 0) { $remote.Output.Trim() } else { $null }
    current_branch = if ($branch.ExitCode -eq 0) { $branch.Output.Trim() } else { $null }
    has_uncommitted_or_untracked_changes = -not [string]::IsNullOrWhiteSpace($status.Output)
    status_short = @($status.Output -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    remote_action_boundary = "No push, release, issue, PR, merge, remote branch mutation or credential change without explicit user approval."
}

$result | ConvertTo-Json -Depth 6
