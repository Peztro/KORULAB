import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/modelos/perfil.dart';
import 'package:korulab/servicios/sesion_actual.dart';

void main() {
  group('Perfil.desdeFila', () {
    test('lee todas las columnas de profiles', () {
      final perfil = Perfil.desdeFila({
        'id': 'abc',
        'username': 'ana.eco',
        'display_name': 'Ana',
        'email': 'ana@example.com',
        'age': 20,
        'birth_year': 2006,
        'location': 'Bogotá',
        'occupation': 'Estudiante',
        'bio': 'Hola',
        'learning_goal': 'Reciclar',
        'gender': 'female',
        'profile_photo':
            'https://x.supabase.co/storage/v1/object/public/profile-images/abc/avatar',
        'banner': null,
        'role': 'teacher',
        'handle_changed_at': '2026-01-02T03:04:05Z',
        'created_at': '2025-12-01T00:00:00Z',
      });

      expect(perfil.id, 'abc');
      expect(perfil.username, 'ana.eco');
      expect(perfil.displayName, 'Ana');
      expect(perfil.email, 'ana@example.com');
      expect(perfil.age, 20);
      expect(perfil.birthYear, 2006);
      expect(perfil.location, 'Bogotá');
      expect(perfil.gender, 'female');
      expect(perfil.foto?.url, contains('/profile-images/abc/avatar'));
      expect(perfil.banner, isNull);
      expect(perfil.esProfesor, isTrue);
      expect(perfil.esAdmin, isFalse);
      expect(
        perfil.handleChangedAt!.isAtSameMomentAs(
          DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
        isTrue,
      );
      expect(perfil.createdAt!.isUtc, isFalse, reason: 'se pasa a hora local');
    });

    test('usa valores por defecto si faltan columnas', () {
      final perfil = Perfil.desdeFila({'username': 'pepe'});
      expect(perfil.displayName, '');
      expect(perfil.bio, '');
      expect(perfil.role, Rol.estudiante);
      expect(perfil.foto, isNull);
      expect(perfil.createdAt, isNull);
    });

    test('nombreVisible cae en el @usuario si no hay nombre', () {
      expect(const Perfil(username: 'pepe').nombreVisible, 'pepe');
      expect(
        const Perfil(username: 'pepe', displayName: '  Pepe  ').nombreVisible,
        'Pepe',
      );
    });
  });

  test('PerfilPublico lee las estadísticas, aunque vengan como texto', () {
    final perfil = PerfilPublico.desdeFila({
      'username': 'ana',
      'role': 'admin',
      'completed_lessons': 7,
      'daily_streak': 3,
      'posts_count': '2',
      'replies_count': 5.0,
    });
    expect(perfil.esAdmin, isTrue);
    expect(perfil.leccionesCompletadas, 7);
    expect(perfil.rachaDiaria, 3);
    expect(perfil.publicaciones, 2);
    expect(perfil.respuestas, 5);
  });

  test('CuentaGuardada.nombreVisible usa @usuario sin nombre', () {
    expect(
      const CuentaGuardada(id: '1', username: 'ana').nombreVisible,
      '@ana',
    );
    expect(
      const CuentaGuardada(
        id: '1',
        username: 'ana',
        displayName: 'Ana',
      ).nombreVisible,
      'Ana',
    );
  });

  group('SesionActual', () {
    test('avisa a quien escucha al actualizar y al limpiar', () {
      final sesion = SesionActual.paraTests();
      var avisos = 0;
      sesion.addListener(() => avisos++);

      expect(sesion.haySesion, isFalse);
      sesion.actualizar(const Perfil(username: 'ana'));
      expect(sesion.username, 'ana');
      expect(avisos, 1);

      sesion.limpiar();
      expect(sesion.perfil, isNull);
      expect(avisos, 2);

      sesion.limpiar();
      expect(avisos, 2, reason: 'limpiar sin sesión no avisa');
    });
  });
}
