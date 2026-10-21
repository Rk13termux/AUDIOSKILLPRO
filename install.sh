#!/usr/bin/env bash
# install.sh — instala la skill crear-audio (AUDIOSKILLPRO) en otro dispositivo.
#
# Copia (o enlaza) la skill a la carpeta de skills del agente, verifica las
# dependencias del pipeline y deja la ruta lista para generar audios.
#
# Uso:
#   ./install.sh                      # instala en ~/.claude/skills/crear-audio
#   ./install.sh --dest DIR           # instalacion personalizada
#   ./install.sh --link               # symlink en vez de copia (desarrollo)
#   ./install.sh --check              # solo verifica dependencias
#
# No requiere permisos de root. No escribe fuera de --dest.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.claude/skills/crear-audio"
MODO="copia"
SOLO_CHECK=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dest) DEST="${2:?--dest requiere una ruta}"; shift 2 ;;
        --link) MODO="link"; shift ;;
        --check) SOLO_CHECK=1; shift ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "[x] opcion desconocida: $1" >&2; exit 1 ;;
    esac
done

ok=0
avisos=0

check() {
    printf '%-22s' "$1"
    if command -v "$2" >/dev/null 2>&1; then
        echo "OK ($("$2" --version 2>/dev/null | head -1))"
    else
        echo "FALTA"
        avisos=$((avisos + 1))
    fi
}

echo "== Verificando dependencias =="
check "ffmpeg" ffmpeg
check "ffprobe" ffprobe
check "jq" jq
check "awk" awk
check "python3" python3

printf '%-22s' "tts-edge"
if command -v tts-edge >/dev/null 2>&1; then
    echo "OK ($(command -v tts-edge))"
elif [ -x "${HOME}/tts-edge/.venv/bin/tts-edge" ]; then
    echo "OK (${HOME}/tts-edge/.venv/bin/tts-edge)"
else
    echo "FALTA"
    avisos=$((avisos + 1))
fi

printf '%-22s' "edge-tts (opcional)"
if command -v edge-tts >/dev/null 2>&1; then
    echo "OK"
else
    echo "no instalado (necesario para tts-edge real)"
fi

printf '%-22s' "~/audio-breaths (opc.)"
if [ -d "${HOME}/audio-breaths" ]; then
    echo "OK"
else
    echo "no existe (se usan solo silencios)"
fi

printf '%-22s' "AZURE_SPEECH_KEY (opc.)"
if [ -n "${AZURE_SPEECH_KEY:-}" ]; then echo "definida"; else echo "no definida (fallback a tts-edge)"; fi

if [ "$SOLO_CHECK" -eq 1 ]; then
    echo
    [ "$avisos" -eq 0 ] && echo "[OK] dependencias completas." || echo "[!] $avisos dependencia(s) faltante(s)."
    exit 0
fi

echo
echo "== Instalando skill en: $DEST =="
if [ -e "$DEST" ]; then
    echo "[!] ya existe $DEST; no lo piso. Borra o mueve esa carpeta y reintenta." >&2
    exit 1
fi
mkdir -p "$(dirname "$DEST")"

if [ "$MODO" = "link" ]; then
    ln -s "$SRC_DIR" "$DEST"
    echo "[OK] symlink creado -> $SRC_DIR"
else
    mkdir -p "$DEST"
    cp -a "$SRC_DIR/SKILL.md" "$SRC_DIR/AGENTS.md" "$SRC_DIR/plantilla_guion.md" "$SRC_DIR/README.md" "$DEST/"
    cp -a "$SRC_DIR/scripts" "$DEST/"
    chmod +x "$DEST"/scripts/*.sh "$DEST"/scripts/phonetic-commands.py 2>/dev/null || true
    echo "[OK] copia instalada."
fi

AUDIO_ROOT="${AUDIO_ROOT:-${HOME}/SKILLAB/audio-project}"
echo
echo "== Raiz de trabajo de audios =="
echo "Los guiones y salidas viven en: $AUDIO_ROOT/audios/<tema>/"
echo "Crea la carpeta cuando generes el primer audio:"
echo "  mkdir -p \"$AUDIO_ROOT/audios\""
echo
echo "Listo. Invoca la skill como /crear-audio \"tu tema\"."
