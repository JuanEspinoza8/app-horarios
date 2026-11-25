/// Genera el .docx del mes y lo saca del dispositivo: compartir (WhatsApp,
/// Drive, mail, imprimir…) o guardar/descargar.
///
/// La forma de compartir y guardar depende de la plataforma y se elige al
/// compilar: Android usa `salida_io.dart` y la versión web `salida_web.dart`.
library;

import 'package:flutter/services.dart';

import '../data/models.dart';
import '../domain/overtime.dart';
import 'planilla_docx.dart';
import 'planilla_generada.dart';

export 'planilla_generada.dart';
export 'salida_io.dart' if (dart.library.js_interop) 'salida_web.dart';

Future<PlanillaGenerada> generarPlanilla(Empleado empleado, List<Dia> dias, int anio, int mes, ReglasConfig cfg) async {
  final data = await rootBundle.load('assets/plantilla.docx');
  final plantilla = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final bytes = renderPlanilla(plantilla, armarPlanilla(empleado, dias, mes, cfg));
  return PlanillaGenerada(nombreArchivo(anio, mes), bytes);
}
