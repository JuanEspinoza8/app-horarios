/**
 * Motor de reglas de horas extras (CCT 36/75 FATyF, reconstruido a partir de la
 * planilla de agosto y validado contra sus totales: 30:56 al 50% y 26:44 al 100%).
 *
 * Reglas:
 *  - Horario normal Lun–Vie (por defecto 08:00–16:00). Solo cuenta como extra el
 *    tiempo trabajado FUERA de esa franja. Salir antes no descuenta.
 *  - En día hábil: la extra diurna es al 50%; la extra en franja nocturna
 *    (por defecto 21:00–06:00) es al 100%.
 *  - Sábado, domingo y feriado: TODO lo trabajado es al 100%.
 *  - Domingo/feriado: se sugiere franco compensatorio (editable por el usuario).
 */
import { parseHHMM, workedSpan } from "./time";

export interface Config {
  /** Inicio del horario normal, minutos desde medianoche. Def. 08:00. */
  normalStartMin: number;
  /** Fin del horario normal, minutos desde medianoche. Def. 16:00. */
  normalEndMin: number;
  /** Inicio de la franja nocturna (tarde/noche). Def. 21:00. */
  nightStartMin: number;
  /** Fin de la franja nocturna (madrugada). Def. 06:00. */
  nightEndMin: number;
  /** Días de la semana considerados hábiles (0=Dom .. 6=Sáb). Def. Lun–Vie. */
  workdays: number[];
}

export const DEFAULT_CONFIG: Config = {
  normalStartMin: 8 * 60,
  normalEndMin: 16 * 60,
  nightStartMin: 21 * 60,
  nightEndMin: 6 * 60,
  workdays: [1, 2, 3, 4, 5],
};

export type DayType = "habil" | "sabado" | "domingo" | "feriado";

export interface DayResult {
  /** Minutos de hora extra al 50%. */
  min50: number;
  /** Minutos de hora extra al 100%. */
  min100: number;
  /** Tipo de día resuelto. */
  dayType: DayType;
  /** true si corresponde sugerir franco compensatorio (domingo/feriado). */
  francoSugerido: boolean;
}

/** ¿El minuto (0..1439) cae en la franja nocturna? */
function esNocturno(minuteOfDay: number, cfg: Config): boolean {
  const m = ((minuteOfDay % 1440) + 1440) % 1440;
  if (cfg.nightStartMin <= cfg.nightEndMin) {
    // Franja contigua (poco común): [start, end)
    return m >= cfg.nightStartMin && m < cfg.nightEndMin;
  }
  // Franja que cruza medianoche: [nightStart, 24h) ∪ [0, nightEnd)
  return m >= cfg.nightStartMin || m < cfg.nightEndMin;
}

/** Clasifica los minutos de un intervalo [start, end) en 50% vs 100% (día hábil). */
function clasificarPorFranja(start: number, end: number, cfg: Config) {
  let min50 = 0;
  let min100 = 0;
  for (let m = start; m < end; m++) {
    if (esNocturno(m, cfg)) min100++;
    else min50++;
  }
  return { min50, min100 };
}

/**
 * Determina el tipo de día a partir de la fecha ISO "YYYY-MM-DD".
 * Usa UTC para evitar corrimientos por zona horaria.
 */
export function tipoDeDia(fechaISO: string, esFeriado: boolean, cfg: Config = DEFAULT_CONFIG): DayType {
  if (esFeriado) return "feriado";
  const [y, mo, d] = fechaISO.split("-").map(Number);
  const dow = new Date(Date.UTC(y, mo - 1, d)).getUTCDay(); // 0=Dom .. 6=Sáb
  if (dow === 0) return "domingo";
  if (dow === 6) return "sabado";
  if (!cfg.workdays.includes(dow)) return "sabado"; // día no hábil configurado -> como sábado (100%)
  return "habil";
}

export interface ComputeInput {
  fechaISO: string; // "2026-08-18"
  entrada: string; // "HH:MM"
  salida: string; // "HH:MM"
  esFeriado?: boolean;
}

/** Calcula las horas extras de un día. */
export function computeDay(input: ComputeInput, cfg: Config = DEFAULT_CONFIG): DayResult {
  const entradaMin = parseHHMM(input.entrada);
  const salidaMin = parseHHMM(input.salida);
  const { start, end } = workedSpan(entradaMin, salidaMin);
  const dayType = tipoDeDia(input.fechaISO, input.esFeriado ?? false, cfg);

  if (dayType !== "habil") {
    // Sábado/domingo/feriado: todo lo trabajado es al 100%.
    const total = end - start;
    return {
      min50: 0,
      min100: total,
      dayType,
      francoSugerido: dayType === "domingo" || dayType === "feriado",
    };
  }

  // Día hábil: solo cuenta lo trabajado fuera de [normalStart, normalEnd].
  let min50 = 0;
  let min100 = 0;

  // Tramo antes del horario normal.
  if (start < cfg.normalStartMin) {
    const seg = clasificarPorFranja(start, Math.min(end, cfg.normalStartMin), cfg);
    min50 += seg.min50;
    min100 += seg.min100;
  }
  // Tramo después del horario normal.
  if (end > cfg.normalEndMin) {
    const seg = clasificarPorFranja(Math.max(start, cfg.normalEndMin), end, cfg);
    min50 += seg.min50;
    min100 += seg.min100;
  }

  return { min50, min100, dayType, francoSugerido: false };
}

/** Suma los resultados de varios días (para los totales del mes). */
export function totales(resultados: Array<Pick<DayResult, "min50" | "min100">>) {
  return resultados.reduce(
    (acc, r) => ({ min50: acc.min50 + r.min50, min100: acc.min100 + r.min100 }),
    { min50: 0, min100: 0 },
  );
}
