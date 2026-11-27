import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicios/recordatorios.dart';

void main() {
  final manana = DateTime(2026, 11, 27, 8, 0); // 8:00 a. m.

  test('racha: uno al día a las 7 p. m., con tu racha de hoy', () {
    final plan = planearRecordatorios(
      ahora: manana,
      racha: 5,
      estudioHoy: false,
      azar: Random(1),
    );
    final racha = plan.where((r) => r.cuando.hour == horaRacha).toList();
    expect(racha, hasLength(diasProgramados));
    expect(racha.first.cuando, DateTime(2026, 11, 27, 19));
    expect(racha.first.titulo, contains('5 días'));
  });

  test('si ya estudiaste hoy, hoy no se recuerda la racha', () {
    final plan = planearRecordatorios(
      ahora: manana,
      racha: 5,
      estudioHoy: true,
      azar: Random(1),
    );
    final racha = plan.where((r) => r.cuando.hour == horaRacha).toList();
    expect(racha, hasLength(diasProgramados - 1));
    expect(racha.first.cuando.day, 28);
  });

  test('sin racha te invita a empezarla', () {
    final plan = planearRecordatorios(
      ahora: manana,
      racha: 0,
      estudioHoy: false,
      azar: Random(1),
    );
    expect(plan.first.titulo, contains('Empieza tu racha'));
  });

  test('sugerencias cada 8 horas de día, sin repetirse seguidas', () {
    final plan = planearRecordatorios(
      ahora: manana,
      racha: 1,
      estudioHoy: false,
      azar: Random(3),
    );
    final sugerencias =
        plan.where((r) => horasSugerencias.contains(r.cuando.hour)).toList()
          ..sort((a, b) => a.cuando.compareTo(b.cuando));
    expect(sugerencias, hasLength(diasProgramados * horasSugerencias.length));
    expect(horasSugerencias[1] - horasSugerencias[0], 8);
    for (var i = 1; i < sugerencias.length; i++) {
      expect(sugerencias[i].titulo, isNot(sugerencias[i - 1].titulo));
    }
  });

  test('no programa nada en el pasado y los ids no chocan', () {
    final tarde = DateTime(2026, 11, 27, 20, 0); // ya pasaron todas las de hoy
    final plan = planearRecordatorios(
      ahora: tarde,
      racha: 2,
      estudioHoy: false,
      azar: Random(2),
    );
    expect(plan.every((r) => r.cuando.isAfter(tarde)), isTrue);
    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });
}
