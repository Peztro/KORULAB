import 'dart:math';

import 'package:flutter/material.dart';

import '../tema/tema_korulab.dart';

/// Pastilla de "Chats" para la barra superior, a juego con las de racha y
/// ekostrellas. Con mensajes sin leer se pinta de azul, muestra cuántos
/// chats esperan y se sacude un poco cuando llega uno nuevo.
class BotonChats extends StatefulWidget {
  const BotonChats({super.key, required this.sinLeer, required this.onTap});

  /// Chats con mensajes sin leer.
  final int sinLeer;
  final VoidCallback onTap;

  @override
  State<BotonChats> createState() => _BotonChatsState();
}

class _BotonChatsState extends State<BotonChats>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.sinLeer > 0) _sacudir();
  }

  @override
  void didUpdateWidget(BotonChats old) {
    super.didUpdateWidget(old);
    // Llegó un chat nuevo sin leer.
    if (widget.sinLeer > old.sinLeer) _sacudir();
  }

  void _sacudir() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _sacudida.forward(from: 0);
  }

  @override
  void dispose() {
    _sacudida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final hay = widget.sinLeer > 0;
    final texto = hay
        ? (widget.sinLeer > 9 ? '9+' : '${widget.sinLeer}')
        : 'Chats';
    final colorContenido = hay ? Colors.white : koru.agua;

    final pastilla = Material(
      color: hay ? koru.agua : koru.agua.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_rounded, size: 18, color: colorContenido),
              const SizedBox(width: 5),
              Text(
                texto,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: hay ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: hay
          ? 'Mensajes · ${widget.sinLeer} '
                '${widget.sinLeer == 1 ? 'chat' : 'chats'} sin leer'
          : 'Mensajes',
      child: AnimatedBuilder(
        animation: _sacudida,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            pastilla,
            // Punto rojo: hay algo por leer.
            if (hay)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        builder: (context, child) {
          final t = _sacudida.value;
          // Vaivén que se apaga y un pequeño salto.
          final angulo = _sacudida.isAnimating
              ? sin(t * pi * 6) * (1 - t) * 0.22
              : 0.0;
          final escala = _sacudida.isAnimating ? 1 + sin(t * pi) * 0.12 : 1.0;
          return Transform.rotate(
            angle: angulo,
            child: Transform.scale(scale: escala, child: child),
          );
        },
      ),
    );
  }
}
