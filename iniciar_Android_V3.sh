#!/usr/bin/env bash

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

echo -e "${VERMELHO}[1/3] Parando sessões antigas e reiniciando o serviço...${SEM_COR}"
waydroid session stop 2>/dev/null
sudo killall -9 waydroid 2>/dev/null
sudo systemctl restart waydroid-container

echo -e "${AZUL}[2/3] Removendo todas as travas e restaurando o waydroid.cfg ao padrão...${SEM_COR}"
CONFIG_FILE="$HOME/.local/share/waydroid/waydroid.cfg"

if [ -f "$CONFIG_FILE" ]; then
    # Limpa TODAS as modificações customizadas anteriores do arquivo de configuração
    sudo sed -i '/sys.use_fifo_vblank/d; \
                /ro.surface_flinger.max_frame_rate/d; \
                /debug.sf.fps/d; \
                /debug.sf.nobootanimation/d; \
                /ro.config.low_ram/d; \
                /ro.hardware.egl/d; \
                /ro.hardware.gralloc/d; \
                /sys.waydroid.fake_touch/d' "$CONFIG_FILE" 2>/dev/null
    
    # Mantém apenas o fake_touch (necessário para jogos reconhecerem cliques de mouse como toque)
    sudo sed -i '/\[properties\]/a sys.waydroid.fake_touch = true' "$CONFIG_FILE" 2>/dev/null
fi

echo -e "${VERDE}[3/3] Subindo o Waydroid em modo nativo...${SEM_COR}"

waydroid show-full-ui &

# Injeção apenas de rede/DNS pós-boot
(
    echo -e "${AMARELO}Aguardando o sistema iniciar para aplicar o DNS...${SEM_COR}"
    sleep 30
    
    # Injeta os DNS (Cloudflare)
    sudo waydroid shell "setprop net.dns1 1.1.1.1" 2>/dev/null
    sudo waydroid shell "setprop net.dns2 1.0.0.1" 2>/dev/null
    
    echo -e "${VERDE}✔ DNS configurado com sucesso!${SEM_COR}"
) &

echo -e "${VERDE}======================================================${SEM_COR}"
echo -e "${VERDE}   WAYDROID RODANDO 100% NATIVO (SEM LIMITADORES)     ${SEM_COR}"
echo -e "${VERDE}======================================================${SEM_COR}"

wait
