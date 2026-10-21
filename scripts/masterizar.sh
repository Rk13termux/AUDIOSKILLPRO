#!/usr/bin/env bash
# MODO EXTRA — masterizar un audio suelto (WAV o MP3) con la CADENA PRO.
# Opera sobre WAV cuando es posible y entrega <base>-MASTER.wav (48k 24-bit),
# LOSSLESS. Los encodes finales los hace exportar.sh si se desean.
# Modo oscuro (default) o estandar.
#
# Uso: masterizar.sh <archivo.wav|mp3> [--modo oscuro|estandar] [--lufs N]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_audio.sh"

SRC=""
LUFS=""
MODO="oscuro"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --modo) MODO="${2:-oscuro}"; shift 2 ;;
        --lufs) LUFS="${2:?--lufs requiere valor}"; shift 2 ;;
        -h|--help) echo "uso: masterizar.sh <archivo.wav|mp3> [--modo oscuro|estandar] [--lufs N]"; exit 0 ;;
        -*) echo "[✗] opcion desconocida: $1" >&2; exit 1 ;;
        *) SRC="$1"; shift ;;
    esac
done

[ -n "$SRC" ] || { echo "uso: masterizar.sh <archivo.wav|mp3> [--modo oscuro|estandar] [--lufs N]" >&2; exit 1; }
[ -f "$SRC" ] || { echo "[✗] no existe: $SRC" >&2; exit 1; }
case "$MODO" in oscuro|estandar) ;; *) echo "[✗] modo invalido '$MODO' (oscuro|estandar)" >&2; exit 1 ;; esac

OUT="${SRC%.*}-MASTER.wav"

if aplicar_cadena_pro "$SRC" "$OUT" "$LUFS" "" "$MODO"; then
    echo "[+] masterizar OK → $OUT (modo $MODO, WAV 48k 24-bit)"
    echo "    LUFS final: ${OUTPUT_I:-?} · true peak: ${OUTPUT_TP:-?}"
fi