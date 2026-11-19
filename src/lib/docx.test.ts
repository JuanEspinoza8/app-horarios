import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import PizZip from "pizzip";
import { buildPlanillaData, renderPlanilla, type DiaCargado, type Empleado } from "./docx";
import { AGOSTO, AGOSTO_TOTALES } from "./__fixtures__/agosto";

const TEMPLATE_PATH = resolve(process.cwd(), "public/plantilla.docx");

const EMPLEADO: Empleado = {
  nombre: "Pérez Juan",
  legajo: "1234",
  convenio: "CCT 36/75 FATyF",
};

const DIAS: DiaCargado[] = AGOSTO.map((r) => ({
  fechaISO: r.fecha,
  entrada: r.entrada,
  salida: r.salida,
  franco: r.franco,
  motivo: r.motivo,
}));

/** Extrae el texto concatenado de cada celda de cada fila de una tabla. */
function extraerFilasDeTabla(documentXml: string, tablaIndex: number): string[][] {
  const tablas = documentXml.match(/<w:tbl>[\s\S]*?<\/w:tbl>/g) ?? [];
  const tabla = tablas[tablaIndex];
  const filas = tabla.match(/<w:tr\b[\s\S]*?<\/w:tr>/g) ?? [];
  return filas.map((fila) => {
    const celdas = fila.match(/<w:tc>[\s\S]*?<\/w:tc>/g) ?? [];
    return celdas.map((c) => {
      const textos = [...c.matchAll(/<w:t\b[^>]*>([^<]*)<\/w:t>/g)].map((m) => m[1]);
      return textos.join("");
    });
  });
}

describe("export a .docx - regenera la planilla de agosto", () => {
  const template = readFileSync(TEMPLATE_PATH);
  const data = buildPlanillaData(EMPLEADO, DIAS, "Agosto");
  const out = renderPlanilla(template, data);
  const zip = new PizZip(out);
  const xml = zip.file("word/document.xml")!.asText();

  it("el documento resultante es un .docx válido", () => {
    expect(xml).toContain("<w:document");
    expect(xml.trim().endsWith("</w:document>")).toBe(true);
    expect(zip.file("word/media/image1.png")).toBeTruthy(); // conserva assets originales
  });

  it("el encabezado tiene los datos del empleado", () => {
    const enc = extraerFilasDeTabla(xml, 0);
    const textoEnc = enc.flat().join(" | ");
    expect(textoEnc).toContain("Pérez Juan");
    expect(textoEnc).toContain("1234");
    expect(textoEnc).toContain("Agosto");
    expect(textoEnc).toContain("CCT 36/75 FATyF");
  });

  it("hay una fila por día cargado (16 días)", () => {
    const filas = extraerFilasDeTabla(xml, 1);
    // 2 filas de encabezado + 16 de datos + 1 de totales
    expect(filas.length).toBe(2 + 16 + 1);
  });

  it("cada valor cae en su columna, fila por fila", () => {
    const filas = extraerFilasDeTabla(xml, 1);
    const dataRows = filas.slice(2, filas.length - 1);
    expect(dataRows.length).toBe(data.filas.length);
    dataRows.forEach((celdas, i) => {
      const f = data.filas[i];
      expect(celdas).toEqual([
        f.fecha, f.entrada, f.salida, f.al50, f.al100, f.franco, f.via25, f.via50, f.motivo,
      ]);
    });
  });

  it("la fila de totales coincide con el Word original", () => {
    const filas = extraerFilasDeTabla(xml, 1);
    const totales = filas[filas.length - 1];
    expect(totales).toContain(AGOSTO_TOTALES.tot50); // 30:56
    expect(totales).toContain(AGOSTO_TOTALES.tot100); // 26:44
  });
});
