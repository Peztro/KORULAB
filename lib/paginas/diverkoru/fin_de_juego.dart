import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';
import '../../juegos/records_diverkoru.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import '../../widgets/celebracion.dart';
import '../../widgets/koru_mascota.dart';
import 'ranking_juego.dart';

/// Pantalla final común de los juegos de DiverKoru: la marca de la partida,
/// el récord, el ranking de Korulab y botones para repetir o salir. Guarda
/// el récord al aparecer.
class FinDeJuego extends StatefulWidget {
  const FinDeJuego({
    super.key,
    required this.juego,
    required this.valor,
    required this.resumen,
    required this.onRepetir,
  });

  final JuegoDiverKoru juego;

  /// Marca de la partida (objetos, respuestas, gotas o segundos). null si
  /// no cuenta para el récord (por ejemplo, una sopa sin terminar).
  final int? valor;

  /// Una línea sobre cómo le fue, por ejemplo "12 aciertos y 3 fallos".
  final String resumen;
  final VoidCallback onRepetir;

  @override
  State<FinDeJuego> createState() => _FinDeJuegoState();
}

class _FinDeJuegoState extends State<FinDeJuego> {
  bool? _esRecord;
  int _record = 0;

  @override
  void initState() {
    super.initState();
    _guardar();
  }

  Future<void> _guardar() async {
    final valor = widget.valor;
    final nuevo =
        valor != null && await RecordsDiverKoru.registrar(widget.juego, valor);
    final record = await RecordsDiverKoru.leer(widget.juego);
    if (!mounted) return;
    setState(() {
      _esRecord = nuevo;
      _record = record;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final juego = widget.juego;
    final valor = widget.valor;
    final esRecord = _esRecord ?? false;
    final hizoAlgo = valor != null && valor > 0;

    return Stack(
      children: [
        if (esRecord)
          Positioned.fill(
            child: IgnorePointer(
              child: LluviaCelebracion(
                tipo: TipoCelebracion.confeti,
                colores: [koru.hoja, koru.oro, koru.agua, koru.fuego],
              ),
            ),
          ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KoruMascota(
                    emocion: esRecord
                        ? EmocionKoru.celebrando
                        : hizoAlgo
                        ? EmocionKoru.feliz
                        : EmocionKoru.animando,
                    tamano: 130,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    esRecord
                        ? '¡Nuevo récord!'
                        : hizoAlgo
                        ? '¡Buen juego!'
                        : '¡Inténtalo otra vez!',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.resumen,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (valor != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: koru.degradadoHero,
                        borderRadius: BorderRadius.circular(KoruRadius.l),
                      ),
                      child: Column(
                        children: [
                          Text(
                            juego.formatear(valor),
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: koru.textoHero,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            juego.unidad,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: koru.textoHero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: _esRecord == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: koru.oro),
                        const SizedBox(width: 6),
                        Text(
                          _record > 0
                              ? 'Tu récord: ${juego.formatear(_record)}'
                              : 'Aún no tienes récord',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: widget.onRepetir,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Jugar otra vez'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver al juego'),
                  ),
                  const BotonIrAlInicio(),
                  const SizedBox(height: 16),
                  RankingJuego(
                    juego: juego,
                    valorPartida: valor ?? 0,
                    compacto: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicador pequeño para la barra de los juegos (puntos, tiempo, vidas).
class MarcadorJuego extends StatelessWidget {
  const MarcadorJuego({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
