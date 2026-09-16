[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$nomeServico = 'SensorDeliveryApi'
$nomeTarefaAntiga = 'Sensor Delivery - API'
$raiz = Split-Path -Parent $MyInvocation.MyCommand.Path
$executavel = Join-Path $raiz 'SensorDeliveryService.exe'
$arquivoEnv = Join-Path $raiz 'Servidor\.env'

$identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidade)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Execute este script como Administrador.'
}
if (-not (Test-Path -LiteralPath $executavel)) {
    throw "Serviço não encontrado: $executavel"
}
if (-not (Test-Path -LiteralPath $arquivoEnv)) {
    throw 'Servidor\.env não encontrado. Execute primeiro CONFIGURAR-INSTALACAO.ps1.'
}

# Remove a inicialização anterior para não abrir duas instâncias da API.
Stop-ScheduledTask -TaskName $nomeTarefaAntiga -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $nomeTarefaAntiga -Confirm:$false -ErrorAction SilentlyContinue

# Encerra somente instâncias manuais do Node que estejam executando esta API.
$scriptServidor = Join-Path $raiz 'Servidor\dist\src\server.js'
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CommandLine -and
        $_.CommandLine.IndexOf($scriptServidor, [StringComparison]::OrdinalIgnoreCase) -ge 0
    } |
    ForEach-Object {
        Invoke-CimMethod -InputObject $_ -MethodName Terminate | Out-Null
    }
Start-Sleep -Seconds 1

$existente = Get-Service -Name $nomeServico -ErrorAction SilentlyContinue
if ($existente) {
    if ($existente.Status -ne 'Stopped') {
        Stop-Service -Name $nomeServico -Force
        $existente.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(20))
    }
    & sc.exe delete $nomeServico | Out-Null
    Start-Sleep -Seconds 2
}

$caminhoBinario = '"' + $executavel + '"'
New-Service `
    -Name $nomeServico `
    -BinaryPathName $caminhoBinario `
    -DisplayName 'Sensor Delivery - API' `
    -Description 'Servidor da API do Sensor Delivery.' `
    -StartupType Automatic | Out-Null

& sc.exe config $nomeServico start= delayed-auto | Out-Null
& sc.exe failure $nomeServico reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
& sc.exe failureflag $nomeServico 1 | Out-Null

$regra = Get-NetFirewallRule -DisplayName 'Sensor Delivery API' -ErrorAction SilentlyContinue
if (-not $regra) {
    New-NetFirewallRule `
        -DisplayName 'Sensor Delivery API' `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 3001 `
        -Profile Private,Domain | Out-Null
}

Start-Service -Name $nomeServico
$servico = Get-Service -Name $nomeServico
$servico.WaitForStatus('Running', [TimeSpan]::FromSeconds(20))

Write-Host ''
Write-Host 'Serviço instalado e iniciado com sucesso.' -ForegroundColor Green
Write-Host 'Nome interno: SensorDeliveryApi'
Write-Host 'O serviço iniciará automaticamente com o Windows.'
Write-Host 'Execute VERIFICAR-SERVICO-WINDOWS.ps1 para testar a API.' -ForegroundColor Yellow
