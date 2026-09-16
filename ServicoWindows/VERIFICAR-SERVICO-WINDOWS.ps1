[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$nomeServico = 'SensorDeliveryApi'
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$ini = Join-Path $raiz 'Painel\sensor-delivery.ini'
$url = 'http://localhost:3001'

$servico = Get-Service -Name $nomeServico -ErrorAction Stop
Write-Host "Serviço: $($servico.Status)" -ForegroundColor Cyan

if (Test-Path -LiteralPath $ini) {
    $linha = Get-Content -LiteralPath $ini | Where-Object { $_ -match '^BaseURL=' } | Select-Object -First 1
    if ($linha) {
        $url = $linha.Substring('BaseURL='.Length).Trim().TrimEnd('/')
    }
}

try {
    $resultado = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 15
    $resultado | Format-List
    Write-Host 'Serviço e API funcionando corretamente.' -ForegroundColor Green
} catch {
    Write-Host 'O serviço existe, mas a API não respondeu.' -ForegroundColor Red
    Write-Host $_.Exception.Message

    $logServico = Join-Path $raiz 'Servidor\logs\servico-windows.log'
    $logApi = Join-Path $raiz 'Servidor\logs\servidor.log'
    if (Test-Path -LiteralPath $logServico) {
        Write-Host ''
        Write-Host 'Log do serviço:' -ForegroundColor Yellow
        Get-Content -LiteralPath $logServico -Tail 30
    }
    if (Test-Path -LiteralPath $logApi) {
        Write-Host ''
        Write-Host 'Log da API:' -ForegroundColor Yellow
        Get-Content -LiteralPath $logApi -Tail 50
    }
    exit 1
}
