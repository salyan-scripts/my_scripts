#!/bin/bash

# Verifica se há arquivos .mkv
shopt -s nullglob
arquivos=(*.mkv)
if [ ${#arquivos[@]} -eq 0 ]; then
    echo "Nenhum arquivo .mkv encontrado na pasta atual."
    exit 0
fi

# Processa cada .mkv
for arquivo in "${arquivos[@]}"; do
    nome="$arquivo"

    # Remove [qualquer coisa], limpa espaços, troca por _, remove _ extras
    novo_nome=$(echo "$nome" | \
        sed -E 's/\[[^]]*\]//g' | \
        sed -E 's/  +/ /g' | \
        sed -E 's/^ +| +$//g' | \
        sed -E 's/ /_/g' | \
        sed -E 's/_+/_/g' | \
        sed -E 's/_+$//')

    # Garante que termine com .mkv (sem espaço antes)
    if [[ "$novo_nome" == *.mkv ]]; then
        novo_nome="${novo_nome%.mkv}.mkv"
    else
        novo_nome="${novo_nome}.mkv"
    fi

    # Remove _ antes da extensão
    novo_nome=$(echo "$novo_nome" | sed -E 's/_+\.mkv$/.mkv/')

    # Renomeia se for diferente
    if [ "$nome" != "$novo_nome" ]; then
        if [ -f "$novo_nome" ]; then
            echo "AVISO: '$novo_nome' já existe. Pulando."
        else
            echo "Renomeando: '$nome' → '$novo_nome'"
            mv "$arquivo" "$novo_nome"
        fi
    fi
done

echo "Concluído! Todos os .mkv foram processados."