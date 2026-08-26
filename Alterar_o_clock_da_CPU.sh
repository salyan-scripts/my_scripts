#!/usr/bin/env bash
#
# Script para limitar ou restaurar o clock do processador (Intel Sandy Bridge)
# Requer permissões de superusuário (sudo)

if [ "$EUID" -ne 0 ]; then
  echo "Erro: Este script precisa ser executado como root (use sudo)."
  exit 1
fi

CPU_DIR="/sys/devices/system/cpu/cpu0/cpufreq"

if [ ! -d "$CPU_DIR" ]; then
  echo "Erro: Interface cpufreq não encontrada em $CPU_DIR."
  exit 1
fi

MIN_FREQ=$(cat "$CPU_DIR/scaling_min_freq")
MAX_FREQ_LIMIT=$(cat "$CPU_DIR/cpuinfo_max_freq")

show_menu() {
  echo "========================================"
  echo "       CONTROLE DE CLOCK DA CPU        "
  echo "========================================"
  echo "1) Baixo Temp / Economia  (~2.0 GHz)"
  echo "2) Médio / Balanceado     (~2.7 GHz)"
  echo "3) Clock Base Máximo      (3.4 GHz)"
  echo "4) Frequência Personalizada"
  echo "5) Restaurar Padrão do Sistema"
  echo "6) Sair"
  echo "========================================"
  echo -n "Escolha uma opção [1-6]: "
}

apply_freq() {
  local target_freq_khz=$1
  echo "Aplicando limite de $(($target_freq_khz / 1000)) MHz em todos os núcleos..."
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    echo "$target_freq_khz" > "$cpu" 2>/dev/null
  done
  echo "Concluído!"
}

show_status() {
  echo ""
  echo "Frequência máxima atual definida:"
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq | awk '{print $1/1000 " MHz"}'
  echo ""
}

show_menu
read -r opt

case $opt in
  1)
    apply_freq 2000000
    show_status
    ;;
  2)
    apply_freq 2700000
    show_status
    ;;
  3)
    apply_freq 3400000
    show_status
    ;;
  4)
    echo -n "Digite a frequência máxima desejada em MHz (ex: 2400): "
    read -r user_mhz
    user_khz=$((user_mhz * 1000))
    if [ "$user_khz" -ge "$MIN_FREQ" ] && [ "$user_khz" -le "$MAX_FREQ_LIMIT" ]; then
      apply_freq "$user_khz"
      show_status
    else
      echo "Frequência fora dos limites permitidos ($(($MIN_FREQ/1000)) MHz - $(($MAX_FREQ_LIMIT/1000)) MHz)."
    fi
    ;;
  5)
    echo "Restaurando limite padrão ($(($MAX_FREQ_LIMIT / 1000)) MHz)..."
    apply_freq "$MAX_FREQ_LIMIT"
    show_status
    ;;
  6)
    exit 0
    ;;
  *)
    echo "Opção inválida."
    ;;
esac
