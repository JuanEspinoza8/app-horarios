import 'package:flutter/material.dart';

import '../domain/time.dart';

/// Abre el selector de hora (24 h, con teclado numérico para tipear minutos exactos).
Future<int?> elegirHora(BuildContext context, {required int inicial, String? titulo}) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: (inicial ~/ 60) % 24, minute: inicial % 60),
    initialEntryMode: TimePickerEntryMode.input,
    helpText: titulo,
    hourLabelText: 'Hora',
    minuteLabelText: 'Minutos',
    cancelText: 'Cancelar',
    confirmText: 'Aceptar',
    builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Campo que muestra una hora y abre el selector al tocarlo.
class CampoHora extends StatelessWidget {
  const CampoHora({
    super.key,
    required this.label,
    required this.minutos,
    required this.onChanged,
    this.inicial = 8 * 60,
    this.nota,
  });

  final String label;
  final int? minutos;
  final ValueChanged<int> onChanged;
  final int inicial;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final valor = minutos;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final m = await elegirHora(context, inicial: valor ?? inicial, titulo: label);
        if (m != null) onChanged(m);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: nota,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.schedule),
        ),
        child: Text(valor == null ? '--:--' : minutesToClock(valor), style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

enum TipoEtiqueta { al50, al100, franco, neutra }

/// Pastilla de color para 50% / 100% / franco.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.tipo = TipoEtiqueta.neutra});

  final String texto;
  final TipoEtiqueta tipo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tipo) {
      TipoEtiqueta.al50 => (cs.tertiaryContainer, cs.onTertiaryContainer),
      TipoEtiqueta.al100 => (cs.primaryContainer, cs.onPrimaryContainer),
      TipoEtiqueta.franco => (cs.secondaryContainer, cs.onSecondaryContainer),
      TipoEtiqueta.neutra => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Título de sección para formularios.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
