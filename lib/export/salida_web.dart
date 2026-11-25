/// Compartir / descargar el Word en la versión web (iPhone y navegadores).
library;

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'planilla_docx.dart';
import 'planilla_generada.dart';

/// En la web el botón dice "Descargar".
const bool esWeb = true;

/// Abre el menú de compartir del navegador con el archivo (en iPhone:
/// WhatsApp, Mail, "Guardar en Archivos"…). Si el navegador no puede
/// compartir archivos, lo descarga.
///
/// Safari exige que el menú se abra enseguida después del toque del usuario,
/// por eso el Word ya tiene que estar generado cuando se llama.
Future<void> compartirPlanilla(PlanillaGenerada p) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(p.bytes, mimeType: docxMime, name: p.nombre)],
      fileNameOverrides: [p.nombre],
    ),
  );
}

/// Descarga el archivo (en iPhone queda en la app Archivos → Descargas).
Future<bool> guardarPlanilla(PlanillaGenerada p) async {
  await FilePicker.saveFile(fileName: p.nombre, bytes: p.bytes, mimeType: docxMime);
  return true;
}
