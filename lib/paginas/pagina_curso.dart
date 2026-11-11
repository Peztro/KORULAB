import 'package:flutter/material.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_completar.dart';
import '../paginas/pagina_relacionar.dart';
import '../paginas/pagina_memoria.dart';
import '../paginas/pagina_quiz.dart';
import '../paginas/pagina_ordenar.dart';
import '../servicios/estadisticas_progreso.dart';

String _activityLabel(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return 'Quiz';
    case ActivityType.matching:
      return 'Relacionar';
    case ActivityType.memory:
      return 'Memoria';
    case ActivityType.fillBlank:
      return 'Completar';
    case ActivityType.sorting:
      return 'Ordenar';
  }
}

IconData _activityIcon(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return Icons.quiz;
    case ActivityType.matching:
      return Icons.compare_arrows;
    case ActivityType.memory:
      return Icons.grid_view;
    case ActivityType.fillBlank:
      return Icons.edit_note;
    case ActivityType.sorting:
      return Icons.sort;
  }
}

Color _activityColor(ActivityType t) {
  switch (t) {
    case ActivityType.quiz:
      return Colors.blue.shade400;
    case ActivityType.matching:
      return Colors.purple.shade400;
    case ActivityType.memory:
      return Colors.orange.shade400;
    case ActivityType.fillBlank:
      return Colors.teal.shade400;
    case ActivityType.sorting:
      return Colors.red.shade400;
  }
}

// Página de detalle del curso - muestra todas las actividades de un curso específico
class CoursePage extends StatelessWidget {
  final Course course;
  final int courseIndex;

  const CoursePage({
    required this.course,
    required this.courseIndex,
    super.key,
  });

  Widget _buildActivityPage(LessonActivity activity) {
    if (activity is QuizActivity) return QuizPage(activity: activity);
    if (activity is MatchingActivity) return MatchingPage(activity: activity);
    if (activity is MemoryActivity) return MemoryPage(activity: activity);
    if (activity is FillBlankActivity) return FillBlankPage(activity: activity);
    if (activity is SortingActivity) return SortingPage(activity: activity);
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedActivities = course.activities
        .where(progressStats.isActivityCompleted)
        .length;
    final totalActivities = course.activities.length;
    final progressPercent = totalActivities > 0
        ? (completedActivities * 100 / totalActivities).round()
        : 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header con información de la unidad
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.subtitle.isNotEmpty
                          ? course.subtitle
                          : 'Completa todas las actividades para dominar este tema',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progressPercent / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$progressPercent%',
                          style:
                              theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedActivities de $totalActivities completadas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Título de actividades
            Text(
              'Actividades',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            // Lista de actividades
            ...course.activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final color = _activityColor(activity.type);
              final isUnlocked = progressStats.isActivityUnlocked(activity);
              final isCompleted = progressStats.isActivityCompleted(activity);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(
                    alpha: 0.5,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: isCompleted
                        ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    )
                        : Icon(
                      _activityIcon(activity.type),
                      color: color,
                    ),
                  ),
                  title: Text(
                    activity.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    _activityLabel(activity.type),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    isCompleted
                        ? Icons.check_circle_outline
                        : isUnlocked
                        ? Icons.play_arrow
                        : Icons.lock_outline,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : isUnlocked
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.error,
                  ),
                  onTap: () {
                    if (!isUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Completa la actividad ${index} para continuar.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _buildActivityPage(activity),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED: RESULT SCREEN
// ─────────────────────────────────────────────
class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int incorrectAttempts;
  final VoidCallback onRetry;
  final String activityName;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    this.incorrectAttempts = 0,
    required this.onRetry,
    required this.activityName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempts = score + incorrectAttempts;
    final pct = attempts > 0 ? score / attempts : 0.0;
    // Cuando existan más emociones, devolver aquí la imagen según el resultado.
    final mascot = pct == 1.0
        ? 'assets/images/koru_base.png'
        : pct >= 0.7
        ? 'assets/images/koru_base.png'
        : 'assets/images/koru_base.png';
    final msg = pct == 1.0
        ? '¡Perfecto!'
        : pct >= 0.7
        ? '¡Muy bien!'
        : '¡Sigue practicando!';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(mascot, height: 160, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(
            msg,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total correctas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Precisión: ${(pct * 100).toInt()}%'
            '${incorrectAttempts > 0 ? ' · $incorrectAttempts errores' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: onRetry,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide(color: theme.colorScheme.primaryContainer),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al curso'),
          ),
        ],
      ),
    );
  }
}
