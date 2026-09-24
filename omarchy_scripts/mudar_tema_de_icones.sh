#!/usr/bin/env bash

# Função para listar os temas de ícones instalados
listar_temas() {
    local diretorios=(
        "$HOME/.icons"
        "$HOME/.local/share/icons"
        "/usr/share/icons"
    )
    
    local temas=()
    for dir in "${diretorios[@]}"; do
        if [ -d "$dir" ]; then
            for item in "$dir"/*; do
                if [ -d "$item" ] && [ -f "$item/index.theme" ]; then
                    temas+=("$(basename "$item")")
                fi
            done
        fi
    done

    # Remove duplicados e ordena
    readarray -t temas_unicos < <(printf "%s\n" "${temas[@]}" | sort -u)
    
    echo "${temas_unicos[@]}"
}

# Se o parâmetro for -l ou --list, apenas exibe a lista simples
if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
    echo "=== Temas de Ícones Instalados ==="
    listar_temas | tr ' ' '\n'
    exit 0
fi

# Se nenhum parâmetro for fornecido, abre um menu interativo com números
if [ -z "$1" ]; then
    readarray -t lista_temas < <(listar_temas | tr ' ' '\n')
    
    if [ ${#lista_temas[@]} -eq 0 ]; then
        echo "Nenhum tema de ícones foi encontrado nos diretórios padrão."
        exit 1
    fi

    echo "=== Escolha um Tema de Ícones ==="
    for i in "${!lista_temas[@]}"; do
        printf " [%2d] %s\n" $((i+1)) "${lista_temas[$i]}"
    done
    echo ""
    
    read -rp "Digite o número do tema desejado (ou o nome do tema): " ESCOLHA

    # Verifica se a entrada é um número e está no alcance da lista
    if [[ "$ESCOLHA" =~ ^[0-9]+$ ]] && [ "$ESCOLHA" -ge 1 ] && [ "$ESCOLHA" -le "${#lista_temas[@]}" ]; then
        TEMA_ICONES="${lista_temas[$((ESCOLHA-1))]}"
    else
        TEMA_ICONES="$ESCOLHA"
    fi
else
    TEMA_ICONES="$1"
fi

if [ -z "$TEMA_ICONES" ]; then
    echo "Operação cancelada. Nenhum tema selecionado."
    exit 1
fi

ARQUIVO_GTK3="$HOME/.config/gtk-3.0/settings.ini"
ARQUIVO_GTK4="$HOME/.config/gtk-4.0/settings.ini"

# 1. Altera via gsettings (GTK / XDG Desktop Portal)
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$TEMA_ICONES"
fi

# 2. Atualiza ou insere no arquivo settings.ini do GTK
atualizar_gtk_ini() {
    local arq="$1"
    if [ -f "$arq" ]; then
        if grep -q "gtk-icon-theme-name" "$arq"; then
            sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$TEMA_ICONES/" "$arq"
        else
            echo "gtk-icon-theme-name=$TEMA_ICONES" >> "$arq"
        fi
    else
        mkdir -p "$(dirname "$arq")"
        echo -e "[Settings]\ngtk-icon-theme-name=$TEMA_ICONES" > "$arq"
    fi
}

atualizar_gtk_ini "$ARQUIVO_GTK3"
atualizar_gtk_ini "$ARQUIVO_GTK4"

# 3. Notificação no sistema
if command -v notify-send &> /dev/null; then
    notify-send "Tema de Ícones" "Alterado com sucesso para: $TEMA_ICONES" -i "$TEMA_ICONES"
fi

echo -e "\n✓ Tema de ícones alterado com sucesso para: $TEMA_ICONES"
