import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../juegos/datos_juegos.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import 'escenario_gotas.dart';
import 'fin_de_juego.dart';

/// Salva las gotas: mueve la planta para atrapar el agua limpia y esquiva
/// las gotas contaminadas. Cada gota limpia que cae al suelo cuesta una vida.
///
/// El paisaje avanza del día a la noche a medida que sumas gotas y la planta
/// crece por etapas.
class JuegoGotas extends StatefulWidget {
  const JuegoGotas({super.key});

  @override
  State<JuegoGotas> createState() => _JuegoGotasState();
}

/// Texto que sube y se desvanece sobre la planta ("+1", "-2 ❤").
class _Etiqueta {
  _Etiqueta(this.texto, this.color, this.x);
  final String texto;
  final Color color;
  final double x;
  double edad = 0;
}

/// La planta crece con las gotas salvadas.
String plantaPara(int puntos) => puntos < 10
    ? '🌱'
    : puntos < 25
    ? '🌿'
    : puntos < 50
    ? '🪴'
    : '🌻';

class _JuegoGotasState extends State<JuegoGotas> with TickerProviderStateMixin {
  static const _anchoPlanta = anchoPlantaGotas;
  static const _altoPlanta = 0.86;
  static const _suelo = 0.94;
  static const _vidaEtiqueta = 0.9;

  /// Segundos que la leyenda se ve al empezar (o al pedirla con "?").
  static const _duracionLeyenda = 8.0;

  final _azar = Random();
  late final Ticker _ticker = createTicker(_avanzar);
  Duration _anterior = Duration.zero;

  /// Salto de alegría al atrapar una gota buena.
  late final AnimationController _salto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Sacudida al atrapar una gota mala (la planta y la pantalla).
  late final AnimationController _sacudida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  final _gotas = <GotaCayendo>[];
  final _particulas = <Particula>[];
  final _etiquetas = <_Etiqueta>[];
  double _planta = 0.5;

  /// Dónde cayó la última gota buena (para colocar las siguientes).
  double? _ultimaBuena;
  double _hastaLaSiguiente = 0.6;
  int _puntos = 0;
  int _vidas = vidasGotas;
  int _atrapadas = 0;
  bool _terminado = false;

  /// Segundos de juego (mueven nubes, pasto y destellos).
  double _tiempo = 0;

  /// Hasta qué momento se ve la leyenda.
  double _leyendaHasta = _duracionLeyenda;

  /// Tinte rojo del paisaje al perder vida (se apaga solo).
  double _golpe = 0;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  void _empezar() {
    _gotas.clear();
    _particulas.clear();
    _etiquetas.clear();
    _planta = 0.5;
    _ultimaBuena = null;
    _hastaLaSiguiente = 0.6;
    _puntos = 0;
    _vidas = vidasGotas;
    _atrapadas = 0;
    _terminado = false;
    _tiempo = 0;
    _leyendaHasta = _duracionLeyenda;
    _golpe = 0;
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

    _tiempo += dt;
    _golpe = max(0, _golpe - dt * 4);
    final velocidad = velocidadGotas(_puntos);

    _hastaLaSiguiente -= dt;
    if (_hastaLaSiguiente <= 0) {
      _hastaLaSiguiente = intervaloGotas(_puntos);
      for (final nueva in planearGotas(
        puntos: _puntos,
        ultimaBuena: _ultimaBuena,
        azar: _azar,
      )) {
        if (!nueva.tipo.esMala) _ultimaBuena = nueva.x;
        _gotas.add(GotaCayendo(nueva.x, nueva.tipo, y: nueva.y));
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
        _atrapar(gota);
      } else if (gota.y > _suelo) {
        _gotas.remove(gota);
        // Salpica contra el suelo.
        _particulas.addAll(
          salpicadura(
            x: gota.x,
            y: _suelo,
            color: colorGota(gota.tipo),
            azar: _azar,
            cantidad: 7,
            fuerza: 0.35,
          ),
        );
        if (gota.tipo.cuestaVidaSiCae) _perderVidas(1, gota.x, vibrar: false);
      }
    }

    _particulas.removeWhere((p) => !p.avanzar(dt));
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

  void _atrapar(GotaCayendo gota) {
    final tipo = gota.tipo;
    final cambio = tipo.vidasAlAtrapar;
    final arriba = _altoPlanta - 0.02;
    if (cambio < 0) {
      _particulas.addAll(
        salpicadura(
          x: gota.x,
          y: arriba,
          color: colorGota(tipo),
          azar: _azar,
          cantidad: 16,
          fuerza: 0.6,
          haciaArriba: false,
        ),
      );
      _perderVidas(-cambio, _planta, vibrar: true);
      _sacudida.forward(from: 0);
      return;
    }
    final etapaAntes = plantaPara(_puntos);
    _puntos += tipo.puntosAlAtrapar;
    _atrapadas++;
    _vidas += cambio;
    _salto.forward(from: 0);
    _particulas.addAll(
      salpicadura(
        x: gota.x,
        y: arriba,
        color: colorGota(tipo),
        azar: _azar,
        cantidad: tipo == TipoGota.dorada ? 22 : 12,
        fuerza: tipo == TipoGota.dorada ? 0.75 : 0.55,
      ),
    );
    final koru = context.koru;
    _etiquetas.add(
      cambio > 0
          ? _Etiqueta('+1 ❤', koru.oro, _planta)
          : _Etiqueta('+1', const Color(0xFF0277BD), _planta),
    );
    if (plantaPara(_puntos) != etapaAntes) {
      // ¡La planta creció!
      _etiquetas.add(_Etiqueta('¡Creció!', const Color(0xFF2E7D32), _planta));
      _particulas.addAll(
        salpicadura(
          x: _planta,
          y: arriba,
          color: const Color(0xFF66BB6A),
          azar: _azar,
          cantidad: 20,
          fuerza: 0.7,
          haciaArriba: false,
        ),
      );
    }
    if (cambio > 0) HapticFeedback.selectionClick();
  }

  void _perderVidas(int cuantas, double x, {required bool vibrar}) {
    _vidas -= cuantas;
    _etiquetas.add(_Etiqueta('-$cuantas ❤', const Color(0xFFD32F2F), x));
    if (vibrar) HapticFeedback.mediumImpact();
    _golpe = 1;
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
                  final yPlanta =
                      _altoPlanta * alto - ancho * _anchoPlanta * 0.35;
                  final verLeyenda = _tiempo < _leyendaHasta;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _moverPlanta(d.localPosition.dx, ancho),
                    onPanUpdate: (d) => _moverPlanta(d.localPosition.dx, ancho),
                    child: ClipRect(
                      // La pantalla tiembla un poco con los golpes.
                      child: AnimatedBuilder(
                        animation: _sacudida,
                        builder: (context, child) {
                          final t = _sacudida.value;
                          final temblor = _sacudida.isAnimating
                              ? sin(t * pi * 8) * (1 - t) * 6
                              : 0.0;
                          return Transform.translate(
                            offset: Offset(temblor, 0),
                            child: child,
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: PaisajePainter(
                                  tiempo: _tiempo,
                                  fase: faseDelDia(_puntos),
                                  golpe: _golpe,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GotasPainter(
                                  gotas: _gotas,
                                  particulas: _particulas,
                                  velocidad: velocidadGotas(_puntos),
                                  tiempo: _tiempo,
                                ),
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
                                planta: plantaPara(_puntos),
                              ),
                            ),
                            for (final e in _etiquetas)
                              Positioned(
                                left: e.x * ancho - 50,
                                width: 100,
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
                                      shadows: const [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // La leyenda se aparta sola; "?" la vuelve a mostrar.
                            Positioned(
                              left: 8,
                              right: 48,
                              top: 8,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: verLeyenda ? 1 : 0,
                                  duration: const Duration(milliseconds: 400),
                                  child: const _Leyenda(),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: IconButton.filledTonal(
                                tooltip: 'Qué hace cada gota',
                                icon: const Icon(Icons.help_outline_rounded),
                                onPressed: () => setState(
                                  () => _leyendaHasta =
                                      _tiempo + _duracionLeyenda / 2,
                                ),
                              ),
                            ),
                          ],
                        ),
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
    required this.planta,
  });

  final Animation<double> salto;
  final Animation<double> sacudida;
  final double tamano;

  /// Emoji de la etapa de la planta.
  final String planta;

  @override
  Widget build(BuildContext context) {
    final dibujo = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: FittedBox(
        key: ValueKey(planta),
        child: Text(planta, style: TextStyle(fontSize: tamano)),
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([salto, sacudida]),
      child: dibujo,
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
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconoGota(tipo: tipo, tamano: 22),
                const SizedBox(width: 2),
                Text(
                  '${tipo.nombre} ${efecto(tipo)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
