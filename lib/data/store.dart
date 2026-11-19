import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/overtime.dart';
import 'modo_noche.dart';
import 'models.dart';

/// Estado de la app y persistencia local (offline) en SharedPreferences.
class AppStore extends ChangeNotifier {
  AppStore(this._prefs) {
    _cargar();
  }

  static const _kEmpleado = 'he.empleado.v2';
  static const _kConfig = 'he.config.v2';
  static const _kDias = 'he.dias.v2';
  static const _kTema = 'he.tema.v1';

  final SharedPreferences _prefs;

  Empleado empleado = const Empleado();
  ReglasConfig config = ReglasConfig.defaults;
  List<Dia> _dias = [];

  /// Tema: automático (según el teléfono), claro u oscuro (negro puro).
  ThemeMode tema = ThemeMode.system;

  List<Dia> get dias => List.unmodifiable(_dias);

  void _cargar() {
    tema = ThemeMode.values.asNameMap()[_prefs.getString(_kTema)] ?? ThemeMode.system;
    final e = _leerMapa(_kEmpleado);
    if (e != null) empleado = Empleado.fromJson(e);
    final c = _leerMapa(_kConfig);
    if (c != null) config = ReglasConfig.fromJson(c);
    final raw = _prefs.getString(_kDias);
    if (raw != null) {
      try {
        _dias = (jsonDecode(raw) as List).map((x) => Dia.fromJson(Map<String, dynamic>.from(x as Map))).toList();
      } catch (_) {
        _dias = [];
      }
    }
  }

  Map<String, dynamic>? _leerMapa(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Días del mes, ordenados por fecha y hora de entrada.
  List<Dia> diasDelMes(int anio, int mes) {
    final l = _dias.where((d) => d.fecha.year == anio && d.fecha.month == mes).toList()
      ..sort((a, b) {
        final c = a.fecha.compareTo(b.fecha);
        return c != 0 ? c : a.entradaMin.compareTo(b.entradaMin);
      });
    return l;
  }

  Future<void> guardarDia(Dia d) async {
    final i = _dias.indexWhere((x) => x.id == d.id);
    if (i == -1) {
      _dias.add(d);
    } else {
      _dias[i] = d;
    }
    notifyListeners();
    await _prefs.setString(_kDias, jsonEncode(_dias.map((x) => x.toJson()).toList()));
  }

  Future<void> borrarDia(String id) async {
    _dias.removeWhere((x) => x.id == id);
    notifyListeners();
    await _prefs.setString(_kDias, jsonEncode(_dias.map((x) => x.toJson()).toList()));
  }

  Future<void> cambiarTema(ThemeMode t) async {
    tema = t;
    notifyListeners();
    await _prefs.setString(_kTema, t.name);
    await sincronizarModoNoche(t);
  }

  Future<void> guardarAjustes(Empleado e, ReglasConfig c) async {
    empleado = e;
    config = c;
    notifyListeners();
    await _prefs.setString(_kEmpleado, jsonEncode(e.toJson()));
    await _prefs.setString(_kConfig, jsonEncode(c.toJson()));
  }
}
