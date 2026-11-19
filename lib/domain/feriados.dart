/// Feriados nacionales de Argentina que la app marca automáticamente.
///
/// - 2026: calendario oficial con los traslados ya decretados (Güemes 15/6,
///   Soberanía 23/11) y el feriado del 9/11. NO incluye los "días no laborables
///   con fines turísticos" (23/3, 10/7, 7/12): no son feriados obligatorios.
/// - 2027: SOLO los inamovibles. Los trasladables (Güemes, San Martín,
///   Diversidad Cultural, Soberanía) dependen del decreto anual, que todavía no
///   salió; se marcan a mano con la casilla "Feriado" hasta actualizar esta lista.
///
/// Los feriados provinciales o puentes se marcan a mano.
/// Para actualizar: `https://api.argentinadatos.com/v1/feriados/AÑO`
library;

import 'fechas.dart';

const Map<String, String> feriadosNacionales = {
  // 2026
  '2026-01-01': 'Año Nuevo',
  '2026-02-16': 'Carnaval',
  '2026-02-17': 'Carnaval',
  '2026-03-24': 'Día de la Memoria',
  '2026-04-02': 'Malvinas',
  '2026-04-03': 'Viernes Santo',
  '2026-05-01': 'Día del Trabajador',
  '2026-05-25': 'Revolución de Mayo',
  '2026-06-15': 'Paso a la Inmortalidad de Güemes',
  '2026-06-20': 'Paso a la Inmortalidad de Belgrano',
  '2026-07-09': 'Día de la Independencia',
  '2026-08-17': 'Paso a la Inmortalidad de San Martín',
  '2026-10-12': 'Día de la Diversidad Cultural',
  '2026-11-09': 'Visita del papa León XIV',
  '2026-11-23': 'Día de la Soberanía Nacional',
  '2026-12-08': 'Inmaculada Concepción',
  '2026-12-25': 'Navidad',
  // 2027 (solo inamovibles)
  '2027-01-01': 'Año Nuevo',
  '2027-02-08': 'Carnaval',
  '2027-02-09': 'Carnaval',
  '2027-03-24': 'Día de la Memoria',
  '2027-03-26': 'Viernes Santo',
  '2027-04-02': 'Malvinas',
  '2027-05-01': 'Día del Trabajador',
  '2027-05-25': 'Revolución de Mayo',
  '2027-06-20': 'Paso a la Inmortalidad de Belgrano',
  '2027-07-09': 'Día de la Independencia',
  '2027-12-08': 'Inmaculada Concepción',
  '2027-12-25': 'Navidad',
};

/// Nombre del feriado nacional en esa fecha, o null si no hay.
String? feriadoEn(DateTime fecha) => feriadosNacionales[isoDate(fecha)];
