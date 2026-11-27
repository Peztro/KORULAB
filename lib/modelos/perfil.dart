import 'imagen_perfil.dart';

/// Roles de usuario tal como se guardan en la columna `profiles.role`.
abstract final class Rol {
  static const admin = 'admin';
  static const profesor = 'teacher';
  static const estudiante = 'student';
}

DateTime? _fecha(Object? valor) =>
    valor is String ? DateTime.tryParse(valor)?.toLocal() : null;

String _texto(Object? valor) => valor is String ? valor : '';

int _entero(Object? valor) => switch (valor) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v) ?? 0,
  _ => 0,
};

/// Perfil de un usuario (tabla `profiles`).
class Perfil {
  const Perfil({
    required this.username,
    this.id,
    this.displayName = '',
    this.email,
    this.age,
    this.birthYear,
    this.location = '',
    this.occupation = '',
    this.bio = '',
    this.learningGoal = '',
    this.gender,
    this.foto,
    this.banner,
    this.role = Rol.estudiante,
    this.handleChangedAt,
    this.createdAt,
  });

  factory Perfil.desdeFila(Map<String, dynamic> fila) {
    return Perfil(
      id: fila['id'] as String?,
      username: _texto(fila['username']),
      displayName: _texto(fila['display_name']),
      email: fila['email'] as String?,
      age: fila['age'] as int?,
      birthYear: fila['birth_year'] as int?,
      location: _texto(fila['location']),
      occupation: _texto(fila['occupation']),
      bio: _texto(fila['bio']),
      learningGoal: _texto(fila['learning_goal']),
      gender: fila['gender'] as String?,
      foto: ImagenPerfil.desde(fila['profile_photo']),
      banner: ImagenPerfil.desde(fila['banner']),
      role: fila['role'] as String? ?? Rol.estudiante,
      handleChangedAt: _fecha(fila['handle_changed_at']),
      createdAt: _fecha(fila['created_at']),
    );
  }

  final String? id;
  final String username;
  final String displayName;
  final String? email;
  final int? age;
  final int? birthYear;
  final String location;
  final String occupation;
  final String bio;
  final String learningGoal;
  final String? gender;
  final ImagenPerfil? foto;
  final ImagenPerfil? banner;
  final String role;
  final DateTime? handleChangedAt;
  final DateTime? createdAt;

  bool get esAdmin => role == Rol.admin;
  bool get esProfesor => role == Rol.profesor;

  /// Nombre visible, o el @usuario si no tiene nombre.
  String get nombreVisible =>
      displayName.trim().isNotEmpty ? displayName.trim() : username;
}

/// Perfil que cualquier usuario puede ver (RPC `get_public_profile`).
class PerfilPublico extends Perfil {
  const PerfilPublico({
    required super.username,
    super.displayName,
    super.location,
    super.occupation,
    super.bio,
    super.learningGoal,
    super.foto,
    super.banner,
    super.role,
    super.createdAt,
    this.leccionesCompletadas = 0,
    this.rachaDiaria = 0,
    this.publicaciones = 0,
    this.respuestas = 0,
  });

  factory PerfilPublico.desdeFila(Map<String, dynamic> fila) {
    final base = Perfil.desdeFila(fila);
    return PerfilPublico(
      username: base.username,
      displayName: base.displayName,
      location: base.location,
      occupation: base.occupation,
      bio: base.bio,
      learningGoal: base.learningGoal,
      foto: base.foto,
      banner: base.banner,
      role: base.role,
      createdAt: base.createdAt,
      leccionesCompletadas: _entero(fila['completed_lessons']),
      rachaDiaria: _entero(fila['daily_streak']),
      publicaciones: _entero(fila['posts_count']),
      respuestas: _entero(fila['replies_count']),
    );
  }

  final int leccionesCompletadas;
  final int rachaDiaria;
  final int publicaciones;
  final int respuestas;
}

/// Cuenta guardada en el dispositivo para cambiar de sesión rápido.
class CuentaGuardada {
  const CuentaGuardada({
    required this.id,
    required this.username,
    this.displayName = '',
    this.foto,
    this.esActual = false,
  });

  final String id;
  final String username;
  final String displayName;
  final ImagenPerfil? foto;
  final bool esActual;

  String get nombreVisible =>
      displayName.trim().isNotEmpty ? displayName.trim() : '@$username';
}
