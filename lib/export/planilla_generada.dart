import 'dart:typed_data';

/// Word del mes ya generado, listo para compartir o guardar.
class PlanillaGenerada {
  final String nombre;
  final Uint8List bytes;
  const PlanillaGenerada(this.nombre, this.bytes);
}
