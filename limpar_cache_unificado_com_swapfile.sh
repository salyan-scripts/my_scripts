#!/bin/bash

# ==============================================================================
# Otimizador de Memória & Gerenciador de Swap (HD / ext4 - CachyOS)
# ==============================================================================

SWAPFILE="/swapfile"

if [ "$EUID" -ne 0 ]; then
    echo "❌ Por favor, execute este script com sudo: sudo $0"
    exit 1
fi

garantir_sem_zram() {
    if systemctl is-active --quiet systemd-zram-setup@zram0.service 2>/dev/null; then
        systemctl stop systemd-zram-setup@zram0.service 2>/dev/null
        swapoff /dev/zram0 2>/dev/null
    fi
}

status_memoria() {
    echo -e "\n=== 📊 STATUS DA MEMÓRIA E SWAP ==="
    free -h
    echo -e "\n=== 🧩 FRAGMENTAÇÃO DA RAM (BUDDYINFO) ==="
    cat /proc/buddyinfo
    echo -e "\n=== 🛠️ SWAP ATIVO ==="
    swapon --show
    echo "==================================="
}

limpar_e_compactar_ram() {
    echo -e "\n--------------------------------------------------"
    echo -e "📊 ANTES DA LIMPEZA"
    echo -e "--------------------------------------------------"
    free -h
    echo -e "\n🧩 Buddyinfo (Antes):"
    cat /proc/buddyinfo

    echo -e "\n🚀 Executando Sync, Drop Caches e Compactação..."
    sync
    echo 1 > /proc/sys/vm/drop_caches
    echo 1 > /proc/sys/vm/compact_memory
    sync

    echo -e "\n--------------------------------------------------"
    echo -e "✅ DEPOIS DA LIMPEZA"
    echo -e "--------------------------------------------------"
    free -h
    echo -e "\n🧩 Buddyinfo (Depois):"
    cat /proc/buddyinfo
}

resetar_swapfile() {
    garantir_sem_zram

    if [ ! -f "$SWAPFILE" ]; then
        echo -e "\n⚠️ Arquivo $SWAPFILE não encontrado no sistema!"
        return 1
    fi

    echo -e "\n🔄 Resetando Swapfile ($SWAPFILE)..."
    swapoff "$SWAPFILE" 2>/dev/null
    mkswap "$SWAPFILE" > /dev/null 2>&1
    swapon "$SWAPFILE"
    echo "✅ Swapfile resetado!"
}

exibir_menu() {
    clear
    echo "====================================="
    echo "     OTIMIZADOR DE MEMÓRIA & SWAP    "
    echo "====================================="
    echo " [1] ⚡ Reset Total (Limpar RAM + Resetar Swap)"
    echo " [2] 📦 Limpar e Compactar RAM"
    echo " [3] 🔄 Resetar Swapfile ($SWAPFILE)"
    echo " [4] 📊 Ver Status da Memória"
    echo " [5] ❌ Sair"
    echo "====================================="
    echo -n "Escolha uma opção [1-5]: "
}

while true; do
    exibir_menu
    read -r OPCAO

    case $OPCAO in
        1)
            echo -e "\n=================================================="
            echo -e "📊 ESTADO INICIAL (ANTES)"
            echo -e "=================================================="
            free -h
            echo -e "\n🧩 Buddyinfo:"
            cat /proc/buddyinfo

            echo -e "\n⚡ Executando limpeza de RAM e Reset de Swap..."
            sync
            echo 1 > /proc/sys/vm/drop_caches
            echo 1 > /proc/sys/vm/compact_memory
            sync
            resetar_swapfile

            echo -e "\n=================================================="
            echo -e "✅ RESULTADO FINAL (DEPOIS)"
            echo -e "=================================================="
            free -h
            echo -e "\n🧩 Buddyinfo:"
            cat /proc/buddyinfo
            echo -e "\n--- SWAP ATIVO ---"
            swapon --show
            echo "=================================================="
            read -p "Pressione [Enter] para continuar..."
            ;;

        2)
            limpar_e_compactar_ram
            read -p "Pressione [Enter] para continuar..."
            ;;

        3)
            resetar_swapfile
            status_memoria
            read -p "Pressione [Enter] para continuar..."
            ;;

        4)
            status_memoria
            read -p "Pressione [Enter] para continuar..."
            ;;

        5)
            echo "Saindo..."
            exit 0
            ;;

        *)
            echo -e "\n❌ Opção inválida! Digite de 1 a 5."
            sleep 2
            ;;
    esac
done
