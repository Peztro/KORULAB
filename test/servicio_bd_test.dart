import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicio_bd.dart';

void main() {
  group('DBService.normalizeUsername', () {
    test('quita espacios y @ iniciales y pasa a minúsculas', () {
      expect(DBService.normalizeUsername('  @@Ana.Eco '), 'ana.eco');
      expect(DBService.normalizeUsername('pepe'), 'pepe');
    });

    test('solo quita las @ del principio', () {
      expect(DBService.normalizeUsername('a@b'), 'a@b');
    });
  });

  group('DBService.isValidUsername', () {
    test('acepta 3 a 20 letras, números, punto o guion bajo', () {
      expect(DBService.isValidUsername('ana'), isTrue);
      expect(DBService.isValidUsername('@Ana_Eco.2026'), isTrue);
      expect(DBService.isValidUsername('a' * 20), isTrue);
    });

    test('rechaza nombres cortos, largos o con otros caracteres', () {
      expect(DBService.isValidUsername('ab'), isFalse);
      expect(DBService.isValidUsername('a' * 21), isFalse);
      expect(DBService.isValidUsername('ana eco'), isFalse);
      expect(DBService.isValidUsername('ana-eco'), isFalse);
      expect(DBService.isValidUsername('añá'), isFalse);
    });
  });

  test('roleLabel traduce los roles', () {
    expect(DBService.roleLabel(DBService.roleAdmin), 'Administrador');
    expect(DBService.roleLabel(DBService.roleTeacher), 'Profesor');
    expect(DBService.roleLabel(DBService.roleStudent), 'Estudiante');
    expect(DBService.roleLabel(null), 'Estudiante');
  });
}
