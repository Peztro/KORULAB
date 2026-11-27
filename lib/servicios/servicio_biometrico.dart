import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────
// Servicio de autenticación biométrica
// Maneja huella dactilar, reconocimiento facial y PIN
// Biometría es POR USUARIO (no global)
// ─────────────────────────────────────────────────────────────────

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // Verificar si el dispositivo soporta autenticación biométrica
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      return canAuthenticateWithBiometrics;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  // Obtener lista de tipos de biometría disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> biometrics = await _auth
          .getAvailableBiometrics();
      return biometrics;
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  // Si el usuario ya se verificó desde que abrió la app, no se le vuelve a
  // pedir la huella al entrar al inicio.
  static bool _verificadoEnEstaApertura = false;
  static Future<bool>? _enCurso;

  /// True si ya hubo una verificación biométrica correcta desde que se abrió
  /// la app (y no se ha cerrado sesión).
  static bool get verificadoEnEstaApertura => _verificadoEnEstaApertura;

  /// El usuario acaba de demostrar su identidad de otra forma (contraseña).
  static void marcarVerificado() => _verificadoEnEstaApertura = true;

  /// Olvida la verificación; se llama al cerrar sesión.
  static void olvidarVerificacion() => _verificadoEnEstaApertura = false;

  // Autenticar con biometría. Si ya hay una petición en pantalla, se reutiliza
  // en lugar de abrir otra encima.
  static Future<bool> authenticate({required String reason}) {
    return _enCurso ??= _authenticate(
      reason,
    ).whenComplete(() => _enCurso = null);
  }

  static Future<bool> _authenticate(String reason) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (didAuthenticate) _verificadoEnEstaApertura = true;
      return didAuthenticate;
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return false;
    }
  }

  // Autenticar con solo biometría (sin PIN de respaldo)
  static Future<bool> authenticateBiometricOnly({
    required String reason,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Error during biometric-only authentication: $e');
      return false;
    }
  }

  // MÉTODOS POR USUARIO

  // Guardar que el usuario quiere usar biometría (POR USUARIO)
  static Future<void> saveBiometricPreference(
    bool enabled,
    String username,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'biometric_enabled_$username';
    await prefs.setBool(key, enabled);
  }

  // Obtener preferencia de biometría (POR USUARIO)
  static Future<bool> isBiometricEnabled(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'biometric_enabled_$username';
    return prefs.getBool(key) ?? false;
  }

  // Verificar si el usuario está guardado para biometría (POR USUARIO)
  static Future<bool> hasBiometricUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'biometric_user_saved_$username';
    return prefs.getBool(key) ?? false;
  }

  // Guardar que existe un usuario con biometría (POR USUARIO)
  static Future<void> saveBiometricUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'biometric_user_saved_$username';
    await prefs.setBool(key, true);
  }

  // Limpiar datos de biometría (POR USUARIO)
  static Future<void> clearBiometricData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_enabled_$username');
    await prefs.remove('biometric_user_saved_$username');
  }

  // MÉTODOS GLOBALES (para compatibilidad con login page)

  // Obtener nombre descriptivo del tipo de biometría
  static String getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Reconocimiento Facial';
      case BiometricType.fingerprint:
        return 'Huella Dactilar';
      case BiometricType.iris:
        return 'Iris';
      // Android a veces solo informa la "clase" de seguridad del sensor,
      // no si es huella o rostro.
      case BiometricType.strong:
      case BiometricType.weak:
        return 'Huella o rostro';
    }
  }

  /// Nombre en minúsculas para usar dentro de frases
  /// ("Entrar con tu huella", "Usa tu reconocimiento facial").
  ///
  /// Android suele informar solo "fuerte" o "débil" (la clase de seguridad
  /// del sensor), que no le dice nada al usuario; en ese caso se usa un
  /// nombre genérico.
  static String nombreAmigable(List<BiometricType> tipos) {
    if (tipos.contains(BiometricType.face) &&
        !tipos.contains(BiometricType.fingerprint)) {
      return 'reconocimiento facial';
    }
    if (tipos.contains(BiometricType.fingerprint) &&
        !tipos.contains(BiometricType.face)) {
      return 'huella';
    }
    return 'huella o rostro';
  }
}
