# AUDIOSKILLPRO

Skill `crear-audio` de AudioBlaze: convierte un tema (o un guion pegado) en un
audio narrado y masterizado, más el texto para ElevenLabs. Español neutro, voz
de marca `es-ES-AlvaroNeural`, post-proceso LOSSLESS con `ffmpeg` y exportes por
destino.

Sin API keys obligatorias y sin costos: la síntesis va con `tts-edge`
(`edge-tts`), y Azure es un módulo opcional.

## Qué incluye

```
SKILL.md                  definición y flujo de la skill
AGENTS.md                 contrato operativo del pipeline
plantilla_guion.md        plantilla de estructura del guion
install.sh                instalador + verificador de dependencias
scripts/
    procesar.sh               orquestador del post-proceso
    convertir_secciones.sh    secciones a WAV 48k mono float (sin reencode)
    unir_pro.sh               unión con silencios variables + respiraciones
    cadena_pro.sh             EQ/compresión/de-ess/limiter + loudnorm (2 pasos)
    lib_audio.sh              cadenas oscura y estándar (compartida)
    exportar.sh               encodes finales por destino
    masterizar.sh             aplicar la cadena a un audio suelto
    sanitizar_tts.sh          glosario fonético de marca
    azure_tts.sh              módulo opcional Azure 48k lossless
    texto_elevenlabs.sh       genera texto-elevenlabs.txt + conteo de caracteres
    phonetic-commands.py      deletreado de comandos CLI para el TTS
audios/                   guiones de ejemplo (solo .md; el audio no se versiona)
```

## Instalación en otro dispositivo

```bash
git clone https://github.com/Rk13termux/AUDIOSKILLPRO.git
cd AUDIOSKILLPRO
./install.sh --check     # verifica ffmpeg, jq, python3 y tts-edge
./install.sh             # copia la skill a ~/.claude/skills/crear-audio
```

- `./install.sh --dest DIR` instala en otra carpeta.
- `./install.sh --link` crea un symlink en vez de copiar (útil si editas la skill).
- `./install.sh --check` solo verifica dependencias, sin instalar nada.

### Dependencias

| Dependencia | Para qué | Cómo |
|---|---|---|
| `ffmpeg` / `ffprobe` | todo el post-proceso | `pkg install ffmpeg` · `apt install ffmpeg` |
| `jq` | leer la medición de loudnorm | `pkg install jq` |
| `python3` | `phonetic-commands.py` | `pkg install python` |
| `edge-tts` | motor de síntesis real | `pip install edge-tts` |
| `tts-edge` | CLI que usa la skill | adaptador sobre `edge-tts` (ver abajo) |
| `~/audio-breaths/breath-*.wav` | respiraciones opcionales | opcional: sin la carpeta se usan solo silencios |
| `AZURE_SPEECH_KEY` | síntesis 48k lossless opcional | ver sección Azure |

#### tts-edge

La skill invoca `tts-edge "$AUDIO_ROOT/<slug>/guion.md" --sections`. Ese CLI es
un adaptador que parsea el frontmatter (`voice`, `rate`), parte el guion por
encabezados `##` y llama a `edge-tts` sección por sección.

- Búscalo en el `PATH` o en `$HOME/tts-edge/.venv/bin/tts-edge`.
- Si no lo tienes, instala primero `edge-tts` (`pip install edge-tts`) y crea un
  wrapper propio que respete el contrato: una salida por sección y `--sections`
  como opción obligatoria.

## Pipeline (LOSSLESS interno)

```
guion.md ──tts-edge──▶ guion-NN-*.mp3 ──▶ s0N.wav (48k mono f32)
s0N.wav ──unir_pro.sh──▶ guion-PRO.wav
guion-PRO.wav ──cadena_pro.sh──▶ guion-MASTER.wav (48k 24-bit, archival)
guion-MASTER.wav ──exportar.sh──▶ telegram.mp3 (160k mono) · pack.mp3 (320k estéreo)
```

Regla de calidad: **cero MP3 intermedios**. El master se procesa en WAV
lossless de punta a punta; el único encode lossy es el final, uno por destino.

## Uso

```bash
# Ruta de trabajo de los audios (por defecto $HOME/SKILLAB/audio-project/audios)
export AUDIO_ROOT="${AUDIO_ROOT:-$HOME/SKILLAB/audio-project/audios}"
mkdir -p "$AUDIO_ROOT/mi-tema"
# ... escribe guion.md siguiendo plantilla_guion.md ...

# 1. Comandos/CLI: deletrear antes del TTS (opcional pero recomendado)
python3 scripts/phonetic-commands.py "$AUDIO_ROOT/mi-tema/guion.md" \
    -o "$AUDIO_ROOT/mi-tema/guion-phonetic.md"

# 2. Síntesis por secciones
tts-edge "$AUDIO_ROOT/mi-tema/guion.md" --sections

# 3. Post-proceso completo (unión → cadena → exports → texto ElevenLabs)
scripts/procesar.sh "$AUDIO_ROOT/mi-tema" "mi tema"

# Masterizar un audio externo con la misma cadena
scripts/masterizar.sh toma.wav --modo oscuro
```

Al terminar quedan: `guion-MASTER.wav` (48k 24-bit), `telegram.mp3`,
`pack.mp3` y `texto-elevenlabs.txt` con el conteo de caracteres.

## Modos, voz y loudness

- Preset por defecto `marca` = `es-ES-AlvaroNeural`, `mode: oscuro`
  (rate `-16%`, pitch `-6Hz`, volume `-5%`, LUFS `-18`, TP `-1.5`).
- `mode: estandar` = cadena suave, LUFS `-16`, TP `-1.0`.
- Un `mode` distinto de `oscuro|estandar` aborta el script.
- El `lufs` del frontmatter gana sobre el modo.
- `gaps` (base de pausa, por defecto `0.9`) rota `[base−0.2, base, base+0.2]`.
- `breaths: true` inserta `~/audio-breaths/breath-*.wav`; si la carpeta no
  existe, usa solo silencios y avisa (no falla).

## Glosario fonético de marca

Se aplica solo a la capa TTS con `scripts/sanitizar_tts.sh <voz> <seccion.txt>`,
antes de sintetizar. El `guion.md` conserva `AudioBlaze` escrito correcto.

| voz activa | AudioBlaze → |
|---|---|
| `es-ES-*` | AudioBléis |
| `es-VE-*`, `es-MX-*`, `es-CO-*`, `es-US-*` | AudioBleiz |
| `kokoro` | AudioBleis |

## Módulo Azure opcional

Si defines `AZURE_SPEECH_KEY`, `scripts/azure_tts.sh` sintetiza cada sección a
**48 kHz lossless** (`raw-48khz-16bit-mono-pcm`). Sin la key cae a `tts-edge`
sin error.

- Plan gratuito: unos ~500 000 caracteres/mes en la región `eastus`.
- Cómo obtener la key: portal.azure.com → crear recurso **Speech** → plan
  **F0 (Free)** → "Claves y endpoint" → copiar `KEY 1` y la región.

```bash
export AZURE_SPEECH_KEY="<tu-key>"
export AZURE_SPEECH_REGION="eastus"     # opcional
bash scripts/azure_tts.sh "$AUDIO_ROOT/mi-tema/guion.md" --sections
```

Las salidas son `guion-NN-<seccion>.wav` 48k; el pipeline las copia a `s0N.wav`
sin reencode.

## Notas

- Los audios (`*.mp3`, `*.wav`, `*.vtt`) **no** se versionan: son productos
  regenerables y pesados. El repo guarda los guiones.
- `audios/` incluye dos guiones técnicos de ejemplo:
  `instalar-npm-termux` y `parrot-os-alpine-termux`.
- Ninguna credencial vive en el repo: el `.gitignore` excluye `.env`,
  `.git-credentials` y similares.
- La cadena de post-proceso es español neutro, sin voseo ni modismos regionales.
