import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../juegos/datos_juegos.dart';
import '../modelos/imagen_perfil.dart';

/// Un puesto del ranking global de DiverKoru.
@immutable
class PuestoRanking {
  const PuestoRanking({
    required this.posicion,
    required this.username,
    required this.nombre,
    required this.foto,
    required this.puntos,
    required this.soyYo,
  });

  final int posicion;
  final String username;
  final String nombre;
  final ImagenPerfil? foto;
  final int puntos;
  final bool soyYo;

  factory PuestoRanking.desdeMapa(Map<String, dynamic> m) {
    final username = (m['username'] as String?) ?? '';
    final nombre = (m['display_name'] as String?)?.trim();
    return PuestoRanking(
      posicion: (m['posicion'] as num).toInt(),
      username: username,
      nombre: nombre == null || nombre.isEmpty ? username : nombre,
      foto: ImagenPerfil.desde(m['profile_photo']),
      puntos: (m['puntos'] as num).toInt(),
      soyYo: m['soy_yo'] == true,
    );
  }
}

/// Ranking global de DiverKoru en Supabase
/// (supabase/migrations/20261130_diverkoru_ranking_todos.sql).
abstract final class ServicioRanking {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Sube una marca; el servidor solo la guarda si mejora tu récord.
  static Future<void> registrar(JuegoDiverKoru juego, int puntos) async {
    if (puntos <= 0) return;
    await _db.rpc(
      'registrar_record_diverkoru',
      params: {'p_juego': juego.clave, 'p_puntos': puntos},
    );
  }

  /// Los mejores estudiantes del juego, más tu puesto si no estás entre
  /// ellos (al final de la lista).
  static Future<List<PuestoRanking>> ranking(
    JuegoDiverKoru juego, {
    int limite = 10,
  }) async {
    final filas = await _db.rpc(
      'ranking_diverkoru',
      params: {'p_juego': juego.clave, 'p_limite': limite},
    );
    return [
      for (final fila in (filas as List).cast<Map<String, dynamic>>())
        PuestoRanking.desdeMapa(fila),
    ];
  }
}
