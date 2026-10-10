import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db_service.dart';
import '../services/progress_stats.dart';

// Tarjeta que muestra el progreso general del usuario (respuestas, lecciones, racha diaria)
class ProgressCard extends StatefulWidget {
  final String username;

  const ProgressCard({super.key, required this.username});

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  bool _isExpanded = false;
  bool _userChangedExpansion = false;

  String get _preferenceKey =>
      'korulab_progress_expanded_${DBService.normalizeUsername(widget.username)}';

  @override
  void initState() {
    super.initState();
    _loadExpansionPreference();
  }

  @override
  void didUpdateWidget(covariant ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (DBService.normalizeUsername(oldWidget.username) !=
        DBService.normalizeUsername(widget.username)) {
      _isExpanded = false;
      _userChangedExpansion = false;
      _loadExpansionPreference();
    }
  }

  Future<void> _loadExpansionPreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedValue = preferences.getBool(_preferenceKey);
      if (!mounted || _userChangedExpansion || savedValue == null) return;
      setState(() => _isExpanded = savedValue);
    } catch (error) {
      debugPrint('No se pudo cargar la preferencia de progreso: $error');
    }
  }

  Future<void> _toggleExpanded() async {
    final expanded = !_isExpanded;
    setState(() {
      _isExpanded = expanded;
      _userChangedExpansion = true;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_preferenceKey, expanded);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la preferencia de Progreso.'),
          ),
        );
      }
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia de progreso: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la preferencia de Progreso.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: progressStats,
      builder: (context, _) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.insights, color: theme.colorScheme.primary),
                title: Text(
                  'Progreso',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: !_isExpanded
                    ? Text(
                        '${progressStats.completedActivities} actividades · '
                        '${progressStats.accuracyPercent}% precisión',
                      )
                    : null,
                trailing: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: _toggleExpanded,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _ProgressRing(
                                    percentage: progressStats.totalLessons == 0
                                        ? 0
                                        : (progressStats.completedActivities *
                                                  100 ~/
                                                  progressStats.totalLessons)
                                              .clamp(0, 100)
                                              .toInt(),
                                    label: 'Lecciones hechas',
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ProgressRing(
                                    percentage: progressStats.accuracyPercent,
                                    label: 'Precisión',
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${progressStats.completedActivities} de '
                              '${progressStats.totalLessons} actividades '
                              'completadas',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sigue avanzando para completar tu primera unidad.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percentage;
  final String label;
  final Color color;

  const _ProgressRing({
    required this.percentage,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: percentage.clamp(0, 100) / 100,
                  strokeWidth: 9,
                  backgroundColor: theme.colorScheme.outlineVariant,
                  color: color,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
