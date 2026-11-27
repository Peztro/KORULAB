@Tags(['visual'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/datos/catalogo_cursos.dart';
import 'package:korulab/modelos/modelos_curso.dart';
import 'package:korulab/paginas/pagina_completar.dart';
import 'package:korulab/paginas/pagina_curso.dart';
import 'package:korulab/paginas/pagina_memoria.dart';
import 'package:korulab/paginas/pagina_ordenar.dart';
import 'package:korulab/paginas/pagina_quiz.dart';
import 'package:korulab/paginas/pagina_relacionar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arnes_visual.dart';

T _primera<T extends LessonActivity>() =>
    courses.expand((c) => c.activities).whereType<T>().first;

Future<void> _capturar(
  WidgetTester tester,
  Widget pantalla,
  String nombre,
  Brightness brillo, {
  Future<void> Function()? interactuar,
}) async {
  usarTamanoTelefono(tester);
  await tester.pumpWidget(conTema(pantalla, brillo));
  await tester.pump(const Duration(milliseconds: 500));
  if (interactuar != null) {
    await interactuar();
    await tester.pump(const Duration(milliseconds: 600));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/${nombre}_${brillo.name}.png'),
  );
  // Deja que terminen temporizadores de avisos y animaciones.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await cargarFuentes();
  });

  for (final brillo in Brightness.values) {
    testWidgets('unidad (${brillo.name})', (tester) async {
      await _capturar(
        tester,
        CoursePage(course: courses.first, courseIndex: 0),
        'unidad',
        brillo,
      );
    });

    testWidgets('quiz (${brillo.name})', (tester) async {
      await _capturar(
        tester,
        QuizPage(activity: _primera<QuizActivity>()),
        'quiz',
        brillo,
        interactuar: () async {
          await tester.tap(find.byType(InkWell).at(1));
        },
      );
    });
  }

  testWidgets('completar (dark)', (tester) async {
    await _capturar(
      tester,
      FillBlankPage(activity: _primera<FillBlankActivity>()),
      'completar',
      Brightness.dark,
    );
  });

  testWidgets('relacionar (light)', (tester) async {
    await _capturar(
      tester,
      MatchingPage(activity: _primera<MatchingActivity>()),
      'relacionar',
      Brightness.light,
    );
  });

  testWidgets('memoria (dark)', (tester) async {
    await _capturar(
      tester,
      MemoryPage(activity: _primera<MemoryActivity>()),
      'memoria',
      Brightness.dark,
      interactuar: () async {
        await tester.tap(find.byType(GestureDetector).first);
      },
    );
  });

  testWidgets('ordenar (light)', (tester) async {
    await _capturar(
      tester,
      SortingPage(activity: _primera<SortingActivity>()),
      'ordenar',
      Brightness.light,
    );
  });

  testWidgets('resultado (dark)', (tester) async {
    await _capturar(
      tester,
      Scaffold(
        body: ResultScreen(
          score: 4,
          total: 5,
          incorrectAttempts: 1,
          onRetry: () {},
          activityName: 'Quiz: energía limpia',
        ),
      ),
      'resultado',
      Brightness.dark,
    );
  });
}
