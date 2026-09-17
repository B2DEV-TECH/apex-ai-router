<#
.SYNOPSIS
  Renders deploy/switchyard/routes.generated.toml and runs the NVIDIA NeMo
  Switchyard sidecar on this machine against the docker-compose mock models.

.DESCRIPTION
  The gateway reaches the sidecar through SWITCHYARD_BASE_URL (localhost in
  .env.example; a gateway running inside docker-compose needs
  host.docker.internal instead), while the sidecar runs on the host and
  reaches the mock models through the ports docker-compose publishes.
  The model base URLs are overridden for the render step only, so
  gateway/config/routing.yaml and .env stay untouched.

  Needs .tools/switchyard/bin/switchyard-server.exe (deploy/switchyard/README.md,
  section 1) and a Python that can import the gateway package.

.PARAMETER EfficientUrl
  Base URL of the efficient model as seen from this machine.
.PARAMETER CapableUrl
  Base URL of the capable model as seen from this machine.
.PARAMETER JudgeUrl
  Base URL of the classifier ("judge") model. The mock server answers
  Switchyard's classifier call with a word-count verdict, so any mock works.
.PARAMETER Port
  Port the sidecar listens on (4000 matches .env.example).
.PARAMETER RoutingLog
  JSON-lines file where Switchyard records every routing decision.
.PARAMETER DryRun
  Only render and validate the config; do not start the server.
#>
param(
    [string]$EfficientUrl = 'http://127.0.0.1:9001',
    [string]$CapableUrl   = 'http://127.0.0.1:9002',
    [string]$JudgeUrl     = 'http://127.0.0.1:9002',
    [string]$BindHost     = '127.0.0.1',
    [int]$Port            = 4000,
    [string]$RoutingLog   = '.tools/switchyard/routing.jsonl',
    [string]$Python       = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$binary = Join-Path $root '.tools\switchyard\bin\switchyard-server.exe'
if (-not (Test-Path $binary)) {
    throw "switchyard-server not found at $binary - build it first (deploy/switchyard/README.md, section 1)"
}

if (-not $Python) {
    $candidates = @(
        (Join-Path $root '.tools\venv312\Scripts\python.exe'),
        (Join-Path $root 'gateway\.venv\Scripts\python.exe')
    )
    $Python = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Python) { $Python = 'python' }
}

# The mock models ignore API keys, but Switchyard refuses to start while an
# api_key_env variable is unset, so the mock targets get a placeholder.
foreach ($name in 'EFFICIENT_MODEL_API_KEY', 'CAPABLE_MODEL_API_KEY', 'JUDGE_MODEL_API_KEY') {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        [Environment]::SetEnvironmentVariable($name, 'mock-local')
    }
}
$env:EFFICIENT_MODEL_BASE_URL = $EfficientUrl
$env:CAPABLE_MODEL_BASE_URL = $CapableUrl
$env:JUDGE_MODEL_BASE_URL = $JudgeUrl

& $Python (Join-Path $root 'scripts\render_switchyard_config.py')
if ($LASTEXITCODE -ne 0) { throw 'render_switchyard_config.py failed' }
$config = Join-Path $root 'deploy\switchyard\routes.generated.toml'

& $binary --config $config --dry-run
if ($LASTEXITCODE -ne 0) { throw 'switchyard-server rejected the generated config' }
if ($DryRun) { return }

$logPath = $RoutingLog
if (-not [System.IO.Path]::IsPathRooted($logPath)) { $logPath = Join-Path $root $logPath }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $logPath) | Out-Null

Write-Host "switchyard-server listening on http://${BindHost}:$Port (routing log: $logPath). Ctrl+C stops it."
& $binary --config $config --host $BindHost --port $Port --routing-log-file $logPath
