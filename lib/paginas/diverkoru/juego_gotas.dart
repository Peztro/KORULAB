import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../juegos/datos_juegos.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import 'fin_de_juego.dart';

/// Salva las gotas: mueve la planta para atrapar el agua limpia y esquiva
/// las gotas contaminadas. Cada gota limpia que cae al suelo cuesta una vida.
class JuegoGotas extends StatefulWidget {
  const JuegoGotas({super.key});

  @override
  State<JuegoGotas> createState() => _JuegoGotasState();
}

class _Gota {
  _Gota(this.x, this.tipo);
  final double x;
  final TipoGota tipo;
  double y = -0.05;
}

/// Texto que sube y se desvanece sobre la planta ("+1", "-2 ❤").
class _Etiqueta {
  _Etiqueta(this.texto, this.color, this.x);
  final String texto;
  final Color color;
  final double x;
  double edad = 0;
}

/// Colores de cada gota (iguales en tema claro y oscuro para que se
/// reconozcan siempre).
Color colorGota(TipoGota tipo) => switch (tipo) {
  TipoGota.agua => const Color(0xFF29B6F6),
  TipoGota.aceite => const Color(0xFF8D6E63),
  TipoGota.acida => const Color(0xFFC0CA33),
  TipoGota.petroleo => const Color(0xFF212121),
  TipoGota.dorada => const Color(0xFFFFC107),
};

class _JuegoGotasState extends State<JuegoGotas> with TickerProviderStateMixin {
  static const _anchoPlanta = 0.22;
  static const _altoPlanta = 0.86;
  static const _vidaEtiqueta = 0.9;

  final _azar = Random();
  late final Ticker _ticker = createTicker(_avanzar);
  Duration _anterior = Duration.zero;

  /// Salto de alegría al atrapar una gota buena.
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Sacudida al atrapar una gota mala.
  late final AnimationController _sacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  final _gotas = <_Gota>[];
  final _etiquetas = <_Etiqueta>[];
  double _planta = 0.5;

  /// Dónde cayó la última gota buena (para colocar las siguientes).
  double? _ultimaBuena;
  double _hastaLaSiguiente = 0.6;
  int _puntos = 0;
  int _vidas = vidasGotas;
  int _atrapadas = 0;
  bool _terminado = false;

  /// Destello rojo del fondo al perder una vida.
  bool _golpe = false;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  void _empezar() {
    _gotas.clear();
    _etiquetas.clear();
    _planta = 0.5;
    _ultimaBuena = null;
    _hastaLaSiguiente = 0.6;
    _puntos = 0;
    _vidas = vidasGotas;
    _atrapadas = 0;
    _terminado = false;
    _anterior = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
    setState(() {});
  }

  void _avanzar(Duration transcurrido) {
    final dt = _anterior == Duration.zero
        ? 0.0
        : (transcurrido - _anterior).inMicroseconds / 1e6;
    _anterior = transcurrido;
    if (dt <= 0 || dt > 0.1) return; // primer cuadro o tirón

    final velocidad = velocidadGotas(_puntos);

    _hastaLaSiguiente -= dt;
    if (_hastaLaSiguiente <= 0) {
      _hastaLaSiguiente = intervaloGotas(_puntos);
      // La gota buena más baja: hacia donde va el jugador.
      _Gota? objetivo;
      for (final g in _gotas) {
        if (!g.tipo.esMala && (objetivo == null || g.y > objetivo.y)) {
          objetivo = g;
        }
      }
      for (final nueva in planearGotas(
        puntos: _puntos,
        ultimaBuena: _ultimaBuena,
        objetivo: objetivo?.x,
        azar: _azar,
      )) {
        if (!nueva.tipo.esMala) _ultimaBuena = nueva.x;
        _gotas.add(_Gota(nueva.x, nueva.tipo)..y = nueva.y);
      }
    }

    for (final gota in [..._gotas]) {
      gota.y += velocidad * dt;
      final enPlanta =
          gota.y >= _altoPlanta - 0.03 &&
          gota.y <= _altoPlanta + 0.04 &&
          (gota.x - _planta).abs() <= _anchoPlanta / 2;
      if (enPlanta) {
        _gotas.remove(gota);
        _atrapar(gota.tipo);
      } else if (gota.y > 1.02) {
        _gotas.remove(gota);
        if (gota.tipo.cuestaVidaSiCae) _perderVidas(1, gota.x, vibrar: false);
      }
    }

    for (final e in [..._etiquetas]) {
      e.edad += dt;
      if (e.edad >= _vidaEtiqueta) _etiquetas.remove(e);
    }

    if (_vidas <= 0) {
      _ticker.stop();
      _terminado = true;
    }
    setState(() {});
  }

  void _atrapar(TipoGota tipo) {
    final cambio = tipo.vidasAlAtrapar;
    if (cambio < 0) {
      _perderVidas(-cambio, _planta, vibrar: true);
      _sacudida.forward(from: 0);
      return;
    }
    _puntos += tipo.puntosAlAtrapar;
    _atrapadas++;
    _vidas += cambio;
    _salto.forward(from: 0);
    final koru = context.koru;
    _etiquetas.add(
      cambio > 0
          ? _Etiqueta('+1 ❤', koru.oro, _planta)
          : _Etiqueta('+1', koru.agua, _planta),
    );
    if (cambio > 0) HapticFeedback.selectionClick();
  }

  void _perderVidas(int cuantas, double x, {required bool vibrar}) {
    _vidas -= cuantas;
    _etiquetas.add(_Etiqueta('-$cuantas ❤', context.koru.fuego, x));
    if (vibrar) HapticFeedback.mediumImpact();
    _golpe = true;
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _golpe = false);
    });
  }

  void _moverPlanta(double dx, double ancho) {
    setState(() {
      _planta = (dx / ancho).clamp(_anchoPlanta / 2, 1 - _anchoPlanta / 2);
    });
  }

  void _pausar() => _ticker.stop();

  void _reanudar() {
    if (_terminado || !mounted) return;
    _anterior = Duration.zero;
    _ticker.start();
  }

  Future<bool> _confirmarSalida() =>
      SalidaDeJuego.preguntar(context, pausar: _pausar, reanudar: _reanudar);

  @override
  void dispose() {
    _ticker.dispose();
    _salto.dispose();
    _sacudida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return SalidaDeJuego(
      enJuego: !_terminado,
      pausar: _pausar,
      reanudar: _reanudar,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salva las gotas'),
          actions: [
            if (!_terminado) ...[
              MarcadorJuego(
                icono: Icons.favorite_rounded,
                texto: '$_vidas',
                color: koru.fuego,
              ),
              MarcadorJuego(
                icono: Icons.water_drop_rounded,
                texto: '$_puntos',
                color: koru.agua,
              ),
            ],
            BotonInicio(confirmar: _terminado ? null : _confirmarSalida),
          ],
        ),
        body: _terminado
            ? FinDeJuego(
                juego: JuegoDiverKoru.gotas,
                valor: _puntos,
                resumen: 'Salvaste $_atrapadas gotas de agua',
                onRepetir: _empezar,
              )
            : LayoutBuilder(
                builder: (context, r) {
                  final ancho = r.maxWidth;
                  final alto = r.maxHeight;
                  final tamGota = ancho * 0.09;
                  final yPlanta =
                      _altoPlanta * alto - ancho * _anchoPlanta * 0.35;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _moverPlanta(d.localPosition.dx, ancho),
                    onPanUpdate: (d) => _moverPlanta(d.localPosition.dx, ancho),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            koru.agua.withValues(alpha: 0.16),
                            _golpe
                                ? koru.fuego.withValues(alpha: 0.35)
                                : koru.hoja.withValues(alpha: 0.22),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 8,
                            right: 8,
                            top: 8,
                            child: _Leyenda(),
                          ),
                          for (final gota in _gotas)
                            Positioned(
                              left: gota.x * ancho - tamGota / 2,
                              top: gota.y * alto - tamGota / 2,
                              child: _DibujoGota(
                                tipo: gota.tipo,
                                tamano: tamGota,
                              ),
                            ),
                          // Suelo.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: alto * 0.06,
                            child: ColoredBox(
                              color: koru.tierra.withValues(alpha: 0.5),
                            ),
                          ),
                          Positioned(
                            left: (_planta - _anchoPlanta / 2) * ancho,
                            top: yPlanta,
                            width: _anchoPlanta * ancho,
                            child: _PlantaAnimada(
                              salto: _salto,
                              sacudida: _sacudida,
                              tamano: ancho * 0.18,
                            ),
                          ),
                          for (final e in _etiquetas)
                            Positioned(
                              left: e.x * ancho - 40,
                              width: 80,
                              top: yPlanta - 24 - e.edad * 60,
                              child: Opacity(
                                opacity: (1 - e.edad / _vidaEtiqueta).clamp(
                                  0,
                                  1,
                                ),
                                child: Text(
                                  e.texto,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: e.color,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// La planta salta al atrapar algo bueno y se sacude (y se pone roja) al
/// atrapar algo malo.
class _PlantaAnimada extends StatelessWidget {
  const _PlantaAnimada({
    required this.salto,
    required this.sacudida,
    required this.tamano,
  });

  final Animation<double> salto;
  final Animation<double> sacudida;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final planta = FittedBox(
      child: Text('🪴', style: TextStyle(fontSize: tamano)),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([salto, sacudida]),
      child: planta,
      builder: (context, child) {
        // Salto: sube y se estira un poco, y vuelve.
        final s = sin(salto.value * pi);
        // Sacudida: vaivén que se apaga.
        final t = sacudida.value;
        final vaiven = sin(t * pi * 6) * (1 - t);
        final rojo = sacudida.isAnimating ? (1 - t) * 0.6 : 0.0;
        Widget w = Transform.translate(
          offset: Offset(vaiven * 10, -s * tamano * 0.18),
          child: Transform.rotate(
            angle: vaiven * 0.18,
            child: Transform.scale(scale: 1 + s * 0.15, child: child),
          ),
        );
        if (rojo > 0) {
          w = ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.red.withValues(alpha: rojo),
              BlendMode.srcATop,
            ),
            child: w,
          );
        }
        return w;
      },
    );
  }
}

class _DibujoGota extends StatelessWidget {
  const _DibujoGota({required this.tipo, required this.tamano});

  final TipoGota tipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = colorGota(tipo);
    final gota = Icon(
      Icons.water_drop_rounded,
      size: tamano,
      color: color,
      shadows: [
        Shadow(
          color: tipo == TipoGota.dorada
              ? color
              : Colors.black.withValues(alpha: 0.35),
          blurRadius: tipo == TipoGota.dorada ? 14 : 3,
        ),
      ],
    );
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          gota,
          // Marca pequeña para distinguirlas sin depender solo del color.
          if (tipo != TipoGota.agua)
            Padding(
              padding: EdgeInsets.only(top: tamano * 0.25),
              child: Text(
                switch (tipo) {
                  TipoGota.aceite => '🍳',
                  TipoGota.acida => '☠',
                  TipoGota.petroleo => '⚫',
                  TipoGota.dorada => '✨',
                  TipoGota.agua => '',
                },
                style: TextStyle(
                  fontSize: tamano * 0.32,
                  color: tipo == TipoGota.acida ? Colors.black87 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Explica qué hace cada gota.
class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String efecto(TipoGota t) => switch (t) {
      TipoGota.agua => '+1 punto',
      TipoGota.dorada => '+1 ❤',
      _ => '${t.vidasAlAtrapar} ❤',
    };
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final tipo in TipoGota.values)
          Container(
            padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DibujoGota(tipo: tipo, tamano: 20),
                const SizedBox(width: 2),
                Text(
                  '${tipo.nombre} ${efecto(tipo)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
