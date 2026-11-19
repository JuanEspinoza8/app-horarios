import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../domain/fechas.dart';
import '../domain/overtime.dart';
import '../domain/time.dart';
import 'widgets.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  late final TextEditingController _nombre;
  late final TextEditingController _legajo;
  late final TextEditingController _convenio;
  late final TextEditingController _horario;
  late ReglasConfig _cfg;

  @override
  void initState() {
    super.initState();
    final e = widget.store.empleado;
    _nombre = TextEditingController(text: e.nombre);
    _legajo = TextEditingController(text: e.legajo);
    _convenio = TextEditingController(text: e.convenio);
    _horario = TextEditingController(text: e.horario);
    _cfg = widget.store.config;
  }

  @override
  void dispose() {
    for (final c in [_nombre, _legajo, _convenio, _horario]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    await widget.store.guardarAjustes(
      Empleado(
        nombre: _nombre.text.trim(),
        legajo: _legajo.text.trim(),
        convenio: _convenio.text.trim(),
        horario: _horario.text.trim(),
      ),
      _cfg,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Widget _par(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      // Botón dentro del body para que quede visible arriba del teclado.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const TituloSeccion('Apariencia'),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Claro')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Oscuro')),
                  ],
                  selected: {widget.store.tema},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) async {
                    await widget.store.cambiarTema(s.first);
                    if (mounted) setState(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Oscuro usa fondo negro puro, ideal para pantallas OLED. Auto sigue al teléfono.',
                    style: tt.bodySmall,
                  ),
                ),
                const TituloSeccion('Empleado (encabezado del Word)'),
                TextField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellido y Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                _par(
                  TextField(
                    controller: _legajo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Legajo N°', border: OutlineInputBorder()),
                  ),
                  TextField(
                    controller: _convenio,
                    decoration: const InputDecoration(labelText: 'Convenio', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _horario,
                  decoration: const InputDecoration(
                    labelText: 'Horario Normal (texto del encabezado)',
                    helperText: 'Opcional. En la planilla original va vacío.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const TituloSeccion('Horario de verano'),
                _par(
                  CampoHora(
                    label: 'Desde',
                    minutos: _cfg.horarioVerano.inicioMin,
                    onChanged: (m) =>
                        setState(() => _cfg = _cfg.copyWith(horarioVerano: Horario(m, _cfg.horarioVerano.finMin))),
                  ),
                  CampoHora(
                    label: 'Hasta',
                    minutos: _cfg.horarioVerano.finMin,
                    onChanged: (m) =>
                        setState(() => _cfg = _cfg.copyWith(horarioVerano: Horario(_cfg.horarioVerano.inicioMin, m))),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Meses con horario de verano:', style: tt.bodyMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      FilterChip(
                        label: Text(nombreMes(m).substring(0, 3)),
                        selected: _cfg.mesesVerano.contains(m),
                        onSelected: (sel) => setState(() {
                          final s = {..._cfg.mesesVerano};
                          sel ? s.add(m) : s.remove(m);
                          _cfg = _cfg.copyWith(mesesVerano: s);
                        }),
                      ),
                  ],
                ),
                const TituloSeccion('Horario del resto del año'),
                _par(
                  CampoHora(
                    label: 'Desde',
                    minutos: _cfg.horarioResto.inicioMin,
                    onChanged: (m) =>
                        setState(() => _cfg = _cfg.copyWith(horarioResto: Horario(m, _cfg.horarioResto.finMin))),
                  ),
                  CampoHora(
                    label: 'Hasta',
                    minutos: _cfg.horarioResto.finMin,
                    onChanged: (m) =>
                        setState(() => _cfg = _cfg.copyWith(horarioResto: Horario(_cfg.horarioResto.inicioMin, m))),
                  ),
                ),
                const TituloSeccion('Franja nocturna (al 100% en día hábil)'),
                _par(
                  CampoHora(
                    label: 'Desde',
                    minutos: _cfg.nocheInicioMin,
                    onChanged: (m) => setState(() => _cfg = _cfg.copyWith(nocheInicioMin: m)),
                  ),
                  CampoHora(
                    label: 'Hasta',
                    minutos: _cfg.nocheFinMin,
                    onChanged: (m) => setState(() => _cfg = _cfg.copyWith(nocheFinMin: m)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'En día hábil, fuera del horario normal: la franja nocturna va al 100% y el resto al 50%. '
                    'Sábados, domingos y feriados: todo al 100%.',
                    style: tt.bodySmall,
                  ),
                ),
                const TituloSeccion('Franco automático'),
                _Umbral(
                  label: 'Sábado o domingo, desde',
                  minutos: _cfg.francoFindeMin,
                  onChanged: (m) => setState(() => _cfg = _cfg.copyWith(francoFindeMin: m)),
                ),
                _Umbral(
                  label: 'Feriado, desde',
                  minutos: _cfg.francoFeriadoMin,
                  onChanged: (m) => setState(() => _cfg = _cfg.copyWith(francoFeriadoMin: m)),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restaurar reglas por defecto'),
                    onPressed: () => setState(() => _cfg = ReglasConfig.defaults),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _guardar,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Guardar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Umbral de horas para el franco, de a 30 minutos.
class _Umbral extends StatelessWidget {
  const _Umbral({required this.label, required this.minutos, required this.onChanged});
  final String label;
  final int minutos;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton.outlined(
        icon: const Icon(Icons.remove),
        tooltip: 'Menos',
        onPressed: minutos > 30 ? () => onChanged(minutos - 30) : null,
      ),
      SizedBox(
        width: 64,
        child: Text(
          '${formatHHMM(minutos)} h',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton.outlined(
        icon: const Icon(Icons.add),
        tooltip: 'Más',
        onPressed: minutos < 24 * 60 ? () => onChanged(minutos + 30) : null,
      ),
    ],
  );
}
