// Genera un .docx de muestra (agosto) rellenando public/plantilla.docx.
// Sirve para comparar visualmente contra la planilla original del cliente.
// Uso: node scripts/gen-agosto.mjs [rutaSalida]
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import PizZip from "pizzip";
import Docxtemplater from "docxtemplater";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, "..");
const salida = process.argv[2] ?? resolve(ROOT, "HSX-agosto-generado.docx");

// Datos de agosto (al50/al100 ya validados por el motor y sus tests).
const filas = [
  ["03/08/26", "8:00", "16:23", "0:23", "", "", "Capacitación"],
  ["07/08/26", "6:02", "17:37", "3:35", "", "", "Capacitación de manejo"],
  ["09/08/26", "7:00", "15:10", "", "8:10", "1", "Mantenimiento de semibarra"],
  ["11/08/26", "6:59", "16:00", "1:01", "", "", "Maniobra"],
  ["12/08/26", "7:03", "17:33", "2:30", "", "", "Ensayos"],
  ["13/08/26", "8:00", "18:35", "2:35", "", "", "Obra"],
  ["18/08/26", "4:52", "18:35", "4:35", "1:08", "", "Guardia"],
  ["22/08/26", "7:51", "12:26", "", "4:35", "", "Obra de línea (sábado)"],
  ["24/08/26", "8:00", "19:10", "3:10", "", "", "Obra de línea"],
  ["25/08/26", "6:53", "18:45", "3:52", "", "", "Obra de línea"],
  ["26/08/26", "6:54", "18:30", "3:36", "", "", "Obra de línea"],
  ["27/08/26", "7:00", "19:15", "4:15", "", "", "Obra de línea"],
  ["28/08/26", "7:00", "14:00", "1:00", "", "", "Obra de línea"],
  ["29/08/26", "15:22", "20:00", "", "4:38", "", "Obra de línea"],
  ["30/08/26", "7:50", "16:03", "", "8:13", "", "Mantenimiento de barra"],
  ["31/08/26", "7:36", "16:00", "0:24", "", "", ""],
].map(([fecha, entrada, salida, al50, al100, franco, motivo]) => ({
  fecha, entrada, salida, al50, al100, franco, via25: "", via50: "", motivo,
}));

const data = {
  nombre: "Pérez Juan",
  legajo: "1234",
  mes: "Agosto",
  convenio: "CCT 36/75 FATyF",
  horario: "",
  filas,
  tot50: "30:56",
  tot100: "26:44",
};

const template = readFileSync(resolve(ROOT, "public/plantilla.docx"));
const doc = new Docxtemplater(new PizZip(template), { paragraphLoop: true, linebreaks: true });
doc.render(data);
writeFileSync(salida, doc.getZip().generate({ type: "nodebuffer" }));
console.log("Generado:", salida);
