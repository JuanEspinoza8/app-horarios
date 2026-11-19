import 'package:flutter/material.dart';

const _semilla = Color(0xFF1E5AA8);

ThemeData temaClaro() => ThemeData(colorSchemeSeed: _semilla, brightness: Brightness.light);

/// Tema oscuro para pantallas OLED: el fondo es negro puro (#000000), así esos
/// píxeles quedan apagados. Las tarjetas, diálogos y hojas usan grises muy
/// oscuros con un borde sutil para que se distingan del fondo.
ThemeData temaOscuro() {
  const negro = Color(0xFF000000);
  const tarjeta = Color(0xFF111111);
  const borde = Color(0xFF2C2C2C);

  final cs = ColorScheme.fromSeed(seedColor: _semilla, brightness: Brightness.dark).copyWith(
    surface: negro,
    surfaceDim: negro,
    surfaceBright: const Color(0xFF2A2A2A),
    surfaceContainerLowest: negro,
    surfaceContainerLow: tarjeta,
    surfaceContainer: const Color(0xFF161616),
    surfaceContainerHigh: const Color(0xFF1C1C1C),
    surfaceContainerHighest: const Color(0xFF262626),
    outlineVariant: borde,
  );

  return ThemeData(
    colorScheme: cs,
    scaffoldBackgroundColor: negro,
    canvasColor: negro,
    appBarTheme: const AppBarTheme(
      backgroundColor: negro,
      surfaceTintColor: Colors.transparent,
      // Que no se aclare al hacer scroll: se mantiene negro.
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: tarjeta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: borde),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF161616),
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1C1C1C), surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
