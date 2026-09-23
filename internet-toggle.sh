#!/usr/bin/env bash

# Função para verificar o status atual da rede
check_status() {
    status=$(nmcli networking connectivity check)
    if [ "$status" = "full" ]; args
    then
        echo "Conectado"
    else
        echo "Desconectado"
    fi
}

show_menu() {
    clear
    echo "================================="
    echo "  GERENCIADOR DE INTERNET OMARCHY "
    echo "================================="
    echo "Status atual: $(nmcli networking)"
    echo ""
    echo "1) Voltar ao padrão (Ativar Internet)"
    echo "2) Desativar temporariamente a internet"
    echo "3) Sair"
    echo "================================="
    read -p "Escolha uma opção [1-3]: " choice

    case $choice in
        1)
            echo "Ativando a rede..."
            nmcli networking on
            sleep 1
            echo "Rede ativada com sucesso!"
            ;;
        2)
            echo "Desativando a rede..."
            nmcli networking off
            sleep 1
            echo "Rede desativada com sucesso!"
            ;;
        3)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            sleep 1
            show_menu
            ;;
    esac
}

show_menu
