#!/usr/bin/env bash

# Cores para deixar o menu bonito
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

exibir_menu() {
    clear
    echo -e "${AZUL}==================================================${SEM_COR}"
    echo -e "${AZUL}      GERENCIADOR DE TEMPERATURA E CPU (INTEL)     ${SEM_COR}"
    echo -e "${AZUL}==================================================${SEM_COR}"
    echo -e "1) 🔍 Mostrar valores atuais e limites do CPU"
    echo -e "2) ⚡ Desativar Turbo Boost AGORA (Temporário)"
    echo -e "3) 🚀 Ativar Turbo Boost AGORA (Temporário)"
    echo -e "4) 💾 ATIVAR 'No_Turbo' ao iniciar o sistema (Permanente)"
    echo -e "5) ❌ REMOVER 'No_Turbo' da inicialização (Voltar ao padrão)"
    echo -e "6) 🛑 Sair"
    echo -e "${AZUL}==================================================${SEM_COR}"
    echo -n "Escolha uma opção [1-6]: "
}

while true; do
    exibir_menu
    read -r opcao
    case $opcao in
        1)
            echo -e "\n${AMARELO}--- Informações do Processador ---${SEM_COR}"
            if command -v cpupower &> /dev/null; then
                cpupower frequency-info
            else
                echo -e "${VERMELHO}Ferramenta 'cpupower' não instalada.${SEM_COR}"
                echo "Frequência atual básica:"
                grep "cpu MHz" /proc/cpuinfo | head -n 4
            fi
            echo -e "\nStatus atual do No_Turbo (1 = Desativado, 0 = Ativado):"
            cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo "Não foi possível ler o arquivo intel_pstate."
            echo -e "\nPressione [ENTER] para voltar ao menu..."
            read -r
            ;;
        2)
            echo -e "\n${AMARELO}Desativando o Turbo Boost temporariamente...${SEM_COR}"
            echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
            echo -e "${VERDE}Feito! O processador foi limitado ao clock base.${SEM_COR}"
            sleep 2
            ;;
        3)
            echo -e "\n${AMARELO}Reativando o Turbo Boost temporariamente...${SEM_COR}"
            echo "0" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
            echo -e "${VERDE}Feito! Turbo Boost liberado novamente.${SEM_COR}"
            sleep 2
            ;;
        4)
            echo -e "\n${AMARELO}Configurando o 'No_Turbo' para iniciar com o sistema...${SEM_COR}"
            echo "w /sys/devices/system/cpu/intel_pstate/no_turbo - - - - 1" | sudo tee /etc/tmpfiles.d/desativar-turbo.conf
            echo -e "${VERDE}Configuração permanente criada com sucesso!${SEM_COR}"
            sleep 2
            ;;
        5)
            echo -e "\n${AMARELO}Removendo configuração de inicialização...${SEM_COR}"
            if [ -f /etc/tmpfiles.d/desativar-turbo.conf ]; then
                sudo rm /etc/tmpfiles.d/desativar-turbo.conf
                echo -e "${VERDE}Arquivo de inicialização removido.${SEM_COR}"
            else
                echo -e "${AMARELO}A configuração permanente já não existia.${SEM_COR}"
            fi
            sleep 2
            ;;
        6)
            echo -e "\n${VERDE}Saindo... Até mais!${SEM_COR}"
            exit 0
            ;;
        *)
            echo -e "\n${VERMELHO}Opção inválida! Tente novamente.${SEM_COR}"
            sleep 1.5
            ;;
    esac
done
