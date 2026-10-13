@echo off
chcp 65001 >nul
title GERENCIADOR DE INTERNET

:menu
cls
echo =================================
echo     GERENCIADOR DE INTERNET     
echo =================================

REM Verifica se há conexão ativa pingando o Google
ping -n 1 8.8.8.8 >nul
if %errorlevel% equ 0 (
    echo Status atual: Conectado (Cabo ativo)
) else (
    echo Status atual: Desconectado / Sem internet
)

echo.
echo 1) Voltar ao padrão (Ativar Cabo de Rede)
echo 2) Desativar temporariamente a internet (Desativar Cabo)
echo 3) Sair
echo =================================
set /p choice="Escolha uma opção [1-3]: "

if "%choice%"=="1" goto ativar
if "%choice%"=="2" goto desativar
if "%choice%"=="3" exit

echo Opção inválida!
timeout /t 2 >nul
goto menu

:ativar
cls
echo Ativando o cabo de rede...
netsh interface set interface "Ethernet" admin=enabled 2>nul
timeout /t 1 >nul
echo Cabo de rede ativado com sucesso!
timeout /t 2 >nul
goto menu

:desativar
cls
echo Desativando o cabo de rede...
netsh interface set interface "Ethernet" admin=disabled 2>nul
timeout /t 1 >nul
echo Cabo de rede desativado com sucesso!
timeout /t 2 >nul
goto menu
