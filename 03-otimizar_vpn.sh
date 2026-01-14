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

otimizar_conexao() {
    echo -e "\n${AMARELO}Iniciando Otimização de Rota (Ping Test)...${SEM_COR}"
    
    # Lista de Endpoints comuns da Cloudflare
    endpoints=(
        "162.159.192.1:2408"
        "162.159.193.1:2408"
        "162.159.195.1:2408"
        "188.114.96.1:2408"
        "188.114.97.1:2408"
    )

    melhor_ip=""
    menor_ping=999

    echo "Testando latência para servidores Cloudflare no Brasil..."

    for ip_port in "${endpoints[@]}"; do
        ip=$(echo $ip_port | cut -d':' -f1)
        # Tira a média de 3 pings
        ping_res=$(ping -c 3 -q $ip | awk -F"/" '{print $5}' | cut -d'.' -f1)
        
        if [ ! -z "$ping_res" ]; then
            echo "Servidor $ip_port - Ping: ${ping_res}ms"
            if [ "$ping_res" -lt "$menor_ping" ]; then
                menor_ping=$ping_res
                melhor_ip=$ip_port
            fi
        fi
    done

    if [ -z "$melhor_ip" ]; then
        echo -e "${VERMELHO}Não foi possível testar os servidores. Verifique sua internet.${SEM_COR}"
        return
    fi

    echo -e "${VERDE}Melhor servidor encontrado: $melhor_ip (${menor_ping}ms)${SEM_COR}"
    
    # Aplicando configurações
    sed -i "s|^Endpoint = .*|Endpoint = $melhor_ip|" /etc/wireguard/warp.conf
    
    # Garantindo o MTU para estabilidade
    if grep -q "MTU" /etc/wireguard/warp.conf; then
        sed -i "s|^MTU = .*|MTU = 1280|" /etc/wireguard/warp.conf
    else
        sed -i "/^Address/a MTU = 1280" /etc/wireguard/warp.conf
    fi

    systemctl restart wg-quick@warp
    echo -e "${VERDE}Configurações aplicadas com sucesso!${SEM_COR}"
}

# --- Menu Principal ---
while true; do
    echo -e "\n${AZUL}=========================================="
    echo -e "       CENTRAL CLOUDFLARE WARP (32-bit)   "
    echo -e "==========================================${SEM_COR}"
    echo -e "1) Habilitar VPN (WARP)"
    echo -e "2) Desabilitar VPN"
    echo -e "3) Verificar Status (Trace)"
    echo -e "4) ${AMARELO}Otimizar Latência e MTU${SEM_COR}"
    echo -e "5) Gerenciar Boot"
    echo -e "6) Sair"
    echo -ne "\nEscolha: "
    read OPCAO

    case $OPCAO in
        1) check_root; systemctl start wg-quick@warp; sleep 2; curl -s https://www.cloudflare.com/cdn-cgi/trace | grep "warp=" ;;
        2) check_root; systemctl stop wg-quick@warp; echo -e "${VERMELHO}VPN OFF${SEM_COR}" ;;
        3) curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E "ip|warp|colo|loc" ;;
        4) check_root; otimizar_conexao ;;
        5) check_root; echo "1-Auto 2-Manual"; read B; [ "$B" == "1" ] && systemctl enable wg-quick@warp || systemctl disable wg-quick@warp ;;
        6) exit 0 ;;
        *) echo "Opção inválida" ;;
    esac
done
