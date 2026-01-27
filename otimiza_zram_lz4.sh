#!/bin/bash

# ==========================================================================
# OTIMIZADOR ZRAM - VERSÃO EQUILIBRADA (BALANCED)
# Foco: Estabilidade e fluidez sem uso agressivo de CPU
# Ideal para: 6GB RAM ou mais
# ==========================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${BLUE}>>> Aplicando Otimização Equilibrada (LZ4 + Balanced Tweaks)...${NC}"

# 1. Instalação
apt update && apt install -y zram-tools

# 2. Configuração ZRAM Conservadora (40% da RAM)
echo -e "${YELLOW}[1/3] Configurando ZRAM (40% da RAM - LZ4)...${NC}"
cat <<EOF > /etc/default/zramswap
ALGO=lz4
PERCENT=40
PRIORITY=100
EOF

# 3. Ajustes de Kernel Equilibrados
echo -e "${YELLOW}[2/3] Ajustando parâmetros de Kernel para modo equilibrado...${NC}"
cat <<EOF > /etc/sysctl.d/99-zram-optimized.conf
# Uso equilibrado de swap
vm.swappiness=60
# Essencial para ZRAM: remove latência de busca
vm.page-cluster=0
# Mantém o cache de arquivos em RAM por mais tempo (melhora navegação)
vm.vfs_cache_pressure=50
# Gestão de escrita em disco (segurança para o EXT4)
vm.dirty_ratio=20
vm.dirty_background_ratio=10
EOF

# 4. Aplicação e Limpeza
echo -e "${YELLOW}[3/3] Reiniciando serviços...${NC}"
sed -i 's/^vm.swappiness=/#vm.swappiness=/g' /etc/sysctl.conf

systemctl restart zramswap
sysctl --system

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}OTIMIZAÇÃO EQUILIBRADA CONCLUÍDA!${NC}"
echo -e "Perfil: ${BLUE}Estabilidade e Resposta Térmica${NC}"
echo -e "Algoritmo: ${BLUE}LZ4${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
zramctl
