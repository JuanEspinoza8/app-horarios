import 'package:flutter_test/flutter_test.dart';
import 'package:horas_extras/domain/feriados.dart';
import 'package:horas_extras/domain/overtime.dart';
import 'package:horas_extras/domain/time.dart';

import 'fixtures/agosto.dart';

String celda(int min) => min == 0 ? '' : formatHHMM(min);

ResultadoDia calc(String fecha, String entrada, String salida, {bool feriado = false}) => calcularDia(
  fecha: DateTime.parse(fecha),
  entradaMin: parseHHMM(entrada),
  salidaMin: parseHHMM(salida),
  esFeriado: feriado,
);

void main() {
  group('planilla real de agosto 2026 (marzo–diciembre, 08–16)', () {
    for (final r in agosto) {
      test('${r.fecha} ${r.entrada}-${r.salida}', () {
        final res = calc(r.fecha, r.entrada, r.salida);
        expect(celda(res.min50), r.exp50, reason: 'al 50%');
        expect(celda(res.min100), r.exp100, reason: 'al 100%');
      });
    }

    test('totales del mes = $agostoTot50 al 50% y $agostoTot100 al 100%', () {
      var t50 = 0, t100 = 0;
      for (final r in agosto) {
        final res = calc(r.fecha, r.entrada, r.salida);
        t50 += res.min50;
        t100 += res.min100;
      }
      expect(formatHHMM(t50), agostoTot50);
      expect(formatHHMM(t100), agostoTot100);
    });
  });

  group('horario de verano (enero y febrero, 07–15)', () {
    test('enero usa 07–15 y marzo vuelve a 08–16', () {
      expect(ReglasConfig.defaults.horarioDelMes(1).texto, '07:00 a 15:00');
      expect(ReglasConfig.defaults.horarioDelMes(2).texto, '07:00 a 15:00');
      expect(ReglasConfig.defaults.horarioDelMes(3).texto, '08:00 a 16:00');
      expect(ReglasConfig.defaults.horarioDelMes(12).texto, '08:00 a 16:00');
    });

    test('enero 07:00–17:00 → 2:00 al 50% (15 a 17)', () {
      final r = calc('2027-01-12', '7:00', '17:00'); // martes
      expect(r.tipo, TipoDia.habil);
      expect(celda(r.min50), '2:00');
      expect(celda(r.min100), '');
    });

    test('enero 05:30–15:00 → 0:30 al 100% (05:30–06) y 1:00 al 50% (06–07)', () {
      final r = calc('2027-01-12', '5:30', '15:00');
      expect(celda(r.min100), '0:30');
      expect(celda(r.min50), '1:00');
    });

    test('febrero 07:00–23:00 → 6:00 al 50% (15–21) y 2:00 al 100% (21–23)', () {
      final r = calc('2027-02-10', '7:00', '23:00'); // miércoles
      expect(celda(r.min50), '6:00');
      expect(celda(r.min100), '2:00');
    });

    test('el mismo horario en marzo da distinto (08–16)', () {
      final r = calc('2027-03-10', '7:00', '17:00'); // miércoles
      expect(celda(r.min50), '2:00'); // 07–08 y 16–17
    });
  });

  group('franja nocturna y turnos que cruzan la medianoche', () {
    test('hábil 16:00–02:00 → 5:00 al 50% (16–21) y 5:00 al 100% (21–02)', () {
      final r = calc('2026-09-15', '16:00', '2:00'); // martes
      expect(r.trabajadoMin, 10 * 60);
      expect(celda(r.min50), '5:00');
      expect(celda(r.min100), '5:00');
    });

    test('martes 22:00 → miércoles 09:00: 8:00 al 100%, 2:00 al 50%; 08–09 del miércoles es horario normal', () {
      final r = calc('2026-09-15', '22:00', '9:00');
      expect(celda(r.min100), '8:00');
      expect(celda(r.min50), '2:00');
    });

    test('viernes 22:00 → sábado 08:00: todo al 100% (lo del sábado es fin de semana)', () {
      final r = calc('2026-09-18', '22:00', '8:00');
      expect(r.tipo, TipoDia.habil);
      expect(celda(r.min100), '10:00');
      expect(r.min50, 0);
    });

    test('domingo 22:00 → lunes 07:00: 8:00 al 100% y 1:00 al 50% (06–07 del lunes)', () {
      final r = calc('2026-09-20', '22:00', '7:00');
      expect(r.tipo, TipoDia.domingo);
      expect(celda(r.min100), '8:00');
      expect(celda(r.min50), '1:00');
    });

    test('domingo 16/08 22:00 → lunes 17/08 (feriado San Martín) 10:00: todo al 100%', () {
      final r = calc('2026-08-16', '22:00', '10:00');
      expect(celda(r.min100), '12:00');
      expect(r.min50, 0);
    });

    test('salir antes no descuenta', () {
      final r = calc('2026-09-15', '8:00', '12:00');
      expect(r.min50, 0);
      expect(r.min100, 0);
    });
  });

  group('tipo de día', () {
    test('sábado, domingo y hábil', () {
      expect(tipoDeDia(DateTime(2026, 8, 1), false), TipoDia.sabado);
      expect(tipoDeDia(DateTime(2026, 8, 2), false), TipoDia.domingo);
      expect(tipoDeDia(DateTime(2026, 8, 3), false), TipoDia.habil);
    });
    test('feriado tiene prioridad y va todo al 100%', () {
      final r = calc('2026-07-09', '8:00', '12:00', feriado: true); // jueves
      expect(r.tipo, TipoDia.feriado);
      expect(celda(r.min100), '4:00');
      expect(r.min50, 0);
    });
  });

  group('franco sugerido', () {
    test('sábado con 4:00 justas → franco', () {
      expect(calc('2026-08-22', '8:00', '12:00').francoSugerido, isTrue);
    });
    test('sábado con 3:59 → no', () {
      expect(calc('2026-08-22', '8:00', '11:59').francoSugerido, isFalse);
    });
    test('domingo 09/08 (8:10) → franco, como en la planilla real', () {
      expect(calc('2026-08-09', '7:00', '15:10').francoSugerido, isTrue);
    });
    test('feriado hábil con 8:00 justas → franco; con 7:59 → no', () {
      expect(calc('2026-07-09', '8:00', '16:00', feriado: true).francoSugerido, isTrue);
      expect(calc('2026-07-09', '8:00', '15:59', feriado: true).francoSugerido, isFalse);
    });
    test('feriado que cae sábado: alcanza con 4:00 (regla de fin de semana)', () {
      expect(calc('2026-06-20', '8:00', '12:00', feriado: true).francoSugerido, isTrue);
    });
    test('día hábil nunca sugiere franco', () {
      expect(calc('2026-08-18', '4:52', '18:35').francoSugerido, isFalse);
    });
  });

  group('feriados nacionales', () {
    test('2026 con traslados decretados', () {
      expect(feriadoEn(DateTime(2026, 8, 17)), isNotNull);
      expect(feriadoEn(DateTime(2026, 6, 15)), isNotNull); // Güemes trasladado
      expect(feriadoEn(DateTime(2026, 6, 17)), isNull);
      expect(feriadoEn(DateTime(2026, 11, 23)), isNotNull); // Soberanía trasladado
      expect(feriadoEn(DateTime(2026, 7, 10)), isNull); // día no laborable, no feriado
      expect(feriadoEn(DateTime(2026, 8, 18)), isNull);
    });
  });
}
