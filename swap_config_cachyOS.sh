#!/bin/bash

# Script Interativo de zRAM integrado ao zram-generator (CachyOS/Arch)

# Garante que o script seja executado como root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "❌ Por favor, execute este script usando sudo: sudo ./gerenciar_swap.sh"
  exit 1
fi

status_swap() {
    echo -e "\n=== 📊 STATUS ATUAL DO SWAP ==="
    swapon --show
    echo -e "\n=== 🛠️ DISPOSITIVOS ZRAM ==="
    zramctl
    echo "==============================="
}

exibir_menu() {
    clear
    echo "====================================="
    echo "    GERENCIADOR DE ZRAM (SWAP)       "
    echo "====================================="
    echo " [1] 🚀 Ativar Swap (Via Systemd)"
    echo " [2] 🛑 Desativar Swap"
    echo " [3] 🔄 Resetar/Limpar Swap"
    echo " [4] 📊 Ver Status Atual"
    echo " [5] ❌ Sair"
    echo "====================================="
    echo -n "Escolha uma opção [1-5]: "
}

while true; do
    exibir_menu
    read -r OPCAO

    case $OPCAO in
        1)
            echo -e "\n🚀 Ativando zRAM Swap de forma oficial..."
            # Força o systemd a ler as configurações e iniciar o serviço correto
            systemctl daemon-reload
            systemctl start systemd-zram-setup@zram0.service 2>/dev/null

            # Garante a ativação caso o bloco já estivesse criado mas solto
            if [ -b /dev/zram0 ]; then
                swapon /dev/zram0 2>/dev/null
            fi
            echo "✅ zRAM inicializado com sucesso!"

            status_swap
            read -p "Pressione [Enter] para voltar ao menu..."
            ;;

        2)
            echo -e "\n🛑 Desativando todos os Swaps..."
            # Desativa o swap geral e para o serviço gerenciador
            swapoff -a 2>/dev/null
            systemctl stop systemd-zram-setup@zram0.service 2>/dev/null
            echo "✅ Swap desativado!"

            status_swap
            read -p "Pressione [Enter] para voltar ao menu..."
            ;;

        3)
            echo -e "\n🔄 Resetando e limpando a zRAM..."
            # Para o serviço e desativa o bloco
            systemctl stop systemd-zram-setup@zram0.service 2>/dev/null
            swapoff /dev/zram0 2>/dev/null

            # Força o reset físico da memória para liberar espaço preso
            if [ -b /dev/zram0 ]; then
                zramctl --reset /dev/zram0 2>/dev/null
            fi

            # Recarrega e reinicia tudo do zero
            systemctl daemon-reload
            systemctl start systemd-zram-setup@zram0.service 2>/dev/null
            echo "✅ zRAM totalmente limpo, resetado e reativado!"

            status_swap
            read -p "Pressione [Enter] para voltar ao menu..."
            ;;

        4)
            status_swap
            read -p "Pressione [Enter] para voltar ao menu..."
            ;;

        5)
            echo "Saindo... Até mais!"
            exit 0
            ;;

        *)
            echo -e "\n❌ Opção inválida! Escolha um número de 1 a 5."
            sleep 2
            ;;
    esac
done
