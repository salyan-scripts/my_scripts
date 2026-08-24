#!/usr/bin/env bash

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

IP_WAYDROID="192.168.240.112:5555"

echo -e "${AZUL}[1/2] Verificando e conectando ADB ao Waydroid ($IP_WAYDROID)...${SEM_COR}"

# Tenta conectar via ADB
adb connect "$IP_WAYDROID" 2>/dev/null

# Aguarda um instante para a conexão estabilizar
sleep 2

# Verifica se a conexão foi estabelecida
if adb devices | grep -q "$IP_WAYDROID.*device"; then
    echo -e "${VERDE}✔ Conectado ao Waydroid com sucesso!${SEM_COR}"
    echo -e "${AZUL}[2/2] Iniciando scrcpy (--no-audio -m 1024)...${SEM_COR}"
    
    # Executa o scrcpy com os parâmetros solicitados
    scrcpy --no-audio -m 1024
else
    echo -e "${VERMELHO}✖ Falha ao conectar ao Waydroid via ADB.${SEM_COR}"
    echo -e "${AMARELO}Certifique-se de que o Waydroid está rodando e a Depuração USB está ativa em Configurações > Opções do desenvolvedor.${SEM_COR}"
    exit 1
fi
