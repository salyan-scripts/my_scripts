#!/bin/bash

# Cores para facilitar a leitura
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

echo -e "${VERDE}=== Iniciando Configuração do Cloudflare WARP (Via WireGuard) para 32-bits ===${SEM_COR}"

# 1. Verificação de Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${VERMELHO}Por favor, execute como root (sudo ./nome_do_script.sh)${SEM_COR}"
  exit 1
fi

# 2. Atualizar e Instalar Dependências (WireGuard e ferramentas de rede)
echo -e "${AMARELO}[1/6] Atualizando repositórios e instalando WireGuard...${SEM_COR}"
apt-get update -y
apt-get install -y wireguard wireguard-tools curl jq openresolv

# 3. Baixar o gerador de chaves (wgcf) compatível com 32-bits (i386)
echo -e "${AMARELO}[2/6] Baixando a ferramenta wgcf (versão 386)...${SEM_COR}"
# Busca a URL da última versão para linux_386
WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url" | grep "linux_386" | cut -d '"' -f 4)

if [ -z "$WGCF_URL" ]; then
    echo -e "${VERMELHO}Erro: Não foi possível encontrar a URL de download do wgcf. Verifique sua conexão.${SEM_COR}"
    exit 1
fi

curl -L -o /usr/local/bin/wgcf "$WGCF_URL"
chmod +x /usr/local/bin/wgcf

# 4. Registrar Conta na Cloudflare (Necessita aceitar os Termos)
echo -e "${AMARELO}[3/6] Registrando nova conta WARP...${SEM_COR}"
echo -e "${VERDE}IMPORTANTE: Se solicitado, pressione ENTER para aceitar os termos de serviço da Cloudflare.${SEM_COR}"

# Cria um diretório temporário para gerar os arquivos
mkdir -p /tmp/warp_setup
cd /tmp/warp_setup

# Tenta registrar. Se já existir, ignora.
if [ -f "wgcf-account.toml" ]; then
    echo "Conta já existente encontrada."
else
    /usr/local/bin/wgcf register --accept-tos
fi

# 5. Gerar Perfil WireGuard
echo -e "${AMARELO}[4/6] Gerando arquivo de configuração do WireGuard...${SEM_COR}"
/usr/local/bin/wgcf generate

# O arquivo gerado geralmente se chama wgcf-profile.conf
if [ ! -f "wgcf-profile.conf" ]; then
    echo -e "${VERMELHO}Erro: Falha ao gerar o arquivo de configuração.${SEM_COR}"
    exit 1
fi

# Move para o diretório do WireGuard renomeando para 'warp.conf'
cp wgcf-profile.conf /etc/wireguard/warp.conf
chmod 600 /etc/wireguard/warp.conf

echo -e "${VERDE}Configuração instalada em /etc/wireguard/warp.conf${SEM_COR}"

# 6. Ativar a VPN
echo -e "${AMARELO}[5/6] Ativando o serviço WARP...${SEM_COR}"
systemctl enable wg-quick@warp
systemctl start wg-quick@warp

# Aguarda alguns segundos para a conexão estabilizar
sleep 3

# 7. Verificação
echo -e "${AMARELO}[6/6] Verificando conexão...${SEM_COR}"
TRACE_OUTPUT=$(curl -s https://www.cloudflare.com/cdn-cgi/trace)

WARP_STATUS=$(echo "$TRACE_OUTPUT" | grep "warp=" | cut -d= -f2)
IP_ATUAL=$(echo "$TRACE_OUTPUT" | grep "ip=" | cut -d= -f2)

echo "----------------------------------------------------"
if [ "$WARP_STATUS" == "on" ] || [ "$WARP_STATUS" == "plus" ]; then
    echo -e "${VERDE}SUCESSO! WARP ATIVADO.${SEM_COR}"
    echo -e "Status WARP: ${VERDE}$WARP_STATUS${SEM_COR}"
    echo -e "Seu IP (Cloudflare): $IP_ATUAL"
    echo -e "Protocolo: WireGuard + IPv6 (Habilitado no túnel)"
else
    echo -e "${VERMELHO}ALERTA: O WARP parece não estar ativo.${SEM_COR}"
    echo "Status retornado: $WARP_STATUS"
    echo "Tente rodar 'systemctl status wg-quick@warp' para diagnosticar."
fi
echo "----------------------------------------------------"
