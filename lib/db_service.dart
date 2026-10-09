import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso a datos de Korulab sobre Supabase (Auth + Postgres).
/// El esquema y las políticas de seguridad están en supabase/schema.sql.
class DBService {
  static const String supabaseUrl = 'https://rnsxdjmywwweqkrxasjg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_y2fjGIPrGY1pWWg_e9Ochg_39qsjK9t';

  static const String userTable = 'profiles';
  static const String discussionTable = 'discussion_spaces';
  static const String replyTable = 'discussion_replies';
  static const String supportRequestTable = 'support_requests';
  static const String teacherLessonTable = 'teacher_lessons';
  static const String teacherCourseTable = 'teacher_courses';
  static const String ecoJournalEntryTable = 'eco_journal_entries';
  static const String ecoJournalPhotoTable = 'eco_journal_photos';
  static const String progressTable = 'user_progress';
  static const String adminUsername = 'koruadm';
  static const String adminDisplayName = 'KORUADMIN';
  static const String koruColUsername = 'korucol';
  static const String koruColDisplayName = 'KoruCol';
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get _db => Supabase.instance.client;

  // ─────────────────────────────────────────────
  //  Utilidades
  // ─────────────────────────────────────────────

  static String normalizeUsername(String username) {
    return username.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();
  }

  static bool isValidUsername(String username) {
    return RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(normalizeUsername(username));
  }

  static Uint8List? _decodePhoto(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  // Los timestamps llegan en UTC; la app los espera en hora local.
  static String? _localTimestamp(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal().toIso8601String();
  }

  static Map<String, dynamic> _withLocalDate(Map<String, dynamic> row) {
    final copy = Map<String, dynamic>.from(row);
    if (copy['created_at'] != null) {
      copy['created_at'] = _localTimestamp(copy['created_at']);
    }
    return copy;
  }

  static List<Map<String, dynamic>> _rows(dynamic data) {
    return [
      for (final row in (data as List)) Map<String, dynamic>.from(row as Map),
    ];
  }

  static Map<String, dynamic> _profileRow(Map<String, dynamic> raw) {
    final row = Map<String, dynamic>.from(raw);
    final private = row.remove('profile_private');
    if (private is Map) {
      row['email'] = private['email'];
    } else if (private is List && private.isNotEmpty) {
      row['email'] = (private.first as Map)['email'];
    }
    row['profile_photo'] = _decodePhoto(row['profile_photo']);
    row['is_admin'] = row['role'] == roleAdmin ? 1 : 0;
    if (row['created_at'] != null) {
      row['created_at'] = _localTimestamp(row['created_at']);
    }
    return row;
  }

  static Future<Map<String, String>> _displayNames(
    Iterable<String> usernames,
  ) async {
    final names = usernames.toSet().toList();
    if (names.isEmpty) return {};
    final rows = _rows(
      await _db
          .from('public_profiles')
          .select('username, display_name')
          .inFilter('username', names),
    );
    return {
      for (final row in rows)
        row['username'] as String: (row['display_name'] as String?) ?? '',
    };
  }

  // ─────────────────────────────────────────────
  //  Perfiles y roles
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserProfile(String username) async {
    final handle = normalizeUsername(username);
    final rows = _rows(
      await _db
          .from(userTable)
          .select('*, profile_private(email)')
          .eq('username', handle)
          .limit(1),
    );
    if (rows.isEmpty) return null;
    final profile = _profileRow(rows.first);
    if (profile['email'] == null &&
        handle == _cachedUsername) {
      profile['email'] = _db.auth.currentUser?.email;
    }
    return profile;
  }

  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      return await getUserProfile(username);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  static Future<bool> usernameExists(String username) async {
    final available = await _db.rpc(
      'username_available',
      params: {'p_username': normalizeUsername(username)},
    );
    return available != true;
  }

  // El correo se valida en el registro; Supabase rechaza los duplicados.
  static Future<bool> emailExists(String email) async => false;

  static String? _cachedUsername;
  static final Map<String, ({String role, DateTime at})> _roleCache = {};

  static Future<String> _roleOf(String username) async {
    final handle = normalizeUsername(username);
    final cached = _roleCache[handle];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(seconds: 20)) {
      return cached.role;
    }
    final rows = _rows(
      await _db.from(userTable).select('role').eq('username', handle).limit(1),
    );
    final role = rows.isEmpty ? roleStudent : rows.first['role'] as String;
    _roleCache[handle] = (role: role, at: DateTime.now());
    return role;
  }

  static Future<bool> isAdmin(String username) async =>
      await _roleOf(username) == roleAdmin;

  static Future<bool> isTeacher(String username) async =>
      await _roleOf(username) == roleTeacher;

  static Future<bool> canModerateDiscussions(String username) async {
    final role = await _roleOf(username);
    return role == roleAdmin || role == roleTeacher;
  }

  static Future<bool> canTeachLessons(String username) =>
      canModerateDiscussions(username);

  static Future<String> getUserRole(String username) => _roleOf(username);

  static String roleLabel(String? role) {
    return switch (role) {
      roleAdmin => 'Administrador',
      roleTeacher => 'Profesor',
      _ => 'Estudiante',
    };
  }

  static Future<String?> saveUserProfile({
    required String username,
    required String newUsername,
    required String displayName,
    required int? age,
    required int? birthYear,
    required String location,
    required String occupation,
    required String bio,
    required String learningGoal,
    required Uint8List? profilePhoto,
  }) async {
    final oldUsername = normalizeUsername(username);
    final normalizedNewUsername = normalizeUsername(newUsername);
    if (!isValidUsername(normalizedNewUsername)) return 'invalid';
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return 'not_found';

    if (oldUsername != normalizedNewUsername) {
      final result = await _db.rpc(
        'change_username',
        params: {'new_name': normalizedNewUsername},
      );
      if (result != null) return result as String;
      await _migrateUserPreferences(oldUsername, normalizedNewUsername);
      _cachedUsername = normalizedNewUsername;
      _roleCache.remove(oldUsername);
    }

    await _db.from(userTable).update({
      'display_name': displayName,
      'age': age,
      'birth_year': birthYear,
      'location': location,
      'occupation': occupation,
      'bio': bio,
      'learning_goal': learningGoal,
      'profile_photo': profilePhoto == null ? null : base64Encode(profilePhoto),
    }).eq('id', userId);
    return null;
  }

  static Future<List<Map<String, dynamic>>> getUsersForRoleManagement(
    String adminUsername,
  ) async {
    if (!await isAdmin(adminUsername)) {
      throw StateError('Solo los administradores pueden asignar roles.');
    }
    final rows = _rows(
      await _db
          .from(userTable)
          .select('username, display_name, role, profile_private(email)')
          .order('username'),
    );
    final users = rows.map(_profileRow).toList();
    users.sort((a, b) {
      String key(Map<String, dynamic> u) =>
          (((u['display_name'] as String?)?.trim().isNotEmpty ?? false)
                  ? u['display_name'] as String
                  : u['username'] as String)
              .toLowerCase();
      return key(a).compareTo(key(b));
    });
    return users;
  }

  static Future<bool> updateUserRole({
    required String adminUsername,
    required String targetUsername,
    required String role,
  }) async {
    if (!await isAdmin(adminUsername) ||
        ![roleAdmin, roleTeacher, roleStudent].contains(role)) {
      return false;
    }
    final normalizedAdmin = normalizeUsername(adminUsername);
    final normalizedTarget = normalizeUsername(targetUsername);
    if (normalizedTarget == normalizedAdmin ||
        normalizedTarget == adminUsername ||
        normalizedTarget == koruColUsername) {
      return false;
    }
    final updated = _rows(
      await _db
          .from(userTable)
          .update({'role': role})
          .eq('username', normalizedTarget)
          .select('id'),
    );
    _roleCache.remove(normalizedTarget);
    return updated.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  //  Progreso (sincronizado con la nube)
  // ─────────────────────────────────────────────

  static const List<String> _progressPrefixes = [
    'korulab_course_progress_',
    'korulab_eko_stars_',
    'korulab_correct_answers_',
    'korulab_total_answers_',
    'korulab_completed_lessons_',
    'korulab_daily_streak_',
    'korulab_hint_credits_',
    'korulab_streak_protectors_',
    'korulab_star_multipliers_',
    'korulab_second_chances_',
    'korulab_last_lesson_',
    'korulab_eco_challenges_',
  ];

  static Future<void> _migrateUserPreferences(
    String oldUsername,
    String newUsername,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    for (final prefix in _progressPrefixes) {
      final oldKey = '$prefix$oldUsername';
      final value = preferences.get(oldKey);
      if (value == null) continue;
      final newKey = '$prefix$newUsername';
      if (value is String) {
        await preferences.setString(newKey, value);
      } else if (value is int) {
        await preferences.setInt(newKey, value);
      } else if (value is List<String>) {
        await preferences.setStringList(newKey, value);
      }
      await preferences.remove(oldKey);
    }
  }

  /// Sube el progreso local del usuario a la nube.
  static Future<void> pushProgress(String username) async {
    try {
      final handle = normalizeUsername(username);
      final preferences = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final prefix in _progressPrefixes) {
        final value = preferences.get('$prefix$handle');
        if (value != null) data[prefix] = value;
      }
      await _db.from(progressTable).upsert({
        'username': handle,
        'data': data,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('No se pudo sincronizar el progreso: $e');
    }
  }

  /// Descarga el progreso de la nube; si no hay, sube el local.
  static Future<void> pullProgress(String username) async {
    try {
      final handle = normalizeUsername(username);
      final rows = _rows(
        await _db
            .from(progressTable)
            .select('data')
            .eq('username', handle)
            .limit(1),
      );
      if (rows.isEmpty) {
        await pushProgress(handle);
        return;
      }
      final data = Map<String, dynamic>.from(rows.first['data'] as Map);
      final preferences = await SharedPreferences.getInstance();
      for (final prefix in _progressPrefixes) {
        final value = data[prefix];
        final key = '$prefix$handle';
        if (value is String) {
          await preferences.setString(key, value);
        } else if (value is int) {
          await preferences.setInt(key, value);
        } else if (value is List) {
          await preferences.setStringList(key, value.cast<String>());
        } else {
          await preferences.remove(key);
        }
      }
    } catch (e) {
      print('No se pudo descargar el progreso: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentLearningProfiles(
    String requesterUsername,
  ) async {
    if (!await canTeachLessons(requesterUsername)) {
      throw StateError('Solo profesores y administradores pueden ver estudiantes.');
    }
    final users = _rows(
      await _db
          .from(userTable)
          .select(
            'username, display_name, age, birth_year, location, occupation, '
            'bio, learning_goal, profile_photo, role, profile_private(email)',
          )
          .eq('role', roleStudent),
    ).map(_profileRow).toList();
    users.sort((a, b) {
      String key(Map<String, dynamic> u) =>
          (((u['display_name'] as String?)?.trim().isNotEmpty ?? false)
                  ? u['display_name'] as String
                  : u['username'] as String)
              .toLowerCase();
      return key(a).compareTo(key(b));
    });

    final progressRows = users.isEmpty
        ? <Map<String, dynamic>>[]
        : _rows(
            await _db
                .from(progressTable)
                .select('username, data')
                .inFilter('username', [
                  for (final u in users) u['username'] as String,
                ]),
          );
    final progress = {
      for (final row in progressRows)
        row['username'] as String: Map<String, dynamic>.from(row['data'] as Map),
    };

    return users.map((user) {
      final data = progress[user['username'] as String] ?? const {};
      final correct = data['korulab_correct_answers_'] as int? ?? 0;
      final total = data['korulab_total_answers_'] as int? ?? 0;
      final completedIds =
          ((data['korulab_course_progress_'] as List?) ?? const [])
              .cast<String>();
      return {
        ...user,
        'completed_lessons': completedIds.length,
        'completed_ids': completedIds,
        'daily_streak': data['korulab_daily_streak_'] as int? ?? 0,
        'accuracy_percent': total == 0 ? 0 : correct * 100 ~/ total,
      };
    }).toList();
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
      getStudentCommunityActivity(
    String requesterUsername,
    String studentUsername,
  ) async {
    if (!await canTeachLessons(requesterUsername)) {
      throw StateError('Solo profesores y administradores pueden ver estudiantes.');
    }
    final handle = normalizeUsername(studentUsername);
    final posts = _rows(
      await _db
          .from(discussionTable)
          .select('id, title, description, created_at')
          .eq('author_handle', handle)
          .order('created_at', ascending: false),
    ).map(_withLocalDate).toList();
    final replies = _rows(
      await _db
          .from(replyTable)
          .select('id, message, created_at, discussion_id')
          .eq('author_handle', handle)
          .order('created_at', ascending: false),
    );
    final titles = <int, String>{};
    final discussionIds = {for (final r in replies) r['discussion_id'] as int};
    if (discussionIds.isNotEmpty) {
      for (final row in _rows(
        await _db
            .from(discussionTable)
            .select('id, title')
            .inFilter('id', discussionIds.toList()),
      )) {
        titles[row['id'] as int] = row['title'] as String;
      }
    }
    return {
      'posts': posts,
      'replies': [
        for (final reply in replies)
          {
            ..._withLocalDate(reply),
            'discussion_title': titles[reply['discussion_id'] as int],
          },
      ],
    };
  }

  // ─────────────────────────────────────────────
  //  Diario ecológico
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getEcoJournalEntries({
    required String username,
    required String challengeId,
  }) async {
    final entries = _rows(
      await _db
          .from(ecoJournalEntryTable)
          .select()
          .eq('username', normalizeUsername(username))
          .eq('challenge_id', challengeId)
          .order('created_at', ascending: false)
          .order('id', ascending: false),
    );
    if (entries.isEmpty) return entries;

    final photos = _rows(
      await _db
          .from(ecoJournalPhotoTable)
          .select('entry_id, photo')
          .inFilter('entry_id', [for (final e in entries) e['id'] as int])
          .order('id'),
    );
    final photosByEntry = <int, List<Uint8List>>{};
    for (final photo in photos) {
      final bytes = _decodePhoto(photo['photo']);
      if (bytes == null) continue;
      photosByEntry.putIfAbsent(photo['entry_id'] as int, () => []).add(bytes);
    }
    return [
      for (final entry in entries)
        {
          ..._withLocalDate(entry),
          'photos': photosByEntry[entry['id'] as int] ?? <Uint8List>[],
        },
    ];
  }

  static Future<void> addEcoJournalEntry({
    required String username,
    required String challengeId,
    required String note,
    required List<Uint8List> photos,
  }) async {
    final inserted = await _db
        .from(ecoJournalEntryTable)
        .insert({
          'username': normalizeUsername(username),
          'challenge_id': challengeId,
          'note': note.trim(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();
    final entryId = inserted['id'] as int;
    if (photos.isEmpty) return;
    try {
      await _db.from(ecoJournalPhotoTable).insert([
        for (final photo in photos)
          {'entry_id': entryId, 'photo': base64Encode(photo)},
      ]);
    } catch (_) {
      await _db.from(ecoJournalEntryTable).delete().eq('id', entryId);
      rethrow;
    }
  }

  static Future<void> deleteEcoJournalEntry({
    required int entryId,
    required String username,
  }) async {
    await _db
        .from(ecoJournalEntryTable)
        .delete()
        .eq('id', entryId)
        .eq('username', normalizeUsername(username));
  }

  // ─────────────────────────────────────────────
  //  Cursos de profesores
  // ─────────────────────────────────────────────

  static Future<bool> _canManageCourseId(String username, int courseId) async {
    final rows = _rows(
      await _db.from(teacherCourseTable).select().eq('id', courseId).limit(1),
    );
    return rows.isNotEmpty && await canManageCourse(username, rows.first);
  }

  static Future<bool> canManageCourse(
    String username,
    Map<String, dynamic> course,
  ) => canManageLesson(username, course);

  static Future<int> createTeacherCourse({
    required String teacherUsername,
    required String title,
    required String subtitle,
    required String activitiesJson,
  }) async {
    if (!await isTeacher(teacherUsername)) {
      throw StateError('Solo los profesores pueden crear cursos.');
    }
    final row = await _db
        .from(teacherCourseTable)
        .insert({
          'teacher_username': normalizeUsername(teacherUsername),
          'title': title.trim(),
          'subtitle': subtitle.trim(),
          'activities': activitiesJson,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> getTeacherCourses() async {
    final rows = _rows(
      await _db
          .from(teacherCourseTable)
          .select()
          .order('created_at', ascending: true),
    );
    final names = await _displayNames([
      for (final r in rows) r['teacher_username'] as String,
    ]);
    return [
      for (final row in rows)
        {
          ..._withLocalDate(row),
          'teacher_name': names[row['teacher_username']],
        },
    ];
  }

  static Future<bool> updateTeacherCourse({
    required String requesterUsername,
    required int courseId,
    required String title,
    required String subtitle,
    required String activitiesJson,
  }) async {
    if (!await _canManageCourseId(requesterUsername, courseId)) return false;
    final updated = _rows(
      await _db
          .from(teacherCourseTable)
          .update({
            'title': title.trim(),
            'subtitle': subtitle.trim(),
            'activities': activitiesJson,
          })
          .eq('id', courseId)
          .select('id'),
    );
    return updated.isNotEmpty;
  }

  static Future<bool> deleteTeacherCourse({
    required String requesterUsername,
    required int courseId,
  }) async {
    if (!await _canManageCourseId(requesterUsername, courseId)) return false;
    final deleted = _rows(
      await _db.from(teacherCourseTable).delete().eq('id', courseId).select('id'),
    );
    return deleted.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  //  Lecciones de profesores
  // ─────────────────────────────────────────────

  static const String lessonDestinationKoruclases = 'koruclases';
  static const String lessonDestinationKorucol = 'korucol';

  static String _validDestination(String destination) =>
      destination == lessonDestinationKorucol
          ? lessonDestinationKorucol
          : lessonDestinationKoruclases;

  static Future<int> createTeacherLesson({
    required String teacherUsername,
    required String title,
    required String summary,
    required String content,
    String destination = lessonDestinationKoruclases,
  }) async {
    if (!await isTeacher(teacherUsername)) {
      throw StateError('Solo los profesores pueden crear lecciones.');
    }
    final row = await _db
        .from(teacherLessonTable)
        .insert({
          'teacher_username': normalizeUsername(teacherUsername),
          'title': title.trim(),
          'summary': summary.trim(),
          'content': content.trim(),
          'destination': _validDestination(destination),
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> getTeacherLessons({
    String? destination,
  }) async {
    var query = _db.from(teacherLessonTable).select();
    if (destination != null) {
      query = query.eq('destination', _validDestination(destination));
    }
    final rows = _rows(await query.order('created_at', ascending: false));
    final names = await _displayNames([
      for (final r in rows) r['teacher_username'] as String,
    ]);
    return [
      for (final row in rows)
        {
          ..._withLocalDate(row),
          'teacher_name': names[row['teacher_username']],
        },
    ];
  }

  // Los administradores gestionan todo; los profesores solo lo suyo.
  static Future<bool> canManageLesson(
    String username,
    Map<String, dynamic> lesson,
  ) async {
    final role = await _roleOf(username);
    if (role == roleAdmin) return true;
    return role == roleTeacher &&
        normalizeUsername(lesson['teacher_username'] as String) ==
            normalizeUsername(username);
  }

  static Future<bool> _canManageLessonId(String username, int lessonId) async {
    final rows = _rows(
      await _db.from(teacherLessonTable).select().eq('id', lessonId).limit(1),
    );
    return rows.isNotEmpty && await canManageLesson(username, rows.first);
  }

  static Future<bool> updateTeacherLesson({
    required String requesterUsername,
    required int lessonId,
    required String title,
    required String summary,
    required String content,
    required String destination,
  }) async {
    if (!await _canManageLessonId(requesterUsername, lessonId)) return false;
    final updated = _rows(
      await _db
          .from(teacherLessonTable)
          .update({
            'title': title.trim(),
            'summary': summary.trim(),
            'content': content.trim(),
            'destination': _validDestination(destination),
          })
          .eq('id', lessonId)
          .select('id'),
    );
    return updated.isNotEmpty;
  }

  static Future<bool> deleteTeacherLesson({
    required String requesterUsername,
    required int lessonId,
  }) async {
    if (!await _canManageLessonId(requesterUsername, lessonId)) return false;
    final deleted = _rows(
      await _db.from(teacherLessonTable).delete().eq('id', lessonId).select('id'),
    );
    return deleted.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  //  PQRS
  // ─────────────────────────────────────────────

  static Future<int> createSupportRequest({
    required String username,
    required String displayName,
    required String email,
    required String category,
    required String subject,
    required String message,
  }) async {
    final handle = normalizeUsername(username);
    final row = await _db
        .from(supportRequestTable)
        .insert({
          'username': handle,
          'display_name': displayName,
          'author_handle': handle,
          'email': email,
          'category': category,
          'subject': subject,
          'message': message,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> getSupportRequests(
    String adminUsername,
  ) async {
    if (!await isAdmin(adminUsername)) {
      throw StateError('Solo la cuenta administradora puede revisar las PQRS.');
    }
    return _rows(
      await _db
          .from(supportRequestTable)
          .select()
          .order('created_at', ascending: false),
    ).map(_withLocalDate).toList();
  }

  static Future<void> updateSupportRequestStatus({
    required String adminUsername,
    required int requestId,
    required String status,
  }) async {
    if (!await isAdmin(adminUsername)) {
      throw StateError('Solo la cuenta administradora puede revisar las PQRS.');
    }
    if (!['Pendiente', 'En revisión', 'Resuelta'].contains(status)) {
      throw ArgumentError.value(status, 'status', 'Estado no válido');
    }
    await _db
        .from(supportRequestTable)
        .update({'status': status})
        .eq('id', requestId);
  }

  // ─────────────────────────────────────────────
  //  Comunidad
  // ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDiscussionSpaces() async {
    final spaces = _rows(
      await _db
          .from(discussionTable)
          .select()
          .order('created_at', ascending: false),
    );
    final replies = _rows(
      await _db.from(replyTable).select().order('created_at', ascending: true),
    );

    final handles = {
      for (final s in spaces) (s['author_handle'] as String? ?? '').toLowerCase(),
      for (final r in replies) (r['author_handle'] as String? ?? '').toLowerCase(),
    }..remove('');
    final profiles = <String, Map<String, dynamic>>{};
    if (handles.isNotEmpty) {
      for (final p in _rows(
        await _db
            .from('public_profiles')
            .select('username, profile_photo, role')
            .inFilter('username', handles.toList()),
      )) {
        profiles[p['username'] as String] = p;
      }
    }

    Map<String, dynamic> withAuthor(Map<String, dynamic> row) {
      final handle = (row['author_handle'] as String? ?? '').toLowerCase();
      final profile = profiles[handle];
      final isSystem = handle == koruColUsername || handle == adminUsername;
      return {
        ..._withLocalDate(row),
        'author_photo': _decodePhoto(profile?['profile_photo']),
        'author_role':
            profile?['role'] ?? (isSystem ? roleAdmin : roleStudent),
      };
    }

    final repliesBySpace = <int, List<Map<String, dynamic>>>{};
    for (final reply in replies) {
      repliesBySpace
          .putIfAbsent(reply['discussion_id'] as int, () => [])
          .add(withAuthor(reply));
    }
    return [
      for (final space in spaces)
        {
          ...withAuthor(space),
          'replies': repliesBySpace[space['id'] as int] ?? <Map<String, dynamic>>[],
        },
    ];
  }

  static Future<int> createDiscussionSpace({
    required String title,
    required String description,
    required String author,
    String authorHandle = '',
  }) async {
    final row = await _db
        .from(discussionTable)
        .insert({
          'title': title,
          'description': description,
          'author': author,
          'author_handle': authorHandle,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  static Future<bool> _canEditAuthored(
    String table,
    int id,
    String requesterUsername,
  ) async {
    final rows = _rows(
      await _db.from(table).select('author_handle').eq('id', id).limit(1),
    );
    if (rows.isEmpty) return false;
    if (await canModerateDiscussions(requesterUsername)) return true;
    return normalizeUsername(rows.first['author_handle'] as String? ?? '') ==
        normalizeUsername(requesterUsername);
  }

  static Future<bool> updateDiscussionSpace({
    required int discussionId,
    required String requesterUsername,
    required String title,
    required String description,
  }) async {
    if (!await _canEditAuthored(discussionTable, discussionId, requesterUsername)) {
      return false;
    }
    final updated = _rows(
      await _db
          .from(discussionTable)
          .update({'title': title.trim(), 'description': description.trim()})
          .eq('id', discussionId)
          .select('id'),
    );
    return updated.isNotEmpty;
  }

  static Future<bool> deleteDiscussionSpace({
    required int discussionId,
    required String requesterUsername,
  }) async {
    if (!await _canEditAuthored(discussionTable, discussionId, requesterUsername)) {
      return false;
    }
    final deleted = _rows(
      await _db.from(discussionTable).delete().eq('id', discussionId).select('id'),
    );
    return deleted.isNotEmpty;
  }

  static Future<bool> updateDiscussionReply({
    required int replyId,
    required String requesterUsername,
    required String message,
  }) async {
    if (!await _canEditAuthored(replyTable, replyId, requesterUsername)) {
      return false;
    }
    final updated = _rows(
      await _db
          .from(replyTable)
          .update({'message': message.trim()})
          .eq('id', replyId)
          .select('id'),
    );
    return updated.isNotEmpty;
  }

  static Future<bool> deleteDiscussionReply({
    required int replyId,
    required String requesterUsername,
  }) async {
    if (!await _canEditAuthored(replyTable, replyId, requesterUsername)) {
      return false;
    }
    final deleted = _rows(
      await _db.from(replyTable).delete().eq('id', replyId).select('id'),
    );
    return deleted.isNotEmpty;
  }

  static Future<int> addDiscussionReply({
    required int discussionId,
    required String author,
    required String message,
    String authorHandle = '',
  }) async {
    final row = await _db
        .from(replyTable)
        .insert({
          'discussion_id': discussionId,
          'author': author,
          'author_handle': authorHandle,
          'message': message,
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  // ─────────────────────────────────────────────
  //  Autenticación
  // ─────────────────────────────────────────────

  static Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = normalizeUsername(username);
    if (!isValidUsername(normalizedUsername) ||
        normalizedUsername == adminUsername ||
        normalizedUsername == koruColUsername) {
      return false;
    }
    try {
      final response = await _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': normalizedUsername},
      );
      // Con "Confirm email" activo, un correo repetido devuelve identities vacío.
      if (response.user?.identities?.isEmpty ?? false) {
        throw StateError('El email ya está registrado');
      }
      if (response.session != null) await _db.auth.signOut();
      return response.user != null;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        throw StateError('El email ya está registrado');
      }
      throw StateError(e.message);
    }
  }

  static Future<bool> validateLogin({
    required String username,
    required String password,
  }) async {
    final handle = normalizeUsername(username);
    final email = await _db.rpc('login_email', params: {'p_username': handle});
    if (email is! String || email.isEmpty) return false;
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
      _cachedUsername = handle;
      return true;
    } on AuthException {
      return false;
    }
  }

  static Future<bool> changeOwnPassword({
    required String username,
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _db.auth.currentUser?.email;
    if (email == null) return false;
    try {
      await _db.auth.signInWithPassword(email: email, password: currentPassword);
    } on AuthException {
      return false;
    }
    await _db.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }

  // Genera una contraseña temporal mediante la Edge Function (solo profesores).
  static Future<String> resetStudentPassword(
    String teacherUsername,
    String studentUsername,
  ) async {
    if (!await isTeacher(teacherUsername)) {
      throw StateError('Solo los profesores pueden restablecer contraseñas.');
    }
    try {
      final response = await _db.functions.invoke(
        'reset-student-password',
        body: {'username': normalizeUsername(studentUsername)},
      );
      final data = response.data;
      if (data is Map && data['password'] is String) {
        return data['password'] as String;
      }
      throw StateError('Respuesta inesperada del servidor.');
    } on FunctionException catch (e) {
      final details = e.details;
      throw StateError(
        details is Map && details['error'] != null
            ? details['error'].toString()
            : 'No se pudo contactar la función de restablecimiento.',
      );
    }
  }

  // ─────────────────────────────────────────────
  //  Sesión
  // ─────────────────────────────────────────────

  static Future<bool> saveSession(String username) async {
    _cachedUsername = normalizeUsername(username);
    return true;
  }

  static Future<String?> getSessionUsername() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    if (_cachedUsername != null) return _cachedUsername;
    try {
      final rows = _rows(
        await _db.from(userTable).select('username').eq('id', user.id).limit(1),
      );
      _cachedUsername =
          rows.isEmpty ? null : rows.first['username'] as String;
    } catch (e) {
      print('Error obteniendo sesión: $e');
    }
    return _cachedUsername;
  }

  static Future<bool> hasActiveSession() async =>
      _db.auth.currentSession != null;

  static Future<bool> logout() async {
    try {
      await _db.auth.signOut();
      _cachedUsername = null;
      _roleCache.clear();
      return true;
    } catch (e) {
      print('Error cerrando sesión: $e');
      return false;
    }
  }
}
