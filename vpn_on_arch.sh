#!/bin/bash

# Cores
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${VERMELHO}Erro: Execute como sudo.${SEM_COR}"
        exit 1
    fi
}

instalar_warp() {
    echo -e "${VERDE}=== Instalando Cloudflare WARP via WireGuard (CachyOS) ===${SEM_COR}"

    # [1/4] Dependências - Removido openresolv para evitar conflito com systemd-resolvconf
    echo -e "${AMARELO}[1/4] Instalando dependências (WireGuard)...${SEM_COR}"
    sudo pacman -Sy --needed wireguard-tools curl jq --noconfirm

    # [2/4] Baixando wgcf diretamente (Sem AUR)
    echo -e "${AMARELO}[2/4] Baixando binário wgcf (x86_64)...${SEM_COR}"
    WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url" | grep "linux_amd64" | cut -d '"' -f 4)

    if [ -z "$WGCF_URL" ]; then
        echo -e "${VERMELHO}Erro ao buscar URL do wgcf.${SEM_COR}"
        return
    fi

    sudo curl -L -o /usr/local/bin/wgcf "$WGCF_URL"
    sudo chmod +x /usr/local/bin/wgcf

    # [3/4] Configuração
    echo -e "${AMARELO}[3/4] Gerando credenciais WARP...${SEM_COR}"
    mkdir -p ~/warp_setup && cd ~/warp_setup

    # Roda como usuário comum para evitar problemas de permissão
    wgcf register --accept-tos
    wgcf generate

    if [ ! -f "wgcf-profile.conf" ]; then
        echo -e "${VERMELHO}Erro: Perfil não foi gerado.${SEM_COR}"
        return
    fi

    sudo cp wgcf-profile.conf /etc/wireguard/warp.conf
    sudo chmod 600 /etc/wireguard/warp.conf

    # [4/4] Ativação
    echo -e "${AMARELO}[4/4] Ativando túnel WireGuard...${SEM_COR}"
    sudo systemctl enable --now wg-quick@warp

    echo -e "${VERDE}Instalação finalizada!${SEM_COR}"
    sleep 2
    curl -s https://www.cloudflare.com/cdn-cgi/trace | grep "warp="
}

otimizar_conexao() {
    check_root
    echo -e "\n${AMARELO}Otimizando Rota (Ping Test)...${SEM_COR}"
    endpoints=("162.159.192.1:2408" "162.159.193.1:2408" "162.159.195.1:2408")
    melhor_ip=""
    menor_ping=999

    for ip_port in "${endpoints[@]}"; do
        ip=$(echo $ip_port | cut -d':' -f1)
        ping_res=$(ping -c 3 -q $ip | awk -F"/" '{print $5}' | cut -d'.' -f1)
        if [ -n "$ping_res" ] && [ "$ping_res" -lt "$menor_ping" ]; then
            menor_ping=$ping_res
            melhor_ip=$ip_port
        fi
    done

    if [ -n "$melhor_ip" ]; then
        sed -i "s|^Endpoint = .*|Endpoint = $melhor_ip|" /etc/wireguard/warp.conf
        # MTU 1280 é essencial para evitar quedas no WARP
        grep -q "MTU" /etc/wireguard/warp.conf || sed -i "/^Address/a MTU = 1280" /etc/wireguard/warp.conf
        systemctl restart wg-quick@warp
        echo -e "${VERDE}Otimizado para $melhor_ip com MTU 1280.${SEM_COR}"
    fi
}

while true; do
    echo -e "\n${AZUL}=========================================="
    echo -e "       WARP MANAGER - CACHY OS (WireGuard)  "
    echo -e "==========================================${SEM_COR}"
    echo -e "1) Instalar/Reinstalar WARP"
    echo -e "2) Ligar VPN"
    echo -e "3) Desligar VPN"
    echo -e "4) Otimizar Latência/MTU"
    echo -e "5) Status"
    echo -e "6) Sair"
    echo -ne "\nEscolha: "
    read OPCAO

    case $OPCAO in
        1) instalar_warp ;;
        2) check_root; systemctl start wg-quick@warp ;;
        3) check_root; systemctl stop wg-quick@warp ;;
        4) otimizar_conexao ;;
        5) curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E "ip|warp|colo|loc" ;;
        6) exit 0 ;;
        *) echo "Inválido" ;;
    esac
done
