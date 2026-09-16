$ErrorActionPreference = 'Stop'

$listener = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host 'A API já está em execução na porta 3001.' -ForegroundColor Green
    exit 0
}

$api = Start-Process `
    -FilePath 'C:\Program Files\nodejs\node.exe' `
    -ArgumentList 'dist/src/server.js' `
    -WorkingDirectory $PSScriptRoot `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 3
$listener = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue
if (-not $listener) {
    throw 'A API não iniciou na porta 3001.'
}

Write-Host "API pública iniciada. Processo: $($api.Id)" -ForegroundColor Green
