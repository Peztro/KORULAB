import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/juegos/datos_juegos.dart';
import 'package:korulab/paginas/diverkoru/escenario_gotas.dart';
import 'package:korulab/paginas/diverkoru/juego_gotas.dart';

void main() {
  test('la planta crece por etapas', () {
    expect(plantaPara(0), '🌱');
    expect(plantaPara(10), '🌿');
    expect(plantaPara(25), '🪴');
    expect(plantaPara(50), '🌻');
  });

  test('el día avanza con las gotas y se queda en la noche', () {
    expect(faseDelDia(0), 0);
    expect(faseDelDia(25), 1);
    expect(faseDelDia(50), 2);
    expect(faseDelDia(500), 3);
  });

  test('las salpicaduras caen y se apagan', () {
    final gotas = salpicadura(
      x: 0.5,
      y: 0.8,
      color: Colors.blue,
      azar: Random(1),
    );
    expect(gotas, hasLength(12));
    // Al principio suben.
    expect(gotas.every((p) => p.vy < 0), isTrue);
    var vivas = gotas;
    for (var i = 0; i < 100; i++) {
      vivas = vivas.where((p) => p.avanzar(0.016)).toList();
    }
    expect(vivas, isEmpty);
  });

  testWidgets('el paisaje y las gotas se dibujan en todas las fases', (
    tester,
  ) async {
    for (final fase in [0.0, 1.0, 2.0, 2.7, 3.0]) {
      await tester.pumpWidget(
        SizedBox(
          width: 390,
          height: 700,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PaisajePainter(tiempo: 3, fase: fase, golpe: 0.5),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: GotasPainter(
                    gotas: [
                      for (final (i, t) in TipoGota.values.indexed)
                        GotaCayendo(0.1 + i * 0.18, t, y: 0.4),
                    ],
                    particulas: salpicadura(
                      x: 0.5,
                      y: 0.8,
                      color: Colors.blue,
                      azar: Random(2),
                    ),
                    velocidad: 0.5,
                    tiempo: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
