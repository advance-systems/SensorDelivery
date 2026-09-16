# Serviço Windows do Sensor Delivery

O `SensorDeliveryService.exe` executa a API compilada usando o runtime portátil em `Runtime\node.exe`. Ele não utiliza `npm run dev`.

## Instalar

Copie os quatro arquivos desta correção para a raiz `C:\SensorDelivery`. Depois abra o PowerShell como Administrador e execute:

```powershell
cd C:\SensorDelivery
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Get-ChildItem -Recurse -File | Unblock-File
.\INSTALAR-SERVICO-WINDOWS.ps1
.\VERIFICAR-SERVICO-WINDOWS.ps1
```

O instalador remove a tarefa agendada antiga, registra o serviço `SensorDeliveryApi`, configura início automático atrasado e recuperação após falhas.

## Comandos úteis

```powershell
Get-Service SensorDeliveryApi
Start-Service SensorDeliveryApi
Stop-Service SensorDeliveryApi
Restart-Service SensorDeliveryApi
```

Logs:

```text
C:\SensorDelivery\Servidor\logs\servico-windows.log
C:\SensorDelivery\Servidor\logs\servidor.log
```

## Remover

```powershell
.\REMOVER-SERVICO-WINDOWS.ps1
```

A remoção preserva o banco de dados, o `.env`, os uploads e os demais arquivos.
