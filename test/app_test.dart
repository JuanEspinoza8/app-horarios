import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_extras/data/models.dart';
import 'package:horas_extras/data/store.dart';
import 'package:horas_extras/domain/time.dart';
import 'package:horas_extras/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/agosto.dart';

/// Agosto con el franco en automático (como lo cargaría el usuario).
String diasAgostoJson() => jsonEncode([
  for (final (i, r) in agosto.indexed)
    Dia(
      id: 'd$i',
      fecha: r.dia,
      entradaMin: parseHHMM(r.entrada),
      salidaMin: parseHHMM(r.salida),
      motivo: r.motivo,
    ).toJson(),
]);

Future<AppStore> crearStore(Map<String, Object> valores) async {
  SharedPreferences.setMockInitialValues(valores);
  return AppStore(await SharedPreferences.getInstance());
}

Future<void> abrirApp(WidgetTester tester, AppStore store, DateTime mes) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(HorasExtrasApp(store: store, mesInicial: mes));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mes vacío invita a cargar y pide nombre/legajo', (tester) async {
    final store = await crearStore({});
    await abrirApp(tester, store, DateTime(2027, 1));

    expect(find.text('Enero 2027'), findsOneWidget);
    expect(find.text('No cargaste días en Enero 2027.'), findsOneWidget);
    expect(find.text('Horario normal: 07:00 a 15:00'), findsOneWidget);
    expect(find.text('Completá tu nombre y legajo'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Marzo 2027'), findsOneWidget);
    expect(find.text('Horario normal: 08:00 a 16:00'), findsOneWidget);
  });

  testWidgets('agosto: totales, franco automático y franco forzado a No', (tester) async {
    final store = await crearStore({'he.dias.v2': diasAgostoJson()});
    await abrirApp(tester, store, DateTime(2026, 8));

    expect(find.text('30:56'), findsOneWidget);
    expect(find.text('26:44'), findsOneWidget);
    // Regla automática: 09, 22, 29 y 30 de agosto.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('francos'), findsOneWidget);

    // Abrir el sábado 22 y forzar "No".
    final fila22 = find.text('Obra de línea (sábado)');
    await tester.scrollUntilVisible(fila22, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(fila22);
    await tester.pumpAndSettle();
    expect(find.text('Editar día'), findsOneWidget);
    expect(find.text('Sáb 22/08/26'), findsOneWidget);
    expect(find.text('Auto (sí)'), findsOneWidget);
    expect(find.text('4:35'), findsWidgets); // trabajado y al 100%

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Agosto 2026'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(store.dias.firstWhere((d) => d.id == 'd7').franco, FrancoModo.no);

    // Persistió en SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('he.dias.v2'), contains('"franco":"no"'));
  });

  testWidgets('ajustes guarda nombre y legajo', (tester) async {
    final store = await crearStore({});
    await abrirApp(tester, store, DateTime(2026, 11));

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Apellido y Nombre'), 'Pérez Juan');
    await tester.enterText(find.widgetWithText(TextField, 'Legajo N°'), '1234');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(store.empleado.nombre, 'Pérez Juan');
    expect(store.empleado.legajo, '1234');
    expect(find.text('Completá tu nombre y legajo'), findsNothing);
  });

  testWidgets('modo oscuro: fondo negro puro y se guarda la elección', (tester) async {
    final store = await crearStore({'he.dias.v2': diasAgostoJson()});
    await abrirApp(tester, store, DateTime(2026, 8));

    // Por defecto sigue al teléfono (el test corre en claro).
    expect(store.tema, ThemeMode.system);
    expect(Theme.of(tester.element(find.text('Agosto 2026'))).brightness, Brightness.light);

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    final tema = Theme.of(tester.element(find.text('Apariencia')));
    expect(tema.brightness, Brightness.dark);
    expect(tema.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(tema.colorScheme.surface, const Color(0xFF000000));
    expect(tema.appBarTheme.backgroundColor, const Color(0xFF000000));

    // El fondo de la pantalla de Ajustes que se ve es negro.
    final scaffold = tester.widget<Material>(
      find.descendant(of: find.byType(Scaffold).last, matching: find.byType(Material)).first,
    );
    expect(scaffold.color, const Color(0xFF000000));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('he.tema.v1'), 'dark');

    // Al volver, la pantalla del mes también queda en negro.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Agosto 2026'))).scaffoldBackgroundColor, const Color(0xFF000000));
  });

  testWidgets('el tema elegido se recuerda al reabrir la app', (tester) async {
    final store = await crearStore({'he.tema.v1': 'dark'});
    expect(store.tema, ThemeMode.dark);
    await abrirApp(tester, store, DateTime(2026, 11));
    expect(Theme.of(tester.element(find.text('Noviembre 2026'))).scaffoldBackgroundColor, const Color(0xFF000000));
  });
}
