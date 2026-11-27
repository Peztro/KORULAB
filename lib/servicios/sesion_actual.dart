import 'package:flutter/foundation.dart';

import '../modelos/perfil.dart';

/// Perfil del usuario con sesión iniciada, compartido por toda la app.
///
/// Cualquier pantalla puede escucharlo (con [ListenableBuilder] o
/// [addListener]) y se redibuja cuando el perfil cambia, por ejemplo al
/// guardar una foto nueva en la página de perfil. Así ya no hace falta
/// pasar callbacks entre pantallas para mantener los datos sincronizados.
///
/// `DBService` lo actualiza al cargar el perfil propio y lo limpia al cerrar
/// o cambiar de sesión.
class SesionActual extends ChangeNotifier {
  SesionActual._();

  /// Constructor para tests: una sesión independiente de la global.
  @visibleForTesting
  factory SesionActual.paraTests() => SesionActual._();

  static final SesionActual instancia = SesionActual._();

  Perfil? _perfil;

  Perfil? get perfil => _perfil;
  bool get haySesion => _perfil != null;
  String? get username => _perfil?.username;

  void actualizar(Perfil perfil) {
    _perfil = perfil;
    notifyListeners();
  }

  void limpiar() {
    if (_perfil == null) return;
    _perfil = null;
    notifyListeners();
  }
}
