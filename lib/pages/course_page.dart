import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../pages/fill_blank_page.dart';
import '../pages/matching_page.dart';
import '../pages/memory_page.dart';
import '../pages/quiz_page.dart';
import '../pages/sorting_page.dart';
import '../services/progress_stats.dart';

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
        builder: (context, _) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: course.activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final activity = course.activities[index];
            final color = _activityColor(activity.type);
            final isUnlocked = progressStats.isActivityUnlocked(activity);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(_activityIcon(activity.type), color: color),
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
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: Icon(
                isUnlocked ? Icons.play_arrow : Icons.lock_outline,
                color: isUnlocked
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.error,
              ),
              onTap: () {
                if (!isUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa la actividad anterior para continuar.',
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
            );
          },
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
    final emoji = pct == 1.0
        ? '🏆'
        : pct >= 0.7
        ? '⭐'
        : '💪';
    final msg = pct == 1.0
        ? '¡Perfecto!'
        : pct >= 0.7
        ? '¡Muy bien!'
        : '¡Sigue practicando!';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
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
