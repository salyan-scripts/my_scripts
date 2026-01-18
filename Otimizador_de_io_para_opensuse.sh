#!/bin/bash
# ============================================================
#  Otimizacao de RAM para openSUSE Tumbleweed 32-bits
# ------------------------------------------------------------
#  Perfil da maquina:
#   - 32-bits
#   - 3 GB de RAM
#   - HD (lento)
#   - Btrfs
#
#  Seguro para:
#   - Internet (ModemManager NAO TOCADO)
#   - Bluetooth (NAO TOCADO)
#
#  O que este script faz:
#   * Ajusta swappiness
#   * Otimiza cache e escrita (HD + Btrfs)
#   * Ativa zswap (compressao de swap)
#   * Ajusta limites do systemd
#   * Desativa apenas servicos realmente dispensaveis
#
# ============================================================

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Execute como root: sudo $0"
  exit 1
fi

echo "============================================================"
echo " Iniciando otimizacao de RAM - openSUSE 32-bits (HD)"
echo "============================================================"
echo

# ============================================================
# 1. SWAPPINESS
# ------------------------------------------------------------
# Evita uso precoce de swap (HD sofre muito com isso)
# ============================================================

echo "[1/6] Configurando swappiness..."

cat <<EOF > /etc/sysctl.d/99-swappiness.conf
# Uso minimo de swap (ideal para HD)
vm.swappiness=30
EOF

# ============================================================
# 2. AJUSTES DE MEMORIA / CACHE
# ------------------------------------------------------------
# Parametros mais conservadores para HD lento
# ============================================================

echo "[2/6] Ajustando cache e escrita para HD..."

cat <<EOF > /etc/sysctl.d/99-memory-tuning.conf
# Libera cache mais agressivamente
vm.vfs_cache_pressure=120

# Evita grandes rajadas de escrita no HD
vm.dirty_background_ratio=10
vm.dirty_ratio=20
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=1000
EOF

sysctl --system >/dev/null

# ============================================================
# 3. ZSWAP (COMPRESSAO DE SWAP)
# ------------------------------------------------------------
# ESSENCIAL para HD + pouca RAM
# ============================================================

echo "[3/6] Configurando zswap..."

GRUB_FILE="/etc/default/grub"

if ! grep -q "zswap.enabled=1" "$GRUB_FILE"; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=15 /' "$GRUB_FILE"
  grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null
  echo " - zswap configurado (ativo apos reboot)"
else
  echo " - zswap ja estava configurado"
fi

# ============================================================
# 4. SYSTEMD - LIMITE DE TASKS
# ------------------------------------------------------------
# Evita excesso de processos em pouca RAM
# ============================================================

echo "[4/6] Ajustando limites do systemd..."

mkdir -p /etc/systemd/system.conf.d

cat <<EOF > /etc/systemd/system.conf.d/lowram.conf
[Manager]
DefaultTasksMax=1024
EOF

# ============================================================
# 5. SERVICOS REALMENTE DISPENSAVEIS
# ------------------------------------------------------------
# NAO toca em:
#  - ModemManager
#  - Bluetooth
# ============================================================

echo "[5/6] Desativando servicos nao essenciais..."

SERVICES=(
  cups.service
  avahi-daemon.service
)

for svc in "${SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^$svc"; then
    systemctl disable --now "$svc" >/dev/null 2>&1 || true
    echo " - $svc desativado"
  else
    echo " - $svc nao encontrado (ok)"
  fi
done

# ============================================================
# 6. FINALIZACAO
# ============================================================

echo
echo "============================================================"
echo " Otimizacao concluida!"
echo "============================================================"
echo
echo "IMPORTANTE:"
echo " - Reinicie o sistema para ativar o zswap"
echo
echo "Monitoramento:"
echo " - htop (ja instalado)"
echo " - free -h"
echo

