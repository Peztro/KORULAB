@Tags(['visual'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/widgets/sendero.dart';

import 'arnes_visual.dart';

List<ParadaSendero> _paradas() => [
  ParadaSendero(
    titulo: 'Energía renovable',
    subtitulo: 'Fuentes limpias y sostenibles',
    detalle: '5/5 actividades',
    estado: EstadoParada.completada,
    progreso: 1,
    onTap: () {},
  ),
  ParadaSendero(
    titulo: 'Reciclaje',
    subtitulo: 'Reduce, reutiliza y recicla',
    detalle: '2/5 actividades',
    estado: EstadoParada.actual,
    progreso: 0.4,
    onTap: () {},
  ),
  ParadaSendero(
    titulo: 'Hábitat natural',
    subtitulo: 'Bosques, animales y agua',
    detalle: '0/5 actividades',
    estado: EstadoParada.bloqueada,
    progreso: 0,
    onTap: () {},
  ),
  ParadaSendero(
    titulo: 'Contaminación del aire',
    subtitulo: 'Causas, efectos y soluciones',
    detalle: '0/5 actividades',
    estado: EstadoParada.bloqueada,
    progreso: 0,
    onTap: () {},
    menu: IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
  ),
];

void main() {
  setUpAll(cargarFuentes);

  for (final brillo in Brightness.values) {
    testWidgets('sendero de Ruta Eko (${brillo.name})', (tester) async {
      usarTamanoTelefono(tester);
      await tester.pumpWidget(
        conTema(
          Scaffold(
            appBar: AppBar(title: const Text('Ruta Eko')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SenderoRutaEko(paradas: _paradas()),
            ),
          ),
          brillo,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/sendero_${brillo.name}.png'),
      );
    });
  }
}
