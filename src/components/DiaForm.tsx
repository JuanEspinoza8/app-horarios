import { useEffect, useMemo, useState } from "react";
import { computeDay, type Config, type DayType } from "../lib/overtime";
import { formatHHMM } from "../lib/time";
import { nuevoId } from "../lib/store";
import type { Dia, MonthKey } from "../types";

interface Props {
  dia: Dia | null; // null = nuevo
  monthKey: MonthKey;
  config: Config;
  onSave: (d: Dia) => void;
  onDelete?: (id: string) => void;
  onClose: () => void;
}

const ETIQUETA_DIA: Record<DayType, string> = {
  habil: "Día hábil",
  sabado: "Sábado",
  domingo: "Domingo",
  feriado: "Feriado",
};

function boundsDelMes(monthKey: MonthKey) {
  const [y, m] = monthKey.split("-").map(Number);
  const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
  return { min: `${monthKey}-01`, max: `${monthKey}-${String(last).padStart(2, "0")}` };
}

export default function DiaForm({ dia, monthKey, config, onSave, onDelete, onClose }: Props) {
  const esNuevo = dia === null;
  const { min, max } = boundsDelMes(monthKey);

  const [fecha, setFecha] = useState(dia?.fechaISO ?? min);
  const [entrada, setEntrada] = useState(dia?.entrada ?? "");
  const [salida, setSalida] = useState(dia?.salida ?? "");
  const [esFeriado, setEsFeriado] = useState(dia?.esFeriado ?? false);
  const [motivo, setMotivo] = useState(dia?.motivo ?? "");
  const [via25, setVia25] = useState(dia?.viatico25 ?? "");
  const [via50, setVia50] = useState(dia?.viatico50 ?? "");
  const [franco, setFranco] = useState(!!dia?.franco);
  const [francoTouched, setFrancoTouched] = useState(!esNuevo);

  const calc = useMemo(() => {
    if (!entrada || !salida) return null;
    try {
      return computeDay({ fechaISO: fecha, entrada, salida, esFeriado }, config);
    } catch {
      return null;
    }
  }, [fecha, entrada, salida, esFeriado, config]);

  // Para días nuevos, el franco sigue la sugerencia hasta que el usuario lo toca.
  useEffect(() => {
    if (!francoTouched && calc) setFranco(calc.francoSugerido);
  }, [calc, francoTouched]);

  const valido = Boolean(fecha && entrada && salida && calc);

  function guardar() {
    if (!valido) return;
    onSave({
      id: dia?.id ?? nuevoId(),
      fechaISO: fecha,
      entrada,
      salida,
      esFeriado,
      franco: franco ? "1" : "",
      viatico25: via25.trim(),
      viatico50: via50.trim(),
      motivo: motivo.trim(),
    });
  }

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
        <header className="sheet-head">
          <h2>{esNuevo ? "Agregar día" : "Editar día"}</h2>
          <button className="icon-btn" onClick={onClose} aria-label="Cerrar">✕</button>
        </header>

        <div className="sheet-body">
          <label className="field">
            <span>Fecha</span>
            <input type="date" value={fecha} min={min} max={max} onChange={(e) => setFecha(e.target.value)} />
          </label>

          <div className="row2">
            <label className="field">
              <span>Entrada</span>
              <input type="time" value={entrada} onChange={(e) => setEntrada(e.target.value)} />
            </label>
            <label className="field">
              <span>Salida</span>
              <input type="time" value={salida} onChange={(e) => setSalida(e.target.value)} />
            </label>
          </div>

          <label className="check">
            <input type="checkbox" checked={esFeriado} onChange={(e) => setEsFeriado(e.target.checked)} />
            <span>Es feriado</span>
          </label>

          {calc && (
            <div className="calc-preview">
              <span className="badge badge-tipo">{ETIQUETA_DIA[calc.dayType]}</span>
              <span className="badge badge-50">50%: {calc.min50 ? formatHHMM(calc.min50) : "—"}</span>
              <span className="badge badge-100">100%: {calc.min100 ? formatHHMM(calc.min100) : "—"}</span>
              {calc.francoSugerido && <span className="badge badge-franco">franco sugerido</span>}
            </div>
          )}

          <label className="check">
            <input
              type="checkbox"
              checked={franco}
              onChange={(e) => {
                setFranco(e.target.checked);
                setFrancoTouched(true);
              }}
            />
            <span>Genera franco compensatorio</span>
          </label>

          <label className="field">
            <span>Motivo</span>
            <input type="text" value={motivo} placeholder="Ej: Mantto Barra 132KV" onChange={(e) => setMotivo(e.target.value)} />
          </label>

          <div className="row2">
            <label className="field">
              <span>Viático 25%</span>
              <input type="text" value={via25} placeholder="(después)" onChange={(e) => setVia25(e.target.value)} />
            </label>
            <label className="field">
              <span>Viático 50%</span>
              <input type="text" value={via50} placeholder="(después)" onChange={(e) => setVia50(e.target.value)} />
            </label>
          </div>
        </div>

        <footer className="sheet-foot">
          {!esNuevo && onDelete && (
            <button className="btn btn-danger" onClick={() => onDelete(dia!.id)}>Borrar</button>
          )}
          <div className="spacer" />
          <button className="btn btn-ghost" onClick={onClose}>Cancelar</button>
          <button className="btn btn-primary" onClick={guardar} disabled={!valido}>Guardar</button>
        </footer>
      </div>
    </div>
  );
}
