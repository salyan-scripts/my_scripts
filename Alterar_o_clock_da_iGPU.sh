#!/usr/bin/env bash

MIN_FREQ_FILE="/sys/class/drm/card1/gt/gt0/rps_min_freq_mhz"
MAX_FREQ_FILE="/sys/class/drm/card1/gt/gt0/rps_max_freq_mhz"
ACT_FREQ_FILE="/sys/class/drm/card1/gt/gt0/rps_act_freq_mhz"
SERVICE_FILE="/etc/systemd/system/intel-gpu-clock.service"

check_clock() {
    if [ -f "$ACT_FREQ_FILE" ]; then
        echo -e "\nClock Atual da iGPU: $(cat $ACT_FREQ_FILE) MHz"
    else
        echo -e "\n[ERRO] Não foi possível ler o arquivo de frequência da GPU."
    fi
}

echo "=========================================="
echo "    Gerenciador de Frequência da iGPU     "
echo "=========================================="
echo "1) Aplicar 850 MHz agora (Sessão Atual)"
echo "2) Ativar trava em 850 MHz no Boot (Systemd)"
echo "3) Aplicar AGORA e ATIVAR no Boot"
echo "4) Restaurar modo padrão / Remover serviço"
echo "5) Ver frequência atual da GPU"
echo "6) Sair"
echo "=========================================="
read -p "Escolha uma opção [1-6]: " OPTION

case $OPTION in
    1)
        echo "Aplicando 850 MHz..."
        echo 850 | sudo tee "$MIN_FREQ_FILE" "$MAX_FREQ_FILE" > /dev/null
        echo "[OK] Frequência travada em 850 MHz nesta sessão."
        check_clock
        ;;
    2)
        echo "Criando serviço systemd para o boot..."
        sudo bash -c "cat <<SERVICE > $SERVICE_FILE
[Unit]
Description=Trava a frequencia da iGPU Intel em 850 MHz
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 850 > $MIN_FREQ_FILE && echo 850 > $MAX_FREQ_FILE'

[Install]
WantedBy=multi-user.target
SERVICE"
        sudo systemctl daemon-reload
        sudo systemctl enable intel-gpu-clock.service
        echo "[OK] Serviço ativado! O limite será aplicado em todo boot."
        ;;
    3)
        echo "Aplicando agora e configurando para o boot..."
        echo 850 | sudo tee "$MIN_FREQ_FILE" "$MAX_FREQ_FILE" > /dev/null
        sudo bash -c "cat <<SERVICE > $SERVICE_FILE
[Unit]
Description=Trava a frequencia da iGPU Intel em 850 MHz
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 850 > $MIN_FREQ_FILE && echo 850 > $MAX_FREQ_FILE'

[Install]
WantedBy=multi-user.target
SERVICE"
        sudo systemctl daemon-reload
        sudo systemctl enable intel-gpu-clock.service
        echo "[OK] Frequência travada agora e configurada no boot com sucesso!"
        check_clock
        ;;
    4)
        echo "Restaurando configurações padrão..."
        echo 850 | sudo tee "$MIN_FREQ_FILE" > /dev/null
        echo 1100 | sudo tee "$MAX_FREQ_FILE" > /dev/null
        if [ -f "$SERVICE_FILE" ]; then
            sudo systemctl disable --now intel-gpu-clock.service 2>/dev/null
            sudo rm -f "$SERVICE_FILE"
            sudo systemctl daemon-reload
            echo "[OK] Serviço do systemd removido."
        fi
        echo "[OK] iGPU restaurada para o gerenciamento dinâmico (850-1100 MHz)."
        check_clock
        ;;
    5)
        check_clock
        ;;
    6)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac
