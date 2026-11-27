import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/datos/catalogo_cursos.dart';
import 'package:korulab/modelos/modelos_curso.dart';
import 'package:korulab/paginas/pagina_memoria.dart';
import 'package:korulab/servicios/estadisticas_progreso.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Tablero: 0=sol 1=agua 2=sol 3=viento 4=agua 5=viento
  ContadorErroresMemoria tablero() => ContadorErroresMemoria([
    'sol',
    'agua',
    'sol',
    'viento',
    'agua',
    'viento',
  ]);

  group('ContadorErroresMemoria', () {
    test('fallar a ciegas con cartas nuevas no es error', () {
      final c = tablero();
      expect(c.registrarIntento(0, 1), isFalse); // sol, agua: nunca vistas
      expect(c.registrarIntento(3, 2), isFalse); // viento, sol: nuevas
    });

    test('es error si la pareja de la primera carta ya había salido', () {
      final c = tablero();
      c.registrarIntento(0, 1); // ya viste sol(0) y agua(1)
      // Volteas el otro sol (2) y no vas al 0, que ya conocías.
      expect(c.registrarIntento(2, 3), isTrue);
    });

    test('es error si la segunda carta ya la habías visto', () {
      final c = tablero();
      c.registrarIntento(0, 1); // viste sol(0) y agua(1)
      // Volteas viento(3), nuevo, y luego eliges agua(1), que sabías que no era.
      expect(c.registrarIntento(3, 1), isTrue);
    });

    test('acertar una pareja nunca es error', () {
      final c = tablero();
      c.registrarIntento(0, 1);
      expect(c.registrarIntento(2, 0), isFalse); // sol con sol
    });

    test('una partida perfecta de memoria no tiene errores', () {
      final c = tablero();
      // Primero voltea todo a ciegas sin repetir, luego empareja.
      expect(c.registrarIntento(0, 1), isFalse);
      expect(c.registrarIntento(3, 2), isFalse); // viento nuevo, sol nuevo
      // Ahora sabe dónde está todo: empareja sin fallar.
      expect(c.registrarIntento(0, 2), isFalse);
      expect(c.registrarIntento(1, 4), isFalse);
      expect(c.registrarIntento(3, 5), isFalse);
    });
  });

  group('Ekostrellas en memoria', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    Future<ProgressStats> cargar() async {
      SharedPreferences.setMockInitialValues({});
      final stats = ProgressStats();
      await stats.loadCourseProgress('ana');
      return stats;
    }

    final memoria = courses
        .expand((c) => c.activities)
        .whereType<MemoryActivity>()
        .first;

    test('sin errores da 50 estrellas', () async {
      final stats = await cargar();
      stats.reportLessonResult(6, 6, activity: memoria);
      expect(stats.ekostrellas, 50);
    });

    test(
      'con errores da menos estrellas (6 parejas, 2 errores → 37)',
      () async {
        final stats = await cargar();
        stats.reportLessonResult(
          6,
          6 + 2,
          activity: memoria,
          incorrectAttempts: 2,
        );
        expect(stats.ekostrellas, 37);
        expect(stats.accuracyPercent, 75);
      },
    );
  });
}
