#!/bin/bash

# ====================================================================
# Conversor H.265 Definitivo: GT 1030 / CPU + Escala Inteligente
# ====================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}[Erro] O ffmpeg não está instalado. Instale no CachyOS com: sudo pacman -S ffmpeg${NC}"
    exit 1
fi

clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   CONVERSOR H.265 INTELIGENTE (GT 1030 + i7-2600)  ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo ""

# 1. Modo de Hardware (Aceleração vs CPU Pura)
echo -e "${YELLOW}Escolha o modo de decodificação:${NC}"
echo "1) Híbrido: GT 1030 (Decodifica) + i7-2600 (Comprime H.265)"
echo "2) Apenas CPU: i7-2600 Puro (Modo Benchmark / Sem GPU)"
read -p "Digite a opção [1-2]: " hw_choice

case $hw_choice in
    1) 
        HW_FLAGS="-hwaccel cuda -c:v h264_cuvid"
        HW_Name="GPU (NVDEC) + CPU"
        ;;
    2) 
        HW_FLAGS=""
        HW_Name="CPU Pura (Benchmark)"
        ;;
    *) echo -e "${RED}Opção inválida. Saindo.${NC}"; exit 1;;
esac

echo ""
# 2. Seleção de Resolução Inteligente
echo -e "${YELLOW}Escolha a resolução de destino:${NC}"
echo "1) Full HD (1080p - Reduz se > 1080p, mantém se menor)"
echo "2) HD (720p - Reduz se > 720p, mantém se menor)"
echo "3) Manter resolução original do vídeo"
read -p "Digite a opção [1-3]: " res_choice

case $res_choice in
    1) 
        SCALE_FILTER="scale=w='if(gt(ih,1080),-2,iw)':h='if(gt(ih,1080),1080,ih)'"
        RES_TAG="1080p"
        ;;
    2) 
        SCALE_FILTER="scale=w='if(gt(ih,720),-2,iw)':h='if(gt(ih,720),720,ih)'"
        RES_TAG="720p"
        ;;
    3) 
        SCALE_FILTER=""
        RES_TAG="orig"
        ;;
    *) 
        echo -e "${RED}Opção inválida. Saindo.${NC}"
        exit 1
        ;;
esac

echo ""
# 3. Seleção de Arquivos
echo -e "${YELLOW}Como deseja selecionar os vídeos?${NC}"
echo "1) Converter todos os vídeos da pasta atual"
echo "2) Informar o caminho de um arquivo específico"
read -p "Digite a opção [1-2]: " file_choice

files=()
if [ "$file_choice" -eq 1 ]; then
    while IFS= read -r -d $'\0' file; do
        files+=("$file")
    done < <(find . -maxdepth 1 -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mov" \) -print0)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum arquivo de vídeo compatível encontrado na pasta atual.${NC}"
        exit 1
    fi
elif [ "$file_choice" -eq 2 ]; then
    read -p "Digite o caminho ou arraste o arquivo de vídeo aqui: " target_file
    target_file="${target_file//\'/}"
    target_file="${target_file//\"/}"
    
    if [ -f "$target_file" ]; then
        files+=("$target_file")
    else
        echo -e "${RED}Arquivo não encontrado: $target_file${NC}"
        exit 1
    fi
else
    echo -e "${RED}Opção inválida. Saindo.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Iniciando processamento no modo: $HW_Name com escala inteligente...${NC}"
echo ""

# Parâmetros de otimização x265
X265_OPTS="-crf 28 -preset fast -x265-params no-sao=1:aq-mode=3 -tag:v hvc1"

# Loop principal
for input_file in "${files[@]}"; do
    dir_name=$(dirname "$input_file")
    base_name=$(basename "$input_file")
    name_no_ext="${base_name%.*}"
    
    output_dir="${dir_name}/Videos_Convertidos"
    mkdir -p "$output_dir"
    
    output_file="${output_dir}/${name_no_ext}_${RES_TAG}_h265.mkv"
    
    if [ -f "$output_file" ]; then
        echo -e "${YELLOW}[Pulando] O arquivo já existe em 'Videos_Convertidos': $(basename "$output_file")${NC}"
        echo "----------------------------------------------------"
        continue
    fi
    
    echo -e "${BLUE}Processando:${NC} $base_name"
    echo -e "${BLUE}Salvando em:${NC} $output_file"
    
    # Executa com ou sem filtro de escala inteligente (Bloco 'if/fi' corrigido)
    if [ -n "$SCALE_FILTER" ]; then
        ionice -c 3 ffmpeg -y \
            $HW_FLAGS \
            -i "$input_file" \
            -vf "$SCALE_FILTER" \
            -c:v libx265 $X265_OPTS \
            -c:a copy \
            -c:s copy \
            "$output_file"
    else
        ionice -c 3 ffmpeg -y \
            $HW_FLAGS \
            -i "$input_file" \
            -c:v libx265 $X265_OPTS \
            -c:a copy \
            -c:s copy \
            "$output_file"
    fi
        
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[Sucesso] Vídeo convertido com êxito!${NC}"
    else
        echo -e "${RED}[Erro] Falha ao processar o arquivo: $base_name${NC}"
    fi
    echo "----------------------------------------------------"
done

echo -e "${GREEN}Processo concluído! Os vídeos convertidos estão na pasta 'Videos_Convertidos'.${NC}"
