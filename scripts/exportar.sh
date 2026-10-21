#!/usr/bin/env bash
# EXPORTAR — encodes finales por destino a partir de guion-MASTER.wav.
# Cada destino = UN solo encode lossy (generaciones lossy se cuentan aqui).
#
# Uso: exportar.sh <carpeta-del-tema> [tiers: telegram,pack]
#   tiers (separados por coma):
#     telegram -> telegram.mp3   MP3 160k mono     (-ac 1 -b:a 160k)
#     pack     -> pack.mp3       MP3 320k estereo  (-ac 2 -b:a 320k)
#     master   -> ninguno (guion-MASTER.wav 48k 24-bit ya existe = archival)
#   El tier pack se mezcla con el bed musical en Audacity/ffmpeg antes de
#   exportar; aqui se exporta desde el master al estéreo 320k.
# Escribe <carpeta>/.pro-export.env (TIERS, GENERACIONES_LOSSY).
set -euo pipefail

TEMA="${1:?uso: exportar.sh <carpeta-del-tema> [tiers: telegram,pack]}"
TIERS_STR="${2:-telegram,pack}"
MASTER="$TEMA/guion-MASTER.wav"

[ -f "$MASTER" ] || { echo "[✗] falta guion-MASTER.wav en $TEMA (corre cadena_pro.sh)" >&2; exit 1; }

IFS=',' read -ra TIERS <<< "$TIERS_STR"
lossy=0
declared=()
for t in "${TIERS[@]}"; do
    case "$t" in
        telegram)
            ffmpeg -hide_banner -loglevel error -y -i "$MASTER" -ac 1 -b:a 160k "$TEMA/telegram.mp3"
            lossy=$((lossy + 1)); declared+=("telegram")
            echo "[+] export telegram → $TEMA/telegram.mp3 (MP3 160k mono)" >&2
            ;;
        pack)
            ffmpeg -hide_banner -loglevel error -y -i "$MASTER" -ac 2 -b:a 320k "$TEMA/pack.mp3"
            lossy=$((lossy + 1)); declared+=("pack")
            echo "[+] export pack → $TEMA/pack.mp3 (MP3 320k estereo)" >&2
            ;;
        master)
            declared+=("master")
            echo "[+] export master → $TEMA/guion-MASTER.wav (WAV 48k 24-bit, archival)" >&2
            ;;
        *)
            echo "[✗] tier desconocido: '$t' (telegram|pack|master)" >&2
            exit 1
            ;;
    esac
done

cat > "$TEMA/.pro-export.env" <<EOF
TIERS=$(IFS=,; echo "${declared[*]}")
GENERACIONES_LOSSY=$lossy
EOF

echo "[+] export OK → tiers: $(IFS=,; echo "${declared[*]}") · generaciones lossy: $lossy" >&2