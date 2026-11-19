import { useEffect, useMemo, useState } from "react";
import { computeDay } from "./lib/overtime";
import { formatHHMM } from "./lib/time";
import { nombreMes } from "./lib/format";
import {
  loadEmpleado, saveEmpleado, loadConfig, saveConfig, loadDias, saveDias,
} from "./lib/store";
import type { Dia, Empleado, MonthKey } from "./types";
import { monthKeyOf } from "./types";
import DiaForm from "./components/DiaForm";
import Ajustes from "./components/Ajustes";

const DOW = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];

function diaSemana(fechaISO: string): string {
  const [y, m, d] = fechaISO.split("-").map(Number);
  return DOW[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
}

function shiftMonth(monthKey: MonthKey, delta: number): MonthKey {
  const [y, m] = monthKey.split("-").map(Number);
  const d = new Date(Date.UTC(y, m - 1 + delta, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

function labelMes(monthKey: MonthKey): string {
  const [y] = monthKey.split("-");
  return `${nombreMes(`${monthKey}-01`)} ${y}`;
}

type Editing = { mode: "nuevo" } | { mode: "editar"; dia: Dia } | null;

export default function App() {
  const [empleado, setEmpleado] = useState<Empleado>(() => loadEmpleado());
  const [config, setConfig] = useState(() => loadConfig());
  const [dias, setDias] = useState<Dia[]>(() => loadDias());
  const [mes, setMes] = useState<MonthKey>(() => new Date().toISOString().slice(0, 7));
  const [editing, setEditing] = useState<Editing>(null);
  const [verAjustes, setVerAjustes] = useState(false);
  const [exportando, setExportando] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => saveEmpleado(empleado), [empleado]);
  useEffect(() => saveConfig(config), [config]);
  useEffect(() => saveDias(dias), [dias]);

  const delMes = useMemo(
    () =>
      dias
        .filter((d) => monthKeyOf(d.fechaISO) === mes)
        .sort((a, b) => a.fechaISO.localeCompare(b.fechaISO))
        .map((d) => ({ dia: d, calc: computeDay(d, config) })),
    [dias, mes, config],
  );

  const totales = useMemo(() => {
    let min50 = 0, min100 = 0, francos = 0;
    for (const { dia, calc } of delMes) {
      min50 += calc.min50;
      min100 += calc.min100;
      if (dia.franco) francos += 1;
    }
    return { min50, min100, francos };
  }, [delMes]);

  function upsertDia(d: Dia) {
    setDias((prev) => {
      const i = prev.findIndex((x) => x.id === d.id);
      if (i === -1) return [...prev, d];
      const copy = prev.slice();
      copy[i] = d;
      return copy;
    });
    setEditing(null);
  }

  function borrarDia(id: string) {
    setDias((prev) => prev.filter((x) => x.id !== id));
    setEditing(null);
  }

  async function onExportar() {
    setError(null);
    setExportando(true);
    try {
      // Carga diferida: docxtemplater solo se descarga al exportar.
      const { exportarMes } = await import("./lib/export");
      const delMesDias = dias.filter((d) => monthKeyOf(d.fechaISO) === mes);
      await exportarMes(empleado, delMesDias, mes, config);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Error al generar el Word.");
    } finally {
      setExportando(false);
    }
  }

  const perfilIncompleto = !empleado.nombre || !empleado.legajo;

  return (
    <div className="app">
      <header className="topbar">
        <h1>Horas Extras</h1>
        <button className="icon-btn" onClick={() => setVerAjustes(true)} aria-label="Ajustes">⚙</button>
      </header>

      <div className="month-nav">
        <button className="icon-btn" onClick={() => setMes((m) => shiftMonth(m, -1))} aria-label="Mes anterior">‹</button>
        <span className="month-label">{labelMes(mes)}</span>
        <button className="icon-btn" onClick={() => setMes((m) => shiftMonth(m, 1))} aria-label="Mes siguiente">›</button>
      </div>

      <section className="totales-card">
        <div className="total">
          <span className="total-val">{formatHHMM(totales.min50)}</span>
          <span className="total-lbl">al 50%</span>
        </div>
        <div className="total">
          <span className="total-val">{formatHHMM(totales.min100)}</span>
          <span className="total-lbl">al 100%</span>
        </div>
        <div className="total">
          <span className="total-val">{totales.francos}</span>
          <span className="total-lbl">francos</span>
        </div>
      </section>

      {perfilIncompleto && (
        <button className="banner" onClick={() => setVerAjustes(true)}>
          Completá tu nombre y legajo en Ajustes para el encabezado del Word.
        </button>
      )}

      {error && <div className="banner banner-error">{error}</div>}

      <main className="lista">
        {delMes.length === 0 ? (
          <div className="vacio">
            <p>No cargaste días en {labelMes(mes)}.</p>
            <button className="btn btn-primary" onClick={() => setEditing({ mode: "nuevo" })}>Agregar el primero</button>
          </div>
        ) : (
          delMes.map(({ dia, calc }) => (
            <button key={dia.id} className="dia-row" onClick={() => setEditing({ mode: "editar", dia })}>
              <div className="dia-fecha">
                <span className="dia-num">{dia.fechaISO.slice(8)}</span>
                <span className="dia-dow">{diaSemana(dia.fechaISO)}</span>
              </div>
              <div className="dia-main">
                <div className="dia-horas">{dia.entrada} – {dia.salida}{dia.esFeriado ? " · feriado" : ""}</div>
                {dia.motivo && <div className="dia-motivo">{dia.motivo}</div>}
                <div className="dia-badges">
                  {calc.min50 > 0 && <span className="badge badge-50">50%: {formatHHMM(calc.min50)}</span>}
                  {calc.min100 > 0 && <span className="badge badge-100">100%: {formatHHMM(calc.min100)}</span>}
                  {dia.franco && <span className="badge badge-franco">franco</span>}
                  {(dia.viatico25 || dia.viatico50) && <span className="badge badge-via">viático</span>}
                </div>
              </div>
              <span className="chevron">›</span>
            </button>
          ))
        )}
      </main>

      <footer className="actions">
        <button
          className="btn btn-ghost btn-block"
          onClick={onExportar}
          disabled={exportando || delMes.length === 0}
        >
          {exportando ? "Generando…" : "Exportar Word"}
        </button>
        <button className="fab" onClick={() => setEditing({ mode: "nuevo" })} aria-label="Agregar día">+</button>
      </footer>

      {editing && (
        <DiaForm
          dia={editing.mode === "editar" ? editing.dia : null}
          monthKey={mes}
          config={config}
          onSave={upsertDia}
          onDelete={borrarDia}
          onClose={() => setEditing(null)}
        />
      )}

      {verAjustes && (
        <Ajustes
          empleado={empleado}
          config={config}
          onSave={(e, c) => {
            setEmpleado(e);
            setConfig(c);
            setVerAjustes(false);
          }}
          onClose={() => setVerAjustes(false)}
        />
      )}
    </div>
  );
}
