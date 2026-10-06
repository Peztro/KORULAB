import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DBService {
  static const String dbName = 'korulab.db';
  static const String userTable = 'users';
  static const String discussionTable = 'discussion_spaces';
  static const String replyTable = 'discussion_replies';
  static const String supportRequestTable = 'support_requests';
  static const String teacherLessonTable = 'teacher_lessons';
  static const String adminUsername = 'koruadm';
  static const String adminDisplayName = 'KORUADMIN';
  static const String defaultAdminPassword = 'koru123';
  static const String koruColUsername = 'korucol';
  static const String koruColDisplayName = 'KoruCol';
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        display_name TEXT,
        age INTEGER,
        birth_year INTEGER,
        location TEXT,
        occupation TEXT,
        bio TEXT,
        learning_goal TEXT,
        profile_photo BLOB,
        handle_changed_at TEXT,
        is_admin INTEGER NOT NULL DEFAULT 0,
        role TEXT NOT NULL DEFAULT 'student',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await _createDiscussionTables(db);
    await _createSupportRequestTable(db);
    await _createTeacherLessonTable(db);
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDiscussionTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $userTable ADD COLUMN display_name TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN age INTEGER');
      await db.execute('ALTER TABLE $userTable ADD COLUMN birth_year INTEGER');
      await db.execute('ALTER TABLE $userTable ADD COLUMN location TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN occupation TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN bio TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN learning_goal TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN profile_photo BLOB');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $userTable ADD COLUMN handle_changed_at TEXT');
      if (oldVersion >= 2) {
        await db.execute(
          "ALTER TABLE $discussionTable ADD COLUMN author_handle TEXT NOT NULL DEFAULT ''",
        );
        await db.execute(
          "ALTER TABLE $replyTable ADD COLUMN author_handle TEXT NOT NULL DEFAULT ''",
        );
      }
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE $userTable ADD COLUMN is_admin INTEGER NOT NULL DEFAULT 0',
      );
      await _createSupportRequestTable(db);

      final users = await db.query(
        userTable,
        columns: ['username', 'display_name'],
      );
      for (final user in users) {
        final username = user['username'] as String;
        final displayName = (user['display_name'] as String?)?.trim();
        final authorName = displayName == null || displayName.isEmpty
            ? username
            : displayName;
        await db.update(
          discussionTable,
          {'author': authorName, 'author_handle': normalizeUsername(username)},
          where: 'author = ? AND author_handle = ?',
          whereArgs: [username, ''],
        );
        await db.update(
          replyTable,
          {'author': authorName, 'author_handle': normalizeUsername(username)},
          where: 'author = ? AND author_handle = ?',
          whereArgs: [username, ''],
        );
      }
    }
    if (oldVersion < 6) {
      const defaultDiscussionTitles = [
        'Ideas para cuidar el planeta',
        'Preguntas sobre las lecciones',
      ];
      await db.update(
        discussionTable,
        {'author': koruColDisplayName, 'author_handle': koruColUsername},
        where: 'title IN (?, ?) AND author = ?',
        whereArgs: [...defaultDiscussionTitles, 'Korulab'],
      );
      await db.rawUpdate(
        'UPDATE $replyTable SET author = ?, author_handle = ? WHERE author = ? AND discussion_id IN (SELECT id FROM $discussionTable WHERE title IN (?, ?) AND author = ?)',
        [
          koruColDisplayName,
          koruColUsername,
          'Korulab',
          ...defaultDiscussionTitles,
          koruColDisplayName,
        ],
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        "ALTER TABLE $userTable ADD COLUMN role TEXT NOT NULL DEFAULT 'student'",
      );
      await db.execute(
        "UPDATE $userTable SET role = 'admin' WHERE is_admin = 1",
      );
    }
    if (oldVersion < 8) {
      await _createTeacherLessonTable(db);
    }
  }

  static String normalizeUsername(String username) {
    return username.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();
  }

  static bool isValidUsername(String username) {
    return RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(normalizeUsername(username));
  }

  static Future<Map<String, dynamic>?> getUserProfile(String username) async {
    final db = await database;
    final rows = await db.query(
      userTable,
      columns: [
        'username',
        'display_name',
        'age',
        'birth_year',
        'location',
        'occupation',
        'bio',
        'learning_goal',
        'profile_photo',
        'handle_changed_at',
        'is_admin',
        'role',
        'email',
        'created_at',
      ],
      where: 'LOWER(username) = ?',
      whereArgs: [normalizeUsername(username)],
    );
    return rows.isEmpty ? null : rows.first;
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
    final db = await database;
    final oldUsername = normalizeUsername(username);
    final normalizedNewUsername = normalizeUsername(newUsername);
    if (!isValidUsername(normalizedNewUsername)) return 'invalid';

    try {
      final result = await db.transaction<String?>((transaction) async {
        final rows = await transaction.query(
          userTable,
          columns: ['username', 'created_at', 'handle_changed_at', 'is_admin'],
          where: 'LOWER(username) = ?',
          whereArgs: [oldUsername],
          limit: 1,
        );
        if (rows.isEmpty) return 'not_found';

        final storedUsername = rows.first['username'] as String;
        final isHandleChanging = storedUsername != normalizedNewUsername;
        if (isHandleChanging) {
          if ((rows.first['is_admin'] as int? ?? 0) == 1) {
            return 'admin_handle_locked';
          }
          final duplicate = await transaction.query(
            userTable,
            columns: ['id'],
            where: 'LOWER(username) = ? AND username != ?',
            whereArgs: [normalizedNewUsername, storedUsername],
            limit: 1,
          );
          if (duplicate.isNotEmpty) return 'taken';

          final changedAt = DateTime.tryParse(
                rows.first['handle_changed_at'] as String? ?? '',
              ) ??
              DateTime.tryParse(rows.first['created_at'] as String? ?? '');
          if (changedAt != null &&
              DateTime.now().isBefore(changedAt.add(const Duration(days: 60)))) {
            return 'cooldown';
          }
        }

        final values = <String, Object?>{
          'display_name': displayName,
          'age': age,
          'birth_year': birthYear,
          'location': location,
          'occupation': occupation,
          'bio': bio,
          'learning_goal': learningGoal,
          'profile_photo': profilePhoto,
        };
        if (isHandleChanging) {
          values['username'] = normalizedNewUsername;
          values['handle_changed_at'] = DateTime.now().toIso8601String();
        }
        await transaction.update(
          userTable,
          values,
          where: 'username = ?',
          whereArgs: [storedUsername],
        );

        if (isHandleChanging) {
          final displayAuthor = displayName.trim().isEmpty
              ? normalizedNewUsername
              : displayName.trim();
          await transaction.rawUpdate(
            'UPDATE $discussionTable SET author = CASE WHEN author = ? THEN ? ELSE author END, author_handle = ? WHERE author = ? OR author_handle = ?',
            [storedUsername, displayAuthor, normalizedNewUsername, storedUsername, oldUsername],
          );
          await transaction.rawUpdate(
            'UPDATE $replyTable SET author = CASE WHEN author = ? THEN ? ELSE author END, author_handle = ? WHERE author = ? OR author_handle = ?',
            [storedUsername, displayAuthor, normalizedNewUsername, storedUsername, oldUsername],
          );
        }
        return null;
      });

      if (result != null) return result;
      if (oldUsername != normalizedNewUsername) {
        await _migrateUserPreferences(oldUsername, normalizedNewUsername);
      }
      return null;
    } catch (error) {
      if (error.toString().toLowerCase().contains('unique')) return 'taken';
      rethrow;
    }
  }

  static Future<void> _migrateUserPreferences(
    String oldUsername,
    String newUsername,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    const userDataPrefixes = [
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
      'korulab_eco_challenges_',
    ];
    for (final prefix in userDataPrefixes) {
      final oldKey = '$prefix$oldUsername';
      final newKey = '$prefix$newUsername';
      final value = preferences.get(oldKey);
      if (value != null) {
        if (value is String) {
          await preferences.setString(newKey, value);
        } else if (value is int) {
          await preferences.setInt(newKey, value);
        } else if (value is bool) {
          await preferences.setBool(newKey, value);
        } else if (value is double) {
          await preferences.setDouble(newKey, value);
        } else if (value is List<String>) {
          await preferences.setStringList(newKey, value);
        }
        await preferences.remove(oldKey);
      }
    }
    if (preferences.getString(_usernameKey) == oldUsername) {
      await preferences.setString(_usernameKey, newUsername);
    }
  }

  static Future<void> _createDiscussionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $discussionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        author TEXT NOT NULL,
        author_handle TEXT NOT NULL DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $replyTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discussion_id INTEGER NOT NULL,
        author TEXT NOT NULL,
        author_handle TEXT NOT NULL DEFAULT '',
        message TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (discussion_id) REFERENCES $discussionTable (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createSupportRequestTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $supportRequestTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        display_name TEXT NOT NULL,
        author_handle TEXT NOT NULL,
        email TEXT NOT NULL,
        category TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pendiente',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<void> _createTeacherLessonTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $teacherLessonTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_username TEXT NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  static Future<void> ensureAdminAccount() async {
    final db = await database;
    final existing = await db.query(
      userTable,
      where: 'LOWER(username) = ?',
      whereArgs: [adminUsername],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final wasAdmin = (existing.first['is_admin'] as int? ?? 0) == 1;
      final values = <String, Object?>{
        'is_admin': 1,
        'role': roleAdmin,
        'display_name': adminDisplayName,
      };
      if (!wasAdmin) values['password'] = _hashPassword(defaultAdminPassword);
      await db.update(userTable, values,
          where: 'id = ?', whereArgs: [existing.first['id']]);
      return;
    }

    await db.insert(userTable, {
      'username': adminUsername,
      'email': 'koruadm@korulab.local',
      'password': _hashPassword(defaultAdminPassword),
      'display_name': adminDisplayName,
      'is_admin': 1,
      'role': roleAdmin,
    });
  }

  static Future<void> ensureKoruColAccount() async {
    final db = await database;
    final existing = await db.query(
      userTable,
      where: 'LOWER(username) = ?',
      whereArgs: [koruColUsername],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final wasAdmin = (existing.first['is_admin'] as int? ?? 0) == 1;
      final values = <String, Object?>{
        'is_admin': 1,
        'role': roleAdmin,
        'display_name': koruColDisplayName,
      };
      if (!wasAdmin) values['password'] = _hashPassword(defaultAdminPassword);
      await db.update(userTable, values,
          where: 'id = ?', whereArgs: [existing.first['id']]);
      return;
    }

    await db.insert(userTable, {
      'username': koruColUsername,
      'email': 'korucol@korulab.local',
      'password': _hashPassword(defaultAdminPassword),
      'display_name': koruColDisplayName,
      'is_admin': 1,
      'role': roleAdmin,
    });
  }

  static Future<bool> isAdmin(String username) async {
    final user = await getUser(username);
    return user?['role'] == roleAdmin ||
        (user?['is_admin'] as int? ?? 0) == 1;
  }

  static Future<bool> isTeacher(String username) async {
    final user = await getUser(username);
    return user?['role'] == roleTeacher;
  }

  static Future<bool> canModerateDiscussions(String username) async {
    final user = await getUser(username);
    final role = user?['role'];
    return role == roleAdmin ||
        role == roleTeacher ||
        (user?['is_admin'] as int? ?? 0) == 1;
  }

  static Future<bool> canTeachLessons(String username) async {
    return await isAdmin(username) || await isTeacher(username);
  }

  static Future<String> getUserRole(String username) async {
    final user = await getUser(username);
    final role = user?['role'] as String?;
    if ([roleAdmin, roleTeacher, roleStudent].contains(role)) return role!;
    if ((user?['is_admin'] as int? ?? 0) == 1) return roleAdmin;
    return roleStudent;
  }

  static String roleLabel(String? role) {
    return switch (role) {
      roleAdmin => 'Administrador',
      roleTeacher => 'Profesor',
      _ => 'Estudiante',
    };
  }

  static Future<List<Map<String, dynamic>>> getUsersForRoleManagement(
    String adminUsername,
  ) async {
    if (!await isAdmin(adminUsername)) {
      throw StateError('Solo los administradores pueden asignar roles.');
    }
    final db = await database;
    return db.query(
      userTable,
      columns: ['username', 'display_name', 'email', 'role', 'is_admin'],
      orderBy: 'display_name COLLATE NOCASE, username COLLATE NOCASE',
    );
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
        normalizedTarget == 'koruadm' ||
        normalizedTarget == 'korucol') {
      return false;
    }
    final db = await database;
    final count = await db.update(
      userTable,
      {'role': role, 'is_admin': role == roleAdmin ? 1 : 0},
      where: 'LOWER(username) = ?',
      whereArgs: [normalizedTarget],
    );
    return count > 0;
  }

  static Future<List<Map<String, dynamic>>> getStudentLearningProfiles(
    String requesterUsername,
  ) async {
    if (!await canTeachLessons(requesterUsername)) {
      throw StateError('Solo profesores y administradores pueden ver estudiantes.');
    }
    final db = await database;
    final users = await db.query(
      userTable,
      columns: [
        'username',
        'display_name',
        'email',
        'age',
        'birth_year',
        'location',
        'occupation',
        'bio',
        'learning_goal',
        'profile_photo',
        'role',
      ],
      where: 'role = ?',
      whereArgs: [roleStudent],
      orderBy: 'display_name COLLATE NOCASE, username COLLATE NOCASE',
    );
    final preferences = await SharedPreferences.getInstance();
    return users.map((user) {
      final username = normalizeUsername(user['username'] as String);
      final correct = preferences.getInt('korulab_correct_answers_$username') ?? 0;
      final total = preferences.getInt('korulab_total_answers_$username') ?? 0;
      final completed = preferences
              .getStringList('korulab_course_progress_$username')
              ?.length ??
          0;
      return {
        ...user,
        'completed_lessons': completed,
        'daily_streak':
            preferences.getInt('korulab_daily_streak_$username') ?? 0,
        'accuracy_percent': total == 0 ? 0 : correct * 100 ~/ total,
      };
    }).toList();
  }

  static Future<int> createTeacherLesson({
    required String teacherUsername,
    required String title,
    required String summary,
    required String content,
  }) async {
    if (!await canTeachLessons(teacherUsername)) {
      throw StateError('Solo profesores y administradores pueden crear lecciones.');
    }
    final db = await database;
    return db.insert(teacherLessonTable, {
      'teacher_username': normalizeUsername(teacherUsername),
      'title': title.trim(),
      'summary': summary.trim(),
      'content': content.trim(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTeacherLessons() async {
    final db = await database;
    return db.rawQuery('''
      SELECT lessons.*, users.display_name AS teacher_name
      FROM $teacherLessonTable AS lessons
      LEFT JOIN $userTable AS users
        ON LOWER(users.username) = LOWER(lessons.teacher_username)
      ORDER BY lessons.created_at DESC
    ''');
  }

  static Future<int> createSupportRequest({
    required String username,
    required String displayName,
    required String email,
    required String category,
    required String subject,
    required String message,
  }) async {
    final db = await database;
    final normalizedUsername = normalizeUsername(username);
    return db.insert(supportRequestTable, {
      'username': normalizedUsername,
      'display_name': displayName,
      'author_handle': normalizedUsername,
      'email': email,
      'category': category,
      'subject': subject,
      'message': message,
    });
  }

  static Future<List<Map<String, dynamic>>> getSupportRequests(
    String adminUsername,
  ) async {
    if (!await isAdmin(adminUsername)) {
      throw StateError('Solo la cuenta administradora puede revisar las PQRS.');
    }
    final db = await database;
    return db.query(supportRequestTable, orderBy: 'created_at DESC');
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
    final db = await database;
    await db.update(
      supportRequestTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  static Future<List<Map<String, dynamic>>> getDiscussionSpaces() async {
    final db = await database;
    final spaces = await db.rawQuery('''
          SELECT spaces.*, users.profile_photo AS author_photo,
             users.role AS author_role
      FROM $discussionTable AS spaces
      LEFT JOIN $userTable AS users
        ON LOWER(users.username) = LOWER(spaces.author_handle)
      ORDER BY spaces.created_at DESC
    ''');
    final result = <Map<String, dynamic>>[];
    for (final space in spaces) {
      final replies = await db.rawQuery('''
        SELECT replies.*, users.profile_photo AS author_photo,
             users.role AS author_role
        FROM $replyTable AS replies
        LEFT JOIN $userTable AS users
          ON LOWER(users.username) = LOWER(replies.author_handle)
        WHERE replies.discussion_id = ?
        ORDER BY replies.created_at ASC
      ''', [space['id']]);
      result.add({...space, 'replies': replies});
    }
    return result;
  }

  static Future<int> createDiscussionSpace({
    required String title,
    required String description,
    required String author,
    String authorHandle = '',
  }) async {
    final db = await database;
    return db.insert(discussionTable, {
      'title': title,
      'description': description,
      'author': author,
      'author_handle': authorHandle,
    });
  }

  static Future<bool> updateDiscussionSpace({
    required int discussionId,
    required String requesterUsername,
    required String title,
    required String description,
  }) async {
    final db = await database;
    final canModerate = await canModerateDiscussions(requesterUsername);
    final rows = await db.query(
      discussionTable,
      columns: ['author_handle'],
      where: 'id = ?',
      whereArgs: [discussionId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final authorHandle = normalizeUsername(
      rows.first['author_handle'] as String? ?? '',
    );
    if (!canModerate &&
        authorHandle != normalizeUsername(requesterUsername)) {
      return false;
    }
    await db.update(
      discussionTable,
      {'title': title.trim(), 'description': description.trim()},
      where: 'id = ?',
      whereArgs: [discussionId],
    );
    return true;
  }

  static Future<bool> deleteDiscussionSpace({
    required int discussionId,
    required String requesterUsername,
  }) async {
    final db = await database;
    final canModerate = await canModerateDiscussions(requesterUsername);
    return db.transaction((transaction) async {
      final rows = await transaction.query(
        discussionTable,
        columns: ['author_handle'],
        where: 'id = ?',
        whereArgs: [discussionId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final authorHandle = normalizeUsername(
        rows.first['author_handle'] as String? ?? '',
      );
      if (!canModerate &&
          authorHandle != normalizeUsername(requesterUsername)) {
        return false;
      }
      await transaction.delete(
        replyTable,
        where: 'discussion_id = ?',
        whereArgs: [discussionId],
      );
      await transaction.delete(
        discussionTable,
        where: 'id = ?',
        whereArgs: [discussionId],
      );
      return true;
    });
  }

  static Future<bool> updateDiscussionReply({
    required int replyId,
    required String requesterUsername,
    required String message,
  }) async {
    final db = await database;
    final canModerate = await canModerateDiscussions(requesterUsername);
    final rows = await db.query(
      replyTable,
      columns: ['author_handle'],
      where: 'id = ?',
      whereArgs: [replyId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final authorHandle = normalizeUsername(
      rows.first['author_handle'] as String? ?? '',
    );
    if (!canModerate &&
        authorHandle != normalizeUsername(requesterUsername)) {
      return false;
    }
    await db.update(
      replyTable,
      {'message': message.trim()},
      where: 'id = ?',
      whereArgs: [replyId],
    );
    return true;
  }

  static Future<bool> deleteDiscussionReply({
    required int replyId,
    required String requesterUsername,
  }) async {
    final db = await database;
    final canModerate = await canModerateDiscussions(requesterUsername);
    final rows = await db.query(
      replyTable,
      columns: ['author_handle'],
      where: 'id = ?',
      whereArgs: [replyId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final authorHandle = normalizeUsername(
      rows.first['author_handle'] as String? ?? '',
    );
    if (!canModerate &&
        authorHandle != normalizeUsername(requesterUsername)) {
      return false;
    }
    await db.delete(replyTable, where: 'id = ?', whereArgs: [replyId]);
    return true;
  }

  static Future<int> addDiscussionReply({
    required int discussionId,
    required String author,
    required String message,
    String authorHandle = '',
  }) async {
    final db = await database;
    return db.insert(replyTable, {
      'discussion_id': discussionId,
      'author': author,
      'author_handle': authorHandle,
      'message': message,
    });
  }

  // Registrar nuevo usuario
  static Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      final normalizedUsername = normalizeUsername(username);
        if (!isValidUsername(normalizedUsername) ||
          normalizedUsername == adminUsername ||
          normalizedUsername == koruColUsername) {
        return false;
      }
      
      // Verificar si el usuario ya existe
      final existing = await db.query(
        userTable,
        where: 'LOWER(username) = ? OR LOWER(email) = ?',
        whereArgs: [normalizedUsername, email.trim().toLowerCase()],
      );

      if (existing.isNotEmpty) {
        return false; // Usuario ya existe
      }

      // Hashear la contraseña
      final hashedPassword = _hashPassword(password);

      await db.insert(
        userTable,
        {
          'username': normalizedUsername,
          'email': email,
          'password': hashedPassword,
          'role': roleStudent,
        },
      );

      return true;
    } catch (e) {
      print('Error registrando usuario: $e');
      return false;
    }
  }

  // Validar login
  static Future<bool> validateLogin({
    required String username,
    required String password,
  }) async {
    try {
      final db = await database;
      final result = await db.query(
        userTable,
        where: 'LOWER(username) = ?',
        whereArgs: [normalizeUsername(username)],
      );

      if (result.isEmpty) {
        return false; // Usuario no encontrado
      }

      final storedPassword = result.first['password'] as String;
      final hashedPassword = _hashPassword(password);

      return storedPassword == hashedPassword;
    } catch (e) {
      print('Error validando login: $e');
      return false;
    }
  }

  // Obtener usuario por nombre
  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        userTable,
        where: 'LOWER(username) = ?',
        whereArgs: [normalizeUsername(username)],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  // Verificar si username existe
  static Future<bool> usernameExists(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        userTable,
        where: 'LOWER(username) = ?',
        whereArgs: [normalizeUsername(username)],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando username: $e');
      return false;
    }
  }

  // Verificar si email existe
  static Future<bool> emailExists(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        userTable,
        where: 'email = ?',
        whereArgs: [email],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error verificando email: $e');
      return false;
    }
  }

  // Hashear contraseña con SHA-256
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Eliminar usuario (opcional)
  static Future<bool> deleteUser(String username) async {
    try {
      final db = await database;
      await db.delete(
        userTable,
        where: 'LOWER(username) = ?',
        whereArgs: [normalizeUsername(username)],
      );
      return true;
    } catch (e) {
      print('Error eliminando usuario: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  GESTIÓN DE SESIONES
  // ─────────────────────────────────────────────

  static const String _sessionKey = 'korulab_session';
  static const String _usernameKey = 'korulab_username';

  // Guardar sesión iniciada
  static Future<bool> saveSession(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, 'active');
      await prefs.setString(_usernameKey, normalizeUsername(username));
      return true;
    } catch (e) {
      print('Error guardando sesión: $e');
      return false;
    }
  }

  // Obtener usuario de sesión guardada
  static Future<String?> getSessionUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString(_sessionKey);
      
      if (session == 'active') {
        return prefs.getString(_usernameKey);
      }
      return null;
    } catch (e) {
      print('Error obteniendo sesión: $e');
      return null;
    }
  }

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString(_sessionKey);
      return session == 'active';
    } catch (e) {
      print('Error verificando sesión: $e');
      return false;
    }
  }

  // Cerrar sesión (logout)
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_usernameKey);
      return true;
    } catch (e) {
      print('Error cerrando sesión: $e');
      return false;
    }
  }

  // Cerrar base de datos
  static Future<void> closeDB() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

