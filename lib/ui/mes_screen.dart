import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../domain/fechas.dart';
import '../domain/overtime.dart';
import '../domain/time.dart';
import '../export/exportar.dart';
import 'ajustes_screen.dart';
import 'dia_screen.dart';
import 'widgets.dart';

enum _Accion { compartir, guardar }

class MesScreen extends StatefulWidget {
  const MesScreen({super.key, required this.store, this.mesInicial});

  final AppStore store;
  final DateTime? mesInicial;

  @override
  State<MesScreen> createState() => _MesScreenState();
}

class _MesScreenState extends State<MesScreen> {
  late int _anio;
  late int _mes;
  bool _exportando = false;

  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    final m = widget.mesInicial ?? DateTime.now();
    _anio = m.year;
    _mes = m.month;
  }

  void _cambiarMes(int delta) {
    final d = DateTime(_anio, _mes + delta);
    setState(() {
      _anio = d.year;
      _mes = d.month;
    });
  }

  Future<void> _abrirDia([Dia? dia]) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DiaScreen(store: store, anio: _anio, mes: _mes, dia: dia),
    ),
  );

  Future<void> _abrirAjustes() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AjustesScreen(store: store)));

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _exportar(List<Dia> dias) async {
    final accion = await showModalBottomSheet<_Accion>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Planilla de ${nombreMes(_mes)} $_anio', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            if (store.empleado.incompleto)
              const ListTile(
                leading: Icon(Icons.warning_amber),
                title: Text('Falta el nombre o el legajo'),
                subtitle: Text('El encabezado del Word va a salir incompleto. Completalo en Ajustes.'),
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              subtitle: const Text('WhatsApp, Drive, mail, abrir en Word para imprimir…'),
              onTap: () => Navigator.pop(ctx, _Accion.compartir),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Guardar en el teléfono'),
              subtitle: const Text('Elegís la carpeta, por ejemplo Descargas'),
              onTap: () => Navigator.pop(ctx, _Accion.guardar),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (accion == null || !mounted) return;

    setState(() => _exportando = true);
    try {
      final planilla = await generarPlanilla(store.empleado, dias, _anio, _mes, store.config);
      switch (accion) {
        case _Accion.compartir:
          await compartirPlanilla(planilla);
        case _Accion.guardar:
          if (await guardarPlanilla(planilla)) _aviso('Guardada: ${planilla.nombre}');
      }
    } catch (e, st) {
      debugPrint('Error al exportar: $e\n$st');
      final detalle = e.toString().split('\n').first;
      _aviso('No se pudo exportar el Word. ${detalle.length > 120 ? '${detalle.substring(0, 120)}…' : detalle}');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final dias = store.diasDelMes(_anio, _mes);
        final calcs = [for (final d in dias) d.calcular(store.config)];
        var t50 = 0, t100 = 0, francos = 0;
        for (var i = 0; i < dias.length; i++) {
          t50 += calcs[i].min50;
          t100 += calcs[i].min100;
          if (dias[i].francoEfectivo(calcs[i])) francos++;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Horas Extras'),
            actions: [IconButton(icon: const Icon(Icons.settings), tooltip: 'Ajustes', onPressed: _abrirAjustes)],
          ),
          body: Column(
            children: [
              _NavegadorMes(
                titulo: '${nombreMes(_mes)} $_anio',
                onAnterior: () => _cambiarMes(-1),
                onSiguiente: () => _cambiarMes(1),
              ),
              _Totales(min50: t50, min100: t100, francos: francos, horario: store.config.horarioDelMes(_mes)),
              if (store.empleado.incompleto)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Completá tu nombre y legajo'),
                      subtitle: const Text('Van en el encabezado del Word.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _abrirAjustes,
                    ),
                  ),
                ),
              Expanded(
                child: dias.isEmpty
                    ? _Vacio(mes: '${nombreMes(_mes)} $_anio', onAgregar: _abrirDia)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                        itemCount: dias.length,
                        itemBuilder: (_, i) => _FilaDia(dia: dias[i], calc: calcs[i], onTap: () => _abrirDia(dias[i])),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _abrirDia,
            icon: const Icon(Icons.add),
            label: const Text('Agregar día'),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.tonalIcon(
                onPressed: _exportando || dias.isEmpty ? null : () => _exportar(dias),
                icon: _exportando
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.description_outlined),
                label: Text(_exportando ? 'Generando…' : 'Exportar Word'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavegadorMes extends StatelessWidget {
  const _NavegadorMes({required this.titulo, required this.onAnterior, required this.onSiguiente});
  final String titulo;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), tooltip: 'Mes anterior', onPressed: onAnterior),
        Expanded(
          child: Text(titulo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), tooltip: 'Mes siguiente', onPressed: onSiguiente),
      ],
    ),
  );
}

class _Totales extends StatelessWidget {
  const _Totales({required this.min50, required this.min100, required this.francos, required this.horario});
  final int min50;
  final int min100;
  final int francos;
  final Horario horario;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    Widget total(String valor, String label) => Expanded(
      child: Column(
        children: [
          Text(valor, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: tt.bodySmall),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  total(formatHHMM(min50), 'al 50%'),
                  total(formatHHMM(min100), 'al 100%'),
                  total('$francos', francos == 1 ? 'franco' : 'francos'),
                ],
              ),
              const SizedBox(height: 6),
              Text('Horario normal: ${horario.texto}', style: tt.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaDia extends StatelessWidget {
  const _FilaDia({required this.dia, required this.calc, required this.onTap});
  final Dia dia;
  final ResultadoDia calc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final franco = dia.francoEfectivo(calc);
    final cruza = dia.salidaMin <= dia.entradaMin;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Text('${dia.fecha.day}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      diaSemanaCorto(dia.fecha),
                      style: tt.bodySmall?.copyWith(
                        color: calc.tipo == TipoDia.habil ? null : cs.primary,
                        fontWeight: calc.tipo == TipoDia.habil ? null : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${minutesToClock(dia.entradaMin)} – ${minutesToClock(dia.salidaMin)}'
                      '${cruza ? ' (+1)' : ''}${dia.esFeriado ? ' · feriado' : ''}',
                      style: tt.titleMedium,
                    ),
                    if (dia.motivo.isNotEmpty)
                      Text(dia.motivo, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodyMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (calc.min50 > 0) Etiqueta('50%: ${formatHHMM(calc.min50)}', tipo: TipoEtiqueta.al50),
                        if (calc.min100 > 0) Etiqueta('100%: ${formatHHMM(calc.min100)}', tipo: TipoEtiqueta.al100),
                        if (franco)
                          Etiqueta(
                            dia.franco == FrancoModo.auto ? 'franco' : 'franco (manual)',
                            tipo: TipoEtiqueta.franco,
                          ),
                        if (calc.min50 == 0 && calc.min100 == 0) const Etiqueta('sin extras'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.mes, required this.onAgregar});
  final String mes;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text('No cargaste días en $mes.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAgregar, child: const Text('Agregar el primero')),
        ],
      ),
    ),
  );
}
