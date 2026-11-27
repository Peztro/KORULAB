import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:korulab/juegos/datos_juegos.dart';
import 'package:korulab/juegos/records_diverkoru.dart';
import 'package:korulab/juegos/sopa_letras.dart';
import 'package:korulab/servicios/servicio_ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Sopa de letras', () {
    test('esconde todas las palabras en línea recta', () {
      for (var semilla = 0; semilla < 40; semilla++) {
        final sopa = SopaLetras.generar(azar: Random(semilla));
        expect(sopa.palabras, hasLength(6));
        for (final MapEntry(key: palabra, value: celdas)
            in sopa.ubicaciones.entries) {
          final leida = celdas.map((c) => sopa.letras[c.$1][c.$2]).join();
          expect(leida, palabra);
          expect(celdasEnLinea(celdas.first, celdas.last), celdas);
        }
        for (final fila in sopa.letras) {
          expect(fila.every((l) => RegExp(r'^[A-Z]$').hasMatch(l)), isTrue);
        }
      }
    });

    test('reconoce la palabra seleccionada en ambos sentidos', () {
      final sopa = SopaLetras.generar(azar: Random(3));
      final palabra = sopa.palabras.first;
      final celdas = sopa.ubicaciones[palabra]!;
      expect(sopa.palabraEn(celdas), palabra);
      expect(sopa.palabraEn(celdas.reversed.toList()), palabra);
      expect(sopa.palabraEn(celdas.sublist(1)), isNull);
    });

    test('celdasEnLinea solo acepta líneas rectas', () {
      expect(celdasEnLinea((0, 0), (0, 3)), [(0, 0), (0, 1), (0, 2), (0, 3)]);
      expect(celdasEnLinea((2, 2), (0, 0)), [(2, 2), (1, 1), (0, 0)]);
      expect(celdasEnLinea((0, 0), (1, 3)), [(0, 0)]);
    });

    test('lineaAjustada endereza trazos un poco torcidos', () {
      // Horizontal aunque el dedo baje un poquito.
      expect(lineaAjustada((2, 2), 2.8, 5.5, 10), [
        (2, 2),
        (2, 3),
        (2, 4),
        (2, 5),
      ]);
      // Diagonal aunque no sea perfecta.
      expect(lineaAjustada((0, 0), 3.3, 2.9, 10), [
        (0, 0),
        (1, 1),
        (2, 2),
        (3, 3),
      ]);
      // Vertical hacia arriba.
      expect(lineaAjustada((5, 5), 3.6, 5.3, 10), [(5, 5), (4, 5), (3, 5)]);
      // Toque sin moverse: solo la celda inicial.
      expect(lineaAjustada((4, 4), 4.6, 4.4, 10), [(4, 4)]);
      // No se sale del tablero.
      expect(lineaAjustada((0, 8), 0.5, 14.0, 10), [(0, 8), (0, 9)]);
    });

    test('cada dificultad genera su tablero con todas sus palabras', () {
      for (final modo in ModoSopa.values) {
        for (var semilla = 0; semilla < 8; semilla++) {
          final sopa = SopaLetras.paraModo(modo, Random(semilla));
          expect(sopa.tamano, modo.tamano);
          expect(sopa.palabras, hasLength(modo.palabras));
          for (final MapEntry(key: palabra, value: celdas)
              in sopa.ubicaciones.entries) {
            expect(palabra.length, lessThanOrEqualTo(modo.largoMaximo));
            final leida = celdas.map((c) => sopa.letras[c.$1][c.$2]).join();
            expect(leida, palabra);
          }
        }
      }
    });

    test('las palabras aparecen en todas las direcciones', () {
      final direcciones = <(int, int)>{};
      for (var semilla = 0; semilla < 30; semilla++) {
        final sopa = SopaLetras.paraModo(ModoSopa.medio, Random(semilla));
        for (final celdas in sopa.ubicaciones.values) {
          direcciones.add((
            celdas[1].$1 - celdas[0].$1,
            celdas[1].$2 - celdas[0].$2,
          ));
        }
      }
      expect(direcciones, hasLength(8));
    });

    test('el banco tiene más de 500 palabras válidas y sin repetir', () {
      expect(palabrasSopa.length, greaterThanOrEqualTo(539));
      expect(palabrasSopa.toSet(), hasLength(palabrasSopa.length));
      for (final p in palabrasSopa) {
        expect(RegExp(r'^[A-Z]{3,12}$').hasMatch(p), isTrue, reason: p);
      }
    });
  });

  group('Datos de los juegos', () {
    test('hay muchos residuos y ninguno repetido', () {
      expect(residuos.length, greaterThanOrEqualTo(60));
      expect(residuos.map((r) => r.nombre).toSet(), hasLength(residuos.length));
    });

    test('todas las canecas tienen residuos', () {
      for (final caneca in Caneca.values) {
        expect(residuos.where((r) => r.caneca == caneca), isNotEmpty);
      }
    });

    test('preguntas de trivia bien formadas', () {
      expect(preguntasTrivia.length, greaterThanOrEqualTo(100));
      for (final p in preguntasTrivia) {
        final opciones = p.opciones(Random(1));
        expect(opciones, hasLength(4));
        expect(opciones.toSet(), hasLength(4), reason: p.pregunta);
        expect(opciones, contains(p.correcta));
      }
    });

    test('puntajes', () {
      expect(velocidadGotas(0), lessThan(velocidadGotas(30)));
      expect(intervaloGotas(0), greaterThan(intervaloGotas(30)));
      // Progresiva: a los 10 puntos casi no ha cambiado.
      expect(velocidadGotas(10), lessThan(0.35));
      expect(intervaloGotas(10), greaterThan(1.05));
      expect(velocidadGotas(1000), lessThan(0.86));
      expect(intervaloGotas(1000), greaterThan(0.44));
    });
  });

  group('Salva las gotas', () {
    test('efecto de cada gota al atraparla', () {
      expect(TipoGota.aceite.vidasAlAtrapar, -1);
      expect(TipoGota.acida.vidasAlAtrapar, -2);
      expect(TipoGota.petroleo.vidasAlAtrapar, -3);
      expect(TipoGota.dorada.vidasAlAtrapar, 1);
      expect(TipoGota.agua.puntosAlAtrapar, 1);
      expect(TipoGota.values.where((t) => t.cuestaVidaSiCae), [TipoGota.agua]);
    });

    test('las gotas malas aparecen según los puntos', () {
      Set<TipoGota> tipos(int puntos) => {
        for (var i = 0; i < 300; i++) tipoMalo(puntos, Random(i)),
      };
      expect(tipos(5), {TipoGota.aceite});
      expect(tipos(10), {TipoGota.aceite, TipoGota.acida});
      expect(tipos(20), {TipoGota.aceite, TipoGota.acida, TipoGota.petroleo});
      expect(probabilidadPareja(0), 0);
      expect(probabilidadMalaSuelta(0), 0);
      expect(probabilidadPareja(10), greaterThan(0.1));
      expect(probabilidadPareja(40), greaterThan(probabilidadPareja(10)));
    });
  });

  group('Planear gotas', () {
    // Cuenta qué sale en muchas tiradas.
    ({int buenas, int malas, int doradas, int parejas}) muestra(int puntos) {
      final azar = Random(5);
      var buenas = 0, malas = 0, doradas = 0, parejas = 0;
      double? ultima;
      for (var i = 0; i < 4000; i++) {
        final g = planearGotas(
          puntos: puntos,
          ultimaBuena: ultima,
          objetivo: 0.5,
          azar: azar,
        );
        if (g.length == 2) parejas++;
        for (final n in g) {
          expect(n.x, inInclusiveRange(0.06, 0.94));
          if (n.tipo.esMala) {
            malas++;
          } else {
            buenas++;
            if (n.tipo == TipoGota.dorada) doradas++;
            ultima = n.x;
          }
        }
      }
      return (buenas: buenas, malas: malas, doradas: doradas, parejas: parejas);
    }

    test('al empezar solo cae agua', () {
      final m = muestra(0);
      expect(m.malas, 0);
      expect(m.doradas, 0);
    });

    test('con puntos hay muchas malas y pocas doradas', () {
      final m = muestra(40);
      expect(m.malas / (m.buenas + m.malas), greaterThan(0.3));
      expect(m.parejas, greaterThan(0));
      expect(m.doradas / m.buenas, lessThan(0.03));
    });

    test('la mala de una pareja cae pegada a la buena', () {
      final azar = Random(9);
      for (var i = 0; i < 500; i++) {
        final g = planearGotas(
          puntos: 60,
          ultimaBuena: 0.5,
          objetivo: null,
          azar: azar,
        );
        if (g.length != 2) continue;
        expect((g[0].x - g[1].x).abs(), lessThanOrEqualTo(0.13 + 1e-9));
      }
    });

    test('las buenas se separan más con los puntos', () {
      expect(separacionGotasBuenas(0), lessThan(separacionGotasBuenas(50)));
      expect(separacionGotasBuenas(1000), lessThanOrEqualTo(0.6));
    });
  });

  group('Ranking', () {
    test('lee una fila del servidor', () {
      final p = PuestoRanking.desdeMapa({
        'posicion': 2,
        'username': 'ana.eco',
        'display_name': '  ',
        'profile_photo': null,
        'puntos': 87,
        'soy_yo': true,
      });
      expect(p.posicion, 2);
      expect(p.nombre, 'ana.eco');
      expect(p.foto, isNull);
      expect(p.puntos, 87);
      expect(p.soyYo, isTrue);
    });
  });

  group('Reloj de la trivia', () {
    test('empieza con 60 s y los aciertos suman cada vez menos', () {
      final r = RelojTrivia();
      expect(r.restante, 60);
      for (var i = 0; i < 15; i++) {
        expect(r.acierto(), 5);
      }
      expect(r.acierto(), 4);
      for (var i = 0; i < 14; i++) {
        r.acierto();
      }
      expect(r.acierto(), 3);
    });

    test('los fallos aceleran el reloj y los aciertos lo calman', () {
      final r = RelojTrivia();
      r.fallo();
      r.avanzar(1);
      expect(r.restante, closeTo(58.75, 1e-9));
      for (var i = 0; i < 10; i++) {
        r.fallo();
      }
      expect(r.ritmo, RelojTrivia.ritmoMaximo);
      for (var i = 0; i < 20; i++) {
        r.acierto();
      }
      expect(r.ritmo, 1);
    });

    test('se agota y no baja de cero', () {
      final r = RelojTrivia();
      r.avanzar(100);
      expect(r.restante, 0);
      expect(r.agotado, isTrue);
    });
  });

  group('Récords', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda solo si supera el récord, por usuario', () async {
      const j = JuegoDiverKoru.trivia;
      expect(await RecordsDiverKoru.registrar(j, 50, usuario: 'ana'), isTrue);
      expect(await RecordsDiverKoru.registrar(j, 30, usuario: 'ana'), isFalse);
      expect(await RecordsDiverKoru.leer(j, usuario: 'ana'), 50);
      expect(await RecordsDiverKoru.leer(j, usuario: 'luis'), 0);
    });

    test('en la sopa gana el menor tiempo', () async {
      const j = JuegoDiverKoru.sopaMedio;
      expect(await RecordsDiverKoru.registrar(j, 300, usuario: 'ana'), isTrue);
      expect(await RecordsDiverKoru.registrar(j, 420, usuario: 'ana'), isFalse);
      expect(await RecordsDiverKoru.registrar(j, 250, usuario: 'ana'), isTrue);
      expect(await RecordsDiverKoru.leer(j, usuario: 'ana'), 250);
      expect(j.formatear(250), '4:10');
    });

    test('cada juego compara a su manera', () {
      expect(esMejorRecord(JuegoDiverKoru.gotas, 10, 0), isTrue);
      expect(esMejorRecord(JuegoDiverKoru.gotas, 0, 0), isFalse);
      expect(esMejorRecord(JuegoDiverKoru.gotas, 9, 10), isFalse);
      expect(esMejorRecord(JuegoDiverKoru.sopaFacil, 9, 10), isTrue);
      expect(
        JuegoDiverKoru.values.map((j) => j.clave).toSet(),
        hasLength(JuegoDiverKoru.values.length),
      );
    });
  });
}
