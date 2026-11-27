import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tema_korulab.dart';

/// Estado de una parada del sendero.
enum EstadoParada { completada, actual, disponible, bloqueada }

/// Una parada (unidad) del sendero de Ruta Eko.
class ParadaSendero {
  const ParadaSendero({
    required this.titulo,
    required this.estado,
    required this.progreso,
    required this.onTap,
    this.subtitulo = '',
    this.detalle = '',
    this.menu,
  });

  final String titulo;
  final String subtitulo;

  /// Texto pequeño bajo el título, p. ej. "3/5 actividades".
  final String detalle;
  final EstadoParada estado;

  /// Avance de la unidad entre 0 y 1.
  final double progreso;
  final VoidCallback onTap;

  /// Menú de gestión (editar/eliminar) para quien administra la unidad.
  final Widget? menu;
}

/// Sendero serpenteante: un camino dibujado que une las paradas en zigzag,
/// con la etiqueta de cada unidad al otro lado del camino.
class SenderoRutaEko extends StatelessWidget {
  const SenderoRutaEko({super.key, required this.paradas});

  final List<ParadaSendero> paradas;

  static const _alturaParada = 150.0;
  static const _margenSuperior = 96.0;
  static const _margenInferior = 120.0;
  static const _diametroNodo = 76.0;

  // Posición horizontal (fracción del ancho) de cada parada: zigzag suave.
  static double _x(int i) => i.isEven ? 0.24 : 0.76;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final alto =
            _margenSuperior + paradas.length * _alturaParada + _margenInferior;
        final centros = [
          for (var i = 0; i < paradas.length; i++)
            Offset(
              ancho * _x(i),
              _margenSuperior + i * _alturaParada + _alturaParada / 2,
            ),
        ];
        final inicio = Offset(ancho * 0.5, 34);
        final meta = Offset(ancho * 0.5, alto - 46);
        // Hasta dónde llega el tramo recorrido: la parada actual o la última
        // completada.
        final recorridas = paradas.lastIndexWhere(
          (p) =>
              p.estado == EstadoParada.completada ||
              p.estado == EstadoParada.actual,
        );
        final todasCompletas =
            paradas.isNotEmpty &&
            paradas.every((p) => p.estado == EstadoParada.completada);

        return SizedBox(
          height: alto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CaminoPainter(
                    puntos: [inicio, ...centros, meta],
                    // +1 por el punto de inicio.
                    recorridoHasta: todasCompletas
                        ? centros.length + 1
                        : recorridas + 1,
                    colorCamino: theme.colorScheme.surfaceContainerHighest,
                    colorBorde: theme.colorScheme.outlineVariant,
                    colorRecorrido: koru.hoja.withValues(alpha: 0.35),
                    colorLinea: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.35,
                    ),
                    alturaTramo: _alturaParada,
                  ),
                ),
              ),
              ..._decoraciones(centros, ancho, koru),
              _marcador(
                context,
                centro: inicio,
                icono: Icons.flag_rounded,
                texto: 'Inicio',
                color: koru.hoja,
              ),
              _marcador(
                context,
                centro: meta,
                icono: Icons.emoji_events_rounded,
                texto: todasCompletas ? '¡Meta alcanzada!' : 'Meta',
                color: koru.oro,
              ),
              for (var i = 0; i < paradas.length; i++) ...[
                Positioned(
                  left: centros[i].dx - _diametroNodo / 2,
                  top: centros[i].dy - _diametroNodo / 2,
                  child: _NodoParada(parada: paradas[i], numero: i + 1),
                ),
                _etiqueta(context, i, centros[i], ancho),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _marcador(
    BuildContext context, {
    required Offset centro,
    required IconData icono,
    required String texto,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      top: centro.dy - 22,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 20, color: color),
              const SizedBox(width: 6),
              Text(texto, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(BuildContext context, int i, Offset centro, double ancho) {
    final parada = paradas[i];
    final aLaDerecha = _x(i) < 0.5;
    const separacion = _diametroNodo / 2 + 10;
    final anchoEtiqueta = aLaDerecha
        ? ancho - centro.dx - separacion
        : centro.dx - separacion;
    return Positioned(
      top: centro.dy - 50,
      left: aLaDerecha ? centro.dx + separacion : null,
      right: aLaDerecha ? null : ancho - centro.dx + separacion,
      width: anchoEtiqueta.clamp(140, 300),
      child: _EtiquetaParada(
        parada: parada,
        numero: i + 1,
        alineadaDerecha: !aLaDerecha,
      ),
    );
  }

  // Árboles y plantas tenues al lado del camino, para dar sensación de sendero.
  List<Widget> _decoraciones(
    List<Offset> centros,
    double ancho,
    KoruTokens koru,
  ) {
    const iconos = [
      Icons.park_rounded,
      Icons.forest_rounded,
      Icons.grass_rounded,
      Icons.local_florist_rounded,
    ];
    return [
      for (var i = 0; i < centros.length; i++)
        if (i % 2 == 1 || i == 0)
          Positioned(
            left: _x(i) < 0.5 ? 6 : null,
            right: _x(i) < 0.5 ? null : 6,
            top: centros[i].dy + _alturaParada / 2 - 22,
            child: Icon(
              iconos[i % iconos.length],
              size: 30,
              color: koru.hoja.withValues(alpha: 0.22),
            ),
          ),
    ];
  }
}

class _NodoParada extends StatelessWidget {
  const _NodoParada({required this.parada, required this.numero});

  final ParadaSendero parada;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final d = SenderoRutaEko._diametroNodo;

    final (
      Color fondo,
      Color frente,
      IconData icono,
      Gradient? degradado,
    ) = switch (parada.estado) {
      EstadoParada.completada => (
        koru.hoja,
        theme.colorScheme.onPrimary,
        Icons.check_rounded,
        null,
      ),
      EstadoParada.actual => (
        koru.hoja,
        koru.textoHero,
        Icons.play_arrow_rounded,
        koru.degradadoHero,
      ),
      EstadoParada.disponible => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.eco_rounded,
        null,
      ),
      EstadoParada.bloqueada => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.lock_rounded,
        null,
      ),
    };

    final nodo = Semantics(
      button: true,
      label: 'Unidad $numero: ${parada.titulo}',
      child: GestureDetector(
        onTap: parada.onTap,
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo de progreso de la unidad.
              SizedBox(
                width: d,
                height: d,
                child: CircularProgressIndicator(
                  value: parada.estado == EstadoParada.bloqueada
                      ? 0
                      : parada.progreso,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: koru.hoja,
                  backgroundColor: theme.colorScheme.outlineVariant,
                ),
              ),
              Container(
                width: d - 16,
                height: d - 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: degradado == null ? fondo : null,
                  gradient: degradado,
                  boxShadow: parada.estado == EstadoParada.bloqueada
                      ? null
                      : [
                          BoxShadow(
                            color: koru.hoja.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Icon(icono, color: frente, size: 30),
              ),
            ],
          ),
        ),
      ),
    );

    if (parada.estado != EstadoParada.actual) return nodo;
    return _Pulso(color: koru.hoja, diametro: d, child: nodo);
  }
}

/// Anillo que late alrededor de la parada actual.
class _Pulso extends StatefulWidget {
  const _Pulso({
    required this.color,
    required this.diametro,
    required this.child,
  });

  final Color color;
  final double diametro;
  final Widget child;

  @override
  State<_Pulso> createState() => _PulsoState();
}

class _PulsoState extends State<_Pulso> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_controller.value);
            return IgnorePointer(
              child: Container(
                width: widget.diametro * (1 + 0.35 * t),
                height: widget.diametro * (1 + 0.35 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                    width: 3,
                  ),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _EtiquetaParada extends StatelessWidget {
  const _EtiquetaParada({
    required this.parada,
    required this.numero,
    required this.alineadaDerecha,
  });

  final ParadaSendero parada;
  final int numero;
  final bool alineadaDerecha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final bloqueada = parada.estado == EstadoParada.bloqueada;
    final actual = parada.estado == EstadoParada.actual;
    final alineacion = alineadaDerecha
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alineadaDerecha ? TextAlign.right : TextAlign.left;

    return Opacity(
      opacity: bloqueada ? 0.65 : 1,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KoruRadius.m),
          side: BorderSide(
            color: actual ? koru.hoja : theme.colorScheme.outlineVariant,
            width: actual ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: parada.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: alineacion,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alineadaDerecha && parada.menu != null)
                      SizedBox(height: 28, child: parada.menu),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (actual ? koru.hoja : theme.colorScheme.outline)
                                  .withValues(alpha: actual ? 0.18 : 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          actual ? 'UNIDAD $numero · AHORA' : 'UNIDAD $numero',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: actual
                                ? koru.hoja
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    if (!alineadaDerecha && parada.menu != null)
                      SizedBox(height: 28, child: parada.menu),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  parada.titulo,
                  textAlign: textAlign,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (parada.subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    parada.subtitulo,
                    textAlign: textAlign,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (parada.detalle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    parada.detalle,
                    textAlign: textAlign,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: parada.estado == EstadoParada.completada
                          ? koru.hoja
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja el camino: una banda ancha con borde, el tramo ya recorrido en
/// verde y una línea discontinua por el centro.
class _CaminoPainter extends CustomPainter {
  _CaminoPainter({
    required this.puntos,
    required this.recorridoHasta,
    required this.colorCamino,
    required this.colorBorde,
    required this.colorRecorrido,
    required this.colorLinea,
    required this.alturaTramo,
  });

  final List<Offset> puntos;

  /// Índice del último punto del tramo recorrido.
  final int recorridoHasta;
  final Color colorCamino;
  final Color colorBorde;
  final Color colorRecorrido;
  final Color colorLinea;
  final double alturaTramo;

  Path _trazar(int desde, int hasta) {
    final path = Path()..moveTo(puntos[desde].dx, puntos[desde].dy);
    for (var i = desde + 1; i <= hasta; i++) {
      final a = puntos[i - 1];
      final b = puntos[i];
      final tiron = math.min((b.dy - a.dy) * 0.55, alturaTramo * 0.6);
      path.cubicTo(a.dx, a.dy + tiron, b.dx, b.dy - tiron, b.dx, b.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;
    final completo = _trazar(0, puntos.length - 1);

    Paint trazo(Color color, double ancho) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = ancho
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(completo, trazo(colorBorde, 34));
    canvas.drawPath(completo, trazo(colorCamino, 28));

    final hasta = recorridoHasta.clamp(0, puntos.length - 1);
    if (hasta > 0) {
      canvas.drawPath(_trazar(0, hasta), trazo(colorRecorrido, 28));
    }

    // Línea central discontinua.
    final linea = trazo(colorLinea, 3);
    for (final metrica in completo.computeMetrics()) {
      var d = 0.0;
      while (d < metrica.length) {
        final segmento = metrica.extractPath(
          d,
          math.min(d + 12, metrica.length),
        );
        canvas.drawPath(segmento, linea);
        d += 24;
      }
    }
  }

  @override
  bool shouldRepaint(_CaminoPainter old) =>
      old.puntos.length != puntos.length ||
      old.recorridoHasta != recorridoHasta ||
      old.colorCamino != colorCamino ||
      old.colorRecorrido != colorRecorrido ||
      !_mismosPuntos(old.puntos);

  bool _mismosPuntos(List<Offset> otros) {
    for (var i = 0; i < puntos.length; i++) {
      if (otros[i] != puntos[i]) return false;
    }
    return true;
  }
}
