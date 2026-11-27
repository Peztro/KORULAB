import 'dart:async';
import 'package:flutter/material.dart';
import '../tema/tema_korulab.dart';
import '../widgets/actividad_ui.dart';
import '../servicio_comentarios.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

// ─────────────────────────────────────────────
//  2. MATCHING PAGE
// ─────────────────────────────────────────────
class MatchingPage extends StatefulWidget {
  final MatchingActivity activity;
  const MatchingPage({super.key, required this.activity});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  late List<String> terms;
  late List<String> definitions;
  String? selectedTerm;
  Map<String, String> matched = {};
  Set<String> wrongAttempts = {};
  int incorrectAttempts = 0;

  /// Corrección del último intento, mostrada en el pie.
  FeedbackRespuesta? _feedback;
  bool completed = false;
  bool _reportedCompletion = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final pairs = List.of(widget.activity.pairs)..shuffle();
    terms = pairs.map((p) => p.term).toList();
    definitions = pairs.map((p) => p.definition).toList()..shuffle();
    selectedTerm = null;
    matched = {};
    wrongAttempts = {};
    incorrectAttempts = 0;
    _feedback = null;
    completed = false;
    _reportedCompletion = false;
  }

  void _onTermTap(String term) {
    if (matched.containsKey(term)) return;
    setState(() => selectedTerm = term);
  }

  void _onDefinitionTap(String def) {
    if (selectedTerm == null) return;
    final correctDef = widget.activity.pairs
        .firstWhere((p) => p.term == selectedTerm)
        .definition;
    if (def == correctDef) {
      setState(() {
        _feedback = FeedbackRespuesta.correcta('${selectedTerm!} → $def');
        matched[selectedTerm!] = def;
        selectedTerm = null;
        if (matched.length == widget.activity.pairs.length) {
          completed = true;
          if (!_reportedCompletion) {
            _reportedCompletion = true;
            // Ekostrellas = aciertos × 50 ÷ total: con total = parejas +
            // errores, salen proporcionales a la precisión.
            progressStats.reportLessonResult(
              widget.activity.pairs.length,
              widget.activity.pairs.length + incorrectAttempts,
              activity: widget.activity,
              incorrectAttempts: incorrectAttempts,
            );
          }
        }
      });
    } else {
      final wrongTerm = selectedTerm!;
      setState(() {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
        wrongAttempts.add('${selectedTerm!}_$def');
        selectedTerm = null;
      });
      setState(
        () => _feedback = FeedbackRespuesta.incorrecta(
          '$wrongTerm → $correctDef',
        ),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => wrongAttempts.clear());
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      LeaveLessonGuard(active: !completed, child: _buildScaffold(context));

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.activity.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: completed
              ? ResultScreen(
                  score: widget.activity.pairs.length,
                  total: widget.activity.pairs.length,
                  incorrectAttempts: incorrectAttempts,
                  onRetry: () => setState(_reset),
                  activityName: widget.activity.title,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActivityProgressHeader(
                      current: matched.length,
                      total: widget.activity.pairs.length,
                      label: 'Parejas',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedTerm == null
                          ? 'Toca un término y luego su definición.'
                          : 'Ahora elige la definición de "$selectedTerm".',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _columnTitle(theme, 'Términos'),
                                  for (final term in terms)
                                    _MatchTile(
                                      text: term,
                                      bold: true,
                                      state: matched.containsKey(term)
                                          ? _MatchState.matched
                                          : selectedTerm == term
                                          ? _MatchState.selected
                                          : _MatchState.idle,
                                      onTap: () => _onTermTap(term),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _columnTitle(theme, 'Definiciones'),
                                  for (final def in definitions)
                                    _MatchTile(
                                      text: def,
                                      state: matched.containsValue(def)
                                          ? _MatchState.matched
                                          : wrongAttempts.any(
                                              (k) => k.endsWith('_$def'),
                                            )
                                          ? _MatchState.wrong
                                          : _MatchState.idle,
                                      onTap: () => _onDefinitionTap(def),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_feedback != null) ...[
                      const SizedBox(height: 12),
                      AnswerFooter(feedback: _feedback),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _columnTitle(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

enum _MatchState { idle, selected, matched, wrong }

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.text,
    required this.state,
    required this.onTap,
    this.bold = false,
  });

  final String text;
  final _MatchState state;
  final VoidCallback onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final koru = context.koru;
    final (Color fondo, Color borde) = switch (state) {
      _MatchState.matched => (koru.hoja.withValues(alpha: 0.16), koru.hoja),
      _MatchState.selected => (scheme.secondaryContainer, koru.agua),
      _MatchState.wrong => (scheme.error.withValues(alpha: 0.14), scheme.error),
      _MatchState.idle => (scheme.surfaceContainer, scheme.outlineVariant),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(KoruRadius.m),
          border: Border.all(
            color: borde,
            width: state == _MatchState.idle ? 1 : 2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(KoruRadius.m),
            onTap: state == _MatchState.matched ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style:
                          (bold
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(
                                fontWeight: bold
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: state == _MatchState.matched
                                    ? scheme.onSurfaceVariant
                                    : null,
                              ),
                    ),
                  ),
                  if (state == _MatchState.matched)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: koru.hoja,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
