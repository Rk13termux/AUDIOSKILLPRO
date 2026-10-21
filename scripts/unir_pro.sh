#!/usr/bin/env bash
# UNIÓN PRO: une las secciones de un tema (ya convertidas a WAV 48k float en
# s01.wav, s02.wav... por convertir_secciones.sh) en guion-PRO.wav (48k float),
# insertando silencios variables (rotacion determinista) y, si existen,
# respiraciones de ~/audio-breaths/breath-*.wav.
#
# Uso: unir_pro.sh <carpeta-del-tema> [gaps] [breaths:true|false]
# - gaps:       base del silencio en segundos (default 0.9). La rotacion es
#               [base-0.2, base, base+0.2].
# - breaths:    si true y ~/audio-breaths/ tiene WAVs, inserta respiraciones.
# Deja el reporte en <carpeta>/.pro-union.env (RESPIRACIONES, GAPS_USADOS).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMA="${1:?uso: unir_pro.sh <carpeta-del-tema> [gaps] [breaths] }"
GAPS_BASE="${2:-0.9}"
BREATHS_ON="${3:-true}"
case "$GAPS_BASE" in *[!0-9.,-]*|"") echo "[✗] gaps invalido: '$GAPS_BASE'"; exit 1 ;; esac

BREATHS_DIR="$HOME/audio-breaths"
TMP="$TEMA/.pro-tmp"
LIST="$TMP/list.txt"
mkdir -p "$TMP"
trap 'rm -rf -- "$TMP"' EXIT

# Asegura la conversion única de las secciones crudas a WAV 48k float.
bash "$SCRIPT_DIR/convertir_secciones.sh" "$TEMA"

mapfile -t SECS < <(ls -1v "$TEMA"/guion-[0-9][0-9]-*.mp3 "$TEMA"/guion-[0-9][0-9]-*.wav 2>/dev/null \
    | grep -v -E -- 's[0-9]+\.wav|-PRO\.|-MASTER\.' || true)
if [ "${#SECS[@]}" -eq 0 ]; then
    echo "[✗] no hay secciones guion-NN-* en $TEMA" >&2
    exit 1
fi
N="${#SECS[@]}"
echo "[+] union pro: $N secciones en $TEMA" >&2

BREATHS=()
if [ "$BREATHS_ON" = true ] && [ -d "$BREATHS_DIR" ]; then
    mapfile -t BREATHS < <(ls -1v "$BREATHS_DIR"/breath-*.wav 2>/dev/null || true)
    if [ "${#BREATHS[@]}" -eq 0 ]; then
        echo "[!] ~/audio-breaths no tiene breath-*.wav; uso solo silencios" >&2
        BREATHS=()
    else
        echo "[+] respiraciones encontradas: ${#BREATHS[@]} en $BREATHS_DIR" >&2
    fi
elif [ "$BREATHS_ON" = true ]; then
    echo "[!] no existe ~/audio-breaths; uso solo silencios" >&2
fi

# Rotacion determinista de silencios alrededor de la base.
gap_rot() {
    local i="$1" base="$2"
    local vals=(-0.2 0 0.2)
    awk -v b="$base" -v o="${vals[$((i % 3))]}" 'BEGIN{printf "%.3f", b+o}'
}

n_breath=0
gap_list=()
echo "" > "$LIST"
for i in "${!SECS[@]}"; do
    sec="${SECS[$i]}"
    nnum="$(basename "$sec" | sed -E 's/^guion-([0-9]{2}).*/\1/')"
    wav="$TEMA/s$nnum.wav"
    if [ -f "$wav" ]; then
        printf 'file '\''%s'\''\n' "$wav" >> "$LIST"
    else
        echo "[✗] falta el wav lossless $wav (corre convertir_secciones.sh)" >&2
        exit 1
    fi

    # Hueco ENTRE secciones (no despues de la ultima).
    if [ "$i" -lt $((N - 1)) ]; then
        gap="$(gap_rot "$i" "$GAPS_BASE")"
        gap_list+=("$gap")
        ffmpeg -hide_banner -loglevel error -y -f lavfi \
            -i "anullsrc=r=48000:cl=mono" -t "$gap" \
            -c:a pcm_f32le "$TMP/sil.wav" || exit 1
        mv "$TMP/sil.wav" "$TMP/sil-$nnum.wav"
        printf 'file '\''%s'\''\n' "$TMP/sil-$nnum.wav" >> "$LIST"

        # Respiración rotada entre el silencio y la siguiente sección.
        if [ "${#BREATHS[@]}" -gt 0 ]; then
            bidx=$((n_breath % ${#BREATHS[@]}))
            breath="${BREATHS[$bidx]}"
            bnum="$(printf '%02d' "$n_breath")"
            ffmpeg -hide_banner -loglevel error -y -i "$breath" -ar 48000 -ac 1 \
                -sample_fmt flt -c:a pcm_f32le "$TMP/breath-$bnum.wav" \
                || { echo "[✗] no pude convertir $breath" >&2; exit 1; }
            printf 'file '\''%s'\''\n' "$TMP/breath-$bnum.wav" >> "$LIST"
            n_breath=$((n_breath + 1))
        fi
    fi
done

if ! ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i "$LIST" -c:a pcm_f32le \
    -ar 48000 -ac 1 "$TEMA/guion-PRO.wav"; then
    echo "[✗] fallo el concat de la union pro" >&2
    exit 1
fi

cat > "$TEMA/.pro-union.env" <<EOF
RESPIRACIONES=$n_breath
GAPS_USADOS=$(IFS=,; echo "${gap_list[*]}")
EOF

echo "[+] union pro OK → guion-PRO.wav (48k f32, respiraciones: $n_breath, silencios: ${#gap_list[@]})" >&2