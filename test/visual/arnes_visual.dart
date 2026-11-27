// Utilidades para pruebas visuales (capturas de widgets sin teléfono).
//
// Generar o actualizar las imágenes:
//   flutter test test/visual --update-goldens --run-skipped
// Las capturas quedan en test/visual/goldens/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/tema/tema_korulab.dart';

/// Tamaño de un teléfono típico en píxeles lógicos.
const tamanoTelefono = Size(412, 900);

/// Carga Roboto e iconos Material desde el SDK de Flutter, para que los
/// textos e iconos se vean de verdad en las capturas (no como cuadros).
Future<void> cargarFuentes() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final carpeta = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> cargar(String familia, List<String> archivos) async {
    final loader = FontLoader(familia);
    for (final archivo in archivos) {
      final f = File('$carpeta/$archivo');
      if (!f.existsSync()) continue;
      loader.addFont(f.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await cargar('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]);
  await cargar('MaterialIcons', ['materialicons-regular.otf']);
}

/// Monta [child] con el tema de Korulab en el brillo indicado.
Widget conTema(Widget child, Brightness brillo) {
  final tema = construirTemaKorulab(brillo, fuentesDeGoogle: false);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: tema.copyWith(
      textTheme: tema.textTheme.apply(fontFamily: 'Roboto'),
      appBarTheme: tema.appBarTheme.copyWith(
        titleTextStyle: tema.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Roboto',
        ),
      ),
    ),
    home: child,
  );
}

/// Ajusta la ventana de pruebas al tamaño de un teléfono.
void usarTamanoTelefono(WidgetTester tester, {Size tamano = tamanoTelefono}) {
  tester.view.physicalSize = tamano * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
