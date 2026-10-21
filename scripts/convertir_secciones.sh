#!/usr/bin/env bash
# LOSSLESS INTERNO: convierte cada seccion del tema a WAV 48 kHz mono float
# (pcm_f32le) UNA sola vez, reutilizable: s01.wav, s02.wav... en la carpeta.
#
# - Si hay guion-NN-*.wav mono 48k (salida de azure_tts.sh), los copia a s0N.wav
#   SIN reencode (ya son lossless).
# - Si hay guion-NN-*.mp3, los convierte a s0N.wav 48k float.
# - Reusa los s0N.wav existentes salvo que el origen sea mas reciente.
#
# Uso: convertir_secciones.sh <carpeta-del-tema>
set -euo pipefail

TEMA="${1:?uso: convertir_secciones.sh <carpeta-del-tema>}"

n_tot=0
n_conv=0

# WAV de seccion (lossless origen, ej: azure 48k): copiar sin reencode.
for sec in "$TEMA"/guion-[0-9][0-9]-*.wav; do
    [ -e "$sec" ] || continue
    case "$(basename "$sec")" in s*.wav|*-PRO.wav|*-MASTER.wav) continue ;; esac
    nnum="$(basename "$sec" | sed -E 's/^guion-([0-9]{2}).*/\1/')"
    out="$TEMA/s$nnum.wav"
    n_tot=$((n_tot + 1))
    if [ -f "$out" ] && [ ! "$sec" -nt "$out" ]; then continue; fi
    cp -f "$sec" "$out"
    n_conv=$((n_conv + 1))
    echo "[lossless] $out <- $sec (copia sin reencode)" >&2
done

# MP3 de seccion (tts-edge): convertir a 48k mono float una sola vez.
for sec in "$TEMA"/guion-[0-9][0-9]-*.mp3; do
    [ -e "$sec" ] || continue
    case "$(basename "$sec")" in *-PRO.mp3|*-MASTER.mp3) continue ;; esac
    nnum="$(basename "$sec" | sed -E 's/^guion-([0-9]{2}).*/\1/')"
    [ -e "$TEMA/s$nnum.wav" ] && continue
    out="$TEMA/s$nnum.wav"
    n_tot=$((n_tot + 1))
    if [ -f "$out" ] && [ ! "$sec" -nt "$out" ]; then continue; fi
    ffmpeg -hide_banner -loglevel error -y -i "$sec" -ar 48000 -ac 1 \
        -sample_fmt flt -c:a pcm_f32le "$out" \
        || { echo "[✗] no pude convertir $sec a $out" >&2; exit 1; }
    n_conv=$((n_conv + 1))
    echo "[lossless] $out <- $sec (48k mono float)" >&2
done

echo "[lossless] ${n_conv}/${n_tot} secciones convertidas a WAV 48k float" >&2