import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/modo_noche.dart';
import 'data/store.dart';
import 'ui/mes_screen.dart';
import 'ui/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore(prefs);
  runApp(HorasExtrasApp(store: store));
  // Mantiene a Android al tanto del tema para la pantalla de arranque.
  unawaited(sincronizarModoNoche(store.tema));
}

class HorasExtrasApp extends StatelessWidget {
  const HorasExtrasApp({super.key, required this.store, this.mesInicial});

  final AppStore store;

  /// Mes que se muestra al abrir (por defecto el actual). Útil para tests.
  final DateTime? mesInicial;

  @override
  Widget build(BuildContext context) {
    // Se reconstruye cuando cambia el tema elegido en Ajustes.
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Horas Extras',
        debugShowCheckedModeBanner: false,
        theme: temaClaro(),
        darkTheme: temaOscuro(),
        themeMode: store.tema,
        locale: const Locale('es', 'AR'),
        supportedLocales: const [Locale('es', 'AR'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
        home: MesScreen(store: store, mesInicial: mesInicial),
      ),
    );
  }
}
