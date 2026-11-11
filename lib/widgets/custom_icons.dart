import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────
// Iconos personalizados mejorados para KORULAB
// Reemplaza los iconos genéricos por diseños más atractivos
// ─────────────────────────────────────────────────────────────────

/// Icono de libro animado con páginas que se abren
class AnimatedBookIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedBookIcon({
    super.key,
    this.size = 40,
    this.color = Colors.blue,
  });

  @override
  State<AnimatedBookIcon> createState() => _AnimatedBookIconState();
}

class _AnimatedBookIconState extends State<AnimatedBookIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _openAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _openAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _openAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.8),
          painter: AnimatedBookPainter(
            progress: _openAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class AnimatedBookPainter extends CustomPainter {
  final double progress;
  final Color color;

  AnimatedBookPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Portada izquierda
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2 - 2, size.height),
      paint,
    );

    // Portada derecha
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 + 2, 0, size.width / 2 - 2, size.height),
      paint,
    );

    // Línea central (lomo)
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Líneas de página abiertas (animadas)
    final pageProgress = (progress * 2 - 1).clamp(0, 1).toDouble();
    final leftX = size.width / 4 - (size.width / 8 * pageProgress);
    final rightX = (size.width * 3 / 4) + (size.width / 8 * pageProgress);

    canvas.drawLine(
      Offset(leftX, size.height * 0.3),
      Offset(leftX, size.height * 0.7),
      paint..strokeWidth = 1.5,
    );

    canvas.drawLine(
      Offset(rightX, size.height * 0.3),
      Offset(rightX, size.height * 0.7),
      paint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(AnimatedBookPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Icono de juego/puzzle animado con piezas
class AnimatedPuzzleIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedPuzzleIcon({
    super.key,
    this.size = 40,
    this.color = Colors.purple,
  });

  @override
  State<AnimatedPuzzleIcon> createState() => _AnimatedPuzzleIconState();
}

class _AnimatedPuzzleIconState extends State<AnimatedPuzzleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _pieceAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _pieceAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: Offset(0.3 * (index % 2 == 0 ? 1 : -1),
            0.3 * (index < 2 ? 1 : -1)),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval((index * 0.2), (index * 0.2) + 0.6,
            curve: Curves.elasticOut),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pieza superior izquierda
            Transform.translate(
              offset: Offset(_pieceAnimations[0].value.dx * 12,
                  _pieceAnimations[0].value.dy * 12),
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Pieza superior derecha
            Transform.translate(
              offset: Offset(_pieceAnimations[1].value.dx * 12,
                  _pieceAnimations[1].value.dy * 12),
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Pieza inferior izquierda
            Transform.translate(
              offset: Offset(_pieceAnimations[2].value.dx * 12,
                  _pieceAnimations[2].value.dy * 12),
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Pieza inferior derecha
            Transform.translate(
              offset: Offset(_pieceAnimations[3].value.dx * 12,
                  _pieceAnimations[3].value.dy * 12),
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Icono de estrella con brillo animado
class AnimatedStarIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool filled;

  const AnimatedStarIcon({
    super.key,
    this.size = 40,
    this.color = Colors.amber,
    this.filled = true,
  });

  @override
  State<AnimatedStarIcon> createState() => _AnimatedStarIconState();
}

class _AnimatedStarIconState extends State<AnimatedStarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _rotateAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: StarPainter(
              progress: _glowAnimation.value,
              color: widget.color,
              filled: widget.filled,
            ),
          ),
        );
      },
    );
  }
}

class StarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool filled;

  StarPainter({
    required this.progress,
    required this.color,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * progress)
      ..style = PaintingStyle.fill;

    // Glow
    canvas.drawCircle(center, radius * 1.3, glowPaint);

    // Estrella
    _drawStar(canvas, center, radius, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final isOuter = i.isEven;
      final r = isOuter ? radius : radius * 0.4;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Icono de corazón palpitante
class PulsatingHeartIcon extends StatefulWidget {
  final double size;
  final Color color;

  const PulsatingHeartIcon({
    super.key,
    this.size = 40,
    this.color = Colors.red,
  });

  @override
  State<PulsatingHeartIcon> createState() => _PulsatingHeartIconState();
}

class _PulsatingHeartIconState extends State<PulsatingHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.favorite,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Icono de engranaje giratorio
class RotatingGearIcon extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const RotatingGearIcon({
    super.key,
    this.size = 40,
    this.color = Colors.grey,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<RotatingGearIcon> createState() => _RotatingGearIconState();
}

class _RotatingGearIconState extends State<RotatingGearIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.settings,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}

/// Badge animado con contador
class AnimatedBadge extends StatefulWidget {
  final int count;
  final Color backgroundColor;
  final Color textColor;
  final Widget child;

  const AnimatedBadge({
    super.key,
    required this.count,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    required this.child,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        widget.child,
        if (widget.count > 0)
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  child: Text(
                    widget.count > 99 ? '99+' : widget.count.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Funciones auxiliares
const pi = math.pi;

double _cos(double angle) => math.cos(angle);
double _sin(double angle) => math.sin(angle);
