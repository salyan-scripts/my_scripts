#!/bin/bash

# Cores para o menu
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

clear
echo -e "${AZUL}=========================================="
echo -e "       GERENCIADOR CLOUDFLARE WARP        "
echo -e "==========================================${SEM_COR}"
echo -e "Escolha uma opção:"
echo -e "1) ${VERMELHO}Desabilitar VPN${SEM_COR}"
echo -e "2) ${VERDE}Habilitar VPN (WARP)${SEM_COR}"
echo -e "3) Verificar Status Real (Cloudflare Trace)"
echo -e "4) Sair"
echo -ne "\nDigite a opção (1-4): "
read OPCAO

case $OPCAO in
    1)
        echo -e "\n${AMARELO}Desativando...${SEM_COR}"
        sudo systemctl stop wg-quick@warp
        echo -e "${VERMELHO}VPN Desabilitada.${SEM_COR}"
        ;;
    2)
        echo -e "\n${AMARELO}Ativando Cloudflare WARP...${SEM_COR}"
        sudo systemctl start wg-quick@warp
        sleep 2
        # Verifica se ativou corretamente
        STATUS=$(curl -s https://www.cloudflare.com/cdn-cgi/trace | grep "warp=")
        if [[ "$STATUS" == "warp=on" || "$STATUS" == "warp=plus" ]]; then
            echo -e "${VERDE}VPN Habilitada com Sucesso!${SEM_COR}"
        else
            echo -e "${VERMELHO}Erro: O serviço iniciou, mas o WARP não está ativo.${SEM_COR}"
        fi
        ;;
    3)
        echo -e "\n${AZUL}Verificando conexão...${SEM_COR}"
        curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E "ip|warp|colo|loc"
        ;;
    4)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo -e "${VERMELHO}Opção inválida.${SEM_COR}"
        ;;
esac

echo -e "${AZUL}==========================================${SEM_COR}"
