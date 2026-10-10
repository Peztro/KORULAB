import 'dart:async';
import 'package:flutter/material.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

// ─────────────────────────────────────────────
//  1. QUIZ PAGE
// ─────────────────────────────────────────────
class QuizPage extends StatefulWidget {
  final QuizActivity activity;
  const QuizPage({super.key, required this.activity});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int questionIndex = 0;
  int score = 0;
  int incorrectAttempts = 0;
  int? selectedOption;
  int? _hintedOptionIndex;
  bool completed = false;
  bool _reportedCompletion = false;
  late List<Question> shuffledQuestions;

  @override
  void initState() {
    super.initState();
    shuffledQuestions = List.from(widget.activity.questions)..shuffle();
  }

  void _reset() {
    setState(() {
      completed = false;
      questionIndex = 0;
      selectedOption = null;
      _hintedOptionIndex = null;
      score = 0;
      incorrectAttempts = 0;
      _reportedCompletion = false;
      shuffledQuestions = List.from(widget.activity.questions)..shuffle();
    });
  }

  void _reportCompletion() {
    if (_reportedCompletion) return;
    _reportedCompletion = true;
    progressStats.reportLessonResult(
      score,
      shuffledQuestions.length,
      activity: widget.activity,
      incorrectAttempts: incorrectAttempts,
    );
  }

  void selectOption(int index) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = index;
      if (shuffledQuestions[questionIndex].answerIndex == index) {
        score++;
      } else {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      }
    });
  }

  void _useHint() {
    if (selectedOption != null || _hintedOptionIndex != null) return;
    final question = shuffledQuestions[questionIndex];
    final wrongOptions = [
      for (var index = 0; index < question.options.length; index++)
        if (index != question.answerIndex) index,
    ];
    if (wrongOptions.isEmpty) return;
    if (!progressStats.useHint()) return;
    setState(() => _hintedOptionIndex = wrongOptions.first);
  }

  void _useSecondChance() {
    if (selectedOption == null ||
        shuffledQuestions[questionIndex].answerIndex == selectedOption) {
      return;
    }
    if (!progressStats.useSecondChance()) return;
    setState(() => selectedOption = null);
  }

  void nextQuestion() {
    if (questionIndex + 1 >= shuffledQuestions.length) {
      setState(() {
        completed = true;
      });
      _reportCompletion();
      return;
    }
    setState(() {
      questionIndex++;
      selectedOption = null;
      _hintedOptionIndex = null;
    });
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
                total: shuffledQuestions.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: _reset,
                activityName: widget.activity.title,
              )
            : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final theme = Theme.of(context);
    final question = shuffledQuestions[questionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (questionIndex + 1) / shuffledQuestions.length,
          backgroundColor: theme.colorScheme.outlineVariant,
          color: theme.colorScheme.primaryContainer,
        ),
        const SizedBox(height: 12),
        Text(
          'Pregunta ${questionIndex + 1} de ${shuffledQuestions.length}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          question.prompt,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child:
              selectedOption != null &&
                  question.answerIndex != selectedOption &&
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
                      selectedOption != null ||
                          _hintedOptionIndex != null ||
                          progressStats.hintCredits == 0
                      ? null
                      : _useHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Pista (${progressStats.hintCredits})'),
                ),
        ),
        const SizedBox(height: 24),
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isSelected = selectedOption == index;
          final isCorrect = question.answerIndex == index;
          final isEliminated = _hintedOptionIndex == index;
          Color? cardColor;
          Color? textColor;
          if (selectedOption != null) {
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
              onPressed: isEliminated ? null : () => selectOption(index),
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
          onPressed: selectedOption == null ? null : nextQuestion,
          child: Text(
            questionIndex + 1 == shuffledQuestions.length
                ? 'Finalizar'
                : 'Siguiente',
          ),
        ),
      ],
    );
  }
}
