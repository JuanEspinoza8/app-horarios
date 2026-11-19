import { useState } from "react";
import type { Config } from "../lib/overtime";
import { minutesToClock, parseHHMM } from "../lib/time";
import type { Empleado } from "../types";

interface Props {
  empleado: Empleado;
  config: Config;
  onSave: (empleado: Empleado, config: Config) => void;
  onClose: () => void;
}

export default function Ajustes({ empleado, config, onSave, onClose }: Props) {
  const [nombre, setNombre] = useState(empleado.nombre);
  const [legajo, setLegajo] = useState(empleado.legajo);
  const [convenio, setConvenio] = useState(empleado.convenio);
  const [horario, setHorario] = useState(empleado.horario);

  const [normalInicio, setNormalInicio] = useState(minutesToClock(config.normalStartMin));
  const [normalFin, setNormalFin] = useState(minutesToClock(config.normalEndMin));
  const [nocheInicio, setNocheInicio] = useState(minutesToClock(config.nightStartMin));
  const [nocheFin, setNocheFin] = useState(minutesToClock(config.nightEndMin));

  function guardar() {
    onSave(
      { nombre: nombre.trim(), legajo: legajo.trim(), convenio: convenio.trim(), horario: horario.trim() },
      {
        ...config,
        normalStartMin: parseHHMM(normalInicio),
        normalEndMin: parseHHMM(normalFin),
        nightStartMin: parseHHMM(nocheInicio),
        nightEndMin: parseHHMM(nocheFin),
      },
    );
  }

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
        <header className="sheet-head">
          <h2>Ajustes</h2>
          <button className="icon-btn" onClick={onClose} aria-label="Cerrar">✕</button>
        </header>

        <div className="sheet-body">
          <h3 className="group-title">Empleado</h3>
          <label className="field">
            <span>Apellido y Nombre</span>
            <input type="text" value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Apellido Nombre" />
          </label>
          <div className="row2">
            <label className="field">
              <span>Legajo N°</span>
              <input type="text" value={legajo} onChange={(e) => setLegajo(e.target.value)} />
            </label>
            <label className="field">
              <span>Convenio</span>
              <input type="text" value={convenio} onChange={(e) => setConvenio(e.target.value)} />
            </label>
          </div>
          <label className="field">
            <span>Horario normal (texto del encabezado)</span>
            <input type="text" value={horario} onChange={(e) => setHorario(e.target.value)} placeholder="Opcional" />
          </label>

          <h3 className="group-title">Reglas de cálculo</h3>
          <p className="hint">
            Fuera del horario normal cuenta como extra. En día hábil, la franja nocturna va al 100%; el resto al 50%.
          </p>
          <div className="row2">
            <label className="field">
              <span>Horario normal — desde</span>
              <input type="time" value={normalInicio} onChange={(e) => setNormalInicio(e.target.value)} />
            </label>
            <label className="field">
              <span>Horario normal — hasta</span>
              <input type="time" value={normalFin} onChange={(e) => setNormalFin(e.target.value)} />
            </label>
          </div>
          <div className="row2">
            <label className="field">
              <span>Nocturno (100%) — desde</span>
              <input type="time" value={nocheInicio} onChange={(e) => setNocheInicio(e.target.value)} />
            </label>
            <label className="field">
              <span>Nocturno (100%) — hasta</span>
              <input type="time" value={nocheFin} onChange={(e) => setNocheFin(e.target.value)} />
            </label>
          </div>
        </div>

        <footer className="sheet-foot">
          <div className="spacer" />
          <button className="btn btn-ghost" onClick={onClose}>Cancelar</button>
          <button className="btn btn-primary" onClick={guardar}>Guardar</button>
        </footer>
      </div>
    </div>
  );
}
