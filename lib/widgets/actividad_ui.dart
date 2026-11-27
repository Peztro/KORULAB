import 'package:flutter/material.dart';

import '../tema/tema_korulab.dart';

/// Barra superior de una actividad: progreso redondeado y contador.
class ActivityProgressHeader extends StatelessWidget {
  const ActivityProgressHeader({
    super.key,
    required this.current,
    required this.total,
    this.label = 'Pregunta',
    this.trailing,
  });

  /// Paso actual empezando en 1.
  final int current;
  final int total;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : current / total),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              color: koru.hoja,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '$label $current de $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ],
    );
  }
}

/// Estado visual de una opción de respuesta.
enum EstadoOpcion { normal, seleccionada, correcta, incorrecta, descartada }

/// Opción de respuesta con letra (A, B, C...) y color según el resultado.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.index,
    required this.text,
    required this.estado,
    required this.onTap,
  });

  final int index;
  final String text;
  final EstadoOpcion estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final koru = context.koru;

    final (
      Color fondo,
      Color borde,
      Color acento,
      IconData? icono,
    ) = switch (estado) {
      EstadoOpcion.correcta => (
        koru.hoja.withValues(alpha: 0.16),
        koru.hoja,
        koru.hoja,
        Icons.check_circle_rounded,
      ),
      EstadoOpcion.incorrecta => (
        scheme.error.withValues(alpha: 0.14),
        scheme.error,
        scheme.error,
        Icons.cancel_rounded,
      ),
      EstadoOpcion.seleccionada => (
        scheme.primaryContainer,
        koru.hoja,
        koru.hoja,
        null,
      ),
      EstadoOpcion.descartada => (
        scheme.surfaceContainerHigh,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
        Icons.block_rounded,
      ),
      EstadoOpcion.normal => (
        scheme.surfaceContainer,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
        null,
      ),
    };

    final letra = String.fromCharCode(65 + index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: estado == EstadoOpcion.descartada ? 0.55 : 1,
        child: Material(
          color: fondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KoruRadius.m),
            side: BorderSide(
              color: borde,
              width: estado == EstadoOpcion.normal ? 1 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: acento.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      letra,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: acento,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      estado == EstadoOpcion.descartada
                          ? '$text · descartada'
                          : text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: estado == EstadoOpcion.descartada
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (icono != null) ...[
                    const SizedBox(width: 10),
                    Icon(icono, color: acento),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de ayuda (pista o segundo intento) en forma de píldora.
class HelperChip extends StatelessWidget {
  const HelperChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final koru = context.koru;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: onPressed == null ? null : koru.oro),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

/// Tarjeta del enunciado de la pregunta.
class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.child, this.icon});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KoruRadius.l),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: koru.hoja, size: 26),
            const SizedBox(width: 12),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Resultado de una respuesta para mostrar en el pie de la actividad.
@immutable
class FeedbackRespuesta {
  const FeedbackRespuesta.correcta([this.detalle]) : correcta = true;
  const FeedbackRespuesta.incorrecta(this.detalle) : correcta = false;

  final bool correcta;

  /// Texto extra, p. ej. "Respuesta correcta: turbinas".
  final String? detalle;
}

/// Pie de la actividad: el panel de corrección y el botón principal van
/// juntos, así el mensaje nunca tapa el botón. El panel sube deslizándose
/// cuando hay una respuesta y desaparece al pasar a la siguiente.
class AnswerFooter extends StatelessWidget {
  const AnswerFooter({
    super.key,
    required this.feedback,
    this.label,
    this.icon,
    this.onPressed,
  });

  final FeedbackRespuesta? feedback;

  /// Texto del botón; sin él, el pie solo muestra el panel.
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final koru = context.koru;
    final fb = feedback;
    final acento = fb == null
        ? scheme.primary
        : fb.correcta
        ? koru.hoja
        : scheme.error;

    final boton = label == null
        ? null
        : FilledButton.icon(
            onPressed: onPressed,
            style: fb == null || fb.correcta
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
            icon: Icon(icon ?? Icons.arrow_forward_rounded),
            label: Text(label!),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: fb == null ? EdgeInsets.zero : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fb == null ? Colors.transparent : acento.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(KoruRadius.l),
        border: Border.all(
          color: fb == null
              ? Colors.transparent
              : acento.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: fb == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      key: ValueKey('${fb.correcta}${fb.detalle}'),
                      padding: EdgeInsets.only(bottom: boton == null ? 0 : 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            fb.correcta
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: acento,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fb.correcta ? '¡Correcto!' : 'Incorrecto',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: acento,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (fb.detalle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    fb.detalle!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          ?boton,
        ],
      ),
    );
  }
}
