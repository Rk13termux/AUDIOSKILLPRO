---
name: crear-audio
description: "Crea un audio de narracion por tema de programación, desarrollo, termux, comandos, tutoriales técnicos o educación en programación: redacta el guion (o toma uno pegado), lo guarda en audios/<tema>/ dentro de ~/SKILLAB/audio-project y genera un MP3 por seccion mas el completo con tts-edge. Post-procesa con ffmpeg (pausas variables, respiraciones opcionales, EQ/compresion y loudnorm de 2 pasos) y entrega guion-PRO.mp3 listo para Audacity + texto-elevenlabs.txt con su costo en caracteres. Usa: /crear-audio \"tema o guion\""
---

# crear-audio

Genera un audio de narracion profesional, robusta y animada para contenido
técnico de programación (tutoriales, comandos, Termux, scripts, desarrollo
web, Linux, APIs, etc.) mas su transcripcion, con el CLI `tts-edge` y un
post-proceso de terminal con `ffmpeg`. Enfatiza la pronunciación correcta
y profesional de comandos, términos técnicos, nombres de archivos, rutas
y sintaxis de código. Sin API keys ni costos. La salida queda masterizada
(loudness normalizado, EQ y compresion calibrados) lista para que el usuario
solo agregue musica/efectos en Audacity.

Cada tema vive en una carpeta propia bajo la raiz de audios del proyecto:

```
$AUDIO_ROOT/<tema-en-slug>/
    guion.md                  <- transcripcion completa (frontmatter no se narra)
    guion-01-intro.mp3        <- un mp3 por seccion (encabezados del guion)
    guion-02-nucleo.mp3
    ...
    guion.mp3                 <- union cruda (NO se toca; contrato vigente)
    guion-PRO.mp3             <- masterizado final (cadena pro, listo para Audacity)
    texto-elevenlabs.txt      <- texto narrable puro + costo en caracteres
```

Por defecto `AUDIO_ROOT` es `$HOME/SKILLAB/audio-project/audios`; puedes
cambiarlo con la variable de entorno `AUDIO_ROOT`.

## Dependencias

- `ffmpeg` (y `ffprobe`) en el PATH.
- `tts-edge` en el PATH o en `$HOME/tts-edge/.venv/bin/tts-edge`. En este
  entorno de desarrollo es un stub (no genera los mp3); en produccion genera
  `guion-NN-*.mp3` y `guion.mp3`. El post-proceso es el que hace el trabajo
  real sobre esas secciones.
- `jq`, `awk`, `wc` (vienen con el sistema).
- Opcional: `~/audio-breaths/breath-01.wav`, `breath-02.wav`, ... para
  insertar respiraciones entre secciones.

## Flujo general

1.  Recibi el pedido en `$ARGUMENTS`. Determiná el modo:

    -   **Modo tema** (texto corto y descriptivo, una frase): la skill redacta
        un guion poderoso siguiendo `plantilla_guion.md`.
    -   **Modo guion pegado** (texto largo, con encabezados `#` o varias frases
        completas): el texto ES el guion. Guardalo tal cual (limpiando si hace
        falta solo lo que no se narra, sin cambiar las palabras).

    Regla practica: si `$ARGUMENTS` contiene un encabezado `#`/`##` o tiene mas
    de ~400 caracteres con frases completas, es un guion pegado. Si es una
    breve descripcion de intencion, es un tema.

2.  Determiná el slug ASCII del tema:
    -   Modo tema: derivado del tema (ej: "afirmacion de confianza para hablar
        en publico" -> `confianza-publico`).
    -   Modo guion pegado: derivado del titulo del guion (si trae frontmatter
        `title:`) o de la segunda linea / primer encabezado. Si no hay nada
        claro, usa `audio-<fecha>`.
    Evitá caracteres no ascii en los nombres de carpeta y archivo.

3.  Creá la carpeta destino y confirmá que sea escribible:

    ```bash
    SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # o la carpeta de la skill instalada
    AUDIO_ROOT="${AUDIO_ROOT:-$HOME/SKILLAB/audio-project/audios}"
    mkdir -p "$AUDIO_ROOT/<slug>" || {
      echo "no se pudo escribir en $AUDIO_ROOT; uso local ./audios-psicologia"
      AUDIO_ROOT="$PWD/audios-psicologia"; mkdir -p "$AUDIO_ROOT/<slug>"; }
    ```

4.  Escribí `guion.md` dentro de la carpeta con frontmatter YAML (los campos
    nuevos son opcionales, con defaults):

    ```
    ---
    title: <titulo legible>
    voice: <preset marca|latino|neutro|calido|latina o voz edge-tts completa>
    mode: <opcional, oscuro|estandar (por defecto oscuro)>
    rate: <rate final (lo resuelve el preset; puede overridearse)>
    pitch: <pitch final (lo resuelve el preset; puede overridearse)>
    volume: <opcional, -5% en oscuro>
    purpose: <tema o texto dado>
    date: <fecha ISO>
    lufs: <opcional; oscuro -18, estandar -16, sueno -18>
    breaths: <opcional, true|false>
    gaps: <opcional, base de pausa en segundos, por defecto 0.9>
    glossary: <opcional, pares palabra->fonetica separados por comas>
    ---

    <cuerpo del guion, texto hablable, con la estructura de la plantilla>
    ```
    El cuerpo se narra tal cual. Los encabezados marcan las secciones pero no
    se narran.

    **Regla importante:** si `guion.md` ya existe en esa carpeta, NO lo pises.
    Reportá la ruta y preguntá si se regenera, se modifica una seccion o se
    crea otra carpeta.

5.  **Voices de marca y presets latinos** (resolvé la voz antes de
    sintetizar). El campo `voice` acepta un preset corto o un nombre edge-tts
    completo. El campo `mode` acepta `oscuro` (default) o `estandar`.
    Resolucion obligatoria:

| preset  | voz edge-tts           | rate  | pitch  | volume | uso |
|---------|------------------------|-------|--------|--------|-----|
| marca   | es-ES-AlvaroNeural     | -16% oscuro / -10% estandar | -6 Hz oscuro / -2 Hz estandar | -5% oscuro / +0 estandar | **DEFAULT**, toda la produccion de marca |
| tecnico  | es-ES-AlvaroNeural     | -14%  | -4 Hz  | +0     | explicaciones técnicas con mayor claridad |
| latino  | es-CO-GonzaloNeural    | -10%  | -2 Hz  | +0     | solo si se pide explícitamente |
| neutro  | es-US-AlonsoNeural     | -8%   | -3 Hz  | +0     | solo si se pide explícitamente |
| calido  | es-MX-JorgeNeural      | -12%  | -4 Hz  | +0     | solo si se pide explícitamente |
| latina  | es-CO-SalomeNeural     | -10%  | +0 Hz  | +0     | contenido femenino puntual |

    -   **MODO OSCURO (default)**: `mode: oscuro` = rate `-16%`, pitch `-6Hz`,
        volume `-5%` (grave, lento, cercano). Es el modo profesional por
        defecto para todo audio de marca.
    -   **MODO ESTANDAR**: `mode: estandar` = rate `-10%`, pitch `-2Hz`,
        volume `+0%` (para contenido suave diurno). La tabla de presets
        latinos usa estos parametros fijos.
    -   **Técnico detallado**: para comandos complejos, rate `-18%`, pitch
        `-6Hz` para mayor claridad al deletrear comandos técnicos.
    -   `es-MX-DaliaNeural` queda disponible SOLO si el usuario la pide
        explícitamente como alternativa femenina puntual.
    -   Si `voice` es un nombre edge-tts completo (ej: `es-CO-GonzaloNeural`),
        usalo tal cual con los parametros del preset que mas se le parezca
        (por defecto los de `marca`) o los que vengan en `rate`/`pitch`.
    -   Si el guion explicita `rate`/`pitch`/`volume` en el frontmatter, esos
        valores ganan sobre el modo.
    -   **Motor kokoro**: si `engine: kokoro` aparece en un guion de marca,
        avisá: "Kokoro no tiene la voz de marca Sebastian; se usara edge-tts
        para mantener coherencia" y usá edge-tts. Kokoro queda reservado para
        experimentos y voces alternativas, nunca para producto final de marca.
    -   **PROHIBIDO** usar otros `es-ES-*` (fuera de Alvaro), `es-AR-*`,
        `es-UY-*` como default o sugerencia. Prevalece la claridad y
        pronunciación profesional para contenido técnico.
    -   Duracion por defecto: 8 afirmaciones (~10-20 min a +0%).
    -   **LUFS**: modo oscuro -> `-18`; modo estandar -> `-16` (si el tema
        (frontmatter trae `lufs`, ese gana; tema de sueno siempre `-18`).
    -   **Breaths**: si `guion.md` trae `breaths: false`, no insertes
        respiraciones. Por defecto `true` (aplica solo si `~/audio-breaths/`
        existe y tiene `breath-*.wav`; si no, inserta solo silencios y avisá).
    -   **Gaps**: base de pausa entre secciones en segundos. Por defecto `0.9`.
        La rotacion determinista es `[base-0.2, base, base+0.2]` (con 0.9 → 0.7,
        0.9, 1.1).

6.  **GLOSARIO FONETICO DE MARCA — sanitizacion previa al TTS** (aplicar
    SIEMPRE antes de sintetizar). El `guion.md` conserva "AudioBlaze" escrito
    correcto; solo la capa TTS ve la forma fonetica. Separá el cuerpo en
    secciones (frontmatter y encabezados fuera) y pasá cada una por
    `scripts/sanitizar_tts.sh` con la voz activa:

    ```bash
    # <voz> = nombre de la voz edge-tts o kokoro que va a sintetizar
    bash "$SKILL_DIR/scripts/sanitizar_tts.sh" es-VE-SebastianNeural <seccion.txt> \
      > <seccion-tts.txt>
    ```

    Busqueda y reemplazo segun voz activa:

    | voz activa               | AudioBlaze → | AudioBlaze pro → |
    |--------------------------|--------------|------------------|
    | `es-ES-*`                | "AudioBléis" | "AudioBléis pro" |
    | `es-VE-*`                | "AudioBleiz" | "AudioBleiz pro" |
    | `es-MX-*`, `es-CO-*`, `es-US-*` | "AudioBleiz" | "AudioBleiz pro" |
    | `kokoro`                 | "AudioBleis" | "AudioBleis pro" |

    El script aplica ademas el campo `glossary` del frontmatter si lo hay.

7.  Ejecutá el CLI con las secciones YA sanitizadas, usando la ruta absoluta
    del guion:

    ```bash
    tts-edge "$AUDIO_ROOT/<slug>/guion.md" --sections   # ruta absoluta
    ```
    Si el CLI no esta en el PATH, usa
    `$HOME/tts-edge/.venv/bin/tts-edge`. Verificá que existan los
    `guion-NN-*.mp3`.

    **Alternativa de calidad** — si `AZURE_SPEECH_KEY` esta definido:
    `scripts/azure_tts.sh <guion.md> --sections` sintetiza con
    `es-VE-SebastianNeural` a **48 kHz lossless** (`raw-48khz-16bit-mono-pcm`),
    acepta SSML (breaks de seccion) y entrega `guion-NN-<seccion>.wav`
    (sin reencode). Sin la key cae a tts-edge sin error. Plan gratuito y
    obtencion de key: ver `README.md`.

8.  **POST-PROCESO PRO — LOSSLESS INTERNO** (siempre, incluso en este entorno
    de desarrollo):

    ```bash
    "$SKILL_DIR/scripts/procesar.sh" "$AUDIO_ROOT/<slug>" "<tema original>"
    ```

    Regla de calidad: **cero MP3 intermedios**. El master se procesa en WAV
    lossless de punta a punta; el unico encode lossy es el final por destino.
    El script orquesta y reporta:

    1.  **CONVERSION LOSSLESS** (`convertir_secciones.sh`): cada
        `guion-NN-*.mp3` se convierte UNA sola vez a `s01.wav`, `s02.wav`...
        (48 kHz mono float `pcm_f32le`, reutilizados). Si `azure_tts.sh`
        entrego `guion-NN-*.wav` 48k, los copia sin reencode.
    2.  **UNION PRO** (`unir_pro.sh`): une los `s0N.wav` con silencios
        variables deterministas (rotacion `[gaps-0.2, gaps, gaps+0.2]` con
        `ffmpeg anullsrc`) y, si aplica, una respiracion rotada de
        `~/audio-breaths/`. Sin breaths: usa solo silencios y avisa. Concatena
        → `guion-PRO.wav` (48k float). La union cruda `guion.mp3` queda
        intacta.
    3.  **CADENA PRO + MASTER** (`cadena_pro.sh`): opera sobre WAV y entrega
        **`guion-MASTER.wav`** (48 kHz 24-bit, LOSSLESS, archival) con
        loudnorm en DOS pasos. Cadena segun `mode` (default oscuro):
        -   **OSCURO** (modo profesional): `highpass=f=70,
            lowshelf=f=120:g=2.5, equalizer=f=3000:t=q:w=1:g=-2,
            highshelf=f=9500:g=-1,
            acompressor=threshold=0.0794:ratio=3:attack=15:release=120:makeup=2,
            deesser=i=0.05:m=0.29:f=0.7:s=o (de-ess dinamico 5-8 kHz,
            atenuacion max -3 dB),
            equalizer=f=4000:t=q:w=1.2:g=1.5 (presencia),
            alimiter=limit=0.87:attack=3:release=50:level=false (soft-clip
            sutil, umbral -1.2 dBTP)`, luego `aecho=0.8:0.7:18:0.12` y
            loudnorm `I=-18:TP=-1.5:LRA=11` (`print_format=json` medir;
            re-aplicar con `measured_*` + `linear=true`).
        -   **ESTANDAR** (contenido suave): `highpass=f=70, bass=g=1.5:f=150,
            equalizer=f=3200:t=q:w=1:g=-2, equalizer=f=6500:t=q:w=2:g=-1.5,
            acompressor=threshold=0.1:ratio=2.5:attack=15:release=120:makeup=2`
            con loudnorm `I=<lufs>:TP=-1.0:LRA=11`.
    4.  **EXPORTACION** (`exportar.sh`): desde `guion-MASTER.wav`, un encode
        final por destino (cada uno cuenta 1 generacion lossy):
        -   `telegram.mp3` → MP3 160k mono (`-ac 1 -b:a 160k`).
        -   `pack.mp3` → MP3 320k estéreo (`-ac 2 -b:a 320k`); para el pack
            final mezclá el master con el bed musical en Audacity y exportá.
        -   `master` → ya es `guion-MASTER.wav` 48k 24-bit (archival).
    5.  **SALIDA PREMIUM** (`texto_elevenlabs.sh`): genera `texto-elevenlabs.txt`
        (awk que quita frontmatter, encabezados `#` y lineas vacias) y guarda el
        `wc -m` del texto como "caracteres ElevenLabs: N".

    El modo y el LUFS los resuelve `procesar.sh` solo (oscuro → -18;
    estandar → -16; tema de sueno -18; `lufs` del frontmatter gana).

9.  Reportá al usuario la carpeta completa y:
    -   ruta de `guion-MASTER.wav` (master 48k 24-bit) y de
        `texto-elevenlabs.txt`,
    -   exports generados (`telegram.mp3`, `pack.mp3`) y **generaciones
        lossy = 1 por destino** (cero MP3 intermedios),
    -   modo (oscuro/estandar), LUFS final medido y true peak,
    -   duracion total,
    -   respiraciones insertadas (N) y silencios usados (valores),
    -   caracteres ElevenLabs (N),
    -   **preset usado + voz real + rate/pitch/volume aplicados**,
    -   **marca fonetica usada**: ej: "Marca fonetica: AudioBléis (es-ES)",
    -   una linea sobre el contenido,
    -   la linea: **"Listo para Audacity: agrega solo musica de fondo y
        efectos."**

    Y el checklist de **QA de oido** (para que el usuario escuche en el
    celular antes de publicar):

    ```
    [ ] Voz = Alvaro modo oscuro (grave, lento, cercano)
    [ ] Pronunciación correcta de comandos, rutas, nombres de archivo y términos técnicos
    [ ] Pausas adecuadas entre comandos, líneas y explicaciones
    [ ] Ritmo dinámico sin prisa, sin arrastrar
    [ ] Sin muletillas, sin tono infantil ni exagerado
    [ ] LUFS -18 medido en archivo PRO
    ```

    Regla de consistencia: cualquier audio de marca generado con otra voz
    debe marcarse en el reporte como **"VOZ NO ESTÁNDAR"** con el motivo.
    Para contenido técnico de programación, priorizar siempre claridad
    en la pronunciación de comandos sobre dramatización.

    Si el usuario reporta acento extrano, sugerile cambiar de preset
    (marca <-> latino <-> neutro) y re-renderizar solo las secciones
    (`--section` o `--sections`).

    Si el CLI falla, mostrá el codigo de salida y el mensaje tal cual.

## Modificar una seccion (edicion sin rehacer todo)

Cuando el usuario pide cambiar parte de un audio ya creado:

1.  Ubicá la carpeta del tema en `$AUDIO_ROOT/` (por defecto
    `$HOME/SKILLAB/audio-project/audios/`; usa el slug o `ls` para ver los
    temas existentes).
2.  Abri `guion.md`, localiza la seccion por su encabezado (ej: `## Nucleo`) y
    aplica el cambio en SU cuerpo solamente. No cambies otras secciones.
3.  Fijate que numero de seccion es (orden del encabezado en el archivo,
    contando desde 1; el encabezado puede nombrarlos todos para orientarte).
4.  Re-rendí solo esa parte:

    ```bash
    tts-edge "$AUDIO_ROOT/<slug>/guion.md" --section N
    ```

    Eso reconstruye el `guion.mp3` reusando las demas secciones sin
    descargarlas de nuevo. **Despues, re-corre el POST-PROCESO PRO**
    (`scripts/procesar.sh`) para regenerar `guion-PRO.mp3` y
    `texto-elevenlabs.txt`.

Si se agrega o elimina una seccion completa, re-corre `--sections` (regenera
todas). Para avisar que el numero de seccion cambio, el CLI lo reporta si
pediste una inexistente.

## MODO EXTRA: masterizar un archivo suelto

Aplica la misma CADENA PRO (paso 3) a cualquier audio externo (ej: una toma de
ElevenLabs) y entrega `<base>-MASTER.wav` (48 kHz 24-bit, LOSSLESS):

```bash
bash "$SKILL_DIR/scripts/masterizar.sh" <archivo.wav|mp3> [--modo oscuro|estandar] [--lufs N]
```

Default `--modo oscuro` (LUFS -18, TP -1.5). `--modo estandar` usa la cadena
suave (LUFS -16, TP -1.0). Asi la cadena premium sirve para la linea
ElevenLabs sin rehacer nada.

## Reglas de calidad

-   El guion tiene que sonar escrito para ser oido, no leido: frases pensadas
    para respirar y pausar.
-   Manten un foco unico por audio. Un tema = un guion.
-   No mezcles tecnicas. Si el tema es una afirmacion, todo el guion refuerza
    esa afirmacion sin divagar.
-   No agregues musica, efectos ni instrucciones tecnicas dentro del cuerpo:
    el cuerpo se narra tal cual.
-   Numeros, porcentajes, fechas y horas: escribilos con palabras mientras
    redactas para que nazcan hablables ("cien por ciento", no "100%").
-   **Texto neutro, sin modismos de ningun pais**: el guion se escribe en
    tuteo neutro latino, sin castellanismos ("vosotros", "ordenador",
    "movil"), sin voseo ni modismos de Espana o LatAm. La distincion c/z de
    la voz de marca Alvaro es fonetica de la voz, no del texto: no intentar
    "compensarla" escribiendo raro. Aplica el glosario fonetico y el campo
    `glossary` del frontmatter antes de sintetizar. Detalle completo en
    `plantilla_guion.md` (bloque "Pronunciacion y acento").
-   **ESTILO TÉCNICO - PROGRAMACIÓN** (modo tema): frases claras y concisas
    (10-18 palabras máx), punto = pausa. Explica antes de ejecutar comandos.
    Usa terminología precisa. Pronuncia comandos entre backticks con claridad.
    Ritmo dinámico, profesional, robusto y animado. Define términos técnicos
    la primera vez que aparecen. Sin exclamaciones, sin tono infantil.
    **Prioriza siempre claridad en la pronunciación de comandos y sintaxis.**
-   **NO TOCAR**: los contratos de nombres (`guion-NN-*.mp3|wav`,
    `guion.mp3`, `guion-PRO.wav`, `guion-MASTER.wav`, `telegram.mp3`,
    `pack.mp3`), el modo tema/guion pegado, los fallbacks de `AUDIO_ROOT` y
    estas reglas de redaccion. `unir_pro.sh` (union y breaths) ya opera con
    WAV lossless. El post-proceso nunca edita los mp3/audios de seccion ni la
    union cruda, y no genera MP3 intermedios.

## Recordatorios al redactar (modo tema)

-   Escribi con palabras los numeros y porcentajes cuando sea más claro.
-   Sin emojis, sin abreviaturas ambiguas, sin siglas sin expandir (o expándelas).
-   Frases cortas terminadas en punto. Punto = pausa para respirar.
-   **Para comandos técnicos**: muéstralos entre backticks. Deja pausas al leer flags y argumentos.
-   **Claridad sobre velocidad**: prioriza siempre la pronunciación correcta.
-   Sugerencias para un guion técnico profesional: dejo la estructura en
    `plantilla_guion.md` (mismo directorio).
## AGENTE ESPECIALISTA EN PRONUNCIACIÓN DE COMANDOS

Para obtener una pronunciación profesional "elite" de comandos técnicos, se integra un agente fonético:

- `scripts/phonetic-commands.py`: mapea comandos CLI a su forma deletreada/pronunciable
- Detecta: `apt`, `npm`, `npx`, `nodejs`, `pkg`, `curl`, `wget`, `chmod`, `chown`, `git`, `ssh`, `scp`, `python3`, `pip3`, etc.
- Flags: `--version` → "guión guión version", `-la` → "guión la"
- Rutas: separa `/` con pausas naturales
- Aplicar **SIEMPRE** antes de sintetizar con tts-edge cuando el guion contenga comandos

Uso recomendado:
```bash
python3 scripts/phonetic-commands.py guion.md -o guion-phonetic.md
tts-edge guion-phonetic.md --sections
```

**Regla de oro**: Alvaro debe leer los comandos deletreados (a p t, n p m, n o d e j s) para sonar como un programador profesional.
