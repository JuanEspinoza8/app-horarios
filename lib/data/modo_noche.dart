import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';

const _canal = MethodChannel('horas_extras/tema');

/// Avisa a Android el tema elegido para que la pantalla de arranque lo respete
/// (ver MainActivity.kt). Si no hay plataforma (tests) o falla, no pasa nada:
/// solo afecta a la pantalla de arranque.
Future<void> sincronizarModoNoche(ThemeMode tema) async {
  try {
    await _canal.invokeMethod<void>('setModoNoche', tema.name);
  } on MissingPluginException {
    // Tests o plataforma sin el canal.
  } on PlatformException {
    // Versión de Android que no lo soporta.
  }
}
