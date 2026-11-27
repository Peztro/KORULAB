import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../tema/tema_korulab.dart';
import '../widgets/actividad_ui.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

// ─────────────────────────────────────────────
//  3. MEMORY CARD GAME PAGE
// ─────────────────────────────────────────────
class MemoryPage extends StatefulWidget {
  final MemoryActivity activity;
  const MemoryPage({super.key, required this.activity});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  late List<MemoryItem> cardItems;
  List<int> selectedIndices = [];
  int score = 0;
  int incorrectAttempts = 0;
  late ContadorErroresMemoria _contador;
  bool completed = false;
  bool busy = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final cards = widget.activity.cards;
    final doubled = <MemoryCard>[];
    for (final card in cards) {
      doubled.add(card);
      doubled.add(card);
    }
    doubled.shuffle();

    cardItems = doubled.map((c) => MemoryItem(card: c)).toList();
    _contador = ContadorErroresMemoria([for (final c in doubled) c.label]);
    selectedIndices.clear();
    score = 0;
    incorrectAttempts = 0;
    completed = false;
    busy = false;
    _reportedCompletion = false;
  }

  void _onCardTap(int index) {
    if (busy || cardItems[index].isFlipped || cardItems[index].isMatched)
      return;

    setState(() {
      cardItems[index].isFlipped = true;
      selectedIndices.add(index);
    });

    if (selectedIndices.length == 2) {
      final firstIdx = selectedIndices[0];
      final secondIdx = selectedIndices[1];
      final firstCard = cardItems[firstIdx].card;
      final secondCard = cardItems[secondIdx].card;
      final esError = _contador.registrarIntento(firstIdx, secondIdx);

      if (firstCard.label == secondCard.label) {
        setState(() {
          cardItems[firstIdx].isMatched = true;
          cardItems[secondIdx].isMatched = true;
          selectedIndices.clear();
          score++;
          if (score == widget.activity.cards.length) {
            completed = true;
            if (!_reportedCompletion) {
              _reportedCompletion = true;
              // Las ekostrellas son aciertos × 50 ÷ total: con total =
              // parejas + errores, salen proporcionales a la precisión.
              progressStats.reportLessonResult(
                widget.activity.cards.length,
                widget.activity.cards.length + incorrectAttempts,
                activity: widget.activity,
                incorrectAttempts: incorrectAttempts,
              );
            }
          }
        });
      } else {
        setState(() {
          if (esError) {
            incorrectAttempts++;
            unawaited(vibrateOnWrongAnswer());
          }
          busy = true;
        });
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              cardItems[firstIdx].isFlipped = false;
              cardItems[secondIdx].isFlipped = false;
              selectedIndices.clear();
              busy = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      LeaveLessonGuard(active: !completed, child: _buildScaffold(context));

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final found = cardItems.where((c) => c.isMatched).length ~/ 2;
    final totalPairs = cardItems.length ~/ 2;
    return Scaffold(
      appBar: AppBar(title: Text(widget.activity.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: completed
              ? ResultScreen(
                  score: widget.activity.cards.length,
                  total: widget.activity.cards.length,
                  incorrectAttempts: incorrectAttempts,
                  onRetry: _reset,
                  activityName: widget.activity.title,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActivityProgressHeader(
                      current: found,
                      total: totalPairs,
                      label: 'Parejas',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Voltea las cartas y encuentra las parejas.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: cardItems.length,
                        itemBuilder: (context, index) => _MemoryCardView(
                          item: cardItems[index],
                          onTap: () => _onCardTap(index),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Carta del juego de memoria con giro animado.
class _MemoryCardView extends StatelessWidget {
  const _MemoryCardView({required this.item, required this.onTap});

  final MemoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showFace = item.isFlipped || item.isMatched;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotate.value),
              child: child,
            ),
          );
        },
        // Las cartas deben llenar la casilla de la cuadrícula.
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, ?current]),
        child: showFace
            ? _face(context, key: const ValueKey('face'))
            : _back(context, key: const ValueKey('back')),
      ),
    );
  }

  Widget _back(BuildContext context, {Key? key}) {
    final koru = context.koru;
    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: koru.degradadoHero,
        borderRadius: BorderRadius.circular(KoruRadius.m),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.eco_rounded,
            size: 40,
            color: koru.textoHero.withValues(alpha: 0.9),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.eco_rounded,
              size: 56,
              color: koru.textoHero.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _face(BuildContext context, {Key? key}) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final matched = item.isMatched;
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: matched
            ? koru.hoja.withValues(alpha: 0.16)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KoruRadius.m),
        border: Border.all(
          color: matched ? koru.hoja : theme.colorScheme.outline,
          width: matched ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.card.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text(
                    item.card.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (matched)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: koru.hoja,
              ),
            ),
        ],
      ),
    );
  }
}

/// Decide qué intentos fallidos cuentan como error en el juego de memoria.
///
/// Al principio todas las cartas están boca abajo, así que fallar a ciegas es
/// inevitable. Solo cuentan los fallos que podías evitar con lo que ya habías
/// visto:
/// * la pareja de la primera carta ya había salido (sabías dónde estaba), o
/// * la segunda carta ya había salido (sabías que no era la pareja).
class ContadorErroresMemoria {
  ContadorErroresMemoria(this.etiquetas);

  /// Etiqueta de cada carta del tablero, en orden.
  final List<String> etiquetas;
  final Set<int> _vistas = {};

  bool _parejaVista(int indice) {
    for (final otra in _vistas) {
      if (otra != indice && etiquetas[otra] == etiquetas[indice]) return true;
    }
    return false;
  }

  /// Registra que se voltearon [primera] y luego [segunda]. Devuelve true si
  /// el intento cuenta como error.
  bool registrarIntento(int primera, int segunda) {
    final esPareja = etiquetas[primera] == etiquetas[segunda];
    final evitable =
        !esPareja && (_parejaVista(primera) || _vistas.contains(segunda));
    _vistas
      ..add(primera)
      ..add(segunda);
    return evitable;
  }
}

class MemoryItem {
  final MemoryCard card;
  bool isFlipped = false;
  bool isMatched = false;
  MemoryItem({
    required this.card,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
