import { describe, it, expect } from "vitest";
import { computeDay, totales, tipoDeDia } from "./overtime";
import { formatHHMM } from "./time";
import { AGOSTO, AGOSTO_TOTALES } from "./__fixtures__/agosto";

const cell = (min: number) => (min === 0 ? "" : formatHHMM(min));
const compute = (row: { fecha: string; entrada: string; salida: string }) =>
  computeDay({ fechaISO: row.fecha, entrada: row.entrada, salida: row.salida });

describe("motor de reglas - planilla agosto 2026", () => {
  for (const row of AGOSTO) {
    it(`${row.fecha} ${row.entrada}-${row.salida}`, () => {
      const r = compute(row);
      expect(cell(r.min50)).toBe(row.exp50);
      expect(cell(r.min100)).toBe(row.exp100);
    });
  }

  it(`totales del mes coinciden con el Word (${AGOSTO_TOTALES.tot50} al 50%, ${AGOSTO_TOTALES.tot100} al 100%)`, () => {
    const t = totales(AGOSTO.map((row) => compute(row)));
    expect(formatHHMM(t.min50)).toBe(AGOSTO_TOTALES.tot50);
    expect(formatHHMM(t.min100)).toBe(AGOSTO_TOTALES.tot100);
  });
});

describe("clasificación de tipo de día", () => {
  it("sábado, domingo y hábil", () => {
    expect(tipoDeDia("2026-08-01", false)).toBe("sabado");
    expect(tipoDeDia("2026-08-02", false)).toBe("domingo");
    expect(tipoDeDia("2026-08-03", false)).toBe("habil");
  });
  it("feriado tiene prioridad sobre el día de semana", () => {
    expect(tipoDeDia("2026-08-03", true)).toBe("feriado");
  });
  it("franco se sugiere en domingo/feriado, no en sábado", () => {
    expect(computeDay({ fechaISO: "2026-08-09", entrada: "7:00", salida: "15:10" }).francoSugerido).toBe(true);
    expect(computeDay({ fechaISO: "2026-08-22", entrada: "7:51", salida: "12:26" }).francoSugerido).toBe(false);
  });
});
