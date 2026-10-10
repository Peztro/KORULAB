import 'package:flutter/material.dart';
import '../modelos/modelos_curso.dart';
import '../paginas/pagina_curso.dart';
import '../servicios/estadisticas_progreso.dart';

// Tarjeta de curso - muestra su estado bloqueado o disponible
class CourseCard extends StatelessWidget {
  final Course course;
  final int courseIndex;

  const CourseCard({
    required this.course,
    required this.courseIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        final isUnlocked = progressStats.isCourseUnlocked(courseIndex);
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isUnlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CoursePage(course: course, courseIndex: courseIndex),
                    ),
                  )
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa el curso anterior para continuar.',
                      ),
                    ),
                  ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Icon(
                      course.icon,
                      size: 28,
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.activities.length} actividades',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isUnlocked ? Icons.chevron_right : Icons.lock_outline,
                    color: isUnlocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  SPECIAL ACTIVITY CARD
// ─────────────────────────────────────────────
// Tarjeta para actividades especiales - Korucol, retos, talleres y contenido destacado
class SpecialActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SpecialActivityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: color.withOpacity(0.15),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 32, color: color),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
