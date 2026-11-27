import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicios/koru_controlador.dart';
import 'package:korulab/tema/tema_korulab.dart';
import 'package:korulab/widgets/boton_chats.dart';
import 'package:korulab/widgets/mascota_flotante.dart';

Widget _app(Widget hijo) => MaterialApp(
  theme: construirTemaKorulab(Brightness.light, fuentesDeGoogle: false),
  home: Scaffold(body: Center(child: hijo)),
);

void main() {
  test('Koru avisa cuántos chats tienen mensajes y recuerda por qué', () async {
    final frase = await CatalogoFrasesKoru().frasePara(
      EventoKoru.mensajeNuevo,
      const {'chats': '2 chats', 'nombre': 'Ana'},
    );
    expect(frase, isNotNull);
    expect(frase!.texto, isNot(contains('{')));

    final koru = KoruControlador();
    koru.cambiarVisible(true);
    await koru.reaccionar(EventoKoru.mensajeNuevo, importante: true);
    expect(koru.mensaje?.evento, EventoKoru.mensajeNuevo);
    koru.dispose();
  });

  testWidgets('la pastilla dice "Chats" o cuántos hay sin leer', (
    tester,
  ) async {
    var abiertos = 0;
    await tester.pumpWidget(
      _app(BotonChats(sinLeer: 0, onTap: () => abiertos++)),
    );
    expect(find.text('Chats'), findsOneWidget);

    await tester.pumpWidget(
      _app(BotonChats(sinLeer: 3, onTap: () => abiertos++)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(
      _app(BotonChats(sinLeer: 12, onTap: () => abiertos++)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('9+'), findsOneWidget);

    await tester.tap(find.byType(BotonChats));
    expect(abiertos, 1);
  });

  testWidgets('tocar el globo de un aviso de mensajes abre los chats', (
    tester,
  ) async {
    var abiertos = 0;
    final koru = KoruControlador.instancia;
    koru.reiniciar();
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaKorulab(Brightness.light, fuentesDeGoogle: false),
        home: Scaffold(
          body: Stack(
            children: [
              // Como en el inicio: Koru va encima del contenido.
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
              Positioned(
                right: 16,
                bottom: 16,
                child: MascotaFlotante(
                  acciones: {EventoKoru.mensajeNuevo: () => abiertos++},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    koru.cambiarVisible(true);
    await koru.reaccionar(
      EventoKoru.mensajeNuevo,
      datos: const {'chats': '1 chat'},
      importante: true,
    );
    // Un cuadro para que empiece la animación del globo y otro para que
    // termine.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(abiertos, 1);
    koru.reiniciar();
    await tester.pump(const Duration(seconds: 10));
  });
}
