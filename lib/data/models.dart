import 'dart:math';

import '../domain/fechas.dart';
import '../domain/overtime.dart';

/// Franco del día: automático (según la regla) o forzado a Sí / No.
enum FrancoModo { auto, si, no }

/// Un día cargado por el usuario.
class Dia {
  final String id;

  /// Fecha de la ENTRADA (si el turno cruza la medianoche, sigue siendo este día).
  final DateTime fecha;
  final int entradaMin;
  final int salidaMin;
  final bool esFeriado;
  final FrancoModo franco;
  final String motivo;

  Dia({
    required this.id,
    required DateTime fecha,
    required this.entradaMin,
    required this.salidaMin,
    this.esFeriado = false,
    this.franco = FrancoModo.auto,
    this.motivo = '',
  }) : fecha = soloFecha(fecha);

  ResultadoDia calcular(ReglasConfig cfg) =>
      calcularDia(fecha: fecha, entradaMin: entradaMin, salidaMin: salidaMin, esFeriado: esFeriado, cfg: cfg);

  /// Franco que va a la planilla: el sugerido por regla, salvo que se haya forzado.
  bool francoEfectivo(ResultadoDia r) => switch (franco) {
    FrancoModo.auto => r.francoSugerido,
    FrancoModo.si => true,
    FrancoModo.no => false,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': isoDate(fecha),
    'entrada': entradaMin,
    'salida': salidaMin,
    'feriado': esFeriado,
    'franco': franco.name,
    'motivo': motivo,
  };

  factory Dia.fromJson(Map<String, dynamic> j) => Dia(
    id: j['id'] as String,
    fecha: parseIsoDate(j['fecha'] as String),
    entradaMin: (j['entrada'] as num).toInt(),
    salidaMin: (j['salida'] as num).toInt(),
    esFeriado: j['feriado'] as bool? ?? false,
    franco: FrancoModo.values.asNameMap()[j['franco']] ?? FrancoModo.auto,
    motivo: j['motivo'] as String? ?? '',
  );

  static final _rnd = Random();
  static String nuevoId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_rnd.nextInt(1 << 30).toRadixString(36)}';
}

/// Datos fijos del empleado (encabezado de la planilla).
class Empleado {
  final String nombre;
  final String legajo;
  final String convenio;

  /// Texto de la celda "Horario Normal" del encabezado (vacío por defecto,
  /// como en la planilla original).
  final String horario;

  const Empleado({this.nombre = '', this.legajo = '', this.convenio = 'CCT 36/75 FATyF', this.horario = ''});

  bool get incompleto => nombre.trim().isEmpty || legajo.trim().isEmpty;

  Map<String, dynamic> toJson() => {'nombre': nombre, 'legajo': legajo, 'convenio': convenio, 'horario': horario};

  factory Empleado.fromJson(Map<String, dynamic> j) {
    const d = Empleado();
    return Empleado(
      nombre: j['nombre'] as String? ?? d.nombre,
      legajo: j['legajo'] as String? ?? d.legajo,
      convenio: j['convenio'] as String? ?? d.convenio,
      horario: j['horario'] as String? ?? d.horario,
    );
  }
}
