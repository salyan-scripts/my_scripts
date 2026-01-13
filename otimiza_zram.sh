#!/bin/bash

# ==========================================================================
# SCRIPT DE OTIMIZAÇÃO ZRAM PARA MÁQUINAS COM POUCA RAM (3GB ou menos)
# Focado em: Debian 12 (32/64 bits) com HD mecânico
# Autor: Adaptado para a comunidade (Gemini AI Partner)
# ==========================================================================

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}>>> Iniciando Otimização do Sistema...${NC}"

# 1. Instalação das dependências
echo -e "${YELLOW}[1/5] Instalando pacotes necessários...${NC}"
apt update && apt install -y zram-tools zstd

# 2. Configuração do zram-tools
# O Pulo do Gato: Usar ZSTD e 60% da RAM com alta prioridade
echo -e "${YELLOW}[2/5] Configurando ZRAM (60% da RAM, prioridade 100)...${NC}"
cat <<EOF > /etc/default/zramswap
# Configuração otimizada para computadores com HD
ALGO=zstd
PERCENT=60
PRIORITY=100
EOF

# 3. O Pulo do Gato: Otimização do Kernel (sysctl)
# Swappiness alto para ZRAM e page-cluster 0 para evitar latência
echo -e "${YELLOW}[3/5] Aplicando otimizações de Kernel...${NC}"
cat <<EOF > /etc/sysctl.d/99-zram-optimized.conf
# Força o uso do ZRAM (comprimido) antes do swap em disco (lento)
vm.swappiness=150
# Melhora a performance em dispositivos de swap baseados em RAM
vm.page-cluster=0
# Melhora a gestão de cache de arquivos
vm.vfs_cache_pressure=100
EOF

# 4. Resolvendo Conflitos (O Ajuste Fino)
# Este passo comenta qualquer linha de swappiness no arquivo principal
# para garantir que o nosso valor de 150 não seja sobrescrito.
echo -e "${YELLOW}[4/5] Resolvendo conflitos de configuração...${NC}"
if grep -q "vm.swappiness" /etc/sysctl.conf; then
    sed -i 's/^vm.swappiness=/#vm.swappiness=/g' /etc/sysctl.conf
    echo -e "${BLUE}Aviso: Swappiness antigo desativado em /etc/sysctl.conf para evitar conflitos.${NC}"
fi

# 5. Aplicando as mudanças
echo -e "${YELLOW}[5/5] Reiniciando serviços e aplicando filtros...${NC}"
systemctl restart zramswap
sysctl --system

echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}CONCLUÍDO! Seu notebook está otimizado.${NC}"
echo -e "${BLUE}DICAS DE MONITORAMENTO:${NC}"
echo -e "1. Use o comando 'zramctl' para ver a compressão em tempo real."
echo -e "2. Use 'cat /proc/sys/vm/swappiness' para confirmar o valor 150."
echo -e "3. Sinta a diferença ao abrir várias abas no navegador."
echo -e "${GREEN}--------------------------------------------------${NC}"
