import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema elegido por el usuario (sistema, claro u oscuro), guardado en el
/// dispositivo. `KoruApp` lo escucha y cambia el tema al instante.
class PreferenciaTema extends ValueNotifier<ThemeMode> {
  PreferenciaTema._() : super(ThemeMode.dark);

  static final PreferenciaTema instancia = PreferenciaTema._();

  static const _clave = 'korulab_theme_mode';

  /// Lee la preferencia guardada. Sin preferencia, la app arranca en oscuro,
  /// que es como se veía siempre.
  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = _desdeTexto(prefs.getString(_clave));
    } catch (e) {
      debugPrint('No se pudo leer la preferencia de tema: $e');
    }
  }

  Future<void> cambiar(ThemeMode modo) async {
    value = modo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, modo.name);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia de tema: $e');
    }
  }

  static ThemeMode _desdeTexto(String? texto) => ThemeMode.values.firstWhere(
    (m) => m.name == texto,
    orElse: () => ThemeMode.dark,
  );
}
