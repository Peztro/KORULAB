import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tipo de lluvia de partículas al terminar una lección.
enum TipoCelebracion {
  /// Confeti que sale disparado hacia arriba y cae (resultado perfecto).
  confeti,

  /// Hojas que caen girando suavemente (buen resultado).
  hojas,

  /// Unas pocas chispas que suben despacio (resultado aceptable).
  chispas,
}

/// Capa de partículas animadas que se pinta encima del contenido.
/// No recibe toques, así que no bloquea los botones de debajo.
class LluviaCelebracion extends StatefulWidget {
  const LluviaCelebracion({
    super.key,
    required this.tipo,
    required this.colores,
    this.semilla = 7,
  });

  final TipoCelebracion tipo;
  final List<Color> colores;

  /// Semilla fija para que la animación sea reproducible.
  final int semilla;

  @override
  State<LluviaCelebracion> createState() => _LluviaCelebracionState();
}

class _LluviaCelebracionState extends State<LluviaCelebracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particula> _particulas;

  Duration get _duracion => switch (widget.tipo) {
    TipoCelebracion.confeti => const Duration(milliseconds: 3600),
    TipoCelebracion.hojas => const Duration(milliseconds: 5200),
    TipoCelebracion.chispas => const Duration(milliseconds: 3000),
  };

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.semilla);
    final cantidad = switch (widget.tipo) {
      TipoCelebracion.confeti => 90,
      TipoCelebracion.hojas => 26,
      TipoCelebracion.chispas => 18,
    };
    _particulas = List.generate(
      cantidad,
      (i) => _Particula.aleatoria(random, widget.colores, widget.tipo),
    );
    _controller = AnimationController(vsync: this, duration: _duracion)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _LluviaPainter(
              particulas: _particulas,
              segundos: _controller.value * _duracion.inMilliseconds / 1000,
              duracion: _duracion.inMilliseconds / 1000,
              tipo: widget.tipo,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particula {
  _Particula({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.giro,
    required this.velocidadGiro,
    required this.tamano,
    required this.color,
    required this.fase,
    required this.retraso,
    required this.forma,
  });

  factory _Particula.aleatoria(
    math.Random r,
    List<Color> colores,
    TipoCelebracion tipo,
  ) {
    double entre(double a, double b) => a + r.nextDouble() * (b - a);
    final color = colores[r.nextInt(colores.length)];
    switch (tipo) {
      case TipoCelebracion.confeti:
        // Sale desde dos cañones en las esquinas inferiores.
        final izquierda = r.nextBool();
        return _Particula(
          x: izquierda ? entre(0.0, 0.15) : entre(0.85, 1.0),
          y: entre(0.55, 0.7),
          vx: (izquierda ? 1 : -1) * entre(80, 340),
          vy: -entre(650, 1150),
          giro: entre(0, math.pi * 2),
          velocidadGiro: entre(-9, 9),
          tamano: entre(7, 13),
          color: color,
          fase: entre(0, math.pi * 2),
          retraso: entre(0, 0.35),
          forma: r.nextInt(3),
        );
      case TipoCelebracion.hojas:
        return _Particula(
          x: entre(0.0, 1.0),
          y: -0.05,
          vx: entre(-20, 20),
          vy: entre(110, 190),
          giro: entre(0, math.pi * 2),
          velocidadGiro: entre(-1.5, 1.5),
          tamano: entre(14, 24),
          color: color,
          fase: entre(0, math.pi * 2),
          retraso: entre(0, 2.2),
          forma: 0,
        );
      case TipoCelebracion.chispas:
        return _Particula(
          x: entre(0.15, 0.85),
          y: entre(0.35, 0.6),
          vx: entre(-25, 25),
          vy: -entre(40, 110),
          giro: 0,
          velocidadGiro: 0,
          tamano: entre(3, 6),
          color: color,
          fase: entre(0, math.pi * 2),
          retraso: entre(0, 1.2),
          forma: 0,
        );
    }
  }

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double giro;
  final double velocidadGiro;
  final double tamano;
  final Color color;
  final double fase;
  final double retraso;
  final int forma;
}

class _LluviaPainter extends CustomPainter {
  _LluviaPainter({
    required this.particulas,
    required this.segundos,
    required this.duracion,
    required this.tipo,
  });

  final List<_Particula> particulas;
  final double segundos;
  final double duracion;
  final TipoCelebracion tipo;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particulas) {
      final s = segundos - p.retraso;
      if (s <= 0) continue;
      // Se desvanecen en el último 25 % de la animación.
      final restante = (duracion - segundos) / (duracion * 0.25);
      final opacidad = restante.clamp(0.0, 1.0);
      if (opacidad <= 0) continue;

      switch (tipo) {
        case TipoCelebracion.confeti:
          const gravedad = 1300.0;
          final aire = math.exp(-0.6 * s); // frenado del aire
          final px = p.x * size.width + p.vx * s * aire;
          final py = p.y * size.height + p.vy * s + 0.5 * gravedad * s * s;
          if (py > size.height + 20) continue;
          final angulo = p.giro + p.velocidadGiro * s;
          // El "aleteo" del papel se simula escalando un eje.
          final aleteo = math.cos(s * 9 + p.fase).abs() * 0.8 + 0.2;
          canvas.save();
          canvas.translate(px, py);
          canvas.rotate(angulo);
          canvas.scale(1, aleteo);
          paint.color = p.color.withValues(alpha: opacidad);
          switch (p.forma) {
            case 0:
              canvas.drawRect(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: p.tamano,
                  height: p.tamano * 0.55,
                ),
                paint,
              );
            case 1:
              canvas.drawCircle(Offset.zero, p.tamano * 0.38, paint);
            default:
              final path = Path()
                ..moveTo(0, -p.tamano * 0.5)
                ..lineTo(p.tamano * 0.45, p.tamano * 0.4)
                ..lineTo(-p.tamano * 0.45, p.tamano * 0.4)
                ..close();
              canvas.drawPath(path, paint);
          }
          canvas.restore();
        case TipoCelebracion.hojas:
          final px =
              p.x * size.width + p.vx * s + math.sin(s * 1.6 + p.fase) * 34;
          final py = p.y * size.height + p.vy * s;
          if (py > size.height + 30) continue;
          final angulo = p.giro + math.sin(s * 1.6 + p.fase) * 0.9;
          canvas.save();
          canvas.translate(px, py);
          canvas.rotate(angulo);
          paint.color = p.color.withValues(alpha: opacidad * 0.9);
          canvas.drawPath(_hoja(p.tamano), paint);
          // Nervio central.
          canvas.drawLine(
            Offset(0, -p.tamano * 0.45),
            Offset(0, p.tamano * 0.5),
            Paint()
              ..color = Colors.white.withValues(alpha: opacidad * 0.35)
              ..strokeWidth = 1.2,
          );
          canvas.restore();
        case TipoCelebracion.chispas:
          final px = p.x * size.width + p.vx * s;
          final py = p.y * size.height + p.vy * s;
          final brillo = (math.sin(s * 6 + p.fase) * 0.5 + 0.5) * opacidad;
          paint.color = p.color.withValues(alpha: brillo);
          canvas.drawPath(_estrella(Offset(px, py), p.tamano), paint);
      }
    }
  }

  Path _hoja(double t) => Path()
    ..moveTo(0, -t * 0.55)
    ..quadraticBezierTo(t * 0.45, -t * 0.1, 0, t * 0.55)
    ..quadraticBezierTo(-t * 0.45, -t * 0.1, 0, -t * 0.55)
    ..close();

  // Destello de cuatro puntas.
  Path _estrella(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r * 2)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
    ..close();

  @override
  bool shouldRepaint(_LluviaPainter old) => old.segundos != segundos;
}
