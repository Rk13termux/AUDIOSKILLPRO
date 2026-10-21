#!/usr/bin/env bash
# CADENA PRO: aplica filtros EQ/presencia/compresion/soft-clip (modo oscuro)
# o la cadena suave (modo estandar) + loudnorm en 2 pasos sobre guion-PRO.wav
# y entrega guion-MASTER.wav (48 kHz 24-bit, LOSSLESS). No genera MP3
# intermedio: los encodes finales los hace exportar.sh.
#
# Uso: cadena_pro.sh <carpeta-del-tema> [lufs] [modo]
#   lufs: target (default: -18 en oscuro, -16 en estandar)
#   modo: oscuro | estandar (default oscuro)
# Escribe <carpeta>/.pro-cadena.env con OUTPUT_I, OUTPUT_TP y OUTPUT_MODO.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_audio.sh"

TEMA="${1:?uso: cadena_pro.sh <carpeta-del-tema> [lufs] [modo]}"
LUFS="${2:-}"
MODO="${3:-oscuro}"
case "$MODO" in oscuro|estandar) ;; *) echo "[✗] modo invalido '$MODO' (oscuro|estandar)" >&2; exit 1 ;; esac
[ -z "$LUFS" ] && LUFS="$([ "$MODO" = oscuro ] && echo -18 || echo -16)"
WAV="$TEMA/guion-PRO.wav"
OUT="$TEMA/guion-MASTER.wav"

[ -f "$WAV" ] || { echo "[✗] falta guion-PRO.wav en $TEMA (corre unir_pro.sh)" >&2; exit 1; }

if aplicar_cadena_pro "$WAV" "$OUT" "$LUFS" "" "$MODO"; then
    cat > "$TEMA/.pro-cadena.env" <<EOF
OUTPUT_I=${OUTPUT_I:-}
OUTPUT_TP=${OUTPUT_TP:-}
OUTPUT_MODO=${OUTPUT_MODO:-$MODO}
EOF
    echo "[+] cadena pro OK → guion-MASTER.wav (48k 24-bit)" >&2
else
    exit 1
fi