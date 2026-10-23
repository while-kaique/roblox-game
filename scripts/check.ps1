# Pipeline pré-Studio em 4 passos. Rode antes de cada sync/playtest:
#   powershell -ExecutionPolicy Bypass -File scripts/check.ps1        (só checa)
#   powershell -ExecutionPolicy Bypass -File scripts/check.ps1 -Fix   (formata antes)
param([switch]$Fix)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"

$failed = @()
function Step($name, [scriptblock]$cmd) {
	Write-Host "`n== $name ==" -ForegroundColor Cyan
	& $cmd
	if ($LASTEXITCODE -ne 0) { $script:failed += $name; Write-Host "FALHOU: $name" -ForegroundColor Red }
	else { Write-Host "ok" -ForegroundColor Green }
}

New-Item -ItemType Directory -Force build | Out-Null
# API do Roblox atualizada para o selene (o padrão embutido é antigo e erra enums)
if (-not (Test-Path roblox.yml)) { selene generate-roblox-std | Out-Null }
Step "1. rojo build" { rojo build default.project.json -o build/check.rbxl }
Step "2. selene (lint)" { selene src tests studio-tools }
if ($Fix) { stylua src tests studio-tools }
Step "3. stylua (formato)" { stylua --check src tests studio-tools }
Step "4. testes (lune)" { lune run tests/run }

if ($failed.Count -gt 0) {
	Write-Host "`nFalhou: $($failed -join ', ')" -ForegroundColor Red
	exit 1
}
Write-Host "`nTudo verde." -ForegroundColor Green
