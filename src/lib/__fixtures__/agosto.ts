/**
 * Horarios reales de la planilla de agosto 2026 (motivos y datos personales anonimizados) (privado/HSX-agosto-ejemplo.docx).
 * Sirven de "test de oro" para el motor de reglas y para el export a .docx.
 *
 *  - exp50 / exp100: horas extras impresas en el Word ("" cuando la celda va vacía).
 *  - franco / motivo: valores manuales tal como figuran en la planilla real.
 */
export interface AgostoRow {
  fecha: string; // ISO "YYYY-MM-DD"
  entrada: string; // "HH:MM"
  salida: string; // "HH:MM"
  exp50: string;
  exp100: string;
  franco: string;
  motivo: string;
}

export const AGOSTO: AgostoRow[] = [
  { fecha: "2026-08-03", entrada: "8:00", salida: "16:23", exp50: "0:23", exp100: "", franco: "", motivo: "Capacitación" },
  { fecha: "2026-08-07", entrada: "6:02", salida: "17:37", exp50: "3:35", exp100: "", franco: "", motivo: "Capacitación de manejo" },
  { fecha: "2026-08-09", entrada: "7:00", salida: "15:10", exp50: "", exp100: "8:10", franco: "1", motivo: "Mantenimiento de semibarra" },
  { fecha: "2026-08-11", entrada: "6:59", salida: "16:00", exp50: "1:01", exp100: "", franco: "", motivo: "Maniobra" },
  { fecha: "2026-08-12", entrada: "7:03", salida: "17:33", exp50: "2:30", exp100: "", franco: "", motivo: "Ensayos" },
  { fecha: "2026-08-13", entrada: "8:00", salida: "18:35", exp50: "2:35", exp100: "", franco: "", motivo: "Obra" },
  { fecha: "2026-08-18", entrada: "4:52", salida: "18:35", exp50: "4:35", exp100: "1:08", franco: "", motivo: "Guardia" },
  { fecha: "2026-08-22", entrada: "7:51", salida: "12:26", exp50: "", exp100: "4:35", franco: "", motivo: "Obra de línea (sábado)" },
  { fecha: "2026-08-24", entrada: "8:00", salida: "19:10", exp50: "3:10", exp100: "", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-25", entrada: "6:53", salida: "18:45", exp50: "3:52", exp100: "", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-26", entrada: "6:54", salida: "18:30", exp50: "3:36", exp100: "", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-27", entrada: "7:00", salida: "19:15", exp50: "4:15", exp100: "", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-28", entrada: "7:00", salida: "14:00", exp50: "1:00", exp100: "", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-29", entrada: "15:22", salida: "20:00", exp50: "", exp100: "4:38", franco: "", motivo: "Obra de línea" },
  { fecha: "2026-08-30", entrada: "7:50", salida: "16:03", exp50: "", exp100: "8:13", franco: "", motivo: "Mantenimiento de barra" },
  { fecha: "2026-08-31", entrada: "7:36", salida: "16:00", exp50: "0:24", exp100: "", franco: "", motivo: "" },
];

/** Totales impresos en el Word de agosto. */
export const AGOSTO_TOTALES = { tot50: "30:56", tot100: "26:44" };
