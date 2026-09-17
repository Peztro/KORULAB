import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DBService {
  static const String dbName = 'korulab.db';
  static const String userTable = 'users';
  static const String discussionTable = 'discussion_spaces';
  static const String replyTable = 'discussion_replies';
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
      version: 2,
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
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await _createDiscussionTables(db);
  }

  static Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDiscussionTables(db);
    }
  }

  static Future<void> _createDiscussionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $discussionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        author TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $replyTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discussion_id INTEGER NOT NULL,
        author TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (discussion_id) REFERENCES $discussionTable (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<List<Map<String, dynamic>>> getDiscussionSpaces() async {
    final db = await database;
    final spaces = await db.query(discussionTable, orderBy: 'created_at DESC');
    final result = <Map<String, dynamic>>[];
    for (final space in spaces) {
      final replies = await db.query(
        replyTable,
        where: 'discussion_id = ?',
        whereArgs: [space['id']],
        orderBy: 'created_at ASC',
      );
      result.add({...space, 'replies': replies});
    }
    return result;
  }

  static Future<int> createDiscussionSpace({
    required String title,
    required String description,
    required String author,
  }) async {
    final db = await database;
    return db.insert(discussionTable, {
      'title': title,
      'description': description,
      'author': author,
    });
  }

  static Future<int> addDiscussionReply({
    required int discussionId,
    required String author,
    required String message,
  }) async {
    final db = await database;
    return db.insert(replyTable, {
      'discussion_id': discussionId,
      'author': author,
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
      
      // Verificar si el usuario ya existe
      final existing = await db.query(
        userTable,
        where: 'username = ? OR email = ?',
        whereArgs: [username, email],
      );

      if (existing.isNotEmpty) {
        return false; // Usuario ya existe
      }

      // Hashear la contraseña
      final hashedPassword = _hashPassword(password);

      await db.insert(
        userTable,
        {
          'username': username,
          'email': email,
          'password': hashedPassword,
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
        where: 'username = ?',
        whereArgs: [username],
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
        where: 'username = ?',
        whereArgs: [username],
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
        where: 'username = ?',
        whereArgs: [username],
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
        where: 'username = ?',
        whereArgs: [username],
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
      await prefs.setString(_usernameKey, username);
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

