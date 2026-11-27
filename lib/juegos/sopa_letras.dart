import 'dart:math';

import 'banco_palabras.dart';
import 'datos_juegos.dart';

export 'banco_palabras.dart';

/// Una celda del tablero: (fila, columna).
typedef Celda = (int, int);

/// Las palabras se esconden en las 8 direcciones: horizontal, vertical y
/// diagonal, hacia adelante o al revés.
const _direcciones = <Celda>[
  (0, 1),
  (0, -1),
  (1, 0),
  (-1, 0),
  (1, 1),
  (-1, -1),
  (1, -1),
  (-1, 1),
];

/// Dificultades de la sopa de letras.
enum ModoSopa {
  facil(nombre: 'Fácil', palabras: 10, tamano: 10, largoMaximo: 10),
  medio(nombre: 'Medio', palabras: 30, tamano: 16, largoMaximo: 8),
  dificil(nombre: 'Difícil', palabras: 45, tamano: 18, largoMaximo: 7);

  const ModoSopa({
    required this.nombre,
    required this.palabras,
    required this.tamano,
    required this.largoMaximo,
  });

  final String nombre;

  /// Cuántas palabras se esconden.
  final int palabras;

  /// Lado del tablero (tamano × tamano letras).
  final int tamano;

  /// Las palabras más largas no se usan en los tableros muy llenos.
  final int largoMaximo;

  /// Tabla de récords de este modo.
  JuegoDiverKoru get juego => switch (this) {
    ModoSopa.facil => JuegoDiverKoru.sopaFacil,
    ModoSopa.medio => JuegoDiverKoru.sopaMedio,
    ModoSopa.dificil => JuegoDiverKoru.sopaDificil,
  };
}

class SopaLetras {
  SopaLetras._(this.tamano, this.letras, this.ubicaciones);

  final int tamano;

  /// letras[fila][columna].
  final List<List<String>> letras;

  /// Celdas de cada palabra escondida, en orden de lectura.
  final Map<String, List<Celda>> ubicaciones;

  List<String> get palabras => ubicaciones.keys.toList();

  /// Tablero para una dificultad.
  factory SopaLetras.paraModo(ModoSopa modo, Random azar) => SopaLetras.generar(
    azar: azar,
    tamano: modo.tamano,
    cantidad: modo.palabras,
    largoMaximo: modo.largoMaximo,
  );

  /// Crea un tablero de [tamano]×[tamano] con [cantidad] palabras al azar
  /// de como mucho [largoMaximo] letras.
  factory SopaLetras.generar({
    required Random azar,
    int tamano = 10,
    int cantidad = 6,
    int? largoMaximo,
    List<String> banco = palabrasSopa,
  }) {
    final largo = min(largoMaximo ?? tamano, tamano);
    // Reintenta con otro orden si alguna palabra no cupo.
    for (var intento = 0; intento < 80; intento++) {
      final candidatas = banco.where((p) => p.length <= largo).toList()
        ..shuffle(azar);
      final elegidas = candidatas.take(cantidad).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      final tablero = List.generate(tamano, (_) => List.filled(tamano, ''));
      final ubicaciones = <String, List<Celda>>{};
      var todasCupieron = true;
      for (final palabra in elegidas) {
        final celdas = _colocar(palabra, tablero, azar);
        if (celdas == null) {
          todasCupieron = false;
          break;
        }
        ubicaciones[palabra] = celdas;
      }
      if (!todasCupieron) continue;
      const abecedario = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      for (final fila in tablero) {
        for (var c = 0; c < tamano; c++) {
          if (fila[c].isEmpty) {
            fila[c] = abecedario[azar.nextInt(abecedario.length)];
          }
        }
      }
      return SopaLetras._(tamano, tablero, ubicaciones);
    }
    throw StateError('No se pudo generar la sopa de letras');
  }

  static List<Celda>? _colocar(
    String palabra,
    List<List<String>> tablero,
    Random azar,
  ) {
    final n = tablero.length;
    final opciones = <(int, int, Celda)>[];
    final ultimo = palabra.length - 1;
    for (final dir in _direcciones) {
      for (var f = 0; f < n; f++) {
        for (var c = 0; c < n; c++) {
          final ff = f + dir.$1 * ultimo, cf = c + dir.$2 * ultimo;
          if (ff >= 0 && cf >= 0 && ff < n && cf < n) {
            opciones.add((f, c, dir));
          }
        }
      }
    }
    opciones.shuffle(azar);
    for (final (f, c, dir) in opciones) {
      final celdas = [
        for (var i = 0; i < palabra.length; i++)
          (f + dir.$1 * i, c + dir.$2 * i),
      ];
      final cabe = celdas.indexed.every((e) {
        final actual = tablero[e.$2.$1][e.$2.$2];
        return actual.isEmpty || actual == palabra[e.$1];
      });
      if (!cabe) continue;
      for (final (i, (cf, cc)) in celdas.indexed) {
        tablero[cf][cc] = palabra[i];
      }
      return celdas;
    }
    return null;
  }

  /// Palabra escondida que coincide con la selección [celdas] (leída en
  /// cualquier sentido), o null si no hay ninguna.
  String? palabraEn(List<Celda> celdas) {
    if (celdas.length < 2) return null;
    for (final MapEntry(key: palabra, value: ubicacion)
        in ubicaciones.entries) {
      if (ubicacion.length != celdas.length) continue;
      if (_iguales(ubicacion, celdas) ||
          _iguales(ubicacion, celdas.reversed.toList())) {
        return palabra;
      }
    }
    return null;
  }

  static bool _iguales(List<Celda> a, List<Celda> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Selección al arrastrar el dedo desde [inicio] hasta el punto ([fila],
/// [columna]) medido en celdas (con decimales; 2.5 es el centro de la fila
/// 2). Se ajusta a la más cercana de las 8 direcciones, así un trazo un poco
/// torcido sigue marcando la línea que el jugador quería, y nunca se sale de
/// un tablero de [tamano]×[tamano].
List<Celda> lineaAjustada(
  Celda inicio,
  double fila,
  double columna,
  int tamano,
) {
  final df = fila - (inicio.$1 + 0.5);
  final dc = columna - (inicio.$2 + 0.5);
  final largo = sqrt(df * df + dc * dc);
  if (largo < 0.5) return [inicio];
  // Ángulo redondeado a múltiplos de 45°.
  final octante = (atan2(df, dc) / (pi / 4)).round();
  final angulo = octante * pi / 4;
  final sf = sin(angulo).round(), sc = cos(angulo).round();
  final paso = (sf != 0 && sc != 0) ? sqrt2 : 1.0;
  var pasos = (largo / paso).round();
  // Que no se salga del tablero.
  while (pasos > 0) {
    final f = inicio.$1 + sf * pasos, c = inicio.$2 + sc * pasos;
    if (f >= 0 && c >= 0 && f < tamano && c < tamano) break;
    pasos--;
  }
  return [
    for (var i = 0; i <= pasos; i++) (inicio.$1 + sf * i, inicio.$2 + sc * i),
  ];
}

/// Celdas en línea recta desde [inicio] hasta [fin] (horizontal, vertical o
/// diagonal). Si no forman una línea recta, devuelve solo [inicio].
List<Celda> celdasEnLinea(Celda inicio, Celda fin) {
  final df = fin.$1 - inicio.$1;
  final dc = fin.$2 - inicio.$2;
  if (df != 0 && dc != 0 && df.abs() != dc.abs()) return [inicio];
  final pasos = max(df.abs(), dc.abs());
  final sf = df.sign, sc = dc.sign;
  return [
    for (var i = 0; i <= pasos; i++) (inicio.$1 + sf * i, inicio.$2 + sc * i),
  ];
}
