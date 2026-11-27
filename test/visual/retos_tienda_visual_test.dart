@Tags(['visual'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/paginas/pagina_retos_ecologicos.dart';
import 'package:korulab/paginas/pagina_tienda.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arnes_visual.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'korulab_eko_stars_ana': 90,
      'korulab_hint_credits_ana': 2,
    });
    await cargarFuentes();
  });

  for (final brillo in Brightness.values) {
    testWidgets('retos (${brillo.name})', (tester) async {
      usarTamanoTelefono(tester);
      await tester.pumpWidget(
        conTema(const EcoChallengesPage(username: 'ana'), brillo),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/retos_${brillo.name}.png'),
      );
    });

    testWidgets('tienda (${brillo.name})', (tester) async {
      usarTamanoTelefono(tester);
      await tester.pumpWidget(
        conTema(const RewardShopPage(username: 'ana'), brillo),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tienda_${brillo.name}.png'),
      );
    });
  }
}
