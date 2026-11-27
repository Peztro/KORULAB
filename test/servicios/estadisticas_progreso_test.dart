import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/datos/catalogo_cursos.dart';
import 'package:korulab/paginas/pagina_tienda.dart';
import 'package:korulab/servicios/estadisticas_progreso.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supabase no está iniciado en los tests: pullProgress/pushProgress fallan
// y se ignoran, así que el progreso sale solo de SharedPreferences.

DateTime _hoy() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<ProgressStats> _cargar(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final stats = ProgressStats();
  await stats.loadCourseProgress('ana');
  return stats;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carga el progreso guardado del usuario', () async {
    final stats = await _cargar({
      'korulab_eko_stars_ana': 120,
      'korulab_correct_answers_ana': 8,
      'korulab_total_answers_ana': 10,
      'korulab_course_progress_ana': ['0:0', '0:1'],
    });
    expect(stats.isCourseProgressLoaded, isTrue);
    expect(stats.ekostrellas, 120);
    expect(stats.accuracyPercent, 80);
    expect(stats.accuracyRatio, closeTo(0.8, 1e-9));
    expect(stats.completedActivities, 2);
  });

  test('sin respuestas la precisión es 0', () async {
    final stats = await _cargar({});
    expect(stats.accuracyPercent, 0);
    expect(stats.accuracyRatio, 0);
  });

  group('protectores de racha', () {
    test('cubren los días perdidos y mantienen la racha', () async {
      final stats = await _cargar({
        'korulab_daily_streak_ana': 5,
        'korulab_streak_protectors_ana': 2,
        'korulab_last_lesson_ana': _hoy()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      });
      // 3 días desde la última lección = 2 días perdidos.
      expect(stats.streakProtectors, 0);
      expect(stats.dailyStreak, 7);
    });

    test('si no alcanzan, la racha se pierde', () async {
      final stats = await _cargar({
        'korulab_daily_streak_ana': 5,
        'korulab_streak_protectors_ana': 1,
        'korulab_last_lesson_ana': _hoy()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
      });
      expect(stats.streakProtectors, 0);
      expect(stats.dailyStreak, 0);
    });

    test('no se gastan si la última lección fue ayer', () async {
      final stats = await _cargar({
        'korulab_daily_streak_ana': 5,
        'korulab_streak_protectors_ana': 2,
        'korulab_last_lesson_ana': _hoy()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      });
      expect(stats.streakProtectors, 2);
      expect(stats.dailyStreak, 5);
    });
  });

  group('reportLessonResult', () {
    test('suma respuestas, estrellas y marca la actividad', () async {
      final stats = await _cargar({});
      final actividad = courses[0].activities[0];

      stats.reportLessonResult(4, 5, activity: actividad, incorrectAttempts: 1);

      expect(stats.correctAnswers, 4);
      expect(stats.totalAnswers, 5);
      expect(stats.completedLessons, 1);
      expect(stats.ekostrellas, 40); // 4 * 50 ~/ 5
      expect(stats.dailyStreak, 1);
      expect(stats.isActivityCompleted(actividad), isTrue);
    });

    test('el multiplicador duplica las estrellas y se consume', () async {
      final stats = await _cargar({'korulab_star_multipliers_ana': 1});
      final actividad = courses[0].activities[0];

      stats.reportLessonResult(5, 5, activity: actividad);
      expect(stats.ekostrellas, 100);
      expect(stats.starMultipliers, 0);

      stats.reportLessonResult(5, 5, activity: actividad);
      expect(stats.ekostrellas, 150);
    });

    test('continuar la racha de ayer la incrementa', () async {
      final stats = await _cargar({
        'korulab_daily_streak_ana': 3,
        'korulab_last_lesson_ana': _hoy()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
      });
      stats.reportLessonResult(1, 1, activity: courses[0].activities[0]);
      expect(stats.dailyStreak, 4);
    });
  });

  group('tienda', () {
    test('comprar descuenta estrellas y suma el objeto', () async {
      final stats = await _cargar({
        'korulab_eko_stars_ana': RewardShopPage.hintPrice + 5,
      });
      expect(stats.buyHint(), isTrue);
      expect(stats.ekostrellas, 5);
      expect(stats.hintCredits, 1);
      expect(stats.buyHint(), isFalse, reason: 'ya no alcanzan las estrellas');

      expect(stats.useHint(), isTrue);
      expect(stats.useHint(), isFalse);
    });

    test('no se puede comprar antes de cargar el progreso', () {
      final stats = ProgressStats();
      expect(stats.buyHint(), isFalse);
      expect(stats.buyStreakProtector(), isFalse);
      expect(stats.buyStarMultiplier(), isFalse);
      expect(stats.buySecondChance(), isFalse);
    });
  });

  test('un curso se desbloquea al completar todos los anteriores', () async {
    final stats = await _cargar({});
    expect(stats.isCourseUnlocked(0), isTrue);
    expect(stats.isCourseUnlocked(1), isFalse);

    for (final actividad in courses[0].activities) {
      stats.reportLessonResult(1, 1, activity: actividad);
    }
    expect(stats.isCourseUnlocked(1), isTrue);
    expect(stats.isActivityUnlocked(courses[1].activities[0]), isTrue);
  });

  test('las lecciones de profesor solo se completan una vez', () async {
    final stats = await _cargar({});
    expect(stats.completeTeacherLesson(7), isTrue);
    expect(stats.completeTeacherLesson(7), isFalse);
    expect(stats.isTeacherLessonCompleted(7), isTrue);
    expect(stats.ekostrellas, 50);
  });
}
