#!/usr/bin/env bash

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

echo -e "${VERMELHO}[1/2] Parando sessões antigas e reiniciando o serviço...${SEM_COR}"
waydroid session stop 2>/dev/null
sudo killall -9 waydroid 2>/dev/null
sudo systemctl restart waydroid-container

echo -e "${VERDE}[2/2] Subindo o Waydroid...${SEM_COR}"
waydroid show-full-ui &

# Subrotina apenas para injeção dos DNS pós-boot
(
    echo -e "${AMARELO}Aguardando o sistema iniciar para aplicar o DNS...${SEM_COR}"
    sleep 45
    
    # Injeta os DNS (Cloudflare)
    sudo waydroid shell setprop net.dns1 8.8.8.8
    sudo waydroid shell setprop net.dns2 8.8.4.4
    
    echo -e "${VERDE}✔ DNS configurado com sucesso!${SEM_COR}"
) &

echo -e "${VERDE}======================================================${SEM_COR}"
echo -e "${VERDE}               WAYDROID INICIALIZADO                  ${SEM_COR}"
echo -e "${VERDE}======================================================${SEM_COR}"

wait
