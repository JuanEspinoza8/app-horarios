/**
 * Persistencia local (offline) en localStorage. Todo envuelto en try/catch
 * porque el acceso puede fallar (modo privado, storage bloqueado, etc.).
 */
import type { Dia, Empleado } from "../types";
import { DEFAULT_CONFIG, type Config } from "./overtime";

const K = {
  empleado: "he.empleado.v1",
  config: "he.config.v1",
  dias: "he.dias.v1",
};

function read<T>(key: string, fallback: T): T {
  try {
    const s = localStorage.getItem(key);
    return s ? (JSON.parse(s) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, val: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(val));
  } catch {
    /* sin persistencia disponible: la app sigue funcionando en memoria */
  }
}

export const DEFAULT_EMPLEADO: Empleado = {
  nombre: "",
  legajo: "",
  convenio: "CCT 36/75 FATyF",
  horario: "",
};

export function loadEmpleado(): Empleado {
  return { ...DEFAULT_EMPLEADO, ...read(K.empleado, {}) };
}
export function saveEmpleado(e: Empleado): void {
  write(K.empleado, e);
}

export function loadConfig(): Config {
  return { ...DEFAULT_CONFIG, ...read<Partial<Config>>(K.config, {}) };
}
export function saveConfig(c: Config): void {
  write(K.config, c);
}

export function loadDias(): Dia[] {
  return read<Dia[]>(K.dias, []);
}
export function saveDias(d: Dia[]): void {
  write(K.dias, d);
}

export function nuevoId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}
