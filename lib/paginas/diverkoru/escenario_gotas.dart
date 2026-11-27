import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';

/// Dibujo de Salva las gotas: el paisaje, las gotas y las salpicaduras.
/// Todo se pinta con [CustomPainter] para que se vea vivo y siga fluido.

/// Colores de cada gota (iguales en tema claro y oscuro para que se
/// reconozcan siempre).
Color colorGota(TipoGota tipo) => switch (tipo) {
  TipoGota.agua => const Color(0xFF29B6F6),
  TipoGota.aceite => const Color(0xFF8D6E63),
  TipoGota.acida => const Color(0xFFC0CA33),
  TipoGota.petroleo => const Color(0xFF212121),
  TipoGota.dorada => const Color(0xFFFFC107),
};

/// Una gota que va cayendo (posición en fracciones del ancho y del alto).
class GotaCayendo {
  GotaCayendo(this.x, this.tipo, {this.y = -0.05});
  final double x;
  final TipoGota tipo;
  double y;
}

/// Una gotita de una salpicadura.
class Particula {
  Particula({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radio,
    this.vida = 0.6,
  }) : vidaTotal = vida;

  double x, y, vx, vy;
  final Color color;

  /// Radio en fracción del ancho.
  final double radio;
  double vida;
  final double vidaTotal;

  /// Avanza [dt] segundos con gravedad. Devuelve false cuando se apaga.
  bool avanzar(double dt) {
    vy += 1.6 * dt;
    x += vx * dt;
    y += vy * dt;
    vida -= dt;
    return vida > 0;
  }
}

/// Lanza una salpicadura en (x, y).
List<Particula> salpicadura({
  required double x,
  required double y,
  required Color color,
  required Random azar,
  int cantidad = 12,
  double fuerza = 0.5,
  bool haciaArriba = true,
}) {
  return [
    for (var i = 0; i < cantidad; i++)
      () {
        final angulo = haciaArriba
            ? -pi / 2 + (azar.nextDouble() - 0.5) * pi * 0.9
            : azar.nextDouble() * 2 * pi;
        final v = fuerza * (0.5 + azar.nextDouble() * 0.7);
        return Particula(
          x: x,
          y: y,
          vx: cos(angulo) * v * 0.6,
          vy: sin(angulo) * v,
          color: color,
          radio: 0.006 + azar.nextDouble() * 0.009,
          vida: 0.45 + azar.nextDouble() * 0.35,
        );
      }(),
  ];
}

/// Momento del día según los puntos: 0 día, 1 tarde, 2 atardecer, 3 noche.
/// Cambia poco a poco (cada 25 gotas una etapa).
double faseDelDia(int puntos) => (puntos / 25).clamp(0.0, 3.0);

// Colores del cielo (arriba, abajo) en cada etapa.
const _cielos = [
  (Color(0xFF64B5F6), Color(0xFFE3F2FD)), // día
  (Color(0xFFFFB74D), Color(0xFFFFF8E1)), // tarde
  (Color(0xFF5E35B1), Color(0xFFFF8A65)), // atardecer
  (Color(0xFF0D1B4C), Color(0xFF283593)), // noche
];

(Color, Color) _cielo(double fase) {
  final i = fase.floor().clamp(0, _cielos.length - 2);
  final t = fase - i;
  final (a1, b1) = _cielos[i];
  final (a2, b2) = _cielos[i + 1];
  return (Color.lerp(a1, a2, t)!, Color.lerp(b1, b2, t)!);
}

/// El paisaje de fondo: cielo, sol o luna, estrellas, nubes, colinas y
/// pasto. [tiempo] mueve las nubes; [golpe] (0–1) tiñe de rojo al perder.
class PaisajePainter extends CustomPainter {
  PaisajePainter({
    required this.tiempo,
    required this.fase,
    required this.golpe,
  });

  final double tiempo;
  final double fase;
  final double golpe;

  /// Oscurece los colores de la tierra al caer la noche.
  double get _noche => ((fase - 1.5) / 1.5).clamp(0.0, 1.0) * 0.55;

  Color _sombra(Color c) => Color.lerp(c, Colors.black, _noche)!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final (arriba, abajo) = _cielo(fase);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * 0.8), [
          arriba,
          abajo,
        ]),
    );

    // Estrellas (de noche).
    final estrellas = ((fase - 2.2) / 0.8).clamp(0.0, 1.0);
    if (estrellas > 0) {
      final azar = Random(3);
      for (var i = 0; i < 40; i++) {
        final x = azar.nextDouble() * w, y = azar.nextDouble() * h * 0.55;
        final parpadeo = 0.6 + 0.4 * sin(tiempo * 2 + i);
        canvas.drawCircle(
          Offset(x, y),
          0.8 + azar.nextDouble() * 1.2,
          Paint()
            ..color = Colors.white.withValues(
              alpha: estrellas * parpadeo * 0.9,
            ),
        );
      }
    }

    // Sol: baja y se pone rojo; luego sale la luna.
    final alturaSol = 0.14 + (fase / 2.6).clamp(0.0, 1.0) * 0.5;
    final colorSol = Color.lerp(
      const Color(0xFFFFEB3B),
      const Color(0xFFFF5722),
      (fase / 2.4).clamp(0.0, 1.0),
    )!;
    final soleado = (1 - (fase - 2.3) / 0.5).clamp(0.0, 1.0);
    if (soleado > 0) {
      final centro = Offset(w * 0.8, h * alturaSol);
      final radio = w * (0.07 + 0.03 * (fase / 3));
      canvas.drawCircle(
        centro,
        radio * 2.2,
        Paint()
          ..color = colorSol.withValues(alpha: 0.18 * soleado)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(
        centro,
        radio,
        Paint()..color = colorSol.withValues(alpha: soleado),
      );
    }
    final luna = ((fase - 2.4) / 0.6).clamp(0.0, 1.0);
    if (luna > 0) {
      final centro = Offset(w * 0.2, h * 0.14);
      final radio = w * 0.055;
      canvas.drawCircle(
        centro,
        radio * 2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12 * luna)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawCircle(
        centro,
        radio,
        Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: luna),
      );
      // Sombra que la vuelve media luna.
      canvas.drawCircle(
        centro + Offset(radio * 0.45, -radio * 0.15),
        radio * 0.9,
        Paint()..color = _cielo(fase).$1.withValues(alpha: luna),
      );
    }

    // Nubes que avanzan despacio.
    final colorNube = Color.lerp(
      Colors.white,
      const Color(0xFF7986CB),
      ((fase - 1.8) / 1.2).clamp(0.0, 1.0),
    )!.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final velocidad = 0.012 + i * 0.004;
      final x = ((i * 0.31 + tiempo * velocidad) % 1.5) - 0.25;
      final y = 0.05 + (i % 3) * 0.07;
      _nube(
        canvas,
        Offset(x * w, y * h),
        w * (0.09 + (i % 2) * 0.03),
        colorNube,
      );
    }

    // Colinas: una lejana y otra cercana.
    _colina(
      canvas,
      size,
      base: 0.74,
      alto: 0.06,
      frecuencia: 1.3,
      desfase: 0.4,
      color: _sombra(const Color(0xFFA5D6A7)),
    );
    _colina(
      canvas,
      size,
      base: 0.82,
      alto: 0.05,
      frecuencia: 2.1,
      desfase: 1.7,
      color: _sombra(const Color(0xFF66BB6A)),
    );

    // Suelo: pasto con briznas y tierra.
    final suelo = h * 0.94;
    canvas.drawRect(
      Rect.fromLTWH(0, suelo, w, h - suelo),
      Paint()..color = _sombra(const Color(0xFF6D4C41)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, suelo - 6, w, 10),
      Paint()..color = _sombra(const Color(0xFF43A047)),
    );
    final brizna = Paint()
      ..color = _sombra(const Color(0xFF2E7D32))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final azar = Random(11);
    for (var x = 4.0; x < w; x += 9 + azar.nextDouble() * 8) {
      final alto = 5 + azar.nextDouble() * 7;
      final viento = sin(tiempo * 1.5 + x * 0.05) * 1.5;
      canvas.drawLine(
        Offset(x, suelo),
        Offset(x - 2 + viento, suelo - alto),
        brizna,
      );
      if (azar.nextDouble() < 0.12) {
        canvas.drawCircle(
          Offset(x - 2 + viento, suelo - alto - 2),
          2.4,
          Paint()
            ..color = _sombra(
              [
                const Color(0xFFFFEB3B),
                const Color(0xFFF06292),
                Colors.white,
              ][azar.nextInt(3)],
            ),
        );
      }
    }

    if (golpe > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.red.withValues(alpha: 0.22 * golpe),
      );
    }
  }

  void _nube(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color;
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c + Offset(r * 0.9, r * 0.2), r * 0.75, p);
    canvas.drawCircle(c + Offset(-r * 0.9, r * 0.25), r * 0.65, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - r * 1.5, c.dy, r * 3.1, r * 0.75),
        Radius.circular(r * 0.4),
      ),
      p,
    );
  }

  void _colina(
    Canvas canvas,
    Size size, {
    required double base,
    required double alto,
    required double frecuencia,
    required double desfase,
    required Color color,
  }) {
    final w = size.width, h = size.height;
    final camino = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 6) {
      final y =
          base - alto * (0.5 + 0.5 * sin(x / w * pi * frecuencia + desfase));
      camino.lineTo(x, y * h);
    }
    camino
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(camino, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PaisajePainter old) =>
      old.tiempo != tiempo || old.fase != fase || old.golpe != golpe;
}

/// Las gotas (con brillo y estela) y las salpicaduras.
class GotasPainter extends CustomPainter {
  GotasPainter({
    required this.gotas,
    required this.particulas,
    required this.velocidad,
    required this.tiempo,
  });

  final List<GotaCayendo> gotas;
  final List<Particula> particulas;

  /// Velocidad de caída actual: alarga las estelas.
  final double velocidad;
  final double tiempo;

  static final _marcas = <(TipoGota, int), TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w * 0.032;
    for (final gota in gotas) {
      dibujarGota(
        canvas,
        Offset(gota.x * w, gota.y * h),
        r,
        gota.tipo,
        tiempo: tiempo,
        estela: r * (1.5 + velocidad * 4),
      );
    }
    for (final p in particulas) {
      final vida = (p.vida / p.vidaTotal).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * w, p.y * h),
        p.radio * w * (0.5 + 0.5 * vida),
        Paint()..color = p.color.withValues(alpha: vida),
      );
    }
  }

  /// Dibuja una gota con forma de lágrima centrada en [c] con radio [r].
  static void dibujarGota(
    Canvas canvas,
    Offset c,
    double r,
    TipoGota tipo, {
    double tiempo = 0,
    double estela = 0,
  }) {
    final color = colorGota(tipo);
    final punta = c + Offset(0, -r * 1.45);

    if (estela > 0) {
      canvas.drawLine(
        punta,
        punta - Offset(0, estela),
        Paint()
          ..strokeWidth = r * 0.55
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(punta, punta - Offset(0, estela), [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0),
          ]),
      );
    }

    if (tipo == TipoGota.dorada) {
      canvas.drawCircle(
        c,
        r * 2.1,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
      );
    }

    final forma = Path()
      ..moveTo(punta.dx, punta.dy)
      ..cubicTo(
        c.dx + r * 0.25,
        c.dy - r * 0.95,
        c.dx + r,
        c.dy - r * 0.2,
        c.dx + r,
        c.dy + r * 0.25,
      )
      ..arcToPoint(
        Offset(c.dx - r, c.dy + r * 0.25),
        radius: Radius.circular(r),
      )
      ..cubicTo(
        c.dx - r,
        c.dy - r * 0.2,
        c.dx - r * 0.25,
        c.dy - r * 0.95,
        punta.dx,
        punta.dy,
      )
      ..close();
    final claro = Color.lerp(color, Colors.white, 0.45)!;
    canvas.drawPath(
      forma,
      Paint()
        ..shader = ui.Gradient.linear(
          c + Offset(-r, -r),
          c + Offset(r, r * 1.2),
          [claro, color],
        ),
    );
    canvas.drawPath(
      forma,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, r * 0.09)
        ..color = Color.lerp(color, Colors.black, 0.45)!,
    );
    // Brillo.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-r * 0.38, -r * 0.05),
        width: r * 0.32,
        height: r * 0.6,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    switch (tipo) {
      case TipoGota.petroleo:
        // Reflejo de arcoíris, como el petróleo en el agua.
        canvas.drawArc(
          Rect.fromCircle(center: c + Offset(0, r * 0.25), radius: r * 0.6),
          pi * 0.15,
          pi * 0.7,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.16
            ..shader = ui.Gradient.sweep(
              c,
              const [
                Color(0xFFE040FB),
                Color(0xFF40C4FF),
                Color(0xFF69F0AE),
                Color(0xFFE040FB),
              ],
              const [0.0, 0.33, 0.66, 1.0],
            ),
        );
      case TipoGota.acida:
        // Burbujas.
        final burbuja = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(c + Offset(r * 0.35, r * 0.35), r * 0.18, burbuja);
        canvas.drawCircle(c + Offset(r * 0.05, r * 0.6), r * 0.11, burbuja);
      case TipoGota.dorada:
        // Destello que gira.
        final destello = Paint()
          ..color = Colors.white
          ..strokeWidth = max(1.0, r * 0.12)
          ..strokeCap = StrokeCap.round;
        final a = tiempo * 3;
        final centro = c + Offset(r * 0.95, -r * 0.9);
        for (var i = 0; i < 2; i++) {
          final d = Offset(cos(a + i * pi / 2), sin(a + i * pi / 2)) * r * 0.4;
          canvas.drawLine(centro - d, centro + d, destello);
        }
      case TipoGota.agua || TipoGota.aceite:
        break;
    }

    // Marca para distinguirlas sin depender solo del color.
    final simbolo = switch (tipo) {
      TipoGota.aceite => '🍳',
      TipoGota.acida => '☠',
      TipoGota.petroleo => '⚫',
      _ => null,
    };
    if (simbolo != null) {
      final tam = (r * 0.8).round();
      final texto = _marcas.putIfAbsent(
        (tipo, tam),
        () => TextPainter(
          text: TextSpan(
            text: simbolo,
            style: TextStyle(
              fontSize: tam.toDouble(),
              color: tipo == TipoGota.acida ? Colors.black87 : null,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      texto.paint(
        canvas,
        c + Offset(-texto.width / 2, r * 0.3 - texto.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(GotasPainter old) => true;
}

/// Gota suelta para la leyenda.
class IconoGota extends StatelessWidget {
  const IconoGota({super.key, required this.tipo, this.tamano = 20});

  final TipoGota tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(tamano, tamano),
      painter: _IconoGotaPainter(tipo),
    );
  }
}

class _IconoGotaPainter extends CustomPainter {
  _IconoGotaPainter(this.tipo);
  final TipoGota tipo;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.32;
    GotasPainter.dibujarGota(
      canvas,
      Offset(size.width / 2, size.height * 0.58),
      r,
      tipo,
    );
  }

  @override
  bool shouldRepaint(_IconoGotaPainter old) => old.tipo != tipo;
}
