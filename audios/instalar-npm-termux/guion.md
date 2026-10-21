---
title: "Instalar y usar NPM en Termux"
voice: marca
mode: oscuro
rate: -10%
pitch: +1Hz
volume: +0%
lufs: -18
breaths: true
gaps: 0.9
glossary: AudioBleiz: audio bleiz
---

## Apertura

En este tutorial vas a aprender a instalar y configurar Node.js con NPM en Termux. 
El objetivo es tener un entorno de desarrollo JavaScript funcional y listo para trabajar. 
Vamos a empezar paso a paso.

## Instalación de Node.js

Lo primero que debes hacer es actualizar los paquetes del sistema. 
El comando `pkg update && pkg upgrade -y` actualiza los repositorios y paquetes instalados. 
Ahora, para instalar Node.js junto con NPM, ejecutamos `pkg install nodejs -y`. 
Este comando instala la versión estable de Node.js y su gestor de paquetes NPM en Termux.

## Verificar la instalación

Es importante comprobar que todo se instaló correctamente. 
Ejecuta el comando `node --version` para ver la versión de Node.js instalada. 
Luego, ejecuta `npm --version` para verificar la versión de NPM. 
Estos comandos nos confirman que el entorno está listo para usarse.

## Crear y ejecutar un proyecto de prueba

Vamos a crear una carpeta para probar nuestro entorno. 
Con el comando `mkdir -p ~/proyecto-node` creamos el directorio. 
Luego, nos movemos a él con `cd ~/proyecto-node`. 
Ahora inicializamos un proyecto con `npm init -y`. 
Este comando crea el archivo `package.json` con la configuración básica. 
Para probarlo, creamos un archivo con `echo 'console.log("Hola desde Termux");' > index.js`. 
Por último, ejecutamos el script con `node index.js`. 
Verás el mensaje "Hola desde Termux" en la terminal.

## Cierre

Has aprendido a instalar Node.js y NPM en Termux correctamente. 
También verificaste la instalación y ejecutaste tu primer script en JavaScript. 
Ahora estás listo para empezar a desarrollar tus propios proyectos con Node.js.
