#!/usr/bin/env bash
# GLOSARIO FONETICO DE MARCA — sanitizacion previa al TTS.
# Reemplaza "AudioBlaze" (y variantes) por su forma fonetica segun la voz
# activa, para que el TTS pronuncie la marca bien. El guion.md mantiene
# "AudioBlaze" escrito correcto; esta capa es la unica que ve la fonetica.
#
# Uso: sanitizar_tts.sh <voz> [archivo.txt]   (lee stdin si no hay archivo)
#   voz: nombre edge-tts (es-ES-*, es-MX-*, es-CO-*, es-US-*) o "kokoro".
# Escribe por stdout el texto sanitizado.
set -euo pipefail

VOZ="${1:?uso: sanitizar_tts.sh <voz> [archivo.txt]}"
ARCHIVO="${2:-}"
[ -n "$ARCHIVO" ] && [ -f "$ARCHIVO" ] || ARCHIVO=""

case "$VOZ" in
    es-ES-*)  FORMA="AudioBléis" ;;
    es-VE-*|es-MX-*|es-CO-*|es-US-*) FORMA="AudioBleiz" ;;
    kokoro)   FORMA="AudioBleis" ;;
    *) FORMA="AudioBleiz" ;;  # default flexible
esac

if [ -n "$ARCHIVO" ]; then
    sed -E "s/AudioBlaze pro/$FORMA pro/Ig; s/AudioBlaze/$FORMA/Ig" "$ARCHIVO"
else
    sed -E "s/AudioBlaze pro/$FORMA pro/Ig; s/AudioBlaze/$FORMA/Ig"
fi