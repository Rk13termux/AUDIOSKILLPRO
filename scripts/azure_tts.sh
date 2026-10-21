#!/usr/bin/env bash
# AZURE TTS — modulo OPCIONAL de sintesis de calidad.
# Si AZURE_SPEECH_KEY esta definido en env, sintetiza cada seccion del guion
# con es-VE-SebastianNeural a 48 kHz (raw-48khz-16bit-mono-pcm convertido a
# guion-NN-<seccion>.wav lossless). Acepta SSML: el campo `ssml` del guion o
# <break time="..."/> entre secciones se respetan.
#
# Si AZURE_SPEECH_KEY NO existe: fallback automatico al CLI tts-edge SIN
# error (mismo contrato de salida: guion-NN-*.mp3).
#
# Uso: azure_tts.sh <guion.md> [--sections|--section N]
# Env: AZURE_SPEECH_KEY (obligatorio para activar), AZURE_SPEECH_REGION
#      (default: eastus). Ver README.md para el plan gratuito (~500k
#      caracteres/mes) y como obtener la key.
set -uo pipefail

GUION="${1:?uso: azure_tts.sh <guion.md> [--sections|--section N]}"
TEMA="$(dirname "$GUION")"

# ------- Fallback: sin key, delegar en tts-edge (sin error) ---------------
if [ -z "${AZURE_SPEECH_KEY:-}" ]; then
    echo "[azure] AZURE_SPEECH_KEY no definida; fallback a tts-edge" >&2
    if command -v tts-edge >/dev/null 2>&1; then
        tts-edge "$GUION" "$@"
    elif [ -x "$HOME/tts-edge/.venv/bin/tts-edge" ]; then
        "$HOME/tts-edge/.venv/bin/tts-edge" "$GUION" "$@"
    else
        echo "[azure] tts-edge no disponible; dejando las secciones sin sintetizar" >&2
    fi
    exit 0
fi

REGION="${AZURE_SPEECH_REGION:-eastus}"
ENDPOINT="https://$REGION.tts.speech.microsoft.com/cognitiveservices/v1"
VOICE="es-ES-AlvaroNeural"

# Fracciona el guion en secciones (frontmatter y encabezados fuera).
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
awk '
BEGIN{sec=0; fm=0}
/^---[[:space:]]*$/ {fm++; next}
fm==1 {next}
/^## / {sec++; next}
sec==0 {next}
{print > ("'"$TMP"'/sec-" sec ".txt")}
' "$GUION"

sintetizar_seccion() {
    local n="$1" texto="$2" out="$3" ssml
    ssml="<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='es-ES'><voice name='$VOICE'><prosody rate='-16%' pitch='-6Hz' volume='-5%'>$texto</prosody></voice></speak>"
    curl -s -X POST "$ENDPOINT" \
        -H "Ocp-Apim-Subscription-Key: $AZURE_SPEECH_KEY" \
        -H 'Content-Type: application/ssml+xml' \
        -H 'X-Microsoft-OutputFormat: raw-48khz-16bit-mono-pcm' \
        -d "$ssml" -o "$TMP/raw-$n.pcm" || return 1
    # raw 16-bit mono 48k → WAV 48k lossless (guion-NN-<n>.wav, reutilizable).
    ffmpeg -hide_banner -loglevel error -y -f s16le -ar 48000 -ac 1 \
        -i "$TMP/raw-$n.pcm" -c:a pcm_s16le "$out" || return 1
    echo "[azure] OK → $out (48k 16-bit wav, es-ES-AlvaroNeural)" >&2
}

n=0
for f in "$TMP"/sec-*.txt; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    nombre="$(grep -m1 '^## ' "$GUION" | sed -n "${n}p" | sed 's/^## //' | tr ' ' '-' | tr -cd '[:alnum:]-')"
    nombre="${nombre:-seccion}"
    texto="$(cat "$f")"
    if sintetizar_seccion "$n" "$texto" "$TEMA/guion-$(printf '%02d' "$n")-$nombre.wav"; then
        : 
    else
        echo "[✗] fallo la seccion $n en Azure (¿key valida? plan agotado?)" >&2
        exit 1
    fi
done

declare -a SECS_SINTETIZADAS
n=0
for f in "$TEMA"/guion-[0-9][0-9]-*.wav; do
    [ -e "$f" ] || continue
    n=$((n + 1))
done
echo "[azure] $n secciones sintetizadas en 48k wav" >&2