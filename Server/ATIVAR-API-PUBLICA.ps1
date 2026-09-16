$ErrorActionPreference = 'Stop'

$servicoAntigo = Get-Service -Name 'SensorPedidosApi' -ErrorAction SilentlyContinue
if ($servicoAntigo) {
    if ($servicoAntigo.Status -ne 'Stopped') {
        Stop-Service -Name 'SensorPedidosApi' -Force
        $servicoAntigo.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(30))
    }
    Set-Service -Name 'SensorPedidosApi' -StartupType Manual
}

$listeners = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue
foreach ($listener in $listeners) {
    $processo = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)" -ErrorAction SilentlyContinue
    if ($processo -and ($processo.Name -ieq 'node.exe')) {
        Stop-Process -Id $processo.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Milliseconds 800

$api = Start-Process `
    -FilePath 'C:\Program Files\nodejs\node.exe' `
    -ArgumentList 'dist/src/server.js' `
    -WorkingDirectory 'H:\Projetos\SensorDelivery\Server' `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 3
$listenerAtual = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue
if (-not $listenerAtual) {
    throw 'A API atual não iniciou na porta 3001.'
}

"API pública preparada. Processo atual: $($api.Id)"
