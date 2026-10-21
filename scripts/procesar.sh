#!/usr/bin/env bash
# POST-PROCESO PROFESIONAL de crear-audio.
# Orquesta: UNIÓN PRO → CADENA PRO → SALIDA PREMIUM (ElevenLabs) y reporta todo.
#
# Uso: procesar.sh <carpeta-del-tema> [descripcion-del-tema]
# La descripcion alimenta la heuristica de LUFS (sueño → -18).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMA="${1:?uso: procesar.sh <carpeta-del-tema> [descripcion-del-tema]}"
DESC="${2:-}"
GUION="$TEMA/guion.md"

[ -f "$GUION" ] || { echo "[✗] falta $GUION en $TEMA" >&2; exit 1; }

# --- Leer frontmatter (lufs, breaths, gaps) -------------------------------
get_fm() {
    awk -v k="$1" '
        /^---[[:space:]]*$/ { fm++; next }
        fm == 1 && index($0, k ":") == 1 { print substr($0, index($0, ":") + 2); exit }
    ' "$GUION"
}

LUFS_FM="$(get_fm lufs | tr -d ' \r')"
BREATHS_FM="$(get_fm breaths | tr -d ' \r')"
GAPS_FM="$(get_fm gaps | tr -d ' \r')"
MODE_FM="$(get_fm mode | tr -d ' \r')"

# --- Resolver LUFS: frontmatter → modo (oscuro=-18) o heuristica → -16 ----
LUFS=""
MODE="${MODE_FM:-oscuro}"
case "$MODE" in oscuro|estandar) ;; *) echo "[✗] mode invalido '$MODE' (oscuro|estandar)" >&2; exit 1 ;; esac

if [ -n "$LUFS_FM" ]; then
    LUFS="$LUFS_FM"
elif [ "$MODE" = oscuro ]; then
    LUFS="-18"
else
    case "${DESC:-$(get_fm title | tr -d ' \r')}" in
        *sueñ*|*dormir*|*descans*|*insomn*|*sleep*) LUFS="-18" ;;
        *) LUFS="-16" ;;
    esac
fi
case "$LUFS" in *[!0-9,-.]*|"") echo "[✗] luFS invalido '$LUFS'" >&2; exit 1 ;; esac

GAPS="${GAPS_FM:-0.9}"
case "$GAPS" in *[!0-9.,-]*|"") echo "[✗] gaps invalido '$GAPS'" >&2; exit 1 ;; esac
BREATHS="${BREATHS_FM:-true}"
[ "$BREATHS" = true ] || [ "$BREATHS" = false ] || { echo "[✗] breaths debe ser true|false ('$BREATHS')" >&2; exit 1; }

echo "[procesar] tema: $TEMA · modo $MODE · LUFS $LUFS · gaps $GAPS · breaths $BREATHS" >&2

# --- 1. UNIÓN PRO (convierte secciones a WAV 48k float una vez, une) ------
bash "$SCRIPT_DIR/unir_pro.sh" "$TEMA" "$GAPS" "$BREATHS"
source "$TEMA/.pro-union.env"

# --- 2. CADENA PRO → guion-MASTER.wav (48k 24-bit, LOSSLESS) --------------
bash "$SCRIPT_DIR/cadena_pro.sh" "$TEMA" "$LUFS" "$MODE"
source "$TEMA/.pro-cadena.env"

# --- 3. EXPORTACIÓN (encodes finales por destino; master ya es archival) --
bash "$SCRIPT_DIR/exportar.sh" "$TEMA" "telegram,pack"
source "$TEMA/.pro-export.env"

# --- 4. SALIDA PREMIUM (texto-elevenlabs.txt + caracteres) ---------------
bash "$SCRIPT_DIR/texto_elevenlabs.sh" "$TEMA"
source "$TEMA/.pro-elevenlabs.env"

# --- Reporte ampliado ------------------------------------------------------
OUT="$TEMA/guion-MASTER.wav"
TXT="$TEMA/texto-elevenlabs.txt"
DURACION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMA/guion-PRO.mp3" 2>/dev/null || \
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT" 2>/dev/null || echo 0)"

printf '%-30s %s\n' "Master (48k 24-bit):" "$OUT"
printf '%-30s %s\n' "Exports:" "$(IFS=,; echo "[$TIERS]")"
printf '%-30s %s\n' "Generaciones lossy:" "${GENERACIONES_LOSSY} (solo encodes finales)"
printf '%-30s %s\n' "Modo:" "${OUTPUT_MODO:-$MODE}"
printf '%-30s %s\n' "LUFS final (medido):" "${OUTPUT_I:-?}"
printf '%-30s %s\n' "True peak:" "${OUTPUT_TP:-?}"
printf '%-30s %s\n' "Duracion total:" "$(awk -v d="$DURACION" 'BEGIN{printf "%.1f s", d}')"
printf '%-30s %s\n' "Respiraciones insertadas:" "${RESPIRACIONES:-0}"
printf '%-30s %s\n' "Silencios usados (s):" "${GAPS_USADOS:-}"
printf '%-30s %s\n' "Caracteres ElevenLabs:" "${CARACTERES:-0}"
printf '%-30s %s\n' "Texto ElevenLabs:" "$TXT"
echo "Listo para Audacity: agrega solo musica de fondo y efectos."

# limpiar reportes intermedios
rm -f -- "$TEMA/.pro-union.env" "$TEMA/.pro-cadena.env" "$TEMA/.pro-elevenlabs.env" "$TEMA/.pro-export.env"