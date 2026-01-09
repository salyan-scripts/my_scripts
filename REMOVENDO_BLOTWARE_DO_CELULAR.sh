#!/bin/bash

# Script de Limpeza para LG-M320
# Baseado na lista de texto e análise das capturas de tela (Zips 01, 02 e 03)

echo "Aguardando dispositivo..."
adb wait-for-device

# Lista consolidada de pacotes seguros para remoção
PACKAGES=(
    # --- Do seu arquivo original ---
    "com.android.egg"
    "com.google.android.apps.docs.editors.slides"
    "com.orange.update"
    "com.lge.lgdmsclient"
    "com.lge.appbox.client"
    "com.lge.updatecenter"
    "com.lge.sizechangable.weather"
    "com.lge.sizechangable.weather.platform"
    "com.lge.lgaccount"
    "com.lge.email"
    "com.lge.videostudio"
    "com.lge.exchange"
    "com.google.android.googlequicksearchbox"
    "com.google.android.music"
    "com.google.android.videos"
    "com.lge.bnr"
    "com.facebook.system"
    "com.facebook.appmanager"
    "com.lge.sizechangable.musicwidget.widget"
    "com.lge.music"
    "com.google.android.apps.docs.editors.sheets"
    "com.lge.drive.activator"
    "com.google.android.tts"
    "com.rsupport.rs.activity.lge.allinone"
    "com.lge.fmradio"
    "com.lge.wapservice"
    "com.lge.lgworld"
    "com.lge.android.atservice"
    "de.telekom.tsc"
    "com.lge.sizechangable.weather.theme.optimus"
    "com.lge.videoplayer"
    "com.google.android.youtube"

    # --- Identificados nos Prints (Zips 01, 02 e 03) ---
    "com.google.android.apps.docs.editors.docs" # Google Docs
    "com.google.android.feedback"             # Feedback do Market
    "com.lge.upsell"                          # Marketing LG
    "com.android.bookmarkprovider"            # Marcadores antigos
    "com.google.android.apps.photos"          # Google Fotos
    "com.google.android.apps.tachyon"         # Google Duo
    "com.lge.snappage"                        # LG Snap Page
    "com.lge.task"                            # Tarefas LG
    "com.lge.friendsmanager"                  # LG Friends
    "com.lge.vrplayer"                        # LG VR
)

echo "Iniciando a remoção de $(echo ${#PACKAGES[@]}) pacotes..."

for package in "${PACKAGES[@]}"
do
    echo "Removendo: $package"
    # O comando 'uninstall -k --user 0' remove o app para o usuário atual
    adb shell pm uninstall -k --user 0 "$package"
done

echo "------------------------------------------------"
echo "Limpeza concluída! Recomenda-se reiniciar o celular."
echo "------------------------------------------------"
