import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/juegos/datos_juegos.dart';
import 'package:korulab/paginas/pagina_ruta_eko.dart';
import 'package:korulab/tema/tema_korulab.dart';
import 'package:korulab/widgets/explora_inicio.dart';
import 'package:korulab/widgets/koru_mascota.dart';

void main() {
  test('la tienda dice qué te alcanza o cuánto te falta', () {
    expect(datoTienda(10), 'Te faltan 15 ⭐ para una Pista');
    expect(datoTienda(30), contains('una Pista'));
    expect(datoTienda(50), contains('un Segundo intento'));
    expect(datoTienda(80), contains('un Doble de ekostrellas'));
    expect(datoTienda(150), contains('un Protector de racha'));
  });

  test('DiverKoru presume tu mejor récord', () {
    expect(datoDiverKoru(const {}), '4 juegos y un ranking te esperan');
    expect(
      datoDiverKoru(const {JuegoDiverKoru.gotas: 34}),
      contains('34 gotas'),
    );
    expect(
      datoDiverKoru(const {JuegoDiverKoru.trivia: 12}),
      contains('Trivia: 12'),
    );
  });

  testWidgets('mosaicos y mini sendero se dibujan sin errores', (tester) async {
    var tocado = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaKorulab(Brightness.light, fuentesDeGoogle: false),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const MiniSendero(
                colorTexto: Colors.white,
                estados: [
                  EstadoUnidadRuta.completada,
                  EstadoUnidadRuta.completada,
                  EstadoUnidadRuta.actual,
                  EstadoUnidadRuta.bloqueada,
                  EstadoUnidadRuta.bloqueada,
                  EstadoUnidadRuta.bloqueada,
                  EstadoUnidadRuta.bloqueada,
                  EstadoUnidadRuta.bloqueada,
                  EstadoUnidadRuta.bloqueada,
                ],
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MosaicoExplora(
                        titulo: 'Retos',
                        dato: '6 retos para cuidar el planeta hoy',
                        color: Colors.blue,
                        emocion: EmocionKoru.feliz,
                        onTap: () => tocado = true,
                      ),
                    ),
                    Expanded(
                      child: MosaicoExplora(
                        titulo: 'Tienda',
                        dato: datoTienda(60),
                        color: Colors.orange,
                        emocion: EmocionKoru.tendero,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              MosaicoExplora(
                titulo: 'DiverKoru',
                dato: datoDiverKoru(const {}),
                color: Colors.brown,
                emocion: EmocionKoru.jugando,
                ancho: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('…'), findsOneWidget);
    await tester.tap(find.text('Retos'));
    expect(tocado, isTrue);
  });
}
