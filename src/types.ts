import type { Config } from "./lib/overtime";

/** Un día cargado y persistido. */
export interface Dia {
  id: string;
  fechaISO: string; // "YYYY-MM-DD"
  entrada: string; // "HH:MM"
  salida: string; // "HH:MM"
  esFeriado: boolean;
  franco: string; // "" | "1"
  viatico25: string;
  viatico50: string;
  motivo: string;
}

/** Datos fijos del empleado (encabezado de la planilla). */
export interface Empleado {
  nombre: string;
  legajo: string;
  convenio: string;
  horario: string;
}

export type ConfigReglas = Config;

/** Clave de mes "YYYY-MM". */
export type MonthKey = string;

export function monthKeyOf(fechaISO: string): MonthKey {
  return fechaISO.slice(0, 7);
}
