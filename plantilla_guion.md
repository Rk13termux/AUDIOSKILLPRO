# Plantilla de guion para crear-audio - Contenido de Programación

Estructura base. Cada seccion va como encabezado markdown (no se narra) y el
contenido debajo es texto hablable que se narra tal cual.

Recuerda: el guion se ESCUCHA. Escribi para una voz profesional, clara, robusta
y animada. Prioriza la **pronunciación correcta de comandos, rutas, nombres de
archivos, términos técnicos y sintaxis** sobre cualquier dramatización.

## Frontmatter (presets de voz latina)

```yaml
---
title: <titulo legible>
voice: marca          # marca|tecnico|latino|neutro|calido|latina o nombre edge-tts completo
mode: oscuro          # oscuro (default) | estandar
rate: -10%            # oscuro -10% / estandar -6% (lo resuelve el preset; puede overridearse)
pitch: +1Hz           # oscuro +1Hz / estandar +0Hz
volume: +0%           # oscuro +0% / estandar +0
lufs: -18             # oscuro -18 / estandar -16 / explicativo siempre -18
breaths: true         # opcional: inserte respiraciones de ~/audio-breaths si existen
gaps: 0.9             # opcional: base de pausa entre secciones (rotacion base±0.2)
glossary:      # opcional: pares palabra->fonetica separados por comas
  AudioBleiz: audio bleiz
---
```

## Apertura (2-4 frases)

- Presenta el tema de forma clara y profesional: explica qué se va a aprender.
- Nombra el objetivo del tutorial en una línea, sin ambigüedad.
- Usa tono directo, didáctico y animado. Genera interés sin exagerar.
- Gancho de entrada: una frase corta que sitúe al oyente en el contexto técnico.
- **Enfoque práctico**: establece el alcance y qué necesita el oyente (herramientas, entorno).

## El núcleo del contenido (explicación paso a paso)

Cada idea o instrucción por párrafo. Características para contenido técnico narrado:

- **Claridad ante todo**: frases concisas y bien estructuradas. Máximo 15-20 palabras por frase.
- **Pronunciación deliberada**: al leer comandos, sílaba cada elemento clave. Separa comandos largos con pausas naturales.
- **Enfoque práctico**: explica QUÉ hace el comando y POR QUÉ se usa, cuando es relevante.
- **Terminología correcta**: usa nombres exactos de comandos, flags, rutas y archivos.
- **Ritmo dinámico**: alterna entre explicación conceptual y ejemplo práctico.
- **Pausas estratégicas**: punto = pausa. Comas para separar argumentos.
- **Para comandos**: lee carácter a carácter cuando hay guiones, mayúsculas o símbolos críticos (ej: `chmod +x`, `ls -la`, `pkg install`).

Ejemplos de ritmo para contenido técnico:
  - "Vamos a ver cómo instalar los paquetes necesarios."
  - "El comando `pkg update && pkg upgrade` actualiza los repositorios."
  - "Presta atención a la ruta de destino."
  - "Este comando crea el directorio con todos sus permisos correctos."

## Cierre (2-4 frases)

- Resume los puntos clave de forma concisa.
- Reafirma lo aprendido o el siguiente paso práctico.
- Termina con una frase clara y profesional que invite a la práctica.
- Cierre natural, directo y útil para el oyente.

## Pronunciacion y acento (al redactar, siempre)

El audio de marca se narra con la voz **Alvaro** (es-ES-AlvaroNeural, español
castellano) en **modo oscuro** por defecto (rate -16%, pitch -6Hz, volume -5%).
Es una voz profesional, grave y clara, ideal para contenido técnico.
La voz pone el acento; el texto NO debe sumar modismos de ningún país.

-   **Enfoque en pronunciación técnica**: Sebastian pronuncia muy claro.
    Al redactar comandos, mantené el nombre exacto (ej: `git`, `npm`, `curl`, `chmod`).
-   **Comandos y sintaxis**: lee los comandos entre backticks tal como son.
    Para flags con guiones (`--version`, `-la`), pronuncia "guión guión versión",
    "guión la" o léelos de forma clara y pausada.
-   **Rutas y archivos**: pronuncia rutas como `/home/user/` separando directorios
    con pausas naturales. Nombres con guiones bajos o puntos: léelos claramente.
-   **Prohibido voseo y modismos regionales**: nada de "vos", "che", "parcero",
    "guey", "boludo". Usa español neutro, profesional y claro.
-   **Glosario fonetico de marca** (se aplica SOLO a la capa TTS via
    `scripts/sanitizar_tts.sh`, nunca editando el guion):
      voz es-ES-*          -> AudioBlaze = "AudioBléis"
      voz es-VE-*          -> AudioBlaze = "AudioBleiz"
      voz es-MX/es-CO/es-US -> AudioBlaze = "AudioBleiz"
      kokoro               -> AudioBlaze = "AudioBleis"
      variantes            -> "AudioBlaze pro" = "AudioBleiz pro"
-   Glosario general (aplicar al redactar el cuerpo):
      link        -> "enlace"
      email       -> "correo electrónico"
      URL         -> "U R L" o "dirección web"
      API         -> "A P I"
      CLI         -> "C L I"
      JSON        -> "J S O N"
      HTML        -> "H T M L"
      CSS         -> "C S S"
      repo        -> "repositorio"
      commit      -> "commit"
      push        -> "push"
      pull        -> "pull"
      merge       -> "merge"
      script      -> "script"
      path        -> "ruta"
      terminal    -> "terminal"
      shell       -> "shell"
-   Campo opcional `glossary` en el frontmatter: agrega pares
    palabra->fonetica propios del tema; la skill los aplica al cuerpo antes de
    sintetizar.
-   Números y versiones: lee "versión uno punto dos punto tres" para `1.2.3`.

## Recordatorios de pronunciación (al redactar contenido técnico)

- **Comandos entre backticks**: mantenlos exactos. No los "traduzcas".
- **Explica antes de ejecutar**: describe qué hace el comando antes de leerlo.
- **Pausas para sintaxis**: deja pausas entre comando, opciones y argumentos.
- **Sin abreviaturas ambiguas** sin explicar previamente.
- **Sin markdown en el cuerpo** (el CLI limpia encabezados y énfasis, pero el
  guion debe nacer limpio).
- **Frases cortas y claras** terminadas en punto. Punto = pausa.
- **Prioriza claridad**: es mejor una pausa extra que una pronunciación apresurada.
- **Términos técnicos**: defínelos brevemente la primera vez que aparecen.
- **Para Termux/Linux**: pronuncia comandos con precisión, enfatizando rutas y permisos.