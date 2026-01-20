#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
NC='\033[0m' # Sem cor

echo -e "${AZUL}➔ Iniciando processo de publicação...${NC}"

# 1. Mostrar status
echo -e "${AMARELO}📋 Status atual:${NC}"
git status -s

# 2. Adicionar tudo
git add .

# 3. Gerar mensagem com data e hora automática
DATA_HORA=$(date +"%d/%m/%Y às %H:%M")
MENSAGEM="Alterações de $DATA_HORA"

# 4. Commit
echo -e "${VERDE}💾 Criando commit: $MENSAGEM...${NC}"
git commit -m "$MENSAGEM"

# 5. Push
echo -e "${AZUL}📤 Enviando para o GitHub...${NC}"
git push origin main

# 6. BÔNUS: Acompanhar o Build do APK automaticamente
if command -v gh &> /dev/null
then
    echo -e "${AMARELO}👀 Acompanhando o build do APK no GitHub... (Pressione Ctrl+C para parar de vigiar sem cancelar o build)${NC}"
    sleep 2
    gh run watch
else
    echo -e "${AMARELO}💡 Dica: Instale o 'gh' (GitHub CLI) para acompanhar o build aqui no terminal.${NC}"
fi

echo -e "${VERDE}✅ Processo concluído!${NC}"
