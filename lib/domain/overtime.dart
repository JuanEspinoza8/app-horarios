/// Motor de reglas de horas extras (CCT 36/75 FATyF), según lo indicado por el
/// cliente y validado contra la planilla real de agosto 2026 (30:56 al 50% y
/// 26:44 al 100%).
///
/// Reglas:
///  - Horario normal Lun–Vie según el mes: enero y febrero 07:00–15:00, marzo a
///    diciembre 08:00–16:00. Lo trabajado DENTRO del horario normal no es extra;
///    salir antes no descuenta.
///  - Día hábil: fuera del horario normal, la franja nocturna (21:00–06:00) va
///    al 100% y el resto al 50%.
///  - Sábado, domingo y feriado: TODO lo trabajado va al 100%.
///  - Franco sugerido: sábado/domingo con 4:00 o más trabajadas, o feriado con
///    8:00 o más. El usuario lo puede forzar a Sí/No.
///  - Si el turno cruza la medianoche, lo que cae al día siguiente se evalúa
///    con el tipo y el horario de ese día.
library;

import 'feriados.dart';
import 'time.dart';

/// Horario normal de trabajo (minutos desde la medianoche).
class Horario {
  final int inicioMin;
  final int finMin;
  const Horario(this.inicioMin, this.finMin);

  String get texto => '${minutesToClock(inicioMin)} a ${minutesToClock(finMin)}';

  Map<String, dynamic> toJson() => {'inicio': inicioMin, 'fin': finMin};
  factory Horario.fromJson(Map<String, dynamic> j, Horario fallback) =>
      Horario((j['inicio'] as num?)?.toInt() ?? fallback.inicioMin, (j['fin'] as num?)?.toInt() ?? fallback.finMin);

  @override
  bool operator ==(Object other) => other is Horario && other.inicioMin == inicioMin && other.finMin == finMin;
  @override
  int get hashCode => Object.hash(inicioMin, finMin);
}

class ReglasConfig {
  /// Horario de verano (por defecto 07:00–15:00).
  final Horario horarioVerano;

  /// Meses (1..12) en los que rige el horario de verano. Def. enero y febrero.
  final Set<int> mesesVerano;

  /// Horario del resto del año (por defecto 08:00–16:00).
  final Horario horarioResto;

  /// Inicio de la franja nocturna al 100% (def. 21:00).
  final int nocheInicioMin;

  /// Fin de la franja nocturna al 100% (def. 06:00).
  final int nocheFinMin;

  /// Sábado/domingo: horas trabajadas a partir de las cuales corresponde franco.
  final int francoFindeMin;

  /// Feriado: horas trabajadas a partir de las cuales corresponde franco.
  final int francoFeriadoMin;

  const ReglasConfig({
    this.horarioVerano = const Horario(7 * 60, 15 * 60),
    this.mesesVerano = const {1, 2},
    this.horarioResto = const Horario(8 * 60, 16 * 60),
    this.nocheInicioMin = 21 * 60,
    this.nocheFinMin = 6 * 60,
    this.francoFindeMin = 4 * 60,
    this.francoFeriadoMin = 8 * 60,
  });

  static const ReglasConfig defaults = ReglasConfig();

  Horario horarioDelMes(int mes) => mesesVerano.contains(mes) ? horarioVerano : horarioResto;

  ReglasConfig copyWith({
    Horario? horarioVerano,
    Set<int>? mesesVerano,
    Horario? horarioResto,
    int? nocheInicioMin,
    int? nocheFinMin,
    int? francoFindeMin,
    int? francoFeriadoMin,
  }) => ReglasConfig(
    horarioVerano: horarioVerano ?? this.horarioVerano,
    mesesVerano: mesesVerano ?? this.mesesVerano,
    horarioResto: horarioResto ?? this.horarioResto,
    nocheInicioMin: nocheInicioMin ?? this.nocheInicioMin,
    nocheFinMin: nocheFinMin ?? this.nocheFinMin,
    francoFindeMin: francoFindeMin ?? this.francoFindeMin,
    francoFeriadoMin: francoFeriadoMin ?? this.francoFeriadoMin,
  );

  Map<String, dynamic> toJson() => {
    'horarioVerano': horarioVerano.toJson(),
    'mesesVerano': (mesesVerano.toList()..sort()),
    'horarioResto': horarioResto.toJson(),
    'nocheInicio': nocheInicioMin,
    'nocheFin': nocheFinMin,
    'francoFinde': francoFindeMin,
    'francoFeriado': francoFeriadoMin,
  };

  factory ReglasConfig.fromJson(Map<String, dynamic> j) {
    const d = defaults;
    return ReglasConfig(
      horarioVerano: j['horarioVerano'] is Map
          ? Horario.fromJson(Map<String, dynamic>.from(j['horarioVerano'] as Map), d.horarioVerano)
          : d.horarioVerano,
      mesesVerano: j['mesesVerano'] is List
          ? (j['mesesVerano'] as List).map((e) => (e as num).toInt()).toSet()
          : d.mesesVerano,
      horarioResto: j['horarioResto'] is Map
          ? Horario.fromJson(Map<String, dynamic>.from(j['horarioResto'] as Map), d.horarioResto)
          : d.horarioResto,
      nocheInicioMin: (j['nocheInicio'] as num?)?.toInt() ?? d.nocheInicioMin,
      nocheFinMin: (j['nocheFin'] as num?)?.toInt() ?? d.nocheFinMin,
      francoFindeMin: (j['francoFinde'] as num?)?.toInt() ?? d.francoFindeMin,
      francoFeriadoMin: (j['francoFeriado'] as num?)?.toInt() ?? d.francoFeriadoMin,
    );
  }
}

enum TipoDia {
  habil('Día hábil'),
  sabado('Sábado'),
  domingo('Domingo'),
  feriado('Feriado');

  const TipoDia(this.etiqueta);
  final String etiqueta;
}

class ResultadoDia {
  /// Minutos de hora extra al 50%.
  final int min50;

  /// Minutos de hora extra al 100%.
  final int min100;

  /// Minutos trabajados entre entrada y salida.
  final int trabajadoMin;

  final TipoDia tipo;

  /// Horario normal que rige ese día (según el mes).
  final Horario horario;

  /// true si por regla corresponde franco compensatorio.
  final bool francoSugerido;

  const ResultadoDia({
    required this.min50,
    required this.min100,
    required this.trabajadoMin,
    required this.tipo,
    required this.horario,
    required this.francoSugerido,
  });
}

/// ¿El minuto (puede ser >= 1440 si el turno cruzó la medianoche) cae en la
/// franja nocturna?
bool _esNocturno(int minuto, ReglasConfig cfg) {
  final m = ((minuto % minutosPorDia) + minutosPorDia) % minutosPorDia;
  if (cfg.nocheInicioMin <= cfg.nocheFinMin) {
    return m >= cfg.nocheInicioMin && m < cfg.nocheFinMin;
  }
  // Franja que cruza la medianoche: [inicio, 24h) ∪ [0, fin)
  return m >= cfg.nocheInicioMin || m < cfg.nocheFinMin;
}

/// Tipo de día. El feriado tiene prioridad sobre el día de la semana.
TipoDia tipoDeDia(DateTime fecha, bool esFeriado) {
  if (esFeriado) return TipoDia.feriado;
  return switch (fecha.weekday) {
    DateTime.saturday => TipoDia.sabado,
    DateTime.sunday => TipoDia.domingo,
    _ => TipoDia.habil,
  };
}

bool esFinDeSemana(DateTime fecha) => fecha.weekday == DateTime.saturday || fecha.weekday == DateTime.sunday;

/// Calcula las horas extras de un día.
ResultadoDia calcularDia({
  required DateTime fecha,
  required int entradaMin,
  required int salidaMin,
  bool esFeriado = false,
  ReglasConfig cfg = ReglasConfig.defaults,
}) {
  final span = workedSpan(entradaMin, salidaMin);
  final trabajado = span.end - span.start;
  final tipo = tipoDeDia(fecha, esFeriado);
  final horario = cfg.horarioDelMes(fecha.month);

  // Franco: fin de semana con >= 4 h, o feriado con >= 8 h (ambas reglas
  // valen a la vez: un feriado que cae sábado da franco con 4 h).
  final francoSugerido =
      (esFinDeSemana(fecha) && trabajado >= cfg.francoFindeMin) || (esFeriado && trabajado >= cfg.francoFeriadoMin);

  // Cada minuto se evalúa según el día calendario en que cae: si el turno
  // cruza la medianoche, lo que cae al día siguiente usa el tipo y el horario
  // de ese día (p. ej. viernes 22:00 → sábado 08:00: lo del sábado va al 100%).
  var min50 = 0;
  var min100 = 0;
  var diaOffset = -1;
  late bool diaAl100;
  late Horario horarioDia;
  for (var m = span.start; m < span.end; m++) {
    final offset = m ~/ minutosPorDia;
    if (offset != diaOffset) {
      diaOffset = offset;
      final dia = DateTime(fecha.year, fecha.month, fecha.day + offset);
      final feriadoDia = offset == 0 ? esFeriado : feriadoEn(dia) != null;
      diaAl100 = feriadoDia || esFinDeSemana(dia);
      horarioDia = cfg.horarioDelMes(dia.month);
    }
    final minDelDia = m % minutosPorDia;
    if (diaAl100) {
      min100++;
    } else if (minDelDia >= horarioDia.inicioMin && minDelDia < horarioDia.finMin) {
      // Dentro del horario normal: no es extra.
    } else if (_esNocturno(minDelDia, cfg)) {
      min100++;
    } else {
      min50++;
    }
  }

  return ResultadoDia(
    min50: min50,
    min100: min100,
    trabajadoMin: trabajado,
    tipo: tipo,
    horario: horario,
    francoSugerido: francoSugerido,
  );
}
