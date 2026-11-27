import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import 'fin_de_juego.dart';

/// Clasifica la basura: arrastra (o toca la caneca) cada residuo a su
/// caneca antes de que se acabe el tiempo.
class JuegoClasifica extends StatefulWidget {
  const JuegoClasifica({super.key});

  @override
  State<JuegoClasifica> createState() => _JuegoClasificaState();
}

class _JuegoClasificaState extends State<JuegoClasifica> {
  static const _duracion = segundosClasifica;
  final _azar = Random();

  Timer? _reloj;
  int _segundos = _duracion;
  int _racha = 0;
  int _aciertos = 0;
  int _fallos = 0;
  late Residuo _actual;

  /// Residuos barajados: no se repite ninguno hasta que salgan todos.
  final _mazo = <Residuo>[];
  bool _terminado = false;

  /// Mensaje tras cada jugada: (texto, ¿acierto?).
  (String, bool)? _aviso;
  Timer? _ocultarAviso;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  void _empezar() {
    _reloj?.cancel();
    setState(() {
      _segundos = _duracion;
      _racha = 0;
      _aciertos = 0;
      _fallos = 0;
      _aviso = null;
      _terminado = false;
      _mazo.clear();
      _actual = _sacar();
    });
    _iniciarReloj();
  }

  void _iniciarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _segundos--);
      if (_segundos <= 0) _terminar();
    });
  }

  void _terminar() {
    _reloj?.cancel();
    _ocultarAviso?.cancel();
    setState(() => _terminado = true);
  }

  Residuo _sacar() {
    if (_mazo.isEmpty) _mazo.addAll([...residuos]..shuffle(_azar));
    return _mazo.removeLast();
  }

  void _soltar(Caneca caneca) {
    if (_terminado) return;
    final acierto = caneca == _actual.caneca;
    setState(() {
      if (acierto) {
        _aciertos++;
        _racha++;
        _aviso = (
          _racha >= 3 ? '¡Racha de $_racha! 🔥' : '¡Bien separado!',
          true,
        );
      } else {
        _fallos++;
        _racha = 0;
        // Equivocarse cuesta tiempo: así no sirve tocar canecas al azar.
        _segundos = max(0, _segundos - penalizacionClasifica);
        _aviso = (
          '−$penalizacionClasifica s. ${_actual.nombre} va en la caneca '
              '${_actual.caneca.nombre.toLowerCase()}. ${_actual.pista}',
          false,
        );
      }
      _actual = _sacar();
    });
    if (_segundos <= 0) {
      _terminar();
      return;
    }
    _ocultarAviso?.cancel();
    _ocultarAviso = Timer(
      Duration(milliseconds: acierto ? 900 : 2600),
      () => mounted ? setState(() => _aviso = null) : null,
    );
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
    _ocultarAviso?.cancel();
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
          title: const Text('Clasifica la basura'),
          actions: [
            if (!_terminado) ...[
              MarcadorJuego(
                icono: Icons.timer_rounded,
                texto: '$_segundos s',
                color: _segundos <= 10 ? koru.fuego : koru.agua,
              ),
              MarcadorJuego(
                icono: Icons.recycling_rounded,
                texto: '$_aciertos',
                color: koru.hoja,
              ),
            ],
            BotonInicio(confirmar: _terminado ? null : _confirmarSalida),
          ],
        ),
        body: _terminado
            ? FinDeJuego(
                juego: JuegoDiverKoru.clasifica,
                valor: _aciertos,
                resumen: _fallos == 0
                    ? '¡Sin errores!'
                    : '$_fallos ${_fallos == 1 ? 'error' : 'errores'}',
                onRepetir: _empezar,
              )
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: _segundos / _duracion,
                    color: _segundos <= 10 ? koru.fuego : koru.hoja,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'Arrastra el residuo a su caneca o toca la caneca correcta.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Draggable<Residuo>(
                          key: ValueKey(_actual),
                          data: _actual,
                          // El residuo queda centrado bajo el dedo: la caneca que se
                          // ve debajo es la que lo recibe.
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                _actual.emoji,
                                style: const TextStyle(fontSize: 72),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.25,
                            child: _TarjetaResiduo(residuo: _actual),
                          ),
                          child: _TarjetaResiduo(residuo: _actual),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 64,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _aviso == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(_aviso),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                _aviso!.$1,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: _aviso!.$2 ? koru.hoja : koru.fuego,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Row(
                        children: [
                          for (final caneca in Caneca.values)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _CanecaDestino(
                                  caneca: caneca,
                                  onSoltar: _soltar,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TarjetaResiduo extends StatelessWidget {
  const _TarjetaResiduo({required this.residuo});
  final Residuo residuo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(KoruRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(residuo.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          Text(
            residuo.nombre,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _CanecaDestino extends StatelessWidget {
  const _CanecaDestino({required this.caneca, required this.onSoltar});

  final Caneca caneca;
  final ValueChanged<Caneca> onSoltar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (fondo, texto, borde) = switch (caneca) {
      Caneca.blanca => (
        const Color(0xFFF7F7F2),
        const Color(0xFF263238),
        const Color(0xFFB0BEC5),
      ),
      Caneca.verde => (
        const Color(0xFF2E7D32),
        Colors.white,
        const Color(0xFF1B5E20),
      ),
      Caneca.negra => (
        const Color(0xFF263238),
        Colors.white,
        const Color(0xFF000000),
      ),
    };
    return DragTarget<Residuo>(
      onAcceptWithDetails: (_) => onSoltar(caneca),
      builder: (context, candidatos, _) {
        final encima = candidatos.isNotEmpty;
        return GestureDetector(
          onTap: () => onSoltar(caneca),
          child: AnimatedScale(
            scale: encima ? 1.08 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 128,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                  bottom: Radius.circular(KoruRadius.m),
                ),
                border: Border.all(
                  color: encima ? theme.colorScheme.primary : borde,
                  width: encima ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: texto, size: 34),
                  const SizedBox(height: 4),
                  Text(
                    caneca.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: texto,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    caneca.contenido,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: theme.textTheme.labelSmall?.copyWith(color: texto),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
