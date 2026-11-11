import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────
// Servicio de autenticación biométrica
// Maneja huella dactilar, reconocimiento facial y PIN
// ─────────────────────────────────────────────────────────────────

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();
  
  // Verificar si el dispositivo soporta autenticación biométrica
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      return canAuthenticateWithBiometrics;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  // Obtener lista de tipos de biometría disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> biometrics = await _auth.getAvailableBiometrics();
      return biometrics;
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Autenticar con biometría
  static Future<bool> authenticate({
    required String reason,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      print('Error during authentication: $e');
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
      print('Error during biometric-only authentication: $e');
      return false;
    }
  }

  // Guardar que el usuario quiere usar biometría al iniciar
  static Future<void> saveBiometricPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  // Obtener preferencia de biometría
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Verificar si el usuario está guardado para biometría
  static Future<bool> hasBiometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_user_saved') ?? false;
  }

  // Guardar que existe un usuario con biometría
  static Future<void> saveBiometricUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_user_saved', true);
    await prefs.setString('biometric_username', username);
  }

  // Obtener usuario guardado para biometría
  static Future<String?> getBiometricUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_username');
  }

  // Limpiar datos de biometría
  static Future<void> clearBiometricData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_enabled');
    await prefs.remove('biometric_user_saved');
    await prefs.remove('biometric_username');
  }

  // Obtener nombre descriptivo del tipo de biometría
  static String getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Reconocimiento Facial';
      case BiometricType.fingerprint:
        return 'Huella Dactilar';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometría Fuerte';
      case BiometricType.weak:
        return 'Biometría Débil';
    }
  }
}
