#!/usr/bin/env bash
# Libreria compartida: cadenas de filtros "CADENA PRO" (estandar y oscura)
# + loudnorm en 2 pasos. Usada por cadena_pro.sh y masterizar.sh.

# Cadena estandar (contenido suave diurno).
FILTROS_ESTANDAR="highpass=f=70,bass=g=1.5:f=150,equalizer=f=3200:t=q:w=1:g=-2,equalizer=f=6500:t=q:w=2:g=-1.5,acompressor=threshold=0.1:ratio=2.5:attack=15:release=120:makeup=2"

# Cadena oscura (modo profesional / audio de marca).
# lowshelf 120 Hz +2.5 dB, peaking 3000 Hz -2 dB, highshelf 9500 Hz -1 dB,
# compresion 3:1 umbral -22 dB, de-ess dinamico 5-8 kHz (atenuacion max -3 dB),
# presencia +1.5 dB @ 4 kHz Q=1.2, soft-clip sutil umbral -1.2 dBTP.
# El aecho (AECHO_OSCURO) se inserta justo antes del loudnorm.
FILTROS_OSCURO="highpass=f=70,lowshelf=f=120:g=2.5,equalizer=f=3000:t=q:w=1:g=-2,highshelf=f=9500:g=-1,acompressor=threshold=0.0794:ratio=3:attack=15:release=120:makeup=2,deesser=i=0.05:m=0.29:f=0.7:s=o,equalizer=f=4000:t=q:w=1.2:g=1.5,alimiter=limit=0.87:attack=3:release=50:level=false"
AECHO_OSCURO="aecho=0.8:0.7:18:0.12"

# TPs por modo: oscuro -1.5, estandar -1.0.
tp_por_modo() { [ "${1:-oscuro}" = "oscuro" ] && echo "-1.5" || echo "-1.0"; }

# aplicar_cadena_pro <entrada> <salida> <lufs> [tp] [modo]
#   lufs: target (default: oscuro -18, estandar -16)
#   tp:   true peak (por defecto segun modo)
#   modo: oscuro | estandar (default oscuro)
# - La salida es LOSSLESS: si se pasa salida .wav, entrega 48 kHz 24-bit
#   (pcm_s24le); si se pasa .mp3, ese es el encode final (192k).
# - Mide loudness (paso 1, print_format=json) y re-aplica con measured_* + linear=true (paso 2).
# - Exporta OUTPUT_I (LUFS final) y OUTPUT_TP (true peak final).
aplicar_cadena_pro() {
    local src="$1" out="$2" lufs="${3:-}" tp="${4:-}" modo="${5:-oscuro}"
    local dir_json measure measure2 measurements input_i input_tp input_lra input_thresh target_offset
    local af_aux json_out tp_default enc_out

    [ -f "$src" ] || { echo "[✗] no existe la entrada: $src" >&2; return 1; }
    case "$modo" in oscuro|estandar) ;; *) echo "[✗] modo invalido '$modo' (oscuro|estandar)" >&2; return 1 ;; esac

    tp_default="$(tp_por_modo "$modo")"
    tp="${tp:-$tp_default}"
    if [ -z "$lufs" ]; then lufs="$([ "$modo" = oscuro ] && echo -18 || echo -16)"; fi
    case "$lufs" in *[!0-9,-.]*|"") echo "[✗] LUFS invalido: '$lufs'" >&2; return 1 ;; esac
    case "$tp" in *[!0-9,-.]*|"") echo "[✗] true peak invalido: '$tp'" >&2; return 1 ;; esac

    if [ "$modo" = oscuro ]; then
        af_aux="$FILTROS_OSCURO,$AECHO_OSCURO"
    else
        af_aux="$FILTROS_ESTANDAR"
    fi
    case "$out" in
        *.wav) enc_out=(-c:a pcm_s24le -ar 48000) ;;
        *.mp3) enc_out=(-c:a libmp3lame -b:a 192k) ;;
        *) echo "[✗] extension de salida no soportada: $out (usa .wav o .mp3)" >&2; return 1 ;;
    esac

    dir_json="$(dirname "$out")"
    measure="$dir_json/.measure-$$.txt"
    measure2="$dir_json/.measure2-$$.txt"

    trap 'rm -f -- "$measure" "$measure2"' RETURN

    # Paso 1: medir (los filtros y el eco ya estan antes del loudnorm).
    ffmpeg -hide_banner -y -i "$src" \
        -af "$af_aux,loudnorm=I=$lufs:TP=$tp:LRA=11:print_format=json" \
        -f null - 2>"$measure" || { echo "[✗] fallo la medicion de loudness (paso 1)" >&2; return 1; }

    measurements="$(sed -n '/^{/,/^}/p' "$measure" | sed 's/^.*\] //')"
    if [ -z "$measurements" ] || ! jq -e . >/dev/null 2>&1 <<<"$measurements"; then
        echo "[✗] no se pudo leer el JSON de medicion de loudnorm" >&2
        return 1
    fi

    input_i="$(jq -r '.input_i' <<<"$measurements")"
    input_tp="$(jq -r '.input_tp' <<<"$measurements")"
    input_lra="$(jq -r '.input_lra' <<<"$measurements")"
    input_thresh="$(jq -r '.input_thresh' <<<"$measurements")"
    target_offset="$(jq -r '.target_offset' <<<"$measurements")"

    for v in "$input_i" "$input_tp" "$input_lra" "$input_thresh" "$target_offset"; do
        [ -n "$v" ] && [ "$v" != "null" ] && [ "$v" != "-inf" ] && [ "$v" != "+inf" ] \
            || { echo "[✗] medida loudnorm incompleta o infinita: $input_i/$input_tp/$input_lra/$input_thresh/$target_offset" >&2; return 1; }
    done

    # Paso 2: aplicar con measured_* y linear=true, summary para reportar.
    ffmpeg -hide_banner -y -i "$src" \
        -af "$af_aux,loudnorm=I=$lufs:TP=$tp:LRA=11:measured_I=$input_i:measured_TP=$input_tp:measured_LRA=$input_lra:measured_thresh=$input_thresh:offset=$target_offset:linear=true:print_format=summary" \
        "${enc_out[@]}" "$out" 2>"$measure2" || { echo "[✗] fallo la cadena pro (paso 2)" >&2; return 1; }

    json_out="$(sed 's/^.*\] //' "$measure2")"
    OUTPUT_I="$(grep -m1 'Output Integrated' <<<"$json_out" | awk -F': ' '{print $2}' | awk '{print $1}')"
    OUTPUT_TP="$(grep -m1 'Output True Peak' <<<"$json_out" | awk -F': ' '{print $2}' | awk '{print $1}')"
    OUTPUT_MODO="$modo"

    echo "[+] cadena pro OK → $out (modo $modo, LUFS $lufs, medido ${OUTPUT_I:-?}, true peak ${OUTPUT_TP:-?})" >&2
}