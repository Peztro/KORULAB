@Tags(['visual'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/modelos/modelos_discusion.dart';
import 'package:korulab/paginas/pagina_discusion.dart';

import 'arnes_visual.dart';

void main() {
  setUpAll(cargarFuentes);

  for (final brillo in Brightness.values) {
    testWidgets('discusión (${brillo.name})', (tester) async {
      usarTamanoTelefono(tester);
      final space = DiscussionSpace(
        id: 1,
        title: '¿Cómo cuido el medio ambiente?',
        description:
            'Comparte ideas sencillas que puedas aplicar en casa o en tu colegio.',
        author: 'Maria F.',
        authorHandle: 'maferr',
        replies: [
          DiscussionReply(
            id: 1,
            author: 'Ingeniero Korucol',
            authorHandle: 'koruadm',
            authorRole: 'admin',
            message: 'Separar los residuos es un gran primer paso.',
          ),
          DiscussionReply(
            id: 2,
            author: 'Ana',
            authorHandle: 'ana',
            message: 'Yo uso una botella reutilizable todos los días.',
          ),
        ],
      );
      await tester.pumpWidget(
        conTema(
          DiscussionPage(
            space: space,
            username: 'ana',
            displayName: 'Ana',
            userRole: 'student',
            authorPhoto: null,
            isAdmin: false,
            isTeacher: false,
          ),
          brillo,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/discusion_${brillo.name}.png'),
      );
    });
  }
}
