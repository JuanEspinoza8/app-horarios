# Horas Extras (PWA)

App móvil (PWA instalable, offline) para cargar horas de entrada/salida día a día,
calcular automáticamente las **horas extras al 50% / 100%** y los **francos**, cargar
los **viáticos** más tarde, y **exportar la planilla HSX en Word** (`.docx`) idéntica
a la del convenio **CCT 36/75 FATyF**.

## Cómo funciona el cálculo

Reglas reconstruidas de la planilla real y **validadas contra agosto 2026** (los
totales dan 30:56 al 50% y 26:44 al 100%, iguales al Word original):

- **Horario normal** (config.): Lun–Vie 08:00–16:00. Solo cuenta como extra el tiempo
  trabajado **fuera** de esa franja; salir antes no descuenta.
- **Día hábil:** extra diurna → **50%**; extra en franja **nocturna** (21:00–06:00) → **100%**.
- **Sábado / domingo / feriado:** todo lo trabajado → **100%**.
- **Domingo / feriado:** se **sugiere franco** (editable; lo decide el usuario).
- **Viáticos** (25% / 50%) y **motivo:** manuales.

Todo es configurable desde **Ajustes** (horario normal, franja nocturna, datos del empleado).

## Estructura

    src/lib/time.ts       Utilidades de tiempo (HH:MM <-> minutos)
    src/lib/overtime.ts   Motor de reglas (50/100/franco). Núcleo, con tests.
    src/lib/format.ts     Formato de fecha/mes (sin dependencias pesadas)
    src/lib/docx.ts       Rellena la plantilla con docxtemplater
    src/lib/export.ts     Descarga el .docx del mes (carga diferida)
    src/lib/store.ts      Persistencia offline (localStorage)
    src/components/       DiaForm (carga de día) y Ajustes
    src/App.tsx           Pantalla principal (mes, lista, totales, exportar)
    public/plantilla.docx Plantilla docxtemplater (generada, ver abajo)
    scripts/              Plantilla base del cliente + generadores

## Desarrollo

    npm install
    npm run dev       # servidor de desarrollo
    npm test          # tests del motor y del export (valida agosto)
    npm run build     # build de producción (genera el service worker PWA)
    npm run preview   # sirve el build

## La plantilla Word

`public/plantilla.docx` se genera a partir de `privado/HSX-base.docx` (copia de la
planilla original del cliente), insertando los marcadores de docxtemplater:

    npm run build:template     # python scripts/build-template.py

Marcadores: encabezado `{nombre} {legajo} {mes} {convenio} {horario}`; detalle, una
fila que se repite `{#filas} {fecha} {entrada} {salida} {al50} {al100} {franco}
{via25} {via50} {motivo} {/filas}`; totales `{tot50} {tot100}`.

Para regenerar el Word de muestra de agosto: `node scripts/gen-agosto.mjs`.

## Despliegue

Es una PWA estática: `npm run build` y servir `dist/` en cualquier hosting **HTTPS**
(Netlify, Vercel, GitHub Pages). Se instala desde el navegador ("Agregar a pantalla de
inicio") y funciona offline. Si se publica en un subpath, configurar `base` en
`vite.config.ts`.
