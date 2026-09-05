#!/bin/bash

# ==============================================================================
# Otimizador de Memória & Gerenciador de Swapfile (16 GB - CachyOS)
# ==============================================================================

SWAPFILE="/swapfile"
TAMANHO_GB="16"

if [ "$EUID" -ne 0 ]; then
    echo "❌ Por favor, execute este script com sudo: sudo $0"
    exit 1
fi

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

    echo -e "\n🚀 Executando Sync, Drop Caches (1) e Compactação..."
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
    if [ ! -f "$SWAPFILE" ]; then
        echo -e "\n⚠️ Arquivo $SWAPFILE não existe! Use a opção de manutenção para criar."
        return 1
    fi

    echo -e "\n🔄 Resetando Swapfile ($SWAPFILE)..."
    swapoff "$SWAPFILE" 2>/dev/null
    sync
    swapon "$SWAPFILE" 2>/dev/null
    echo "✅ Swapfile resetado com sucesso!"
}

manutencao_swapfile() {
    echo -e "\n🛠️ --- MANUTENÇÃO E CRIAÇÃO DO SWAPFILE ($TAMANHO_GB GB) ---"

    # Desativa o swapfile se estiver ativo
    if swapon --show | grep -q "$SWAPFILE"; then
        echo "⏳ Desativando $SWAPFILE ativo..."
        swapoff "$SWAPFILE" 2>/dev/null
    fi

    # Remove o arquivo antigo se existir
    if [ -f "$SWAPFILE" ]; then
        echo "🗑️ Removendo $SWAPFILE antigo..."
        rm -f "$SWAPFILE"
    fi

    echo "📦 Criando novo Swapfile de $TAMANHO_GB GB..."
    # Tenta fallocate primeiro (mais rápido); se falhar no sistema de arquivos, usa dd
    if ! fallocate -l "${TAMANHO_GB}G" "$SWAPFILE" 2>/dev/null; then
        echo "⚠️ fallocate falhou, criando via dd (pode levar alguns segundos)..."
        dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((TAMANHO_GB * 1024)) status=progress
    fi

    # Aplica permissões de segurança estritas (600)
    chmod 600 "$SWAPFILE"

    # Formata como área de swap
    echo "⚙️ Formatando $SWAPFILE..."
    mkswap "$SWAPFILE" > /dev/null

    # Ativa o swapfile
    echo "🚀 Ativando $SWAPFILE..."
    swapon "$SWAPFILE"

    # Garante entrada no /etc/fstab para persistência no boot
    if ! grep -q "$SWAPFILE" /etc/fstab; then
        echo "📝 Adicionando $SWAPFILE ao /etc/fstab..."
        echo "$SWAPFILE none swap defaults 0 0" >> /etc/fstab
    fi

    echo "✅ Swapfile de $TAMANHO_GB GB criado, configurado e ativo!"
}

exibir_menu() {
    clear
    echo "====================================="
    echo "     OTIMIZADOR DE MEMÓRIA & SWAP    "
    echo "====================================="
    echo " [1] ⚡ Reset Total (Limpar RAM + Resetar Swap)"
    echo " [2] 📦 Limpar e Compactar RAM"
    echo " [3] 🔄 Resetar Swapfile ($SWAPFILE)"
    echo " [4] 🛠️ Criar / Recriar Swapfile ($TAMANHO_GB GB)"
    echo " [5] 📊 Ver Status da Memória"
    echo " [6] ❌ Sair"
    echo "====================================="
    echo -n "Escolha uma opção [1-6]: "
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

            echo -e "\n⚡ Executando limpeza de RAM e Reset de Swapfile..."
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
            manutencao_swapfile
            status_memoria
            read -p "Pressione [Enter] para continuar..."
            ;;

        5)
            status_memoria
            read -p "Pressione [Enter] para continuar..."
            ;;

        6)
            echo "Saindo..."
            exit 0
            ;;

        *)
            echo -e "\n❌ Opção inválida! Digite de 1 a 6."
            sleep 2
            ;;
    esac
done
