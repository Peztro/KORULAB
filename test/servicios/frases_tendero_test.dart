import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicios/frases_tendero.dart';

void main() {
  List<String> frases(int ekostrellas) => frasesTendero(
    ekostrellas: ekostrellas,
    precioMinimo: 25,
    precioMaximo: 100,
  );

  test('la frase de ekostrellas depende de cuántas tienes', () {
    expect(frases(10), contains(contains('Te faltan 15 ekostrellas')));
    expect(frases(50), contains(contains('Con tus 50 ekostrellas')));
    expect(frases(150), contains(contains('para lo que quieras')));
  });

  test('no repite la frase anterior', () {
    final lista = frases(50);
    final azar = Random(4);
    var anterior = lista.first;
    for (var i = 0; i < 100; i++) {
      final nueva = elegirFraseTendero(lista, anterior, azar);
      expect(nueva, isNot(anterior));
      anterior = nueva;
    }
  });
}
