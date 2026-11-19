/** Genera y descarga el .docx del mes rellenando public/plantilla.docx. */
import { buildPlanillaData, renderPlanilla, type DiaCargado } from "./docx";
import { nombreMes } from "./format";
import type { Config } from "./overtime";
import type { Dia, Empleado, MonthKey } from "../types";

const DOCX_MIME =
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

export async function exportarMes(
  empleado: Empleado,
  dias: Dia[],
  monthKey: MonthKey,
  cfg: Config,
): Promise<void> {
  const resp = await fetch(`${import.meta.env.BASE_URL}plantilla.docx`);
  if (!resp.ok) throw new Error("No se pudo cargar la plantilla (plantilla.docx).");
  const template = new Uint8Array(await resp.arrayBuffer());

  const [anio] = monthKey.split("-");
  const nombreDelMes = nombreMes(`${monthKey}-01`);

  const cargados: DiaCargado[] = [...dias]
    .sort((a, b) => a.fechaISO.localeCompare(b.fechaISO))
    .map((d) => ({
      fechaISO: d.fechaISO,
      entrada: d.entrada,
      salida: d.salida,
      esFeriado: d.esFeriado,
      franco: d.franco,
      viatico25: d.viatico25,
      viatico50: d.viatico50,
      motivo: d.motivo,
    }));

  const data = buildPlanillaData(empleado, cargados, nombreDelMes, cfg);
  const bytes = renderPlanilla(template, data);

  const blob = new Blob([bytes as BlobPart], { type: DOCX_MIME });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `HSX ${nombreDelMes} ${anio}.docx`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1500);
}
