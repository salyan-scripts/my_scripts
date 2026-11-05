#!/bin/bash
sudo clear
echo "================================="
echo "   GERENCIADOR DE ENERGIA"
echo "================================="
echo "1) Reiniciar o sistema (Reboot)"
echo "2) Desligar o sistema (Poweroff)"
echo "3) Sair"
echo "================================="
read -p "Escolha uma opção [1-3]: " opcao

case $opcao in
    1)
        echo "Reiniciando o sistema..."
        sudo systemctl reboot
        ;;
    2)
        echo "Desligando o sistema..."
        sudo systemctl poweroff
        ;;
    3)
        echo "Saindo."
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac
