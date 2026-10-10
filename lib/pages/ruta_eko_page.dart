import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/course_catalog.dart';
import '../db_service.dart';
import '../models/course_models.dart';
import '../services/progress_stats.dart';
import '../support_pages.dart';
import '../teacher_courses.dart';

class RutaEkoPage extends StatefulWidget {
  final String username;

  const RutaEkoPage({super.key, required this.username});

  @override
  State<RutaEkoPage> createState() => _RutaEkoPageState();
}

class _RutaEkoPageState extends State<RutaEkoPage> {
  List<_RutaEkoTrailUnit> _trailUnits = [];
  bool _isLoadingTeacherLessons = true;
  String? _lessonLoadError;
  String? _realtimeError;
  int _lessonLoadRequest = 0;
  RealtimeChannel? _lessonChangesChannel;
  Future<void>? _builtInCourseMigration;

  @override
  void initState() {
    super.initState();
    progressStats.loadCourseProgress(widget.username);
    _loadTeacherLessons();
    _subscribeToLessonChanges();
  }

  void _subscribeToLessonChanges() {
    _lessonChangesChannel = Supabase.instance.client
        .channel('ruta-eko-lessons-${widget.username}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DBService.teacherLessonTable,
          callback: (_) => _loadTeacherLessons(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DBService.teacherCourseTable,
          callback: (_) => _loadTeacherLessons(),
        )
        .subscribe((status, error) {
          if (!mounted) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            setState(() => _realtimeError = null);
            unawaited(_loadTeacherLessons());
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint('Ruta Eko realtime error: $error');
            setState(() {
              _realtimeError =
                  'No se pudieron activar las actualizaciones automáticas. '
                  'Verifica que la migración de Ruta Eko esté aplicada; '
                  'también puedes deslizar hacia abajo para actualizar.';
            });
          }
        });
  }

  Future<void> _loadTeacherLessons() async {
    final request = ++_lessonLoadRequest;
    try {
      if (DBService.normalizeUsername(widget.username) == 'p.yuli') {
        _builtInCourseMigration ??= DBService.ensureTeacherCourses(
          teacherUsername: 'p.yuli',
          courses: [
            for (final course in courses)
              {
                'title': course.title,
                'subtitle': course.subtitle,
                'activities': encodeCourseActivities(course),
              },
          ],
        );
        await _builtInCourseMigration;
      }
      final lessons = await loadManageableLessons(
        widget.username,
        DBService.lessonDestinationKoruclases,
      );
      lessons.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] as String? ?? '');
        final bDate = DateTime.tryParse(b['created_at'] as String? ?? '');
        if (aDate == null && bDate != null) return 1;
        if (aDate != null && bDate == null) return -1;
        if (aDate != null && bDate != null) {
          final dateOrder = aDate.compareTo(bDate);
          if (dateOrder != 0) return dateOrder;
        }
        return (a['id'] as int).compareTo(b['id'] as int);
      });
      final courseRows = await loadManageableCourses(widget.username);
      if (!mounted || request != _lessonLoadRequest) return;
      final trailUnits = <_RutaEkoTrailUnit>[
        for (final row in courseRows)
          _RutaEkoTrailUnit.course(courseFromRow(row), row),
        for (final row in lessons) _RutaEkoTrailUnit.lesson(row),
      ]..sort(_compareRutaEkoUnits);
      setState(() {
        _trailUnits = trailUnits;
        _lessonLoadError = null;
        _isLoadingTeacherLessons = false;
      });
    } catch (error) {
      debugPrint('No se pudo actualizar Ruta Eko: $error');
      if (!mounted || request != _lessonLoadRequest) return;
      if (DBService.normalizeUsername(widget.username) == 'p.yuli') {
        _builtInCourseMigration = null;
      }
      setState(() {
        _lessonLoadError =
            DBService.normalizeUsername(widget.username) == 'p.yuli'
            ? 'No se pudo migrar el contenido inicial. Verifica que p.yuli '
                  'tenga rol de profesor e inténtalo de nuevo.'
            : 'No se pudo cargar el sendero. Intenta actualizar.';
        _isLoadingTeacherLessons = false;
      });
    }
  }

  @override
  void dispose() {
    final channel = _lessonChangesChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Ruta Eko'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          if (!progressStats.isCourseProgressLoaded ||
              _isLoadingTeacherLessons) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _loadTeacherLessons,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_lessonLoadError != null || _realtimeError != null)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _lessonLoadError ?? _realtimeError!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ...[
                  const SizedBox(height: 20),
                  Text(
                    'Sendero de Ruta Eko',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completa cada unidad para desbloquear la siguiente.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_trailUnits.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'El sendero se está preparando. Inicia sesión con '
                          'la cuenta docente p.yuli y abre Ruta Eko una vez '
                          'para migrar el contenido inicial.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    _UnitTrailProgress(units: _trailUnits),
                    const SizedBox(height: 16),
                    for (final entry in _trailUnits.indexed)
                      if (entry.$2.course != null)
                        TeacherCourseCard(
                          row: entry.$2.row,
                          courseOverride: entry.$2.course,
                          username: widget.username,
                          onChanged: _loadTeacherLessons,
                          unitNumber: entry.$1 + 1,
                          isUnlocked:
                              entry.$1 == 0 ||
                              _trailUnits[entry.$1 - 1].isCompleted,
                        )
                      else
                        _TeacherLessonCard(
                          unitNumber: entry.$1 + 1,
                          lesson: entry.$2.row,
                          username: widget.username,
                          onChanged: _loadTeacherLessons,
                          isUnlocked:
                              entry.$1 == 0 ||
                              _trailUnits[entry.$1 - 1].isCompleted,
                        ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherLessonCard extends StatelessWidget {
  final int unitNumber;
  final Map<String, dynamic> lesson;
  final String username;
  final Future<void> Function() onChanged;
  final bool isUnlocked;

  const _TeacherLessonCard({
    required this.unitNumber,
    required this.lesson,
    required this.username,
    required this.onChanged,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonId = lesson['id'] as int;
    final isCompleted = progressStats.isTeacherLessonCompleted(lessonId);
    final nodeColor = isCompleted || isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: isUnlocked
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isUnlocked
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _TeacherLessonPage(lesson: lesson),
                ),
              )
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Completa la unidad ${unitNumber - 1} para desbloquear esta.',
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'UNIDAD $unitNumber',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: nodeColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                lesson['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                lesson['summary'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: isCompleted ? 1 : 0,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? '100%' : '0%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson['teacher_name'] as String? ?? 'Profesor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (lesson['can_manage'] == true)
                    TeacherLessonMenu(
                      lesson: lesson,
                      username: username,
                      onChanged: onChanged,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 4,
                    color: nodeColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: nodeColor,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isUnlocked
                      ? Icons.eco_outlined
                      : Icons.lock_outline,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: card),
      ],
    );
  }
}

class _RutaEkoTrailUnit {
  final Map<String, dynamic> row;
  final Course? course;

  const _RutaEkoTrailUnit.course(this.course, this.row);

  const _RutaEkoTrailUnit.lesson(this.row) : course = null;

  int get builtInCourseIndex {
    if (course == null ||
        DBService.normalizeUsername(row['teacher_username'] as String? ?? '') !=
            'p.yuli') {
      return -1;
    }
    return courses.indexWhere((item) => item.title == course!.title);
  }

  bool get isCompleted => course == null
      ? progressStats.isTeacherLessonCompleted(row['id'] as int)
      : course!.activities.isNotEmpty &&
            course!.activities.every(progressStats.isActivityCompleted);

  DateTime? get createdAt =>
      DateTime.tryParse(row['created_at'] as String? ?? '');
}

int _compareRutaEkoUnits(_RutaEkoTrailUnit a, _RutaEkoTrailUnit b) {
  final aBuiltIn = a.builtInCourseIndex;
  final bBuiltIn = b.builtInCourseIndex;
  if (aBuiltIn >= 0 && bBuiltIn >= 0) {
    return aBuiltIn.compareTo(bBuiltIn);
  }
  if (aBuiltIn >= 0) return -1;
  if (bBuiltIn >= 0) return 1;
  final aDate = a.createdAt;
  final bDate = b.createdAt;
  if (aDate != null && bDate != null) {
    final dateOrder = aDate.compareTo(bDate);
    if (dateOrder != 0) return dateOrder;
  }
  return (a.row['id'] as int).compareTo(b.row['id'] as int);
}

class _UnitTrailProgress extends StatelessWidget {
  final List<_RutaEkoTrailUnit> units;

  const _UnitTrailProgress({required this.units});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedUnits = units.where((unit) => unit.isCompleted).length;
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${completedUnits} de ${units.length} unidades completadas'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: units.isEmpty ? 0 : completedUnits / units.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

// Carga lecciones marcando cuáles puede editar o eliminar el usuario.
Future<List<Map<String, dynamic>>> loadManageableLessons(
  String username,
  String destination,
) async {
  final lessons = await DBService.getTeacherLessons(destination: destination);
  return [
    for (final lesson in lessons)
      {
        ...lesson,
        'can_manage': await DBService.canManageLesson(username, lesson),
      },
  ];
}

class TeacherLessonMenu extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final String username;
  final Future<void> Function() onChanged;

  const TeacherLessonMenu({
    super.key,
    required this.lesson,
    required this.username,
    required this.onChanged,
  });

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateTeacherLessonPage(teacherUsername: username, lesson: lesson),
      ),
    );
    if (saved == true) await onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar lección'),
        content: Text('¿Eliminar "${lesson['title']}"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await DBService.deleteTeacherLesson(
      requesterUsername: username,
      lessonId: lesson['id'] as int,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Lección eliminada.' : 'No se pudo eliminar la lección.',
        ),
      ),
    );
    if (deleted) await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      onSelected: (value) =>
          value == 'edit' ? _edit(context) : _delete(context),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
      ],
    );
  }
}

class _TeacherLessonPage extends StatelessWidget {
  final Map<String, dynamic> lesson;

  const _TeacherLessonPage({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonId = lesson['id'] as int;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(lesson['title'] as String),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: AnimatedBuilder(
        animation: progressStats,
        builder: (context, _) {
          final isCompleted = progressStats.isTeacherLessonCompleted(lessonId);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                lesson['summary'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lesson['content'] as String,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: isCompleted
                    ? null
                    : () {
                        final completed = progressStats.completeTeacherLesson(
                          lessonId,
                        );
                        if (completed && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Lección completada. ¡Buen trabajo!',
                              ),
                            ),
                          );
                        }
                      },
                icon: Icon(isCompleted ? Icons.check_circle : Icons.done),
                label: Text(
                  isCompleted ? 'Completada' : 'Marcar como completada',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
