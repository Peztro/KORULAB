import 'dart:async';
import 'package:flutter/material.dart';
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
        matched[selectedTerm!] = def;
        selectedTerm = null;
        if (matched.length == widget.activity.pairs.length) {
          completed = true;
          if (!_reportedCompletion) {
            _reportedCompletion = true;
            progressStats.reportLessonResult(
              widget.activity.pairs.length,
              widget.activity.pairs.length,
              activity: widget.activity,
              incorrectAttempts: incorrectAttempts,
            );
          }
        }
      });
    } else {
      setState(() {
        incorrectAttempts++;
        unawaited(vibrateOnWrongAnswer());
        wrongAttempts.add('${selectedTerm!}_$def');
        selectedTerm = null;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => wrongAttempts.clear());
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
                score: widget.activity.pairs.length,
                total: widget.activity.pairs.length,
                incorrectAttempts: incorrectAttempts,
                onRetry: () => setState(_reset),
                activityName: widget.activity.title,
              )
            : Column(
                children: [
                  Text(
                    'Toca un término y luego su definición correcta.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Terms column
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Términos',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...terms.map((term) {
                                final isMatched = matched.containsKey(term);
                                final isSelected = selectedTerm == term;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onTermTap(term),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(
                                                0.7,
                                              )
                                            : isSelected
                                            ? Colors.purple.shade900
                                                  .withOpacity(0.8)
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isMatched
                                              ? Colors.green.shade400
                                              : isSelected
                                              ? Colors.purple.shade400
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        term,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Definitions column
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Definiciones',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...definitions.map((def) {
                                final isMatched = matched.containsValue(def);
                                final isWrong = wrongAttempts.any(
                                  (k) => k.endsWith('_$def'),
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _onDefinitionTap(def),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? Colors.green.shade800.withOpacity(
                                                0.7,
                                              )
                                            : isWrong
                                            ? Colors.red.shade900.withOpacity(
                                                0.8,
                                              )
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isMatched
                                              ? Colors.green.shade400
                                              : isWrong
                                              ? Colors.red.shade400
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        def,
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
