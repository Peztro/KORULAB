import 'dart:async';
import 'package:flutter/material.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

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
  bool _reportedCompletion = false;
  int incorrectAttempts = 0;

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
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(
          widget.activity.correctOrder.length,
          widget.activity.correctOrder.length,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El orden no es correcto. ¡Sigue intentándolo!'),
          backgroundColor: Colors.red,
        ),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.activity.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                  Text(
                    widget.activity.instruction,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantén presionado y arrastra para reordenar los pasos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Theme(
                      data: theme.copyWith(canvasColor: Colors.transparent),
                      child: ReorderableListView.builder(
                        itemCount: currentOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final String item = currentOrder.removeAt(oldIndex);
                            currentOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final step = currentOrder[index];
                          return Card(
                            key: ValueKey(step),
                            margin: const EdgeInsets.only(bottom: 12),
                            color: hasError
                                ? Colors.red.shade900.withOpacity(0.5)
                                : theme.colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: hasError
                                    ? Colors.red
                                    : theme.colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(
                                step,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              trailing: Icon(
                                Icons.drag_handle,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _checkOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Verificar Orden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
