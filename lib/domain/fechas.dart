/// Helpers de fechas en español (sin depender de la inicialización de intl).
library;

const meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String nombreMes(int mes) => meses[mes - 1];

/// "Lun".."Dom" para DateTime.weekday (1..7).
String diaSemanaCorto(DateTime f) => _diasSemana[f.weekday - 1];

/// DateTime -> "YYYY-MM-DD".
String isoDate(DateTime f) =>
    '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

/// "YYYY-MM-DD" -> DateTime local a medianoche.
DateTime parseIsoDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// "DD/MM/YY" como en la planilla.
String fechaCorta(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${(f.year % 100).toString().padLeft(2, '0')}';

/// Solo la fecha (sin hora).
DateTime soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);
