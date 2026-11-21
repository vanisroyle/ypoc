<p align="center">
  <img src="game/assets/icons/launcher.svg" width="112" height="112" alt="Icono de Power of Chaos Remake">
</p>

# Yu-Gi-Oh! Power of Chaos Remake

[English](README.md) | **Español**

[![Descargar EXE para Windows](https://img.shields.io/badge/Descargar_EXE-Windows-2ea44f?style=for-the-badge)](https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake/releases/download/v0.1.0-alpha.42/PowerOfChaos.exe)

**Descarga directa · Windows · Preliminar v0.1.0-alpha.42 · Sin ZIP**

**Tus juegos de Power of Chaos reunidos en un launcher moderno para Windows.**

**Novedades de alpha.42.** Recupera el progreso original e importa mazos, repeticiones y voces desde el launcher de Windows. Consulta los cambios antes de actualizar. [Notas de la versión](RELEASE_NOTES.md)

## Contenido

- [Ventajas](#ventajas)
- [Ajustes del launcher](#ajustes-del-launcher)
- [Tus ISO → PC](#tus-iso--pc)
- [Capturas del launcher](#capturas-del-launcher)
- [¿Qué es este remake?](#qué-es-este-remake)
- [Empezar en Windows](#empezar-en-windows)
- [Cómo funciona](#cómo-funciona)
- [Compatibilidad y límites actuales](#compatibilidad-y-límites-actuales)
- [Idiomas y voces](#idiomas-y-voces)
- [Ejecutar desde el código fuente](#ejecutar-desde-el-código-fuente)
- [Compilaciones automáticas](#compilaciones-automáticas)
- [Estado del proyecto y avisos](#estado-del-proyecto-y-avisos)

## Ventajas

- **Launcher de PC con conversión local.** Selecciona tus imágenes de disco o carpetas instaladas y el launcher prepara tus juegos para Windows en tu equipo.
- **Duelos en red en Joey sin DirectPlay.** La conexión moderna por red local sustituye ese componente antiguo de Windows. Conexión probada entre PC y PC.
- **Portable.** Lleva juntos el EXE y su carpeta **`PoC Data`**: ahí viajan tus recursos, partidas y ajustes.
- **Recursos más livianos.** Las imágenes WebP sin pérdida y el audio OGG reducen el espacio ocupado. La biblioteca de Yugi probada ocupa aproximadamente **un 44% menos** que su versión convertida sin comprimir. El ahorro depende del juego y la edición.
- **Decoraciones para 16:9.** Los laterales decorados rodean el área de duelo original de 4:3 en las vistas compatibles de Yugi, Kaiba y Joey, cada uno con su propio fondo.
- **Todo en uno.** Yugi the Destiny, Kaiba the Revenge y Joey the Passion comparten un launcher. Puedes empezar con uno y añadir los demás cuando quieras.
- **Colección compartida, mazos separados.** Conserva tus cartas entre juegos con las compatibilidades originales: Yugi usa su catálogo, Kaiba también las de Yugi y Joey las de los tres. Cada título mantiene su mazo activo.
- **Elige el ritmo y la imagen.** Selecciona 30 FPS, 60 FPS o la frecuencia de tu monitor; aspecto estirado, 4:3 original o fondos decorativos; y velocidad normal o 2×.
- **Juego rápido opcional en los tres juegos.** Omite escenas de personajes, voces y barridos, conservando la música y los efectos. [Ver ajustes del launcher](#ajustes-del-launcher).

## Ajustes del launcher

Abre el **engranaje** del launcher para elegir cómo jugar:

| Ajuste | Opciones |
|---|---|
| Aspecto | **Estirado** ocupa toda la ventana; **Original sin fondo** conserva el 4:3 con bandas negras; **Overlay** añade el fondo decorativo de cada duelo alrededor del área original 4:3. |
| FPS | **30**, **60** o **Display**, que sigue la frecuencia del monitor actual. |
| Simulación | **Normal** o **2×**. La velocidad de simulación es independiente del límite de FPS. |
| Juego rápido | Omite las escenas de entrada y salida, reacciones con retrato, voces y barridos entre escenas en **Yugi, Kaiba y Joey**. Conserva la música y los efectos de sonido. |
| Traducciones mejoradas | **Originales** o **Mejoradas (ES)**: nombres y descripciones en español para las **771 cartas**, con fuentes comunitarias públicas y adaptaciones que conservan los efectos originales. |

**Valores por defecto:** FPS del display, velocidad normal y juego rápido desactivado.

Las preferencias se recuerdan al volver a abrir el launcher. Juego rápido es opcional
y viene **desactivado**; desactívalo para recuperar la presentación original. El launcher
se abre maximizado desde el principio y puedes redimensionar la ventana o usar
**F11 / Alt+Enter** para alternar la pantalla completa.

**Traducciones mejoradas** es opcional y viene **desactivado**. Cubre los nombres y las descripciones en español de las **771 cartas** de los tres juegos, con bases comunitarias públicas y adaptaciones revisadas para conservar los efectos del inglés original. Los menús y las reglas del juego se conservan; es una mejora comunitaria, no un paquete de traducción oficial.

Actívalo con conexión para preparar el paquete local. La primera descarga es de aproximadamente **110 MB**; después, los textos funcionan sin conexión. Abrir el launcher no inicia descargas. Si la preparación falla, siguen disponibles los textos importados. Puedes desactivar la opción cuando quieras para recuperarlos.

## Tus ISO → PC

Selecciona los ISO o las carpetas instaladas de tus juegos y pulsa **Compilar**, que aparece al elegir una fuente, para preparar los juegos para Windows.

Tus ISO y recursos convertidos permanecen en tu equipo; la descarga no incluye datos originales del juego. La conexión de Joey ya se probó entre **PC y PC**. El proyecto continúa en alfa: agradecemos comentarios, errores y pruebas con otras ediciones y equipos.

## Capturas del launcher

**Biblioteca con los tres juegos preparados (interfaz en inglés)**

![Launcher en inglés con Yugi, Kaiba y Joey listos para jugar](docs/images/launcher-library-en.png)

**Selecciona las ISO o carpetas de tus juegos**

![Pantalla de importación en inglés con selección de ISO y carpeta](docs/images/launcher-import-en.png)

Las capturas muestran el launcher Windows. Los logos aparecen después de importar tus propias copias compatibles.

## ¿Qué es este remake?

Yu-Gi-Oh! Power of Chaos Remake es una reconstrucción experimental en Godot del motor de **Yugi the Destiny, Kaiba the Revenge y Joey the Passion**. Busca conservar las reglas, la presentación y la sensación de los originales, facilitando su uso y mantenimiento en PC modernos.

Tú aportas una copia compatible del juego que quieras usar. El launcher lee sus recursos en tu equipo y los prepara para el nuevo motor. **Basta con un juego para empezar.**

> **Versión preliminar:** el desarrollo y las pruebas de compatibilidad continúan. Todavía no es un reemplazo terminado y completamente fiel de todas las ediciones originales.

### Más funciones del launcher

- **Un solo EXE para Windows.** Incluye Godot, el conversor y 7-Zip; no necesitas instalarlos por separado.
- **Importación desde ISO o carpeta instalada.** Las imágenes compatibles se leen sin ejecutar sus instaladores ni los juegos originales.
- **Archivos locales.** Tus ISO, recursos y partidas no se suben a GitHub ni a un servicio de conversión.
- **Añade juegos sin empezar de nuevo.** Las importaciones posteriores conservan los juegos preparados y los guardados del remake.
- **Selector de idiomas.** Inglés, español, alemán, francés, italiano y japonés; el primer inicio toma un idioma compatible del sistema y recuerda tu elección.
- **Menú propio.** Música del launcher, controles dorados, icono propio y ajuste de volumen.
- **Motor en Godot.** Los recursos originales los aporta cada jugador por separado.

«Remake» se refiere a la reconstrucción del motor. No significa que se hayan redibujado las cartas ni vuelto a grabar las voces y la música originales.

## Empezar en Windows

1. [Descarga **`PowerOfChaos.exe`** directamente](https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake/releases/download/v0.1.0-alpha.42/PowerOfChaos.exe). También hay compilaciones de desarrollo en [Actions](https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake/actions/workflows/build-windows.yml).
2. Pon el EXE en una carpeta donde quieras guardar el launcher y tus partidas, y ábrelo.
3. En **SUBE TUS RECURSOS**, pasa el cursor por el juego que quieras añadir y elige **ISO** o **Carpeta**.
4. Selecciona una imagen de disco o carpeta instalada compatible, pulsa **Compilar** y espera a que termine.
5. Haz clic en el logo del juego preparado para jugar. Puedes añadir los otros después.

La descarga es un único EXE, sin asistente de instalación. La primera importación prepara las herramientas incluidas en `PoC Data/tools/`; abrir el menú no espera esa extracción. Los archivos de Actions pueden venir en ZIP; los de Releases permiten descargar directamente el EXE.

Necesitas Windows con soporte para el renderizador OpenGL de compatibilidad de Godot, una copia compatible de al menos un juego y espacio libre para los recursos y archivos temporales. Una carpeta instalada debe contener `Data.dat`, `Voice.dat`, `Region.dat` y el ejecutable original correspondiente; este se lee para obtener tablas del motor, sin ejecutarlo. También se acepta la carpeta `data` de archivos sueltos que dejan algunos instaladores de terceros en lugar de `Data.dat`.

Yugi the Destiny admite la edición europea/española y la estadounidense. Para el disco estadounidense original (165 cartas), selecciona la ISO o el disco de Yugi. Cuando el importador pida la actualización de diciembre de 2003, elige la ISO o el disco estadounidense de Kaiba the Revenge. El importador prepara Yugi automáticamente a partir de ambos discos. Si ya tienes Yugi actualizado, selecciona su carpeta instalada. Kaiba the Revenge y Joey the Passion admiten sus ediciones en inglés.

## Cómo funciona

```text
Tu ISO o carpeta instalada
            |
 Validación y extracción local
            |
 Recursos convertidos en tu PC
            |
     Motor del juego en Godot
```

El EXE distribuido contiene el launcher, el motor y las herramientas de conversión. No incluye los ejecutables originales ni sus ilustraciones, voces o música de juego: se obtienen de la copia que selecciones.

La conversión valida y comprime una biblioteca temporal dentro de `PoC Data` antes de activarla en `PoC Data/resources/`. Al añadir un juego se conservan los ya importados. Tras completar el cambio se retira la copia generada anterior; tus ISO, carpetas originales y guardados no se sobrescriben. El importador rechaza revisiones no compatibles e imágenes dañadas o incompletas; no descarga recursos faltantes.

### Dónde queda cada archivo

| Archivos | Ubicación junto al EXE |
| --- | --- |
| Recursos WebP/OGG y datos del motor | `PoC Data/resources/` |
| Guardados del remake | `PoC Data/saves/` |
| Ajustes | `PoC Data/content.cfg` |
| Herramientas y licencias | `PoC Data/tools/` |
| Extracción temporal | `PoC Data/temp/` y carpetas transitorias dentro de `PoC Data/` |
| Último error de importación | `PoC Data/import-last-error.log` |

Si falla una importación, el launcher muestra el juego afectado, el archivo o carpeta, la etapa y la causa. La ventana permite **Copiar detalles** y **Abrir registro**; **Ver error** la vuelve a abrir. Un fallo general de conversión, compresión o escritura se identifica por su etapa y no se atribuye a una ISO sin evidencia.

**Mueve o respalda juntos `PowerOfChaos.exe` y `PoC Data`.** Las rutas relativas permiten cambiar de carpeta o unidad sin volver a importar. Usa una carpeta con permiso de escritura.

El launcher busca versiones en GitHub al abrirse. El botón circular de **actualizar**, junto al de encendido, sólo aparece cuando se detecta una versión más nueva. El pie muestra tu versión, el estado y vínculos a GitHub y licencias. Puedes descargar una nueva versión y reiniciar desde el launcher: se verifica su SHA-256 y se reemplaza únicamente el EXE, conservando `PoC Data`. La descarga se puede cancelar. Si falla el reemplazo o el inicio del nuevo proceso, se intenta restaurar el EXE anterior; el diagnóstico queda en `PoC Data/updates/last-update.log`. Las versiones alpha/beta también reciben preliminares; las estables siguen el canal estable. Requiere Windows, conexión y permiso de escritura en la carpeta del EXE.

Al actualizar en la misma carpeta se copian los antiguos `saves/` adyacentes sin reemplazar guardados portables más recientes. También se migran los ajustes anteriores y se prepara una copia compacta de la biblioteca importada. Se mantiene la fuente antigua hasta verificar la nueva. Si cambias de carpeta, lleva el antiguo `saves/` junto al nuevo EXE antes de abrirlo por primera vez, o mueve tu `PoC Data` existente.

## Compatibilidad y límites actuales

Esta versión pública está orientada a **Windows PC**.

| Juego | Importaciones comprobadas | Comprobaciones del motor |
| --- | --- | --- |
| Yugi the Destiny | ISO y carpeta compatibles | Inicio independiente del título y duelo normal |
| Kaiba the Revenge | ISO y carpeta compatibles | Inicio independiente del título y duelo normal; perfiles compatibles sin necesitar Yugi |
| Joey the Passion | ISO y carpeta compatibles | Inicio independiente del título y duelo normal |

Se han importado ISO compatibles de los tres juegos; las imágenes truncadas se rechazan con detalles del juego afectado. La compatibilidad con otras revisiones y regiones sigue ampliándose.

Las reglas, la IA, la presentación y los tiempos siguen comparándose con los originales. Estas pruebas no certifican todos los duelos ni todas las cartas. Al informar de un fallo, indica juego, edición, origen de importación y pasos para reproducirlo; no adjuntes archivos originales del juego.

Los discos MSI/CAB compatibles se extraen con el 7-Zip incluido. Los medios Inno Setup requieren `innoextract` en `PATH`; para otros instaladores, instala tu copia por separado y selecciona su carpeta.

## Idiomas y voces

El selector controla el launcher y los textos disponibles del juego. La disponibilidad depende de la edición importada. `Data.dat` puede variar entre regiones y revisiones.

Los doblajes se detectan desde `Voice.dat`. Al cambiar de idioma se usa el doblaje correspondiente si está importado; de lo contrario, se conserva el principal. El selector no descarga voces.

Abre **Importar más recursos**, elige el juego y selecciona su `Voice.dat` con **Importar voces**. Si ya seleccionaste una ISO o carpeta, pulsa **Compilar** para importarlas juntas. Si el juego ya está preparado, las voces se importan al elegir el archivo. Las herramientas de código fuente hacen lo mismo:

```powershell
python -m pocx.import_games --base "datos-existentes" --voice "joey=C:\Mi copia de Joey\Voice.dat" --out "datos-nuevos"
```

Usa una carpeta de salida nueva para importaciones manuales. El launcher gestiona sus propias actualizaciones. Dos doblajes distintos del mismo juego e idioma se rechazan como conflicto.

El mismo menú importa mazos `.ydc` a la biblioteca compartida y repeticiones `.ydr` al juego detectado o elegido. También restaura `Common/system.dat` del original o `system.json` del remake, con las cartas desbloqueadas y el progreso. El launcher pide confirmación antes de reemplazar un archivo y guarda una copia de la partida activa antes de sustituirla.

## Ejecutar desde el código fuente

Requiere **Godot 4.7.2** y **Python 3.12 o posterior**. La compilación automática usa Python 3.13.

```powershell
git clone https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake.git
cd Yu-Gi-Oh-Power-of-Chaos-Remake
python -m pip install ./tools
godot --editor --path game
```

Ejecuta `game/project.godot` desde el editor e importa tus recursos. Si usas un entorno virtual de Python, abre Godot desde una consola con ese entorno activado. Las importaciones desde el código necesitan 7-Zip instalado en su ubicación habitual de Windows o disponible en `PATH`. El EXE publicado ya incluye las herramientas y el codificador de audio; no necesita FFmpeg.

Pruebas del importador con datos sintéticos, sin recursos originales:

```powershell
$env:PYTHONPATH = "tools"
python -m unittest discover -s tools/tests -p "test_*import.py" -v
```

## Compilaciones automáticas

Cada release incluye [notas de cambios en inglés](RELEASE_NOTES.md) con sus mejoras y correcciones.

El flujo [Launcher Windows](https://github.com/Johanfer12/Yu-Gi-Oh-Power-of-Chaos-Remake/actions/workflows/build-windows.yml) genera una compilación con cada cambio en `main` y cada solicitud de cambios; también puede iniciarse manualmente. Las etiquetas que empiezan por `v` publican una versión preliminar con EXE, suma SHA-256 y manifiesto de compilación.

Cada compilación comprueba la política de archivos, ejecuta las pruebas sintéticas, crea una exportación limpia y verifica el conversor incluido. No necesita ni incorpora recursos originales. Las copias instaladas pueden buscar y descargar versiones desde el botón de actualizar; el reemplazo y reinicio requieren confirmar la actualización.

## Estado del proyecto y avisos

Este es un proyecto independiente y no oficial, sin afiliación ni respaldo de los editores o titulares de los juegos originales. Los nombres identifican los títulos compatibles; los recursos y marcas pertenecen a sus respectivos titulares.

El tema musical del launcher, sus tres fondos externos de duelo y el icono propio pertenecen a este proyecto. Los marcos de juegos pendientes incluyen contornos vectoriales derivados de los logos originales; sus imágenes se cargan únicamente tras importar la copia del usuario.

El código incluye trabajo derivado de ingeniería inversa. Su procedencia y la licencia general siguen en revisión; no se ha asignado una licencia global al repositorio. Publicar estas fuentes no otorga derechos para redistribuir los recursos originales.

Cada componente de terceros conserva su licencia. Consulta [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) y **Licencias** en el launcher, incluidas las fuentes correspondientes de 7-Zip.
