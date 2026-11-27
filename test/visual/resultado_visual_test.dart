@Tags(['visual'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/paginas/pagina_curso.dart';

import 'arnes_visual.dart';

void main() {
  setUpAll(cargarFuentes);

  // (nombre, aciertos, errores, momento de la captura)
  const casos = [
    ('perfecto', 5, 0, 900),
    ('bien', 4, 1, 2200),
    ('regular', 3, 3, 1500),
    ('practicar', 1, 4, 1900),
  ];

  for (final (nombre, aciertos, errores, ms) in casos) {
    testWidgets('resultado $nombre', (tester) async {
      usarTamanoTelefono(tester);
      await tester.pumpWidget(
        conTema(
          Scaffold(
            body: ResultScreen(
              score: aciertos,
              total: 5,
              incorrectAttempts: errores,
              onRetry: () {},
              activityName: 'Quiz: Fuentes de energía',
            ),
          ),
          Brightness.dark,
        ),
      );
      // Avanza la animación hasta el momento elegido, en pasos pequeños.
      for (var t = 0; t < ms; t += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/resultado_$nombre.png'),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }
}
