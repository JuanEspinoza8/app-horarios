import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../domain/fechas.dart';
import '../domain/feriados.dart';
import '../domain/overtime.dart';
import '../domain/time.dart';
import 'widgets.dart';

/// Carga / edición de un día, con el cálculo en vivo.
class DiaScreen extends StatefulWidget {
  const DiaScreen({super.key, required this.store, required this.anio, required this.mes, this.dia});

  final AppStore store;
  final int anio;
  final int mes;

  /// null = día nuevo.
  final Dia? dia;

  @override
  State<DiaScreen> createState() => _DiaScreenState();
}

class _DiaScreenState extends State<DiaScreen> {
  late DateTime _fecha;
  int? _entrada;
  int? _salida;
  late bool _feriado;

  /// Mientras el usuario no toque la casilla, "Feriado" sigue al calendario.
  late bool _feriadoTocado;
  late FrancoModo _franco;
  late final TextEditingController _motivo;

  bool get _esNuevo => widget.dia == null;
  ReglasConfig get _cfg => widget.store.config;

  @override
  void initState() {
    super.initState();
    final d = widget.dia;
    if (d != null) {
      _fecha = d.fecha;
      _entrada = d.entradaMin;
      _salida = d.salidaMin;
      _feriado = d.esFeriado;
      _feriadoTocado = true;
      _franco = d.franco;
      _motivo = TextEditingController(text: d.motivo);
    } else {
      final hoy = DateTime.now();
      _fecha = hoy.year == widget.anio && hoy.month == widget.mes ? soloFecha(hoy) : DateTime(widget.anio, widget.mes);
      _feriado = feriadoEn(_fecha) != null;
      _feriadoTocado = false;
      _franco = FrancoModo.auto;
      _motivo = TextEditingController();
    }
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  ResultadoDia? get _calc {
    final e = _entrada, s = _salida;
    if (e == null || s == null || e == s) return null;
    return calcularDia(fecha: _fecha, entradaMin: e, salidaMin: s, esFeriado: _feriado, cfg: _cfg);
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(widget.anio, widget.mes),
      lastDate: DateTime(widget.anio, widget.mes + 1, 0),
      helpText: 'Fecha de entrada',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (f == null) return;
    setState(() {
      _fecha = soloFecha(f);
      if (!_feriadoTocado) _feriado = feriadoEn(_fecha) != null;
    });
  }

  Future<void> _guardar() async {
    final calc = _calc;
    if (calc == null) return;
    await widget.store.guardarDia(
      Dia(
        id: widget.dia?.id ?? Dia.nuevoId(),
        fecha: _fecha,
        entradaMin: _entrada!,
        salidaMin: _salida!,
        esFeriado: _feriado,
        franco: _franco,
        motivo: _motivo.text.trim(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _borrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar este día?'),
        content: Text('${fechaCorta(_fecha)} · ${minutesToClock(_entrada!)} – ${minutesToClock(_salida!)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.borrarDia(widget.dia!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final calc = _calc;
    final horario = _cfg.horarioDelMes(_fecha.month);
    final nombreFeriado = feriadoEn(_fecha);
    final mismaHora = _entrada != null && _entrada == _salida;
    final cruza = _entrada != null && _salida != null && _salida! < _entrada!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Agregar día' : 'Editar día'),
        actions: [
          if (!_esNuevo) IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Borrar', onPressed: _borrar),
        ],
      ),
      // El botón va dentro del body (no en bottomNavigationBar) para que quede
      // visible arriba del teclado mientras se escribe el motivo.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _elegirFecha,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text('${diaSemanaCorto(_fecha)} ${fechaCorta(_fecha)}', style: tt.titleLarge),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CampoHora(
                        label: 'Entrada',
                        minutos: _entrada,
                        inicial: horario.inicioMin,
                        onChanged: (m) => setState(() => _entrada = m),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CampoHora(
                        label: 'Salida',
                        minutos: _salida,
                        inicial: horario.finMin,
                        nota: cruza ? 'Día siguiente' : null,
                        onChanged: (m) => setState(() => _salida = m),
                      ),
                    ),
                  ],
                ),
                if (mismaHora)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'La salida no puede ser igual a la entrada.',
                      style: tt.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Feriado'),
                  subtitle: Text(
                    nombreFeriado != null
                        ? 'Feriado nacional: $nombreFeriado'
                        : 'Marcalo si es feriado provincial o un traslado que no está en el calendario',
                  ),
                  value: _feriado,
                  onChanged: (v) => setState(() {
                    _feriado = v;
                    _feriadoTocado = true;
                  }),
                ),
                if (calc != null) _Resultado(calc: calc),
                const TituloSeccion('Franco compensatorio'),
                SegmentedButton<FrancoModo>(
                  segments: [
                    ButtonSegment(
                      value: FrancoModo.auto,
                      label: Text(calc == null ? 'Auto' : 'Auto (${calc.francoSugerido ? 'sí' : 'no'})'),
                    ),
                    const ButtonSegment(value: FrancoModo.si, label: Text('Sí')),
                    const ButtonSegment(value: FrancoModo.no, label: Text('No')),
                  ],
                  selected: {_franco},
                  onSelectionChanged: (s) => setState(() => _franco = s.first),
                  showSelectedIcon: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Auto: sábado o domingo desde ${formatHHMM(_cfg.francoFindeMin)} h trabajadas, '
                    'feriado desde ${formatHHMM(_cfg.francoFeriadoMin)} h.',
                    style: tt.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _motivo,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej: Mantto Barra 132KV',
                    border: OutlineInputBorder(),
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
                onPressed: calc == null ? null : _guardar,
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

class _Resultado extends StatelessWidget {
  const _Resultado({required this.calc});
  final ResultadoDia calc;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget dato(String label, String valor) => Expanded(
      child: Column(
        children: [
          Text(valor, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: tt.bodySmall),
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              calc.tipo == TipoDia.habil
                  ? '${calc.tipo.etiqueta} · horario normal ${calc.horario.texto}'
                  : '${calc.tipo.etiqueta} · todo al 100%',
              style: tt.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                dato('trabajado', formatHHMM(calc.trabajadoMin)),
                dato('al 50%', calc.min50 == 0 ? '—' : formatHHMM(calc.min50)),
                dato('al 100%', calc.min100 == 0 ? '—' : formatHHMM(calc.min100)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
