import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicios/servicio_biometrico.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  group('BiometricAuthService.nombreAmigable', () {
    test('solo huella', () {
      expect(
        BiometricAuthService.nombreAmigable([BiometricType.fingerprint]),
        'huella',
      );
    });

    test('solo rostro', () {
      expect(
        BiometricAuthService.nombreAmigable([BiometricType.face]),
        'reconocimiento facial',
      );
    });

    test('Android solo informa "fuerte" o "débil": nombre genérico', () {
      expect(
        BiometricAuthService.nombreAmigable([
          BiometricType.strong,
          BiometricType.weak,
        ]),
        'huella o rostro',
      );
    });

    test('huella y rostro a la vez: nombre genérico', () {
      expect(
        BiometricAuthService.nombreAmigable([
          BiometricType.fingerprint,
          BiometricType.face,
        ]),
        'huella o rostro',
      );
    });
  });
}
