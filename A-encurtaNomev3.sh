#!/bin/bash

# Ativa nullglob para evitar erros se não houver arquivos
shopt -s nullglob

# Busca tanto .mkv quanto .mp4
arquivos=(*.mkv *.mp4)

if [ ${#arquivos[@]} -eq 0 ]; then
    echo "Nenhum arquivo .mkv ou .mp4 encontrado na pasta atual."
    exit 0
fi

# Processa cada arquivo
for arquivo in "${arquivos[@]}"; do
    nome_original="$arquivo"
    ext="${arquivo##*.}" # Extrai a extensão (.mkv ou .mp4)
    apenas_nome="${arquivo%.*}" # Extrai apenas o nome sem a extensão

    # 1. Remove o conteúdo entre colchetes [exemplo]
    # 2. Identifica o padrão SxxExx e remove TUDO o que vem depois dele
    # 3. Substitui espaços e sublinhados por pontos
    # 4. Remove pontos duplicados (ex: .. vira .)
    # 5. Remove pontos que sobraram no final do nome
    novo_nome_base=$(echo "$apenas_nome" | \
        sed -E 's/\[[^]]*\]//g' | \
        sed -E 's/(S[0-9]{2}E[0-9]{2}).*/\1/i' | \
        sed -E 's/[ _]/./g' | \
        sed -E 's/\.+/./g' | \
        sed -E 's/\.+$//')

    # Reconstrói o nome final
    novo_nome="${novo_nome_base}.${ext}"

    # Renomeia apenas se o nome for diferente e o destino não existir
    if [ "$nome_original" != "$novo_nome" ]; then
        if [ -f "$novo_nome" ]; then
            echo "AVISO: '$novo_nome' já existe. Pulando."
        else
            echo "Renomeando: '$nome_original' → '$novo_nome'"
            mv "$nome_original" "$novo_nome"
        fi
    fi
done

echo "Concluído! Todos os arquivos foram padronizados com pontos."
