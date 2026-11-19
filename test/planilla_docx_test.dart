import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_extras/data/models.dart';
import 'package:horas_extras/domain/overtime.dart';
import 'package:horas_extras/domain/time.dart';
import 'package:horas_extras/export/planilla_docx.dart';
import 'package:xml/xml.dart';

import 'fixtures/agosto.dart';

const empleado = Empleado(nombre: 'Pérez Juan', legajo: '1234');

/// Días de agosto con el franco tal como quedó en la planilla real (forzado).
final diasAgosto = [
  for (final (i, r) in agosto.indexed)
    Dia(
      id: '$i',
      fecha: r.dia,
      entradaMin: parseHHMM(r.entrada),
      salidaMin: parseHHMM(r.salida),
      franco: r.franco == '1' ? FrancoModo.si : FrancoModo.no,
      motivo: r.motivo,
    ),
];

/// Texto de cada celda de cada fila de la tabla [indice] del document.xml.
List<List<String>> filasDeTabla(XmlDocument doc, int indice) {
  final tabla = doc.descendantElements.where((e) => e.name.qualified == 'w:tbl').elementAt(indice);
  return [
    for (final tr in tabla.childElements.where((e) => e.name.qualified == 'w:tr'))
      [
        for (final tc in tr.childElements.where((e) => e.name.qualified == 'w:tc'))
          tc.descendantElements.where((e) => e.name.qualified == 'w:t').map((t) => t.innerText).join(),
      ],
  ];
}

({Archive zip, XmlDocument doc}) abrir(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final doc = XmlDocument.parse(utf8.decode(zip.findFile('word/document.xml')!.readBytes()!));
  return (zip: zip, doc: doc);
}

void main() {
  final plantilla = File('assets/plantilla.docx').readAsBytesSync();

  group('export a .docx: regenera la planilla de agosto', () {
    final data = armarPlanilla(empleado, diasAgosto, 8, ReglasConfig.defaults);
    final out = abrir(renderPlanilla(plantilla, data));

    test('es un .docx válido y conserva los recursos originales', () {
      expect(out.zip.findFile('word/media/image1.png'), isNotNull);
      expect(out.zip.findFile('[Content_Types].xml'), isNotNull);
      // No queda ningún marcador sin reemplazar (el XML tiene otras llaves
      // legítimas, como los GUID de extensiones de dibujo).
      expect(RegExp(r'\{[#/]?[a-z]\w*\}').hasMatch(out.doc.toXmlString()), isFalse);
    });

    test('encabezado con los datos del empleado', () {
      final enc = filasDeTabla(out.doc, 0).first;
      expect(enc[0], 'Pérez Juan');
      expect(enc[2], '1234');
      expect(enc[4], 'Agosto');
      expect(enc[6], 'CCT 36/75 FATyF');
      expect(enc[8], '');
    });

    test('una fila por día y cada valor en su columna, igual que el Word real', () {
      final filas = filasDeTabla(out.doc, 1);
      expect(filas.length, 2 + agosto.length + 1); // 2 de encabezado + días + totales
      final datos = filas.sublist(2, filas.length - 1);
      for (final (i, r) in agosto.indexed) {
        final fecha = '${r.fecha.substring(8)}/${r.fecha.substring(5, 7)}/${r.fecha.substring(2, 4)}';
        expect(datos[i], [fecha, r.entrada, r.salida, r.exp50, r.exp100, r.franco, '', '', r.motivo], reason: r.fecha);
      }
    });

    test('totales 30:56 y 26:44', () {
      final tot = filasDeTabla(out.doc, 1).last;
      expect(tot, ['', agostoTot50, agostoTot100, '']);
    });
  });

  test('franco automático: en agosto la regla marcaría 09, 22, 29 y 30', () {
    final auto = [
      for (final d in diasAgosto) Dia(id: d.id, fecha: d.fecha, entradaMin: d.entradaMin, salidaMin: d.salidaMin),
    ];
    final data = armarPlanilla(empleado, auto, 8, ReglasConfig.defaults);
    final conFranco = [
      for (final f in data.filas)
        if (f.franco == '1') f.fecha,
    ];
    expect(conFranco, ['09/08/26', '22/08/26', '29/08/26', '30/08/26']);
  });

  test('escapa caracteres especiales del motivo y ordena por fecha', () {
    final dias = [
      Dia(id: 'b', fecha: DateTime(2027, 1, 20), entradaMin: 7 * 60, salidaMin: 17 * 60, motivo: 'B'),
      Dia(id: 'a', fecha: DateTime(2027, 1, 5), entradaMin: 7 * 60, salidaMin: 16 * 60, motivo: 'Barra <132kV> & "TR"'),
    ];
    final out = abrir(renderPlanilla(plantilla, armarPlanilla(empleado, dias, 1, ReglasConfig.defaults)));
    final filas = filasDeTabla(out.doc, 1);
    expect(filas[2], ['05/01/27', '7:00', '16:00', '1:00', '', '', '', '', 'Barra <132kV> & "TR"']);
    expect(filas[3], ['20/01/27', '7:00', '17:00', '2:00', '', '', '', '', 'B']);
    expect(filasDeTabla(out.doc, 0).first[4], 'Enero');
    expect(filas.last, ['', '3:00', '', '']);
  });

  test('mes sin días: solo encabezados y totales vacíos', () {
    final out = abrir(renderPlanilla(plantilla, armarPlanilla(empleado, [], 3, ReglasConfig.defaults)));
    final filas = filasDeTabla(out.doc, 1);
    expect(filas.length, 3);
    expect(filas.last, ['', '', '', '']);
  });

  test('nombre del archivo', () {
    expect(nombreArchivo(2026, 8), 'HSX Agosto 2026.docx');
  });
}
