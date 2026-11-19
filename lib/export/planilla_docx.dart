/// Generación del Word: rellena `assets/plantilla.docx` (derivada de la
/// planilla original del cliente por `scripts/build-template.py`) con los datos
/// del mes. La plantilla tiene cada marcador `{...}` entero dentro de un solo
/// `<w:t>`, así que alcanza con reemplazar texto y clonar la fila `{#filas}`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../data/models.dart';
import '../domain/fechas.dart';
import '../domain/overtime.dart';
import '../domain/time.dart';

const docxMime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

class FilaPlanilla {
  final String fecha, entrada, salida, al50, al100, franco, via25, via50, motivo;
  const FilaPlanilla({
    required this.fecha,
    required this.entrada,
    required this.salida,
    required this.al50,
    required this.al100,
    required this.franco,
    this.via25 = '',
    this.via50 = '',
    required this.motivo,
  });

  Map<String, String> get valores => {
    'fecha': fecha,
    'entrada': entrada,
    'salida': salida,
    'al50': al50,
    'al100': al100,
    'franco': franco,
    'via25': via25,
    'via50': via50,
    'motivo': motivo,
  };

  List<String> get columnas => [fecha, entrada, salida, al50, al100, franco, via25, via50, motivo];
}

class PlanillaData {
  final String nombre, legajo, mes, convenio, horario, tot50, tot100;
  final List<FilaPlanilla> filas;
  const PlanillaData({
    required this.nombre,
    required this.legajo,
    required this.mes,
    required this.convenio,
    required this.horario,
    required this.filas,
    required this.tot50,
    required this.tot100,
  });

  Map<String, String> get escalares => {
    'nombre': nombre,
    'legajo': legajo,
    'mes': mes,
    'convenio': convenio,
    'horario': horario,
    'tot50': tot50,
    'tot100': tot100,
  };
}

String _celda(int min) => min == 0 ? '' : formatHHMM(min);

/// Arma los datos de la planilla del mes. Los viáticos quedan vacíos: el
/// cliente los completa a mano sobre la fotocopia.
PlanillaData armarPlanilla(Empleado empleado, List<Dia> dias, int mes, ReglasConfig cfg) {
  final ordenados = [...dias]
    ..sort((a, b) {
      final c = a.fecha.compareTo(b.fecha);
      return c != 0 ? c : a.entradaMin.compareTo(b.entradaMin);
    });
  var t50 = 0, t100 = 0;
  final filas = <FilaPlanilla>[];
  for (final d in ordenados) {
    final r = d.calcular(cfg);
    t50 += r.min50;
    t100 += r.min100;
    filas.add(
      FilaPlanilla(
        fecha: fechaCorta(d.fecha),
        entrada: formatHHMM(d.entradaMin),
        salida: formatHHMM(d.salidaMin),
        al50: _celda(r.min50),
        al100: _celda(r.min100),
        franco: d.francoEfectivo(r) ? '1' : '',
        motivo: d.motivo,
      ),
    );
  }
  return PlanillaData(
    nombre: empleado.nombre,
    legajo: empleado.legajo,
    mes: nombreMes(mes),
    convenio: empleado.convenio,
    horario: empleado.horario,
    filas: filas,
    tot50: _celda(t50),
    tot100: _celda(t100),
  );
}

String nombreArchivo(int anio, int mes) => 'HSX ${nombreMes(mes)} $anio.docx';

final _marcador = RegExp(r'\{([#/]?\w+)\}');

/// Reemplaza los marcadores `{clave}` en todos los `<w:t>` debajo de [raiz].
void _reemplazar(XmlElement raiz, Map<String, String> valores) {
  for (final t in raiz.descendantElements.where((e) => e.name.qualified == 'w:t').toList()) {
    final texto = t.innerText;
    if (!texto.contains('{')) continue;
    t.innerText = texto.replaceAllMapped(_marcador, (m) => valores[m.group(1)!] ?? m.group(0)!);
  }
}

/// Rellena la plantilla y devuelve el .docx como bytes.
Uint8List renderPlanilla(Uint8List plantilla, PlanillaData data) {
  final zip = ZipDecoder().decodeBytes(plantilla);
  final docFile = zip.findFile('word/document.xml');
  if (docFile == null) throw StateError('La plantilla no tiene word/document.xml');
  final doc = XmlDocument.parse(utf8.decode(docFile.readBytes()!));

  // Fila que se repite por cada día.
  final filaPlantilla = doc.descendantElements.firstWhere(
    (e) => e.name.qualified == 'w:tr' && e.innerText.contains('{#filas}'),
  );
  final tabla = filaPlantilla.parentElement!;
  var pos = tabla.children.indexOf(filaPlantilla);
  for (final fila in data.filas) {
    final copia = filaPlantilla.copy();
    _reemplazar(copia, {...fila.valores, '#filas': '', '/filas': ''});
    tabla.children.insert(pos++, copia);
  }
  tabla.children.remove(filaPlantilla);

  // Encabezado y totales.
  _reemplazar(doc.rootElement, data.escalares);

  final salida = Archive();
  for (final f in zip.files) {
    if (f.name == 'word/document.xml') {
      salida.addFile(ArchiveFile.bytes(f.name, utf8.encode(doc.toXmlString())));
    } else if (f.isFile) {
      salida.addFile(ArchiveFile.bytes(f.name, f.readBytes() ?? Uint8List(0)));
    }
  }
  return ZipEncoder().encodeBytes(salida);
}
