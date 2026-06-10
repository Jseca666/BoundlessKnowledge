[CmdletBinding()]
param(
    [string[]]$Paths = @(
        "system",
        "docs",
        ".agents",
        "scripts",
        "schemas",
        "30-maps",
        "70-indexes",
        "AGENTS.md",
        "README.md"
    ),
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$TextExtensions = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($extension in @(".json", ".md", ".ps1", ".yaml", ".yml", ".canvas", ".csv", ".txt")) {
    [void]$TextExtensions.Add($extension)
}

$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

$KnownMojibakeCodepoints = @(
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
$KnownMojibakePatterns = @(
    foreach ($codepoints in $KnownMojibakeCodepoints) {
        -join ($codepoints | ForEach-Object { [string][char]$_ })
    }
)

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

function Get-CandidateFiles {
    param([string[]]$InputPaths)

    $files = New-Object System.Collections.Generic.List[object]
    foreach ($pathValue in $InputPaths) {
        $fullPath = Join-Path $Root $pathValue
        if (-not (Test-Path -LiteralPath $fullPath)) {
            $files.Add([pscustomobject]@{
                Path = $pathValue
                Exists = $false
                FullName = $null
            })
            continue
        }

        $item = Get-Item -LiteralPath $fullPath
        if ($item.PSIsContainer) {
            foreach ($file in @(Get-ChildItem -LiteralPath $fullPath -Recurse -File)) {
                if ($TextExtensions.Contains($file.Extension)) {
                    $files.Add([pscustomobject]@{
                        Path = (Get-RelativePath -Path $file.FullName)
                        Exists = $true
                        FullName = $file.FullName
                    })
                }
            }
        }
        elseif ($TextExtensions.Contains($item.Extension)) {
            $files.Add([pscustomobject]@{
                Path = (Get-RelativePath -Path $item.FullName)
                Exists = $true
                FullName = $item.FullName
            })
        }
    }

    return @($files | Sort-Object Path -Unique)
}

function Test-TextFile {
    param([object]$File)

    $findings = @()
    if (-not $File.Exists) {
        $findings += [pscustomobject]@{
            type = "missing-path"
            line = $null
            sample = ""
        }
        return [pscustomobject]@{
            file = $File.Path
            status = "fail"
            utf8_round_trip = $false
            findings = @($findings)
        }
    }

    $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
    try {
        $text = $Utf8Strict.GetString($bytes)
        $roundTripBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        $utf8RoundTrip = $bytes.Length -eq $roundTripBytes.Length
        if ($utf8RoundTrip) {
            for ($byteIndex = 0; $byteIndex -lt $bytes.Length; $byteIndex += 1) {
                if ($bytes[$byteIndex] -ne $roundTripBytes[$byteIndex]) {
                    $utf8RoundTrip = $false
                    break
                }
            }
        }
    }
    catch {
        $findings += [pscustomobject]@{
            type = "invalid-utf8-bytes"
            line = $null
            sample = ""
        }
        return [pscustomobject]@{
            file = $File.Path
            status = "fail"
            utf8_round_trip = $false
            findings = @($findings)
        }
    }

    $lines = $text -split "`r?`n"
    for ($index = 0; $index -lt $lines.Count; $index += 1) {
        $line = [string]$lines[$index]
        $lineNo = $index + 1
        if ($line -match '[?]{4,}') {
            $findings += [pscustomobject]@{
                type = "question-run"
                line = $lineNo
                sample = $line
            }
        }
        if ($line -match ([string][char]0xfffd)) {
            $findings += [pscustomobject]@{
                type = "replacement-character"
                line = $lineNo
                sample = $line
            }
        }
        if ($line -match '[\uE000-\uF8FF]') {
            $findings += [pscustomobject]@{
                type = "private-use-character"
                line = $lineNo
                sample = $line
            }
        }
        foreach ($pattern in $KnownMojibakePatterns) {
            if ($line.Contains($pattern)) {
                $findings += [pscustomobject]@{
                    type = "known-utf8-gbk-mojibake-pattern"
                    line = $lineNo
                    sample = $line
                }
                break
            }
        }
    }

    $status = "pass"
    if ($findings.Count -gt 0 -or -not $utf8RoundTrip) {
        $status = "fail"
    }

    return [pscustomobject]@{
        file = $File.Path
        status = $status
        utf8_round_trip = $utf8RoundTrip
        findings = @($findings)
    }
}

$candidateFiles = Get-CandidateFiles -InputPaths $Paths
$resultsList = @()
foreach ($candidateFile in $candidateFiles) {
    try {
        $resultsList += (Test-TextFile -File $candidateFile)
    }
    catch {
        $resultsList += [pscustomobject]@{
            file = $candidateFile.Path
            status = "fail"
            utf8_round_trip = $false
            findings = @(
                [pscustomobject]@{
                    type = "audit-error"
                    line = $null
                    sample = ($_.Exception.Message + " | " + $_.ScriptStackTrace)
                }
            )
        }
    }
}
$results = @($resultsList)
$failedResults = @($results | Where-Object { $_.status -ne "pass" })
$reportStatus = "pass"
if ($failedResults.Count -gt 0) {
    $reportStatus = "fail"
}

$report = [pscustomobject]@{
    id = "text-integrity-audit"
    generated_at = (Get-Date).ToString("s")
    checked_count = $results.Count
    failed_count = $failedResults.Count
    status = $reportStatus
    paths = $Paths
    results = $results
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $fullOutputPath = Join-Path $Root $OutputPath
    $outputDir = Split-Path -Parent $fullOutputPath
    if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }
    $json = $report | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($fullOutputPath, $json + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
}

$report | ConvertTo-Json -Depth 12

if ($failedResults.Count -gt 0) {
    exit 1
}
