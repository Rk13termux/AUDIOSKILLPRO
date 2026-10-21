# AGENTS.md — audio-project (skill `crear-audio` / AudioBlaze)

Pipeline de narración TTS + post-proceso con `ffmpeg`. No hay build, tests, lint
ni git. La verificación es correr el pipeline en una carpeta de `audios/` e
inspeccionar las salidas con `ffprobe`.

`SKILL.md`, `plantilla_guion.md` y el resto de la skill son contrato: no los
edites. `SKILL.md` es la definición de la skill; un cambio ahí requiere petición
explícita.

## Comando principal

`scripts/procesar.sh <carpeta-del-tema> [descripción]` orquesta todo el
post-proceso (unión lossless → cadena pro → master → exports → `texto-elevenlabs.txt`).
Requiere que ya existan las secciones `guion-NN-*.mp3|wav` en la carpeta.

Cada etapa se puede correr suelta: `convertir_secciones.sh`, `unir_pro.sh`,
`cadena_pro.sh`, `exportar.sh`, `texto_elevenlabs.sh`. Se comunican dejando
`<carpeta>/.pro-*.env`; `procesar.sh` los borra al final. No los escribas a mano.

## Flujo y contratos de nombres (congelados, no renombrar)

```
guion.md ──tts-edge──▶ guion-NN-*.mp3 ──▶ s0N.wav (48k mono f32)
s0N.wav ──unir_pro.sh──▶ guion-PRO.wav
guion-PRO.wav ──cadena_pro.sh──▶ guion-MASTER.wav (48k 24-bit, archival)
guion-MASTER.wav ──exportar.sh──▶ telegram.mp3 (160k mono) · pack.mp3 (320k estéreo)
```

Cero MP3 intermedios: solo el encode final por destino es lossy. Los encabezados
`##` son secciones y no se narran; el frontmatter tampoco.

## Comandos útiles

```bash
# Sintetizar secciones (ruta absoluta al guion; el CLI puede no estar en PATH)
tts-edge "$PWD/audios/<slug>/guion.md" --sections      # o $HOME/tts-edge/.venv/bin/tts-edge
tts-edge "$PWD/audios/<slug>/guion.md" --section N     # re-render de una sola sección

# Comandos/CLI: deletrear antes del TTS (apt→"a p t", --version→"guión guión version")
python3 scripts/phonetic-commands.py audios/<slug>/guion.md -o audios/<slug>/guion-phonetic.md

# Post-proceso completo
scripts/procesar.sh "$PWD/audios/<slug>" "<tema>"

# Masterizar un audio externo (misma CADENA PRO)
scripts/masterizar.sh <archivo.wav|mp3> [--modo oscuro|estandar] [--lufs N]
scripts/exportar.sh "$PWD/audios/<slug>" "pack,master"
```

Tras editar una sección con `--section`, re-corré `scripts/procesar.sh` para
regenerar las salidas. Si agregás/quitás secciones, usá `--sections`.

## Modos, voz y loudness

- Preset por defecto `marca` = `es-ES-AlvaroNeural`, `mode: oscuro`
  (rate `-16%`, pitch `-6Hz`, volume `-5%`, LUFS `-18`, TP `-1.5`).
- `mode: estandar` = cadena suave, LUFS `-16`, TP `-1.0`. Un `mode` distinto de
  `oscuro|estandar` aborta el script.
- El `lufs` del frontmatter gana sobre el modo. `gaps` (base de pausa, def. 0.9)
  rota `[base−0.2, base, base+0.2]`.
- `breaths: true` inserta `~/audio-breaths/breath-*.wav`; si no existe esa
  carpeta, usa solo silencios y avisa (no falla).

## Gotchas del entorno

- `tts-edge` NO está instalado aquí (`$HOME/tts-edge/.venv` vacío) y no hay
  `~/audio-breaths/`. Es un entorno de desarrollo: el post-proceso trabaja sobre
  secciones `mp3`/`wav` ya presentes. No asumas que hay síntesis disponible.
- `AZURE_SPEECH_KEY` (opcional) activa `scripts/azure_tts.sh` con salida 48k
  lossless; sin key cae a `tts-edge` sin error. Región por defecto `eastus`.
- Discrepancia conocida: prosa de `SKILL.md` menciona `es-VE-SebastianNeural`,
  pero scripts y `README.md` usan `es-ES-AlvaroNeural`. Confiá en los scripts.
- `scripts/procesar.sh:72` lee la duración de `guion-PRO.mp3` (legacy) antes de
  caer a `guion-MASTER.wav`; la duración que reporta es la del master.

## Glosario fonético de marca (solo capa TTS)

Aplicar con `scripts/sanitizar_tts.sh <voz> <seccion.txt>` ANTES de sintetizar;
`guion.md` conserva "AudioBlaze" escrito correcto. Nunca edites el guion para
"arreglar" la pronunciación.

| voz activa | AudioBlaze → |
|---|---|
| `es-ES-*` | AudioBléis |
| `es-VE-*`, `es-MX-*`, `es-CO-*`, `es-US-*` | AudioBleiz |
| `kokoro` | AudioBleis |

## Reglas de contenido

- Si `audios/<slug>/guion.md` ya existe, NO lo pises: reportá y preguntá.
- Audio de marca = español neutro, sin voseo ni modismos regionales.
- Números/porcentajes/fechas en palabras al redactar ("cien por ciento", no "100%").
- No mezcles técnicas ni agregues música/efectos/instrucciones dentro del cuerpo.
