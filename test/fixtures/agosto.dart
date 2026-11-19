/// Horarios reales de la planilla de agosto 2026 (motivos y datos personales anonimizados) (privado/HSX-agosto-ejemplo.docx).
/// Son el "test de oro" del motor de reglas y del export a .docx.
///
///  - exp50 / exp100: horas extras impresas en el Word ("" cuando va vacía).
///  - franco / motivo: valores manuales tal como figuran en la planilla real.
class AgostoRow {
  final String fecha; // ISO "YYYY-MM-DD"
  final String entrada;
  final String salida;
  final String exp50;
  final String exp100;
  final String franco;
  final String motivo;
  const AgostoRow(this.fecha, this.entrada, this.salida, this.exp50, this.exp100, this.franco, this.motivo);

  DateTime get dia => DateTime.parse(fecha);
}

const agosto = <AgostoRow>[
  AgostoRow('2026-08-03', '8:00', '16:23', '0:23', '', '', 'Capacitación'),
  AgostoRow('2026-08-07', '6:02', '17:37', '3:35', '', '', 'Capacitación de manejo'),
  AgostoRow('2026-08-09', '7:00', '15:10', '', '8:10', '1', 'Mantenimiento de semibarra'),
  AgostoRow('2026-08-11', '6:59', '16:00', '1:01', '', '', 'Maniobra'),
  AgostoRow('2026-08-12', '7:03', '17:33', '2:30', '', '', 'Ensayos'),
  AgostoRow('2026-08-13', '8:00', '18:35', '2:35', '', '', 'Obra'),
  AgostoRow('2026-08-18', '4:52', '18:35', '4:35', '1:08', '', 'Guardia'),
  AgostoRow('2026-08-22', '7:51', '12:26', '', '4:35', '', 'Obra de línea (sábado)'),
  AgostoRow('2026-08-24', '8:00', '19:10', '3:10', '', '', 'Obra de línea'),
  AgostoRow('2026-08-25', '6:53', '18:45', '3:52', '', '', 'Obra de línea'),
  AgostoRow('2026-08-26', '6:54', '18:30', '3:36', '', '', 'Obra de línea'),
  AgostoRow('2026-08-27', '7:00', '19:15', '4:15', '', '', 'Obra de línea'),
  AgostoRow('2026-08-28', '7:00', '14:00', '1:00', '', '', 'Obra de línea'),
  AgostoRow('2026-08-29', '15:22', '20:00', '', '4:38', '', 'Obra de línea'),
  AgostoRow('2026-08-30', '7:50', '16:03', '', '8:13', '', 'Mantenimiento de barra'),
  AgostoRow('2026-08-31', '7:36', '16:00', '0:24', '', '', ''),
];

const agostoTot50 = '30:56';
const agostoTot100 = '26:44';
