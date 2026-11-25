/// Compartir / guardar el Word en Android (APK).
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'planilla_docx.dart';
import 'planilla_generada.dart';

/// En Android el botón dice "Guardar en el teléfono".
const bool esWeb = false;

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
