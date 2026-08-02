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
  Raising -RunnerVer stops the service, re-extracts that release, then
  reconfigures — does not silently keep old binaries.

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

  [string] $Token
)

$ErrorActionPreference = "Stop"

$owner, $name = $Repo.Split("/")
# Scope by owner/repo so same-named repos under different owners do not collide.
$Dir = Join-Path (Join-Path $Root $owner) $name
$Zip = "actions-runner-win-x64-$RunnerVer.zip"
$Url = "https://github.com/actions/runner/releases/download/v$RunnerVer/$Zip"
$LabelCsv = ($Labels -join ",")
$RunnerName = "windows-amd64-$owner-$name"
$VerStamp = Join-Path $Dir ".gha-runner-ver"

function Stop-RunnerService {
  if (-not (Test-Path ".\svc.cmd")) { return }
  & .\svc.cmd stop 2>$null
  & .\svc.cmd uninstall 2>$null
}

function Install-RunnerPayload {
  param([string] $ZipPath, [string] $DestDir, [string] $Version)

  $extractRoot = Join-Path $env:TEMP ("actions-runner-extract-" + [guid]::NewGuid().ToString("n"))
  New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $extractRoot)

    Get-ChildItem -Force $DestDir | Where-Object {
      $_.Name -ne (Split-Path $ZipPath -Leaf) -and $_.Name -notlike "actions-runner-win-x64-*.zip"
    } | Remove-Item -Recurse -Force

    Get-ChildItem -Force $extractRoot | ForEach-Object {
      Copy-Item -Path $_.FullName -Destination $DestDir -Recurse -Force
    }

    Set-Content -Path (Join-Path $DestDir ".gha-runner-ver") -Value $Version -NoNewline
  } finally {
    Remove-Item -Recurse -Force $extractRoot -ErrorAction SilentlyContinue
  }
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
  Invoke-WebRequest -Uri $Url -OutFile $Zip
}

if ($needPayload) {
  if ($installedVer -and ($installedVer -ne $RunnerVer)) {
    Write-Host "Upgrading runner payload $installedVer -> $RunnerVer"
  } else {
    Write-Host "Extracting runner payload $RunnerVer"
  }
  Stop-RunnerService
  Install-RunnerPayload -ZipPath (Join-Path $Dir $Zip) -DestDir $Dir -Version $RunnerVer
}

if (-not (Test-Path ".\config.cmd")) {
  throw "config.cmd missing after extract; check zip $Zip"
}

# Replace GitHub-side registration if the name still exists after a local wipe.
Stop-RunnerService
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

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh api "repos/$Repo/actions/runners" --jq '.runners[] | {name,status,labels:[.labels[].name]}'
}

Write-Host "OK: $RunnerName -> $Repo ($LabelCsv) under $Dir (runner $RunnerVer)"
Write-Host 'Workflow: runs-on: [self-hosted, windows, x64, overlay]'
