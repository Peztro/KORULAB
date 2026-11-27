import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/actividad_ui.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';
import '../widgets/boton_inicio.dart';

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
  final Map<Question, int> _previousAnswerPositions = {};

  @override
  void initState() {
    super.initState();
    shuffledQuestions = _shuffleQuestions();
  }

  List<Question> _shuffleQuestions() {
    return widget.activity.questions.map((question) {
      final optionIndexes = List<int>.generate(
        question.options.length,
        (index) => index,
      )..shuffle();
      var answerPosition = optionIndexes.indexOf(question.answerIndex);
      final previousAnswerPosition = _previousAnswerPositions[question];
      if (optionIndexes.length > 1 &&
          answerPosition == previousAnswerPosition) {
        final otherPosition = (answerPosition + 1) % optionIndexes.length;
        optionIndexes[answerPosition] = optionIndexes[otherPosition];
        optionIndexes[otherPosition] = question.answerIndex;
        answerPosition = otherPosition;
      }
      _previousAnswerPositions[question] = answerPosition;
      return Question(
        prompt: question.prompt,
        options: optionIndexes.map((index) => question.options[index]).toList(),
        answerIndex: answerPosition,
      );
    }).toList()..shuffle();
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
      shuffledQuestions = _shuffleQuestions();
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
    final question = shuffledQuestions[questionIndex];
    setState(() {
      selectedOption = index;
      if (question.answerIndex == index) {
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
  Widget build(BuildContext context) =>
      LeaveLessonGuard(active: !completed, child: _buildScaffold(context));

  Widget _buildScaffold(BuildContext context) {
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
                  score: score,
                  total: shuffledQuestions.length,
                  incorrectAttempts: incorrectAttempts,
                  onRetry: _reset,
                  activityName: widget.activity.title,
                )
              : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final theme = Theme.of(context);
    final question = shuffledQuestions[questionIndex];
    final canRetry =
        selectedOption != null &&
        question.answerIndex != selectedOption &&
        progressStats.secondChances > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityProgressHeader(
          current: questionIndex + 1,
          total: shuffledQuestions.length,
          trailing: canRetry
              ? HelperChip(
                  icon: Icons.replay_rounded,
                  label: 'Segundo intento (${progressStats.secondChances})',
                  onPressed: _useSecondChance,
                )
              : HelperChip(
                  icon: Icons.lightbulb_rounded,
                  label: 'Pista (${progressStats.hintCredits})',
                  onPressed:
                      selectedOption != null ||
                          _hintedOptionIndex != null ||
                          progressStats.hintCredits == 0
                      ? null
                      : _useHint,
                ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              PromptCard(
                icon: Icons.help_rounded,
                child: Text(
                  question.prompt,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < question.options.length; index++)
                AnswerOption(
                  index: index,
                  text: question.options[index],
                  estado: _optionState(question.answerIndex, index),
                  onTap: _hintedOptionIndex == index || selectedOption != null
                      ? null
                      : () => selectOption(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnswerFooter(
          feedback: selectedOption == null
              ? null
              : selectedOption == question.answerIndex
              ? const FeedbackRespuesta.correcta()
              : FeedbackRespuesta.incorrecta(
                  'Respuesta correcta: ${question.options[question.answerIndex]}',
                ),
          label: questionIndex + 1 == shuffledQuestions.length
              ? 'Finalizar'
              : 'Siguiente',
          icon: questionIndex + 1 == shuffledQuestions.length
              ? Icons.flag_rounded
              : Icons.arrow_forward_rounded,
          onPressed: selectedOption == null ? null : nextQuestion,
        ),
      ],
    );
  }

  EstadoOpcion _optionState(int answerIndex, int index) {
    if (_hintedOptionIndex == index) return EstadoOpcion.descartada;
    if (selectedOption == null) return EstadoOpcion.normal;
    if (selectedOption == index) {
      return index == answerIndex
          ? EstadoOpcion.correcta
          : EstadoOpcion.incorrecta;
    }
    return EstadoOpcion.normal;
  }
}
