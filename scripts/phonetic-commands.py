#!/usr/bin/env python3
"""
Agente especialista en pronunciación de comandos técnicos.

Detecta comandos, nombres de CLI, flags, rutas y términos técnicos comunes
y los transforma a una forma fonéticamente pronunciable en español para TTS.

El objetivo: que "apt", "npm", "npx", "nodejs", "pkg", "curl", "wget", "chmod",
"chown", "git", "ssh", "scp", etc. se deletreen o pronuncien correctamente
como un programador elite.

Estrategia:
- Para acrónimos de 2-4 letras que suelen deletrearse: apt -> "a p t", npm -> "n p m", npx -> "n p x"
- Para nombres con sufijos: nodejs -> "node j s" (pronunciado como "node jess" pero deletreado)
- Para paths con / . - _ y números: se mantienen pero con pausas
- Para flags: --version -> "guión guión version", -la -> "guión la"
"""

import re
import sys
import argparse

# Deletreado para comandos CLI comunes (como programador elite)
COMMAND_SPELL = {
    "apt": "a p t",
    "npm": "n p m",
    "npx": "n p x",
    "ng": "n g",
    "cd": "c d",
    "ls": "l s",
    "rm": "r m",
    "cp": "c p",
    "mv": "m v",
    "ps": "p s",
    "su": "s u",
    "id": "i d",
    "vi": "v i",
    "vim": "v i m",
    "nc": "n c",
    "ssh": "s s h",
    "scp": "s c p",
    "sftp": "s f t p",
    "tar": "t a r",
    "zip": "z i p",
    "gzip": "g z i p",
    "gunzip": "g u n z i p",
    "grep": "g r e p",
    "awk": "a w k",
    "sed": "s e d",
    "cat": "c a t",
    "pwd": "p w d",
    "wc": "w c",
    "du": "d u",
    "df": "d f",
    "top": "t o p",
    "htop": "h t o p",
    "curl": "c u r l",
    "wget": "w g e t",
    "chmod": "c h m o d",
    "chown": "c h o w n",
    "chgrp": "c h g r p",
    "sudo": "s u d o",
    "env": "e n v",
    "man": "m a n",
    "bg": "b g",
    "fg": "f g",
    "jobs": "j o b s",
    "ping": "p i n g",
    "nslookup": "n s l o o k u p",
    "traceroute": "t r a c e r o u t e",
    "ip": "i p",
    "ifconfig": "i f c o n f i g",
    "netstat": "n e t s t a t",
    "ss": "s s",
    "ufw": "u f w",
    "iptables": "i p t a b l e s",
    "docker": "d o c k e r",
    "kubectl": "k u b e c t l",
    "git": "g i t",
    "gh": "g h",
    "python": "p y t h o n",
    "python3": "p y t h o n 3",
    "pip": "p i p",
    "pip3": "p i p 3",
    "node": "n o d e",
    "nodejs": "n o d e j s",
    "yarn": "y a r n",
    "pnpm": "p n p m",
    "bun": "b u n",
    "npm": "n p m",
    "npx": "n p x",
    "pkg": "p k g",
    "apt-get": "a p t g e t",
    "apt-cache": "a p t c a c h e",
    "snap": "s n a p",
    "brew": "b r e w",
    "make": "m a k e",
    "cmake": "c m a k e",
    "gcc": "g c c",
    "g++": "g m a s",
    "clang": "c l a n g",
    "java": "j a v a",
    "javac": "j a v a c",
    "go": "g o",
    "rustc": "r u s t c",
    "cargo": "c a r g o",
    "php": "p h p",
    "ruby": "r u b y",
    "perl": "p e r l",
    "lua": "l u a",
    "js": "j s",
    "ts": "t s",
    "json": "j s o n",
    "html": "h t m l",
    "css": "c s s",
    "sql": "s q l",
    "xml": "x m l",
    "yaml": "y a m l",
    "yml": "y m l",
    "toml": "t o m l",
    "ini": "i n i",
    "md": "m d",
    "txt": "t x t",
    "csv": "c s v",
    "pdf": "p d f",
    "url": "u r l",
    "uri": "u r i",
    "api": "a p i",
    "cli": "c l i",
    "gui": "g u i",
    "os": "o s",
    "db": "d b",
    "io": "i o",
    "cpu": "c p u",
    "gpu": "g p u",
    "ram": "r a m",
    "rom": "r o m",
    "ssd": "s s d",
    "hdd": "h d d",
    "usb": "u s b",
    "ip": "i p",
    "tcp": "t c p",
    "udp": "u d p",
    "http": "h t t p",
    "https": "h t t p s",
    "ftp": "f t p",
    "dns": "d n s",
    "ssh": "s s h",
    "ssl": "s s l",
    "tls": "t l s",
    "rest": "r e s t",
    "crud": "c r u d",
    "jwt": "j w t",
    "oauth": "o a u t h",
    "sdk": "s d k",
    "ide": "i d e",
}

def phoneticize_commands(text: str) -> str:
    """
    Transforma comandos y términos técnicos a pronunciación fonética.
    
    Reglas:
    1. Para comandos entre backticks `comando` -> aplicar mapeo
    2. Para flags: --algo -> "guión guión algo", -a -> "guión a"
    3. Para rutas con /: mantiene separadores con espacios
    4. Para nodejs, npm, apt, pkg, etc. -> deletreado o pronunciación clara
    """
    result = text
    
    # Procesar contenido entre backticks (comandos)
    def process_backtick(match):
        cmd = match.group(1)
        phonetic = phoneticize_single(cmd)
        return f"`{phonetic}`"
    
    result = re.sub(r'`([^`]+)`', process_backtick, result)
    
    # También procesar palabras fuera de backticks que son comandos comunes
    # pero solo si están aisladas o seguidas de espacio
    for term, phon in COMMAND_SPELL.items():
        # Evitar reemplazar dentro de palabras o código ya procesado
        # Solo si es palabra completa
        pattern = r'\b' + re.escape(term) + r'\b'
        result = re.sub(pattern, phon, result, flags=re.IGNORECASE)
    
    return result

def phoneticize_single(cmd: str) -> str:
    """Foneticiza un comando individual."""
    # Separar por espacios para procesar cada parte
    parts = cmd.split()
    processed_parts = []
    
    for part in parts:
        # No modificar URLs completas
        if re.match(r'https?://', part):
            processed_parts.append(part)
            continue
        # Procesar flags
        if re.match(r'^-{1,2}[a-zA-Z0-9][a-zA-Z0-9-]*$', part):
            processed_parts.append(phoneticize_flag(part))
            continue
        # Procesar rutas
        if part.startswith('/') or part.startswith('~') or '/' in part or '\\' in part:
            processed_parts.append(phoneticize_path(part))
            continue
        # Buscar en mapeo directo (case insensitive)
        lower = part.lower()
        if lower in COMMAND_SPELL:
            processed_parts.append(COMMAND_SPELL[lower])
            continue
        # Para nodejs-like patterns
        if re.match(r'^[a-zA-Z]+js$', lower):
            # ej: nodejs -> node j s
            if lower == 'nodejs':
                processed_parts.append('n o d e j s')
                continue
            # otros como denojs? raro, pero deletrear
        # Para nombres con números
        # Si contiene mayúsculas mezcladas, mantener tal cual pero claro
        processed_parts.append(part)
    
    return ' '.join(processed_parts)

def phoneticize_flag(flag: str) -> str:
    """Foneticiza flags: -v -> guión v, --version -> guión guión version"""
    if flag.startswith('--'):
        name = flag[2:]
        return f'guión guión {name}'
    elif flag.startswith('-'):
        name = flag[1:]
        return f'guión {name}'
    return flag

def phoneticize_path(path: str) -> str:
    """Foneticiza rutas añadiendo pausas en /"""
    # Reemplazar separadores con " barra " para mejor pronunciación
    path = path.replace('/', ' barra ')
    path = path.replace('\\', ' barra invertida ')
    path = path.replace('.', ' punto ')
    path = path.replace('_', ' guión bajo ')
    path = path.replace('-', ' guión medio ')
    return path

def main():
    parser = argparse.ArgumentParser(description='Especialista en pronunciación de comandos técnicos')
    parser.add_argument('input', help='Archivo de entrada (.md)')
    parser.add_argument('-o', '--output', help='Archivo de salida (default: stdout)')
    args = parser.parse_args()
    
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            content = f.read()
        
        phoneticized = phoneticize_commands(content)
        
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(phoneticized)
            print(f'Archivo procesado: {args.output}', file=sys.stderr)
        else:
            print(phoneticized)
    
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
