import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../juegos/sopa_letras.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import 'fin_de_juego.dart';

/// Sopa de letras verde: desliza el dedo sobre las letras para marcar las
/// palabras escondidas (en horizontal, vertical o diagonal).
class JuegoSopa extends StatefulWidget {
  const JuegoSopa({super.key, required this.modo});

  final ModoSopa modo;

  @override
  State<JuegoSopa> createState() => _JuegoSopaState();
}

class _JuegoSopaState extends State<JuegoSopa> {
  final _azar = Random();

  late SopaLetras _sopa;
  final _encontradas = <String>[];
  List<Celda> _seleccion = const [];
  Celda? _inicio;
  Timer? _reloj;
  int _segundos = 0;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  void _empezar() {
    _reloj?.cancel();
    setState(() {
      _sopa = SopaLetras.paraModo(widget.modo, _azar);
      _encontradas.clear();
      _seleccion = const [];
      _inicio = null;
      _segundos = 0;
      _terminado = false;
    });
    _iniciarReloj();
  }

  void _iniciarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  void _terminar() {
    _reloj?.cancel();
    setState(() => _terminado = true);
  }

  Celda? _celdaEn(Offset posicion, double lado) {
    final n = _sopa.tamano;
    final f = (posicion.dy / lado * n).floor();
    final c = (posicion.dx / lado * n).floor();
    if (f < 0 || c < 0 || f >= n || c >= n) return null;
    return (f, c);
  }

  void _alEmpezar(Offset posicion, double lado) {
    final celda = _celdaEn(posicion, lado);
    if (celda == null) return;
    setState(() {
      _inicio = celda;
      _seleccion = [celda];
    });
  }

  void _alMover(Offset posicion, double lado) {
    final inicio = _inicio;
    if (inicio == null) return;
    final n = _sopa.tamano;
    final linea = lineaAjustada(
      inicio,
      posicion.dy / lado * n,
      posicion.dx / lado * n,
      n,
    );
    if (linea.length != _seleccion.length || linea.last != _seleccion.last) {
      setState(() => _seleccion = linea);
    }
  }

  void _alSoltar() {
    if (_inicio == null) return;
    final palabra = _sopa.palabraEn(_seleccion);
    setState(() {
      if (palabra != null && !_encontradas.contains(palabra)) {
        _encontradas.add(palabra);
      }
      _seleccion = const [];
      _inicio = null;
    });
    if (_encontradas.length == _sopa.palabras.length) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _terminar();
      });
    }
  }

  void _pausar() => _reloj?.cancel();

  void _reanudar() {
    if (!_terminado && mounted) _iniciarReloj();
  }

  Future<bool> _confirmarSalida() =>
      SalidaDeJuego.preguntar(context, pausar: _pausar, reanudar: _reanudar);

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  String get _tiempo =>
      '${_segundos ~/ 60}:${(_segundos % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final colores = [
      koru.hoja,
      koru.agua,
      koru.oro,
      koru.fuego,
      koru.tierra,
      theme.colorScheme.tertiary,
    ];
    // Color de cada celda ya encontrada.
    final colorCelda = <Celda, Color>{};
    for (final (i, palabra) in _encontradas.indexed) {
      for (final celda in _sopa.ubicaciones[palabra]!) {
        colorCelda[celda] = colores[i % colores.length];
      }
    }
    final seleccionadas = _seleccion.toSet();
    final total = _sopa.palabras.length;

    return SalidaDeJuego(
      enJuego: !_terminado,
      pausar: _pausar,
      reanudar: _reanudar,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sopa de letras · ${widget.modo.nombre}'),
          actions: [
            if (!_terminado) ...[
              MarcadorJuego(
                icono: Icons.timer_rounded,
                texto: _tiempo,
                color: koru.agua,
              ),
              MarcadorJuego(
                icono: Icons.search_rounded,
                texto: '${_encontradas.length}/$total',
                color: koru.hoja,
              ),
            ],
            BotonInicio(confirmar: _terminado ? null : _confirmarSalida),
          ],
        ),
        body: _terminado
            ? FinDeJuego(
                juego: widget.modo.juego,
                // El récord es el tiempo, y solo cuenta si la completaste.
                valor: _encontradas.length == total ? max(1, _segundos) : null,
                resumen: _encontradas.length == total
                    ? '¡Encontraste las $total palabras!'
                    : 'Encontraste ${_encontradas.length} de $total palabras. '
                          'Complétala para tener tiempo récord.',
                onRepetir: _empezar,
              )
            : SafeArea(
                top: false,
                // Sin desplazamiento: si la página se pudiera deslizar, se
                // "robaría" los arrastres verticales y diagonales del tablero.
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.modo == ModoSopa.facil ? 16 : 8,
                    12,
                    widget.modo == ModoSopa.facil ? 16 : 8,
                    8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Desliza el dedo sobre las letras para marcar cada palabra.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: LayoutBuilder(
                              builder: (context, restricciones) {
                                final lado = restricciones.maxWidth;
                                final n = _sopa.tamano;
                                // Listener recibe el dedo al instante (sin esperar a
                                // que el gesto "arranque"), así la primera letra es
                                // justo la que se tocó.
                                return Listener(
                                  onPointerDown: (e) =>
                                      _alEmpezar(e.localPosition, lado),
                                  onPointerMove: (e) =>
                                      _alMover(e.localPosition, lado),
                                  onPointerUp: (_) => _alSoltar(),
                                  onPointerCancel: (_) => _alSoltar(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(
                                        KoruRadius.m,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        for (var f = 0; f < n; f++)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                for (var c = 0; c < n; c++)
                                                  Expanded(
                                                    child: _CeldaSopa(
                                                      letra: _sopa.letras[f][c],
                                                      color:
                                                          seleccionadas
                                                              .contains((f, c))
                                                          ? theme
                                                                .colorScheme
                                                                .primary
                                                          : colorCelda[(f, c)],
                                                      seleccionada:
                                                          seleccionadas
                                                              .contains((f, c)),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Lista de palabras con su propia barra: no se mueve
                      // junto con el tablero, así no le roba los arrastres.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 132),
                        child: SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final palabra in [..._sopa.palabras]..sort())
                                _ChipPalabra(
                                  palabra: palabra,
                                  color: _encontradas.contains(palabra)
                                      ? colores[_encontradas.indexOf(palabra) %
                                            colores.length]
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _terminar,
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Rendirme'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CeldaSopa extends StatelessWidget {
  const _CeldaSopa({
    required this.letra,
    required this.color,
    required this.seleccionada,
  });

  final String letra;
  final Color? color;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: seleccionada ? 0.55 : 0.32),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            letra,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color != null ? theme.colorScheme.onSurface : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPalabra extends StatelessWidget {
  const _ChipPalabra({required this.palabra, required this.color});

  final String palabra;

  /// Color si ya se encontró; null si falta.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hallada = color != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hallada
            ? color!.withValues(alpha: 0.22)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        palabra,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          decoration: hallada ? TextDecoration.lineThrough : null,
          color: hallada ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
    );
  }
}
