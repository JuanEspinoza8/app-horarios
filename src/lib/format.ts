/** Helpers de formato de fecha/mes, sin dependencias pesadas (para no arrastrar
 * docxtemplater al chunk principal). */

const MESES = [
  "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
  "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
];

/** "YYYY-MM-DD" -> "DD/MM/YY" como en la planilla. */
export function formatFechaCorta(fechaISO: string): string {
  const [y, m, d] = fechaISO.split("-");
  return `${d}/${m}/${y.slice(2)}`;
}

/** "YYYY-MM..." -> nombre del mes en español. */
export function nombreMes(fechaISO: string): string {
  const m = Number(fechaISO.split("-")[1]);
  return MESES[m - 1] ?? "";
}
