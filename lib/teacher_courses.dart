import 'dart:convert';

import 'package:flutter/material.dart';

import 'db_service.dart';
import 'main.dart';

const _typeLabels = {
  'quiz': 'Quiz de opción múltiple',
  'matching': 'Relacionar términos',
  'memory': 'Memoria',
  'fillBlank': 'Completar espacios',
  'sorting': 'Ordenar pasos',
};

const _typeIcons = {
  'quiz': Icons.quiz_outlined,
  'matching': Icons.compare_arrows,
  'memory': Icons.grid_view,
  'fillBlank': Icons.edit_note,
  'sorting': Icons.format_list_numbered,
};

List<Map<String, dynamic>> decodeActivities(String? source) {
  try {
    final decoded = jsonDecode(source ?? '[]') as List;
    return [for (final a in decoded) Map<String, dynamic>.from(a as Map)];
  } catch (_) {
    return [];
  }
}

LessonActivity? activityFromJson(Map<String, dynamic> j) {
  try {
    final title = (j['title'] as String?) ?? 'Actividad';
    List<Map<String, dynamic>> list(String key) => [
          for (final e in (j[key] as List)) Map<String, dynamic>.from(e as Map),
        ];
    switch (j['type']) {
      case 'quiz':
        return QuizActivity(title: title, questions: [
          for (final q in list('questions'))
            Question(
              prompt: q['prompt'] as String,
              options: List<String>.from(q['options'] as List),
              answerIndex: q['answer'] as int,
            ),
        ]);
      case 'matching':
        return MatchingActivity(title: title, pairs: [
          for (final p in list('pairs'))
            MatchPair(
              term: p['term'] as String,
              definition: p['definition'] as String,
            ),
        ]);
      case 'memory':
        return MemoryActivity(title: title, cards: [
          for (final c in list('cards'))
            MemoryCard(emoji: c['emoji'] as String, label: c['label'] as String),
        ]);
      case 'fillBlank':
        return FillBlankActivity(title: title, questions: [
          for (final q in list('questions'))
            FillBlankQuestion(
              sentence: q['sentence'] as String,
              options: List<String>.from(q['options'] as List),
              answerIndex: q['answer'] as int,
            ),
        ]);
      case 'sorting':
        return SortingActivity(
          title: title,
          instruction: j['instruction'] as String? ?? 'Ordena los pasos.',
          correctOrder: [for (final i in list('items')) i['text'] as String],
        );
    }
  } catch (_) {}
  return null;
}

// Convierte una fila de la base de datos en un curso jugable.
Course courseFromRow(Map<String, dynamic> row) {
  final courseId = row['id'] as int;
  final activities = <LessonActivity>[];
  final raw = decodeActivities(row['activities'] as String?);
  for (var i = 0; i < raw.length; i++) {
    final activity = activityFromJson(raw[i]);
    if (activity == null) continue;
    progressStats.customActivityIds[activity] = 'custom:$courseId:$i';
    activities.add(activity);
  }
  return Course(
    title: row['title'] as String,
    subtitle: (row['subtitle'] as String?) ?? '',
    icon: Icons.school_outlined,
    activities: activities,
  );
}

class TeacherCourseCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final String username;
  final Future<void> Function() onChanged;

  const TeacherCourseCard({
    super.key,
    required this.row,
    required this.username,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = courseFromRow(row);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
        title: Text(course.title),
        subtitle: Text(
          '${course.subtitle.isEmpty ? '' : '${course.subtitle}\n'}'
          '${course.activities.length} actividades · ${row['teacher_name'] ?? 'Profesor'}',
        ),
        isThreeLine: course.subtitle.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_right),
            if (row['can_manage'] == true)
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                onSelected: (value) async {
                  if (value == 'edit') {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherCourseEditorPage(
                          username: username,
                          course: row,
                        ),
                      ),
                    );
                    if (saved == true) await onChanged();
                  } else {
                    await _delete(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoursePage(course: course, courseIndex: -1),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar curso'),
        content: Text('¿Eliminar "${row['title']}"? No se puede deshacer.'),
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
    final deleted = await DBService.deleteTeacherCourse(
      requesterUsername: username,
      courseId: row['id'] as int,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Curso eliminado.' : 'No se pudo eliminar el curso.',
        ),
      ),
    );
    if (deleted) await onChanged();
  }
}

Future<List<Map<String, dynamic>>> loadManageableCourses(String username) async {
  final rows = await DBService.getTeacherCourses();
  return [
    for (final row in rows)
      {...row, 'can_manage': await DBService.canManageCourse(username, row)},
  ];
}

class TeacherCourseEditorPage extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? course;

  const TeacherCourseEditorPage({
    super.key,
    required this.username,
    this.course,
  });

  @override
  State<TeacherCourseEditorPage> createState() =>
      _TeacherCourseEditorPageState();
}

class _TeacherCourseEditorPageState extends State<TeacherCourseEditorPage> {
  late final _title =
      TextEditingController(text: widget.course?['title'] as String?);
  late final _subtitle =
      TextEditingController(text: widget.course?['subtitle'] as String?);
  late final List<Map<String, dynamic>> _activities =
      decodeActivities(widget.course?['activities'] as String?);
  bool _saving = false;

  bool get _isEditing => widget.course != null;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addActivity() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _typeLabels.entries)
              ListTile(
                leading: Icon(_typeIcons[entry.key]),
                title: Text(entry.value),
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ActivityEditorPage(type: type)),
    );
    if (result != null) setState(() => _activities.add(result));
  }

  Future<void> _editActivity(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditorPage(
          type: _activities[index]['type'] as String,
          initial: _activities[index],
        ),
      ),
    );
    if (result != null) setState(() => _activities[index] = result);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _message('Escribe un título para el curso.');
      return;
    }
    if (_activities.isEmpty) {
      _message('Agrega al menos una actividad.');
      return;
    }
    setState(() => _saving = true);
    try {
      final json = jsonEncode(_activities);
      if (_isEditing) {
        final ok = await DBService.updateTeacherCourse(
          requesterUsername: widget.username,
          courseId: widget.course!['id'] as int,
          title: _title.text,
          subtitle: _subtitle.text,
          activitiesJson: json,
        );
        if (!ok) throw StateError('Sin permiso');
      } else {
        await DBService.createTeacherCourse(
          teacherUsername: widget.username,
          title: _title.text,
          subtitle: _subtitle.text,
          activitiesJson: json,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _message('No se pudo guardar el curso.');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar curso' : 'Crear curso'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            enabled: !_saving,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Título del curso',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitle,
            enabled: !_saving,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Descripción corta',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text('Actividades', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in _activities.indexed)
            Card(
              key: ObjectKey(entry.$2),
              child: ListTile(
                leading: Icon(_typeIcons[entry.$2['type']]),
                title: Text(entry.$2['title'] as String? ?? 'Actividad'),
                subtitle: Text(_typeLabels[entry.$2['type']] ?? ''),
                onTap: _saving ? null : () => _editActivity(entry.$1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Subir',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: entry.$1 == 0
                          ? null
                          : () => setState(() {
                                final item = _activities.removeAt(entry.$1);
                                _activities.insert(entry.$1 - 1, item);
                              }),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          setState(() => _activities.removeAt(entry.$1)),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _saving ? null : _addActivity,
            icon: const Icon(Icons.add),
            label: const Text('Agregar actividad'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando...' : 'Guardar curso'),
          ),
        ],
      ),
    );
  }
}

class ActivityEditorPage extends StatefulWidget {
  final String type;
  final Map<String, dynamic>? initial;

  const ActivityEditorPage({super.key, required this.type, this.initial});

  @override
  State<ActivityEditorPage> createState() => _ActivityEditorPageState();
}

class _ActivityEditorPageState extends State<ActivityEditorPage> {
  int _nextKey = 0;
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?['title'] as String?);
  late String _instruction =
      widget.initial?['instruction'] as String? ?? '';
  late final List<Map<String, dynamic>> _items = _loadItems();

  String get _listKey => switch (widget.type) {
        'matching' => 'pairs',
        'memory' => 'cards',
        'sorting' => 'items',
        _ => 'questions',
      };

  List<Map<String, dynamic>> _loadItems() {
    final source = widget.initial?[_listKey] as List?;
    if (source == null) return [_newItem()];
    return [
      for (final e in source) _withKey(Map<String, dynamic>.from(e as Map)),
    ];
  }

  Map<String, dynamic> _withKey(Map<String, dynamic> item) {
    item['_k'] = _nextKey++;
    if (item['options'] is List) {
      final options = List<String>.from(item['options'] as List);
      while (options.length < 4) {
        options.add('');
      }
      item['options'] = options;
    }
    return item;
  }

  Map<String, dynamic> _newItem() => _withKey(switch (widget.type) {
        'quiz' => {
            'prompt': '',
            'options': ['', '', '', ''],
            'answer': 0,
          },
        'fillBlank' => {
            'sentence': '',
            'options': ['', '', '', ''],
            'answer': 0,
          },
        'matching' => {'term': '', 'definition': ''},
        'memory' => {'emoji': '', 'label': ''},
        _ => {'text': ''},
      });

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save() {
    final cleaned = <Map<String, dynamic>>[];
    for (final item in _items) {
      final copy = Map<String, dynamic>.from(item)..remove('_k');
      String value(String key) => (copy[key] as String? ?? '').trim();
      switch (widget.type) {
        case 'quiz':
        case 'fillBlank':
          final isQuiz = widget.type == 'quiz';
          final textKey = isQuiz ? 'prompt' : 'sentence';
          final raw = List<String>.from(copy['options'] as List);
          final correct = copy['answer'] as int;
          if (value(textKey).isEmpty) {
            _message('Todas las preguntas necesitan texto.');
            return;
          }
          if (!isQuiz && !value(textKey).contains('___')) {
            _message('Cada frase debe incluir ___ donde va el espacio.');
            return;
          }
          if (raw[correct].trim().isEmpty) {
            _message('Marca como correcta una opción con texto.');
            return;
          }
          final options = <String>[];
          var answer = 0;
          for (var i = 0; i < raw.length; i++) {
            if (raw[i].trim().isEmpty) continue;
            if (i == correct) answer = options.length;
            options.add(raw[i].trim());
          }
          if (options.length < 2) {
            _message('Cada pregunta necesita al menos 2 opciones.');
            return;
          }
          cleaned.add({textKey: value(textKey), 'options': options, 'answer': answer});
        case 'matching':
          if (value('term').isEmpty || value('definition').isEmpty) {
            _message('Completa todos los pares.');
            return;
          }
          cleaned.add({'term': value('term'), 'definition': value('definition')});
        case 'memory':
          if (value('emoji').isEmpty || value('label').isEmpty) {
            _message('Cada tarjeta necesita un emoji y un nombre.');
            return;
          }
          cleaned.add({'emoji': value('emoji'), 'label': value('label')});
        default:
          if (value('text').isEmpty) {
            _message('Completa todos los pasos.');
            return;
          }
          cleaned.add({'text': value('text')});
      }
    }
    final minimum = switch (widget.type) {
      'matching' || 'memory' || 'sorting' => 2,
      _ => 1,
    };
    if (_title.text.trim().isEmpty) {
      _message('Escribe un título para la actividad.');
      return;
    }
    if (cleaned.length < minimum) {
      _message('Agrega al menos $minimum elementos.');
      return;
    }
    Navigator.pop(context, {
      'type': widget.type,
      'title': _title.text.trim(),
      if (widget.type == 'sorting')
        'instruction': _instruction.trim().isEmpty
            ? 'Ordena los pasos.'
            : _instruction.trim(),
      _listKey: cleaned,
    });
  }

  Widget _field(
    Map<String, dynamic> item,
    String key,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: item[key] as String? ?? '',
        maxLines: maxLines,
        onChanged: (value) => item[key] = value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _options(Map<String, dynamic> item) {
    final options = item['options'] as List<String>;
    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          Row(
            children: [
              IconButton(
                tooltip: 'Marcar como correcta',
                icon: Icon(
                  item['answer'] == i
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item['answer'] == i ? Colors.greenAccent : null,
                ),
                onPressed: () => setState(() => item['answer'] = i),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    initialValue: options[i],
                    onChanged: (value) => options[i] = value,
                    decoration: InputDecoration(
                      labelText: 'Opción ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _itemCard(int index, Map<String, dynamic> item) {
    final fields = switch (widget.type) {
      'quiz' => [_field(item, 'prompt', 'Pregunta', maxLines: 2), _options(item)],
      'fillBlank' => [
          _field(item, 'sentence', 'Frase (usa ___ para el espacio)', maxLines: 2),
          _options(item),
        ],
      'matching' => [
          _field(item, 'term', 'Término'),
          _field(item, 'definition', 'Definición'),
        ],
      'memory' => [
          _field(item, 'emoji', 'Emoji (ej. 🌳)'),
          _field(item, 'label', 'Nombre'),
        ],
      _ => [_field(item, 'text', 'Paso ${index + 1}')],
    };
    return Card(
      key: ValueKey(item['_k']),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Elemento ${index + 1}')),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _items.length <= 1
                      ? null
                      : () => setState(() => _items.removeAt(index)),
                ),
              ],
            ),
            ...fields,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_typeLabels[widget.type] ?? 'Actividad'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Título de la actividad',
              border: OutlineInputBorder(),
            ),
          ),
          if (widget.type == 'sorting') ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _instruction,
              onChanged: (value) => _instruction = value,
              decoration: const InputDecoration(
                labelText: 'Instrucción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Escribe los pasos en el orden correcto; se mezclarán al jugar.'),
          ],
          const SizedBox(height: 12),
          for (final entry in _items.indexed) _itemCard(entry.$1, entry.$2),
          OutlinedButton.icon(
            onPressed: () => setState(() => _items.add(_newItem())),
            icon: const Icon(Icons.add),
            label: const Text('Agregar elemento'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Guardar actividad'),
          ),
        ],
      ),
    );
  }
}
