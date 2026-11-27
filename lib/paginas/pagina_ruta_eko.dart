import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datos/catalogo_cursos.dart';
import '../servicio_bd.dart';
import '../modelos/modelos_curso.dart';
import '../servicios/estadisticas_progreso.dart';
import '../paginas_soporte.dart';
import '../cursos_docentes.dart';
import '../paginas/pagina_curso.dart';
import '../tema/tema_korulab.dart';
import '../widgets/sendero.dart';

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
      appBar: AppBar(title: const Text('Ruta Eko')),
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (_lessonLoadError != null || _realtimeError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _lessonLoadError ?? _realtimeError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                _UnitTrailProgress(units: _trailUnits),
                const SizedBox(height: 8),
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
                else
                  SenderoRutaEko(paradas: _buildStops(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Convierte las unidades en paradas del sendero.
  List<ParadaSendero> _buildStops(BuildContext context) {
    final stops = <ParadaSendero>[];
    var currentAssigned = false;
    for (final (index, unit) in _trailUnits.indexed) {
      final unlocked = index == 0 || _trailUnits[index - 1].isCompleted;
      final completed = unit.isCompleted;
      final EstadoParada estado;
      if (completed) {
        estado = EstadoParada.completada;
      } else if (unlocked && !currentAssigned) {
        estado = EstadoParada.actual;
        currentAssigned = true;
      } else if (unlocked) {
        estado = EstadoParada.disponible;
      } else {
        estado = EstadoParada.bloqueada;
      }

      void locked() => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Completa la unidad $index para desbloquear esta.'),
          ),
        );

      final course = unit.course;
      if (course != null) {
        final total = course.activities.length;
        final done = course.activities
            .where(progressStats.isActivityCompleted)
            .length;
        stops.add(
          ParadaSendero(
            titulo: course.title,
            subtitulo: course.subtitle,
            detalle: total == 0
                ? 'Sin actividades'
                : '$done/$total actividades',
            estado: estado,
            progreso: total == 0 ? 0 : done / total,
            onTap: unlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CoursePage(course: course, courseIndex: -1),
                    ),
                  )
                : locked,
            menu: unit.row['can_manage'] == true
                ? TeacherCourseMenu(
                    row: unit.row,
                    username: widget.username,
                    onChanged: _loadTeacherLessons,
                  )
                : null,
          ),
        );
      } else {
        final lesson = unit.row;
        stops.add(
          ParadaSendero(
            titulo: lesson['title'] as String,
            subtitulo: lesson['summary'] as String? ?? '',
            detalle: completed ? 'Lección completada' : 'Lección',
            estado: estado,
            progreso: completed ? 1 : 0,
            onTap: unlocked
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TeacherLessonPage(lesson: lesson),
                    ),
                  )
                : locked,
            menu: lesson['can_manage'] == true
                ? TeacherLessonMenu(
                    lesson: lesson,
                    username: widget.username,
                    onChanged: _loadTeacherLessons,
                  )
                : null,
          ),
        );
      }
    }
    return stops;
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
    final koru = context.koru;
    final completedUnits = units.where((unit) => unit.isCompleted).length;
    final ratio = units.isEmpty ? 0.0 : completedUnits / units.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: koru.degradadoHero,
        borderRadius: BorderRadius.circular(KoruRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sendero de Ruta Eko',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: koru.textoHero,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completa cada unidad para abrir la siguiente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: koru.textoHero.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    color: koru.textoHero,
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedUnits de ${units.length} unidades',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: koru.textoHero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.route_rounded, size: 34, color: koru.textoHero),
          ),
        ],
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
      appBar: AppBar(title: Text(lesson['title'] as String)),
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
