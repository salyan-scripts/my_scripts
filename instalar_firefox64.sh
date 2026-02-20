#!/bin/bash

# Variáveis de diretórios (Padrão XDG para usuários locais)
INSTALL_PATH="$HOME/.local/lib/firefox"
BIN_PATH="$HOME/.local/bin"
DESKTOP_PATH="$HOME/.local/share/applications"
FIREFOX_URL="https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=pt-BR"

echo "--- Iniciando Instalação do Firefox 64-bit na Home ---"

# 1. Preparação do ambiente
mkdir -p "$INSTALL_PATH"
mkdir -p "$BIN_PATH"
mkdir -p "$DESKTOP_PATH"

# 2. Download e Extração
echo "Baixando a versão mais recente..."
wget -q --show-progress -O /tmp/firefox.tar.bz2 "$FIREFOX_URL"

echo "Extraindo arquivos para $INSTALL_PATH..."
# Limpa a pasta se já existir uma instalação anterior para evitar conflitos
rm -rf "${INSTALL_PATH:?}"/*
tar -xjf /tmp/firefox.tar.bz2 -C "$INSTALL_PATH" --strip-components=1

# 3. Links e Atalhos
echo "Criando link simbólico em $BIN_PATH..."
ln -sf "$INSTALL_PATH/firefox" "$BIN_PATH/firefox"

echo "Configurando atalho no menu de aplicativos..."
cat > "$DESKTOP_PATH/firefox-local.desktop" <<EOL
[Desktop Entry]
Name=Firefox Local
Comment=Navegador Web (Auto-atualizável)
Exec=$INSTALL_PATH/firefox %u
Icon=$INSTALL_PATH/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOL

# 4. Verificação de PATH no .bashrc
echo "Verificando se $BIN_PATH está no seu PATH..."
if [[ ":$PATH:" != *":$BIN_PATH:"* ]]; then
    echo "Adicionando $BIN_PATH ao seu PATH no .bashrc..."
    echo -e "\n# Caminho para binários locais do usuário\nexport PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "SUCESSO: PATH atualizado. Reinicie o terminal ou use 'source ~/.bashrc'."
else
    echo "O PATH já está configurado corretamente."
fi

# 5. Limpeza e Finalização
rm /tmp/firefox.tar.bz2
update-desktop-database "$DESKTOP_PATH" 2>/dev/null

echo "--- Instalação Concluída! ---"
echo "Agora o Firefox pode se atualizar sozinho sempre que houver uma nova versão."
