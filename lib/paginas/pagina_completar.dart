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
  late List<FillBlankQuestion> shuffledQuestions;
  final Map<FillBlankQuestion, int> _previousAnswerPositions = {};

  @override
  void initState() {
    super.initState();
    shuffledQuestions = _shuffleQuestions();
  }

  List<FillBlankQuestion> _shuffleQuestions() {
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
      return FillBlankQuestion(
        sentence: question.sentence,
        options: optionIndexes.map((index) => question.options[index]).toList(),
        answerIndex: answerPosition,
      );
    }).toList()..shuffle();
  }

  void _reset() {
    setState(() {
      currentQuestionIndex = 0;
      score = 0;
      incorrectAttempts = 0;
      selectedOptionIndex = null;
      _hintedOptionIndex = null;
      completed = false;
      _reportedCompletion = false;
      shuffledQuestions = _shuffleQuestions();
    });
  }

  void _selectOption(int index) {
    if (selectedOptionIndex != null) return;
    final question = shuffledQuestions[currentQuestionIndex];
    setState(() {
      selectedOptionIndex = index;
      if (question.answerIndex == index) {
        score++;
      } else {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
      }
    });
  }

  void _useHint() {
    if (selectedOptionIndex != null || _hintedOptionIndex != null) return;
    final question = shuffledQuestions[currentQuestionIndex];
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
        shuffledQuestions[currentQuestionIndex].answerIndex ==
            selectedOptionIndex) {
      return;
    }
    if (!progressStats.useSecondChance()) return;
    setState(() => selectedOptionIndex = null);
  }

  void _nextQuestion() {
    if (currentQuestionIndex + 1 >= shuffledQuestions.length) {
      setState(() {
        completed = true;
      });
      if (!_reportedCompletion) {
        _reportedCompletion = true;
        progressStats.reportLessonResult(
          score,
          shuffledQuestions.length,
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
                  total: widget.activity.questions.length,
                  incorrectAttempts: incorrectAttempts,
                  onRetry: _reset,
                  activityName: widget.activity.title,
                )
              : _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final koru = context.koru;
    final q = shuffledQuestions[currentQuestionIndex];
    final sentenceParts = q.sentence.split('___');
    final String part1 = sentenceParts.isNotEmpty ? sentenceParts[0] : '';
    final String part2 = sentenceParts.length > 1 ? sentenceParts[1] : '';
    final answered = selectedOptionIndex != null;
    final isRight = answered && q.answerIndex == selectedOptionIndex;
    final blankColor = !answered
        ? koru.hoja
        : isRight
        ? koru.hoja
        : theme.colorScheme.error;
    final canRetry = answered && !isRight && progressStats.secondChances > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityProgressHeader(
          current: currentQuestionIndex + 1,
          total: shuffledQuestions.length,
          label: 'Frase',
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
                      answered ||
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
              Text(
                'Completa la frase',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              PromptCard(
                icon: Icons.edit_note_rounded,
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleLarge?.copyWith(height: 1.6),
                    children: [
                      TextSpan(text: part1),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: blankColor.withValues(
                              alpha: answered ? 0.18 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              bottom: BorderSide(color: blankColor, width: 3),
                            ),
                          ),
                          child: Text(
                            answered
                                ? q.options[selectedOptionIndex!]
                                : '      ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: answered
                                  ? blankColor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: part2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < q.options.length; index++)
                AnswerOption(
                  index: index,
                  text: q.options[index],
                  estado: _hintedOptionIndex == index
                      ? EstadoOpcion.descartada
                      : selectedOptionIndex == index
                      ? (q.answerIndex == index
                            ? EstadoOpcion.correcta
                            : EstadoOpcion.incorrecta)
                      : EstadoOpcion.normal,
                  onTap: _hintedOptionIndex == index || answered
                      ? null
                      : () => _selectOption(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnswerFooter(
          feedback: !answered
              ? null
              : isRight
              ? const FeedbackRespuesta.correcta()
              : FeedbackRespuesta.incorrecta(
                  'Respuesta correcta: ${q.options[q.answerIndex]}',
                ),
          label: currentQuestionIndex + 1 == shuffledQuestions.length
              ? 'Finalizar'
              : 'Siguiente',
          icon: currentQuestionIndex + 1 == shuffledQuestions.length
              ? Icons.flag_rounded
              : Icons.arrow_forward_rounded,
          onPressed: answered ? _nextQuestion : null,
        ),
      ],
    );
  }
}
