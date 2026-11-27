import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/servicios/koru_controlador.dart';
import 'package:korulab/widgets/koru_mascota.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fuente de frases que siempre responde lo mismo, para probar el controlador.
class _FuenteFija implements FuenteFrasesKoru {
  int llamadas = 0;

  @override
  Future<MensajeKoru?> frasePara(
    EventoKoru evento,
    Map<String, Object?> datos,
  ) async {
    llamadas++;
    return MensajeKoru('frase ${evento.name}', EmocionKoru.feliz);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogoFrasesKoru', () {
    test('rellena el nombre en el saludo', () async {
      final frase = await CatalogoFrasesKoru(
        Random(1),
      ).frasePara(EventoKoru.bienvenida, {'nombre': 'Ana'});
      expect(frase, isNotNull);
      expect(frase!.texto, contains('Ana'));
      expect(frase.texto, isNot(contains('{')));
    });

    test('sin nombre no deja huecos como "Hola, !"', () async {
      final catalogo = CatalogoFrasesKoru(Random(2));
      for (var i = 0; i < 20; i++) {
        final frase = await catalogo.frasePara(EventoKoru.bienvenida, {
          'nombre': '',
        });
        expect(frase!.texto, isNot(contains(', !')));
        expect(frase.texto, isNot(contains(',!')));
        expect(frase.texto, isNot(contains('{')));
      }
    });

    test('tiene frases para todos los eventos', () async {
      final catalogo = CatalogoFrasesKoru();
      for (final evento in EventoKoru.values) {
        expect(await catalogo.frasePara(evento, const {}), isNotNull);
      }
    });
  });

  group('KoruControlador', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda el mensaje mientras no está a la vista', () async {
      final koru = KoruControlador(fuente: _FuenteFija());
      await koru.reaccionar(EventoKoru.leccionBien, importante: true);
      expect(koru.mensaje, isNull, reason: 'Koru no está a la vista');

      koru.cambiarVisible(true);
      expect(koru.mensaje?.texto, 'frase leccionBien');
      koru.dispose();
    });

    test('saluda una sola vez por sesión', () async {
      final fuente = _FuenteFija();
      final koru = KoruControlador(fuente: fuente)..cambiarVisible(true);
      await koru.reaccionar(EventoKoru.bienvenida);
      await koru.reaccionar(EventoKoru.bienvenida);
      expect(fuente.llamadas, 1);

      koru.reiniciar();
      await koru.reaccionar(EventoKoru.bienvenida);
      expect(fuente.llamadas, 2, reason: 'tras reiniciar vuelve a saludar');
      koru.dispose();
    });

    test('no habla demasiado seguido, salvo lo importante', () async {
      final fuente = _FuenteFija();
      final koru = KoruControlador(fuente: fuente)..cambiarVisible(true);
      await koru.reaccionar(EventoKoru.avisoNuevo);
      await koru.reaccionar(EventoKoru.avisoNuevo);
      expect(fuente.llamadas, 1);

      await koru.reaccionar(EventoKoru.leccionPerfecta, importante: true);
      expect(fuente.llamadas, 2);
      expect(koru.emocion, EmocionKoru.feliz);
      koru.dispose();
    });

    test('desactivado no dice nada', () async {
      final fuente = _FuenteFija();
      final koru = KoruControlador(fuente: fuente)..cambiarVisible(true);
      await koru.cambiarActivo(false);
      await koru.reaccionar(EventoKoru.consejo);
      expect(fuente.llamadas, 0);
      expect(koru.mensaje, isNull);
      koru.dispose();
    });
  });
}
