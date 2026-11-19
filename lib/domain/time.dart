/// Utilidades de tiempo. Todo se maneja en "minutos desde la medianoche"
/// (0..1439). Las duraciones pueden superar 24 h (p. ej. totales del mes).
library;

const int minutosPorDia = 24 * 60;

/// "HH:MM" -> minutos desde la medianoche. Acepta "8:00", "08:00", "6:53".
int parseHHMM(String value) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (m == null) {
    throw FormatException('Hora inválida: "$value" (formato esperado HH:MM)');
  }
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) throw FormatException('Hora fuera de rango: "$value"');
  return h * 60 + min;
}

/// Formatea una duración (o una hora del día) como "H:MM", sin cero a la
/// izquierda en las horas, tal como aparece en la planilla: "0:23", "8:00", "30:56".
String formatHHMM(int totalMinutes) {
  final sign = totalMinutes < 0 ? '-' : '';
  final abs = totalMinutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  return '$sign$h:${m.toString().padLeft(2, '0')}';
}

/// Minutos desde medianoche -> "HH:MM" 24 h con cero a la izquierda ("08:00").
String minutesToClock(int min) {
  final m = ((min % minutosPorDia) + minutosPorDia) % minutosPorDia;
  final h = m ~/ 60;
  return '${h.toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// Tramo trabajado [start, end) en minutos. Si la salida es <= la entrada se
/// asume que el turno cruza la medianoche (end > 1440).
({int start, int end}) workedSpan(int entradaMin, int salidaMin) {
  final end = salidaMin <= entradaMin ? salidaMin + minutosPorDia : salidaMin;
  return (start: entradaMin, end: end);
}
