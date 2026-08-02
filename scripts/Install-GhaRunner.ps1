#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Register a GitHub Actions self-hosted Windows runner for one repo.

.DESCRIPTION
  Downloads actions/runner (win-x64), mints a registration token via gh,
  configures the runner, and installs it as a Windows service.

  Personal GitHub accounts are repo-scoped: run once per OWNER/REPO
  (separate directory + service per repo on the same machine).

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

if (-not (Test-Path $Zip)) {
  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Zip
}

if (-not (Test-Path ".\config.cmd")) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $Dir $Zip), $Dir)
}

if (Test-Path ".\.runner") {
  throw "Runner already configured in $Dir (found .runner). Remove or use a different -Root/-Repo."
}

& .\config.cmd --url "https://github.com/$Repo" `
  --token $Token `
  --name $RunnerName `
  --labels $LabelCsv `
  --work "_work" `
  --unattended
if ($LASTEXITCODE -ne 0) { throw "config.cmd failed ($LASTEXITCODE)" }

& .\svc.cmd install
if ($LASTEXITCODE -ne 0) { throw "svc.cmd install failed ($LASTEXITCODE)" }

& .\svc.cmd start
if ($LASTEXITCODE -ne 0) { throw "svc.cmd start failed ($LASTEXITCODE)" }

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh api "repos/$Repo/actions/runners" --jq '.runners[] | {name,status,labels:[.labels[].name]}'
}

Write-Host "OK: $RunnerName -> $Repo ($LabelCsv) under $Dir"
Write-Host 'Workflow: runs-on: [self-hosted, windows, x64, overlay]'
