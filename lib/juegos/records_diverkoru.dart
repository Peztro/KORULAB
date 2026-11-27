import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/sesion_actual.dart';
import 'datos_juegos.dart';

/// Mejores marcas de DiverKoru, guardadas en el teléfono por usuario.
///
/// Un 0 significa "sin récord". En la sopa de letras el récord es el menor
/// tiempo; en los demás juegos, el mayor número.
abstract final class RecordsDiverKoru {
  static String _clave(JuegoDiverKoru juego, String? usuario) {
    // "_v2": Clasifica y Trivia cambiaron de reglas, así que sus récords
    // empiezan de cero. Salva las gotas conserva el que ya tenía.
    final version = juego == JuegoDiverKoru.gotas ? '' : '_v2';
    return 'diverkoru_record_${juego.clave}${version}_${usuario ?? 'invitado'}';
  }

  static Future<int> leer(JuegoDiverKoru juego, {String? usuario}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(
          _clave(juego, usuario ?? SesionActual.instancia.username),
        ) ??
        0;
  }

  static Future<Map<JuegoDiverKoru, int>> leerTodos({String? usuario}) async {
    return {
      for (final juego in JuegoDiverKoru.values)
        juego: await leer(juego, usuario: usuario),
    };
  }

  /// Guarda [valor] si mejora el récord. Devuelve true si es récord nuevo.
  static Future<bool> registrar(
    JuegoDiverKoru juego,
    int valor, {
    String? usuario,
  }) async {
    final anterior = await leer(juego, usuario: usuario);
    if (!esMejorRecord(juego, valor, anterior)) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _clave(juego, usuario ?? SesionActual.instancia.username),
      valor,
    );
    return true;
  }
}
