# Horas Extras (Flutter / Android)

App Android para cargar entrada y salida día a día, calcular las **horas extras al 50% / 100%**
y los **francos**, y exportar la **planilla HSX en Word** (`.docx`) igual a la del convenio
**CCT 36/75 FATyF**. Funciona sin internet; los datos quedan en el teléfono.

Tiene **modo oscuro con fondo negro puro** (#000000) para pantallas OLED: en Ajustes →
Apariencia se elige *Auto* (sigue al teléfono), *Claro* u *Oscuro*. La pantalla de arranque
también respeta esa elección (Android 12+, vía `MainActivity.kt`).

## Reglas de cálculo

| | Lunes a viernes | Sáb, dom y feriados |
|---|---|---|
| Horario normal | **Ene–Feb:** 07:00–15:00 · **Mar–Dic:** 08:00–16:00 (no es extra) | — |
| Fuera del horario, de 21:00 a 06:00 | **100%** | **100%** |
| Fuera del horario, resto (p. ej. 16–21, 06–08) | **50%** | **100%** |

- Salir antes no descuenta.
- Si el turno cruza la medianoche, lo que cae al día siguiente se evalúa con el tipo y el
  horario de ese día (viernes 22:00 → sábado 08:00: lo del sábado va todo al 100%).
- **Franco** (Auto / Sí / No): en *Auto* se marca solo si es sábado o domingo con **4:00 h o
  más** trabajadas, o feriado con **8:00 h o más**. Se puede forzar a Sí o No por día.
- **Feriados**: la app marca sola los feriados nacionales de `lib/domain/feriados.dart`
  (2026 completo; 2027 solo inamovibles hasta que salga el decreto de traslados). Los
  provinciales o puentes se marcan a mano con la casilla "Feriado".
- **Viáticos**: no se cargan; esas columnas del Word quedan vacías para completarlas a mano.

Todo es editable en **Ajustes** (horarios, meses de verano, franja nocturna, umbrales del franco).
Las reglas se validan contra la planilla real de agosto 2026 (30:56 al 50%, 26:44 al 100%).

## Estructura

    lib/domain/time.dart          Utilidades de tiempo (HH:MM <-> minutos)
    lib/domain/overtime.dart      Motor de reglas (50/100/franco), con tests
    lib/domain/feriados.dart      Feriados nacionales que se marcan solos
    lib/domain/fechas.dart        Formato de fechas en español
    lib/data/models.dart          Día, Empleado, FrancoModo
    lib/data/store.dart           Estado + guardado local (SharedPreferences)
    lib/export/planilla_docx.dart Rellena assets/plantilla.docx (archive + xml)
    lib/export/exportar.dart      Compartir / guardar el .docx en Android
    lib/ui/                       Pantallas Mes, Día y Ajustes
    lib/ui/tema.dart              Tema claro y oscuro (negro puro OLED)
    lib/data/modo_noche.dart      Avisa a Android el tema para la pantalla de arranque
    assets/plantilla.docx         Plantilla Word (generada, ver abajo)
    scripts/                      Planilla base del cliente + generadores
    test/                         Motor, export del Word e interfaz

## Desarrollo

    flutter pub get
    flutter test                  # motor, Word de agosto e interfaz
    flutter analyze
    flutter run                   # en un emulador o teléfono conectado

## Generar el APK

    flutter build apk --release                  # universal (~54 MB, cualquier teléfono)
    flutter build apk --release --split-per-abi  # por arquitectura (arm64 ~19 MB)

Salida en `build/app/outputs/flutter-apk/`. Para la mayoría de los teléfonos actuales alcanza
con `app-arm64-v8a-release.apk`; ante la duda, mandar `app-release.apk` (universal). Para
instalarlo, el teléfono tiene que permitir "instalar apps desconocidas" para la app desde la
que se abre (WhatsApp, Drive, Archivos…).

Para una versión nueva, subir `version:` en `pubspec.yaml` (p. ej. `1.0.1+2`) antes de compilar.

### Clave de firma (¡hacer copia de seguridad!)

El APK de release se firma con `android/keys/horas-extras.jks` usando los datos de
`android/key.properties`. **Ninguno de los dos está en git.** Guardar copia de ambos en un lugar
seguro: una actualización firmada con otra clave no se puede instalar encima de la anterior
y obliga a desinstalar la app, **lo que borra todos los días cargados**.

## Plantilla Word

`assets/plantilla.docx` se genera a partir de `privado/HSX-base.docx` (copia de la planilla
original del cliente) insertando marcadores:

    python scripts/build-template.py

Encabezado `{nombre} {legajo} {mes} {convenio} {horario}`; una fila que se repite por día
`{#filas}{fecha} {entrada} {salida} {al50} {al100} {franco} {via25} {via50} {motivo}{/filas}`;
totales `{tot50} {tot100}`.

## Ícono

    python scripts/gen-icon.py && dart run flutter_launcher_icons

## Notas

- `path_provider_android` está fijado en 2.2.23: la 2.3.x (con JNI) falla en el APK de
  release al compartir (`ClassNotFoundException`). Revisar antes de subirlo.
- La versión web anterior (PWA con React) quedó en el primer commit del repo.
