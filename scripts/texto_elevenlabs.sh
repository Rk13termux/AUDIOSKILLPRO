#!/usr/bin/env bash
# SALIDA PREMIUM: genera texto-elevenlabs.txt con el texto narrable puro del
# guion.md (sin frontmatter, sin encabezados #, sin lineas vacias) e imprime
# la cantidad de caracteres.
#
# Uso: texto_elevenlabs.sh <carpeta-del-tema>
set -euo pipefail

TEMA="${1:?uso: texto_elevenlabs.sh <carpeta-del-tema>}"
GUION="$TEMA/guion.md"
OUT="$TEMA/texto-elevenlabs.txt"
[ -f "$GUION" ] || { echo "[✗] falta $GUION" >&2; exit 1; }

awk '
    BEGIN { fm = 0 }
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 { next }               # cuerpo del frontmatter
    /^#/ { next }                  # encabezados (secciones) no se narran
    /^[[:space:]]*$/ { next }      # lineas vacias
    { gsub(/[[:space:]]+/, " "); print }
' "$GUION" > "$OUT"

CARACTERES="$(wc -m < "$OUT" | tr -d ' ')"
echo "CARACTERES=$CARACTERES" > "$TEMA/.pro-elevenlabs.env"
echo "[+] texto-elevenlabs.txt → $OUT ($CARACTERES caracteres)" >&2