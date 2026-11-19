/**
 * Utilidades de tiempo. Todo se maneja en "minutos desde la medianoche"
 * (0..1439). Las duraciones pueden superar 24 h (p. ej. totales del mes).
 */

/** "HH:MM" -> minutos desde la medianoche. Acepta "8:00", "08:00", "6:53". */
export function parseHHMM(value: string): number {
  const m = /^(\d{1,2}):(\d{2})$/.exec(value.trim());
  if (!m) throw new Error(`Hora inválida: "${value}" (formato esperado HH:MM)`);
  const h = Number(m[1]);
  const min = Number(m[2]);
  if (h > 23 || min > 59) throw new Error(`Hora fuera de rango: "${value}"`);
  return h * 60 + min;
}

/**
 * Formatea minutos como "H:MM" (horas sin cero a la izquierda, minutos con dos
 * dígitos), tal como aparece en la planilla: "0:23", "8:00", "30:56".
 */
export function formatHHMM(totalMinutes: number): string {
  const sign = totalMinutes < 0 ? "-" : "";
  const abs = Math.abs(Math.round(totalMinutes));
  const h = Math.floor(abs / 60);
  const m = abs % 60;
  return `${sign}${h}:${String(m).padStart(2, "0")}`;
}

/** minutos desde medianoche -> "HH:MM" 24h con cero a la izquierda (para <input type=time>). */
export function minutesToClock(min: number): string {
  const m = ((Math.round(min) % 1440) + 1440) % 1440;
  const h = Math.floor(m / 60);
  return `${String(h).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
}

/**
 * Duración trabajada entre entrada y salida, en minutos.
 * Si la salida es <= entrada se asume que cruza la medianoche (turno nocturno).
 */
export function workedSpan(entradaMin: number, salidaMin: number): { start: number; end: number } {
  const end = salidaMin <= entradaMin ? salidaMin + 24 * 60 : salidaMin;
  return { start: entradaMin, end };
}
