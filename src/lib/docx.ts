/**
 * Capa de generación del Word: rellena la plantilla `public/plantilla.docx`
 * (derivada de la planilla original del cliente) con los datos del mes usando
 * docxtemplater. Funciona igual en el navegador (PWA) y en Node (tests).
 */
import PizZip from "pizzip";
import Docxtemplater from "docxtemplater";
import { computeDay, totales, type Config, DEFAULT_CONFIG } from "./overtime";
import { formatHHMM } from "./time";
import { formatFechaCorta, nombreMes } from "./format";

export { formatFechaCorta, nombreMes };

/** Un día cargado por el usuario. */
export interface DiaCargado {
  fechaISO: string; // "2026-08-18"
  entrada: string; // "HH:MM"
  salida: string; // "HH:MM"
  esFeriado?: boolean;
  /** Franco: "" | "1" | "medio", etc. Lo decide el usuario (sugerido en dom/feriado). */
  franco?: string;
  viatico25?: string;
  viatico50?: string;
  motivo?: string;
}

/** Datos fijos del empleado (encabezado de la planilla). */
export interface Empleado {
  nombre: string;
  legajo: string;
  convenio: string;
  /** Texto del horario normal impreso en el encabezado (opcional). */
  horario?: string;
}

export interface PlanillaData {
  nombre: string;
  legajo: string;
  mes: string;
  convenio: string;
  horario: string;
  filas: Array<{
    fecha: string;
    entrada: string;
    salida: string;
    al50: string;
    al100: string;
    franco: string;
    via25: string;
    via50: string;
    motivo: string;
  }>;
  tot50: string;
  tot100: string;
}

/**
 * Arma el objeto de datos que consume la plantilla, calculando 50/100 con el
 * motor de reglas y los totales del mes.
 */
export function buildPlanillaData(
  empleado: Empleado,
  dias: DiaCargado[],
  mes: string,
  cfg: Config = DEFAULT_CONFIG,
): PlanillaData {
  const resultados = dias.map((d) => computeDay(d, cfg));
  const filas = dias.map((d, i) => {
    const r = resultados[i];
    return {
      fecha: formatFechaCorta(d.fechaISO),
      entrada: d.entrada,
      salida: d.salida,
      al50: r.min50 === 0 ? "" : formatHHMM(r.min50),
      al100: r.min100 === 0 ? "" : formatHHMM(r.min100),
      franco: d.franco ?? "",
      via25: d.viatico25 ?? "",
      via50: d.viatico50 ?? "",
      motivo: d.motivo ?? "",
    };
  });
  const t = totales(resultados);
  return {
    nombre: empleado.nombre,
    legajo: empleado.legajo,
    mes,
    convenio: empleado.convenio,
    horario: empleado.horario ?? "",
    filas,
    tot50: t.min50 === 0 ? "" : formatHHMM(t.min50),
    tot100: t.min100 === 0 ? "" : formatHHMM(t.min100),
  };
}

/** Rellena la plantilla con los datos y devuelve el .docx como bytes. */
export function renderPlanilla(templateBytes: ArrayBuffer | Uint8Array, data: PlanillaData): Uint8Array {
  const zip = new PizZip(templateBytes);
  const doc = new Docxtemplater(zip, {
    paragraphLoop: true,
    linebreaks: true,
  });
  doc.render(data);
  return doc.getZip().generate({ type: "uint8array" });
}
