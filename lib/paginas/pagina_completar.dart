import 'dart:async';
import 'package:flutter/material.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

// ─────────────────────────────────────────────
//  4. FILL IN THE BLANK PAGE
// ─────────────────────────────────────────────
class FillBlankPage extends StatefulWidget {
  final FillBlankActivity activity;
  const FillBlankPage({super.key, required this.activity});

  @override
  State<FillBlankPage> createState() => _FillBlankPageState();
}

class _FillBlankPageState extends State<FillBlankPage> {
  int currentQuestionIndex = 0;
  int score = 0;
  int incorrectAttempts = 0;
  int? selectedOptionIndex;
  int? _hintedOptionIndex;
  bool completed = false;
  bool _reportedCompletion = false;

  void _reset() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      incorrectAttempts = 0;
      selectedOptionIndex = null;
      _hintedOptionIndex = null;
      completed = false;
      _reportedCompletion = false;
    });
  }

  void _selectOption(int index) {
    if (selectedOptionIndex != null) return;
    setState(() {
      selectedOptionIndex = index;
      if (widget.activity.questions[currentQuestionIndex].answerIndex ==
          index) {
        score++;
      } else {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      }
    });
  }

  void _useHint() {
    if (selectedOptionIndex != null || _hintedOptionIndex != null) return;
    final question = widget.activity.questions[currentQuestionIndex];
    final wrongOptions = [
      for (var index = 0; index < question.options.length; index++)
        if (index != question.answerIndex) index,
    ];
    if (wrongOptions.isEmpty) return;
    if (!progressStats.useHint()) return;
    setState(() => _hintedOptionIndex = wrongOptions.first);
  }

  void _useSecondChance() {
    if (selectedOptionIndex == null ||
        widget.activity.questions[currentQuestionIndex].answerIndex ==
            selectedOptionIndex) {
      return;
    }
    if (!progressStats.useSecondChance()) return;
    setState(() => selectedOptionIndex = null);
  }

  void _nextQuestion() {
    if (currentQuestionIndex + 1 >= widget.activity.questions.length) {
      setState(() {
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(
          score,
          widget.activity.questions.length,
          activity: widget.activity,
          incorrectAttempts: incorrectAttempts,
        );
      }
    } else {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        _hintedOptionIndex = null;
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
                score: score,
                total: widget.activity.questions.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final q = widget.activity.questions[currentQuestionIndex];
    final sentenceParts = q.sentence.split('___');
    final String part1 = sentenceParts.isNotEmpty ? sentenceParts[0] : '';
    final String part2 = sentenceParts.length > 1 ? sentenceParts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (currentQuestionIndex + 1) / widget.activity.questions.length,
          backgroundColor: theme.colorScheme.outlineVariant,
          color: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(height: 12),
        Text(
          'Pregunta ${currentQuestionIndex + 1} de ${widget.activity.questions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: part1),
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: selectedOptionIndex == null
                          ? theme.colorScheme.surfaceContainerHighest
                          : (q.answerIndex == selectedOptionIndex
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedOptionIndex == null
                            ? theme.colorScheme.outline
                            : (q.answerIndex == selectedOptionIndex
                                  ? Colors.green.shade400
                                  : Colors.red.shade400),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      selectedOptionIndex == null
                          ? ' ____ '
                          : q.options[selectedOptionIndex!],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: part2),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child:
              selectedOptionIndex != null &&
                  q.answerIndex != selectedOptionIndex &&
                  progressStats.secondChances > 0
              ? TextButton.icon(
                  onPressed: _useSecondChance,
                  icon: const Icon(Icons.replay),
                  label: Text(
                    'Segundo intento (${progressStats.secondChances})',
                  ),
                )
              : TextButton.icon(
                  onPressed:
                      selectedOptionIndex != null ||
                          _hintedOptionIndex != null ||
                          progressStats.hintCredits == 0
                      ? null
                      : _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Pista (${progressStats.hintCredits})'),
                ),
        ),
        const SizedBox(height: 40),
        ...List.generate(q.options.length, (index) {
          final option = q.options[index];
          final isSelected = selectedOptionIndex == index;
          final isCorrect = q.answerIndex == index;
          final isEliminated = _hintedOptionIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOptionIndex != null) {
            if (isSelected && isCorrect) {
              cardColor = Colors.green.shade800;
              textColor = Colors.white;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade800;
              textColor = Colors.white;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEliminated
                    ? theme.colorScheme.outlineVariant
                    : cardColor ??
                          theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                foregroundColor: isEliminated
                    ? theme.colorScheme.onSurfaceVariant
                    : textColor ?? theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onPressed: isEliminated ? null : () => _selectOption(index),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEliminated ? '$option  ·  Descartada' : option,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
          onPressed: selectedOptionIndex == null ? null : _nextQuestion,
          child: Text(
            currentQuestionIndex + 1 == widget.activity.questions.length
                ? 'Finalizar'
                : 'Siguiente',
          ),
        ),
      ],
    );
  }
}
