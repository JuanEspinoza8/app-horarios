/// Genera el .docx del mes y lo saca del teléfono: compartir (WhatsApp, Drive,
/// mail, imprimir…) o guardar en una carpeta elegida por el usuario.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../domain/overtime.dart';
import 'planilla_docx.dart';

class PlanillaGenerada {
  final String nombre;
  final Uint8List bytes;
  const PlanillaGenerada(this.nombre, this.bytes);
}

Future<PlanillaGenerada> generarPlanilla(Empleado empleado, List<Dia> dias, int anio, int mes, ReglasConfig cfg) async {
  final data = await rootBundle.load('assets/plantilla.docx');
  final plantilla = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final bytes = renderPlanilla(plantilla, armarPlanilla(empleado, dias, mes, cfg));
  return PlanillaGenerada(nombreArchivo(anio, mes), bytes);
}

Future<void> compartirPlanilla(PlanillaGenerada p) async {
  final dir = await getTemporaryDirectory();
  final archivo = File('${dir.path}${Platform.pathSeparator}${p.nombre}');
  await archivo.writeAsBytes(p.bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(archivo.path, mimeType: docxMime, name: p.nombre)],
      subject: p.nombre.replaceAll('.docx', ''),
    ),
  );
}

/// Devuelve true si el usuario eligió dónde guardarlo.
Future<bool> guardarPlanilla(PlanillaGenerada p) async {
  final uri = await FilePicker.saveFile(
    fileName: p.nombre,
    bytes: p.bytes,
    mimeType: docxMime,
    dialogTitle: 'Guardar planilla',
  );
  return uri != null;
}
