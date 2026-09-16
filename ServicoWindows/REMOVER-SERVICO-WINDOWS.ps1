[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$nomeServico = 'SensorDeliveryApi'

$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Execute este script como Administrador.'
}

$servico = Get-Service -Name $nomeServico -ErrorAction SilentlyContinue
if (-not $servico) {
    Write-Host 'O serviço Sensor Delivery não está instalado.' -ForegroundColor Yellow
    exit 0
}

if ($servico.Status -ne 'Stopped') {
    Stop-Service -Name $nomeServico -Force
    $servico.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(20))
}

& sc.exe delete $nomeServico | Out-Null
Write-Host 'Serviço removido. Arquivos, configurações e banco foram preservados.' -ForegroundColor Green
