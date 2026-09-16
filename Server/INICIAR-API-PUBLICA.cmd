@echo off
title Iniciar API publica do Sensor Delivery
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INICIAR-API-PUBLICA.ps1"
if errorlevel 1 pause
