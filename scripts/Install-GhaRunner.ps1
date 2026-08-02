#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Register a GitHub Actions self-hosted Windows runner for one repo.

.DESCRIPTION
  Downloads actions/runner (win-x64), mints a registration token via gh,
  configures the runner (with --replace), and installs it as a Windows service.

  Personal GitHub accounts are repo-scoped: run once per OWNER/REPO
  (separate directory + service per repo on the same machine).

  Re-running with the same -Repo replaces an existing GitHub registration.
  Raising -RunnerVer extracts the new release into a staging dir first, then
  stops the service and overlays binaries in place — never wipes the install
  tree before the new payload is ready. On failure after service removal, the
  script attempts to reinstall/start the previous service.

.PARAMETER Repo
  GitHub repository as owner/name (e.g. egao1980/cl-stack).

.PARAMETER RunnerVer
  actions/runner release tag without leading v (default: 2.336.0).

.PARAMETER Root
  Parent directory for runner installs (default: C:\actions-runners).
  Actual path: <Root>\<owner>\<repo-name>\

.PARAMETER Labels
  Runner labels (default: self-hosted, windows, x64, overlay).

.PARAMETER Token
  Optional registration token. If omitted, minted via:
    gh api -X POST repos/<Repo>/actions/runners/registration-token

.PARAMETER RunnerName
  Optional runner name (max 64 chars). Default: windows-amd64-<owner>-<repo>,
  shortened with a hash suffix when that exceeds 64 characters.

.EXAMPLE
  .\Install-GhaRunner.ps1 -Repo egao1980/cl-stack
  .\Install-GhaRunner.ps1 -Repo egao1980/grpc
  .\Install-GhaRunner.ps1 -Repo egao1980/cl-protobufs -RunnerVer 2.336.0
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[^/]+/[^/]+$')]
  [string] $Repo,

  [string] $RunnerVer = "2.336.0",

  [string] $Root = "C:\actions-runners",

  [string[]] $Labels = @("self-hosted", "windows", "x64", "overlay"),

  [string] $Token,

  [ValidateLength(1, 64)]
  [string] $RunnerName
)

$ErrorActionPreference = "Stop"

$owner, $name = $Repo.Split("/")
# Scope by owner/repo so same-named repos under different owners do not collide.
$Dir = Join-Path (Join-Path $Root $owner) $name
$Zip = "actions-runner-win-x64-$RunnerVer.zip"
$Url = "https://github.com/actions/runner/releases/download/v$RunnerVer/$Zip"
$LabelCsv = ($Labels -join ",")
$VerStamp = Join-Path $Dir ".gha-runner-ver"

function Get-DefaultRunnerName {
  param([string] $Owner, [string] $RepoName)

  # GitHub runner names are capped at 64 characters.
  $candidate = "windows-amd64-$Owner-$RepoName"
  if ($candidate.Length -le 64) { return $candidate }

  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes("$Owner/$RepoName")
    $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "").Substring(0, 8).ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }

  $budget = 64 - 1 - $hash.Length
  $base = "win-$Owner-$RepoName"
  if ($base.Length -gt $budget) {
    $base = $base.Substring(0, $budget).TrimEnd("-", "_")
  }
  return "$base-$hash"
}

function Stop-RunnerService {
  if (-not (Test-Path ".\svc.cmd")) { return }
  & .\svc.cmd stop 2>$null
  & .\svc.cmd uninstall 2>$null
}

function Restore-RunnerService {
  if (-not (Test-Path ".\svc.cmd")) { return $false }
  Write-Warning "Install failed after service removal; attempting to restore Windows service."
  & .\svc.cmd install 2>$null
  & .\svc.cmd start 2>$null
  return ($LASTEXITCODE -eq 0)
}

function New-RunnerPayloadStaging {
  param([string] $ZipPath)

  $extractRoot = Join-Path $env:TEMP ("actions-runner-extract-" + [guid]::NewGuid().ToString("n"))
  New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $extractRoot)
    if (-not (Test-Path (Join-Path $extractRoot "config.cmd"))) {
      throw "config.cmd missing in extracted runner zip $(Split-Path $ZipPath -Leaf)"
    }
    return $extractRoot
  } catch {
    Remove-Item -Recurse -Force $extractRoot -ErrorAction SilentlyContinue
    throw
  }
}

function Install-RunnerPayloadFromStaging {
  param([string] $StagingDir, [string] $DestDir, [string] $Version)

  # Overlay in place — never wipe Dest before copy succeeds.
  Get-ChildItem -Force $StagingDir | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $DestDir -Recurse -Force
  }
  Set-Content -Path (Join-Path $DestDir ".gha-runner-ver") -Value $Version -NoNewline
}

if (-not $RunnerName) {
  $RunnerName = Get-DefaultRunnerName -Owner $owner -RepoName $name
}

if (-not $Token) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "gh CLI required (authenticated with repo admin), or pass -Token."
  }
  $Token = gh api -X POST "repos/$Repo/actions/runners/registration-token" --jq .token
  if (-not $Token) {
    throw "Failed to mint registration token for $Repo"
  }
}

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
Set-Location $Dir

$installedVer = if (Test-Path $VerStamp) { (Get-Content -Raw $VerStamp).Trim() } else { "" }
$needPayload = (-not (Test-Path ".\config.cmd")) -or ($installedVer -ne $RunnerVer)

if (-not (Test-Path $Zip)) {
  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing
}

# Stage + validate the new payload while the existing service can still run.
$staging = $null
if ($needPayload) {
  if ($installedVer -and ($installedVer -ne $RunnerVer)) {
    Write-Host "Staging runner payload $installedVer -> $RunnerVer"
  } else {
    Write-Host "Staging runner payload $RunnerVer"
  }
  $staging = New-RunnerPayloadStaging -ZipPath (Join-Path $Dir $Zip)
}

$serviceRemoved = $false
try {
  # Stop/uninstall only after staging succeeds (or when reconfiguring in place).
  Stop-RunnerService
  $serviceRemoved = $true

  if ($staging) {
    Install-RunnerPayloadFromStaging -StagingDir $staging -DestDir $Dir -Version $RunnerVer
  }

  if (-not (Test-Path ".\config.cmd")) {
    throw "config.cmd missing after extract; check zip $Zip"
  }

  # Replace GitHub-side registration if the name still exists after a local wipe.
  & .\config.cmd --url "https://github.com/$Repo" `
    --token $Token `
    --name $RunnerName `
    --labels $LabelCsv `
    --work "_work" `
    --unattended `
    --replace
  if ($LASTEXITCODE -ne 0) { throw "config.cmd failed ($LASTEXITCODE)" }

  & .\svc.cmd install
  if ($LASTEXITCODE -ne 0) { throw "svc.cmd install failed ($LASTEXITCODE)" }

  & .\svc.cmd start
  if ($LASTEXITCODE -ne 0) { throw "svc.cmd start failed ($LASTEXITCODE)" }

  $serviceRemoved = $false
} catch {
  if ($serviceRemoved) { Restore-RunnerService | Out-Null }
  throw
} finally {
  if ($staging) {
    Remove-Item -Recurse -Force $staging -ErrorAction SilentlyContinue
  }
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh api "repos/$Repo/actions/runners" --jq '.runners[] | {name,status,labels:[.labels[].name]}'
}

Write-Host "OK: $RunnerName -> $Repo ($LabelCsv) under $Dir (runner $RunnerVer)"
Write-Host 'Workflow: runs-on: [self-hosted, windows, x64, overlay]'
