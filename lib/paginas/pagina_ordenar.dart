import 'dart:async';
import 'package:flutter/material.dart';
import '../tema/tema_korulab.dart';
import '../widgets/actividad_ui.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';
import '../widgets/boton_inicio.dart';

// ─────────────────────────────────────────────
//  5. SORTING / ORDERING PROCESS PAGE
// ─────────────────────────────────────────────
class SortingPage extends StatefulWidget {
  final SortingActivity activity;
  const SortingPage({super.key, required this.activity});

  @override
  State<SortingPage> createState() => _SortingPageState();
}

class _SortingPageState extends State<SortingPage> {
  late List<String> currentOrder;
  bool completed = false;
  bool hasError = false;

  /// Pista que se muestra en el pie tras un intento fallido.
  String? _pista;
  bool _reportedCompletion = false;
  int incorrectAttempts = 0;
  final Set<int> _revealedPositions = {};

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      currentOrder = List.from(widget.activity.correctOrder)..shuffle();
      completed = false;
      hasError = false;
      _reportedCompletion = false;
      incorrectAttempts = 0;
      _revealedPositions.clear();
    });
  }

  void _checkOrder() {
    bool isCorrect = true;
    for (int i = 0; i < currentOrder.length; i++) {
      if (currentOrder[i] != widget.activity.correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      setState(() {
        _pista = null;
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        // Ekostrellas = aciertos × 50 ÷ total: con total = pasos + intentos
        // fallidos, salen proporcionales a la precisión.
        progressStats.reportLessonResult(
          widget.activity.correctOrder.length,
          widget.activity.correctOrder.length + incorrectAttempts,
          activity: widget.activity,
          incorrectAttempts: incorrectAttempts,
        );
      }
    } else {
      setState(() {
        hasError = true;
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      });
      final wrongPositions = [
        for (var i = 0; i < currentOrder.length; i++)
          if (currentOrder[i] != widget.activity.correctOrder[i]) i,
      ];
      var candidates = wrongPositions
          .where((i) => !_revealedPositions.contains(i))
          .toList();
      if (candidates.isEmpty) {
        _revealedPositions.clear();
        candidates = wrongPositions;
      }
      final revealed = candidates.first;
      _revealedPositions.add(revealed);
      setState(
        () => _pista =
            'Posición ${revealed + 1}: ${widget.activity.correctOrder[revealed]}',
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            hasError = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      LeaveLessonGuard(active: !completed, child: _buildScaffold(context));

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        actions: const [BotonInicio()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: completed
              ? ResultScreen(
                  score: widget.activity.correctOrder.length,
                  total: widget.activity.correctOrder.length,
                  incorrectAttempts: incorrectAttempts,
                  onRetry: _reset,
                  activityName: widget.activity.title,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PromptCard(
                      icon: Icons.format_list_numbered_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.activity.instruction,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mantén presionado un paso y arrástralo a su lugar.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Theme(
                        data: theme.copyWith(canvasColor: Colors.transparent),
                        child: ReorderableListView.builder(
                          itemCount: currentOrder.length,
                          proxyDecorator: (child, _, animation) =>
                              AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) => Transform.scale(
                                  scale: 1 + 0.03 * animation.value,
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 8 * animation.value,
                                    shadowColor: theme.colorScheme.shadow
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(
                                      KoruRadius.m,
                                    ),
                                    child: child,
                                  ),
                                ),
                                child: child,
                              ),
                          onReorderItem: (oldIndex, newIndex) {
                            setState(() {
                              _pista = null;
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              final String item = currentOrder.removeAt(
                                oldIndex,
                              );
                              currentOrder.insert(newIndex, item);
                            });
                          },
                          itemBuilder: (context, index) {
                            final step = currentOrder[index];
                            final accent = hasError
                                ? theme.colorScheme.error
                                : koru.hoja;
                            return Padding(
                              key: ValueKey(step),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: hasError
                                    ? theme.colorScheme.error.withValues(
                                        alpha: 0.1,
                                      )
                                    : theme.colorScheme.surfaceContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    KoruRadius.m,
                                  ),
                                  side: BorderSide(
                                    color: hasError
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.outlineVariant,
                                    width: hasError ? 1.5 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(color: accent),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          step,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.drag_indicator_rounded,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnswerFooter(
                      feedback: _pista == null
                          ? null
                          : FeedbackRespuesta.incorrecta('Pista · $_pista'),
                      label: 'Comprobar orden',
                      icon: Icons.check_rounded,
                      onPressed: _checkOrder,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
