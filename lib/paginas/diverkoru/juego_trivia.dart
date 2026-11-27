import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import '../../widgets/koru_mascota.dart';
import 'fin_de_juego.dart';

/// Trivia relámpago, casi infinita: empiezas con 60 segundos, cada acierto
/// suma tiempo y cada fallo acelera el reloj. Juegas hasta que se acaba.
class JuegoTrivia extends StatefulWidget {
  const JuegoTrivia({super.key});

  @override
  State<JuegoTrivia> createState() => _JuegoTriviaState();
}

class _JuegoTriviaState extends State<JuegoTrivia> {
  static const _paso = Duration(milliseconds: 100);
  final _azar = Random();

  late RelojTrivia _reloj;
  Timer? _tic;

  /// Preguntas barajadas: no se repite ninguna hasta usarlas todas.
  final _mazo = <PreguntaTrivia>[];
  late PreguntaTrivia _actual;
  late List<String> _opciones;

  /// Opción elegida en la pregunta actual (null mientras no responde).
  String? _elegida;

  /// Mensaje que flota sobre el reloj: "+5 s" o "¡Más rápido!".
  String? _destello;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _empezar();
  }

  void _empezar() {
    _tic?.cancel();
    setState(() {
      _reloj = RelojTrivia();
      _mazo.clear();
      _terminado = false;
      _destello = null;
    });
    _siguientePregunta();
  }

  PreguntaTrivia _sacar() {
    if (_mazo.isEmpty) _mazo.addAll([...preguntasTrivia]..shuffle(_azar));
    return _mazo.removeLast();
  }

  void _siguientePregunta() {
    setState(() {
      _actual = _sacar();
      _opciones = _actual.opciones(_azar);
      _elegida = null;
    });
    _iniciarReloj();
  }

  void _iniciarReloj() {
    _tic?.cancel();
    _tic = Timer.periodic(_paso, (_) {
      if (!mounted) return;
      setState(() => _reloj.avanzar(_paso.inMilliseconds / 1000));
      if (_reloj.agotado) _terminar();
    });
  }

  void _terminar() {
    _tic?.cancel();
    setState(() => _terminado = true);
  }

  void _responder(String opcion) {
    if (_elegida != null || _terminado) return;
    // El reloj se detiene mientras se muestra si acertaste.
    _tic?.cancel();
    final acierto = opcion == _actual.correcta;
    setState(() {
      _elegida = opcion;
      if (acierto) {
        _destello = '+${_reloj.acierto()} s';
      } else {
        _reloj.fallo();
        _destello = '¡El reloj va más rápido!';
      }
    });
    Future.delayed(Duration(milliseconds: acierto ? 800 : 1800), () {
      if (!mounted || _terminado) return;
      setState(() => _destello = null);
      _siguientePregunta();
    });
  }

  void _pausar() => _tic?.cancel();

  void _reanudar() {
    if (!_terminado && mounted && _elegida == null) _iniciarReloj();
  }

  Future<bool> _confirmarSalida() =>
      SalidaDeJuego.preguntar(context, pausar: _pausar, reanudar: _reanudar);

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final respondida = _elegida != null;
    final acerto = _elegida == _actual.correcta;
    final segundos = _reloj.restante.ceil();
    final apurado = _reloj.restante < 10;
    final acelerado = _reloj.ritmo > 1.001;

    return SalidaDeJuego(
      enJuego: !_terminado,
      pausar: _pausar,
      reanudar: _reanudar,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trivia relámpago'),
          actions: [
            if (!_terminado)
              MarcadorJuego(
                icono: Icons.check_circle_rounded,
                texto: '${_reloj.aciertos}',
                color: koru.hoja,
              ),
            BotonInicio(confirmar: _terminado ? null : _confirmarSalida),
          ],
        ),
        body: _terminado
            ? FinDeJuego(
                juego: JuegoDiverKoru.trivia,
                valor: _reloj.aciertos,
                resumen: _reloj.fallos == 0
                    ? '¡Sin fallos!'
                    : '${_reloj.fallos} '
                          '${_reloj.fallos == 1 ? 'fallo' : 'fallos'}',
                onRepetir: _empezar,
              )
            : SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Reloj grande.
                    Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: apurado ? koru.fuego : koru.oro,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$segundos s',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: apurado ? koru.fuego : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (acelerado)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: koru.fuego.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '⏩ x${_reloj.ritmo.toStringAsFixed(2)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: koru.fuego,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _destello == null
                              ? const SizedBox.shrink()
                              : Text(
                                  _destello!,
                                  key: ValueKey(_destello),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: acerto ? koru.hoja : koru.fuego,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (_reloj.restante / _reloj.inicial).clamp(0, 1),
                        color: apurado ? koru.fuego : koru.oro,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acierto: +${_reloj.premio} s · Fallo: el reloj se acelera',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        KoruMascota(
                          emocion: !respondida
                              ? EmocionKoru.pensando
                              : acerto
                              ? EmocionKoru.feliz
                              : EmocionKoru.animando,
                          tamano: 72,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _actual.pregunta,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (final opcion in _opciones)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BotonOpcion(
                          texto: opcion,
                          estado: !respondida
                              ? _EstadoOpcion.normal
                              : opcion == _actual.correcta
                              ? _EstadoOpcion.correcta
                              : opcion == _elegida
                              ? _EstadoOpcion.incorrecta
                              : _EstadoOpcion.apagada,
                          onTap: () => _responder(opcion),
                        ),
                      ),
                    if (respondida && !acerto)
                      Text(
                        'La respuesta era: ${_actual.correcta}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: koru.fuego,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

enum _EstadoOpcion { normal, correcta, incorrecta, apagada }

class _BotonOpcion extends StatelessWidget {
  const _BotonOpcion({
    required this.texto,
    required this.estado,
    required this.onTap,
  });

  final String texto;
  final _EstadoOpcion estado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final (fondo, borde, icono) = switch (estado) {
      _EstadoOpcion.normal => (
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.outlineVariant,
        null,
      ),
      _EstadoOpcion.correcta => (
        koru.hoja.withValues(alpha: 0.18),
        koru.hoja,
        Icons.check_circle_rounded,
      ),
      _EstadoOpcion.incorrecta => (
        koru.fuego.withValues(alpha: 0.15),
        koru.fuego,
        Icons.cancel_rounded,
      ),
      _EstadoOpcion.apagada => (
        theme.colorScheme.surfaceContainerLow,
        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        null,
      ),
    };
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(KoruRadius.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(KoruRadius.m),
        onTap: estado == _EstadoOpcion.normal ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KoruRadius.m),
            border: Border.all(color: borde, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: estado == _EstadoOpcion.apagada
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
              if (icono != null) Icon(icono, color: borde),
            ],
          ),
        ),
      ),
    );
  }
}
