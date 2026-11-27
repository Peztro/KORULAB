import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';
import '../../juegos/records_diverkoru.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/boton_inicio.dart';
import 'ranking_juego.dart';

/// Un modo de juego que se puede elegir en la portada (la sopa tiene tres;
/// los demás juegos, uno).
class ModoJuego {
  const ModoJuego({
    required this.nombre,
    required this.juego,
    required this.crear,
    this.detalle,
  });

  final String nombre;

  /// Tabla de récords de este modo.
  final JuegoDiverKoru juego;
  final Widget Function() crear;

  /// Texto corto bajo el selector, por ejemplo "30 palabras".
  final String? detalle;
}

/// Lo que la portada necesita saber de un juego.
class FichaJuego {
  const FichaJuego({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.comoJugar,
    required this.modos,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<String> comoJugar;
  final List<ModoJuego> modos;
}

/// Portada de un juego: cómo se juega, tu récord y el ranking de Korulab,
/// con el botón "Jugar" fijo abajo.
class PortadaJuego extends StatefulWidget {
  const PortadaJuego({super.key, required this.ficha, required this.color});

  final FichaJuego ficha;
  final Color color;

  @override
  State<PortadaJuego> createState() => _PortadaJuegoState();
}

class _PortadaJuegoState extends State<PortadaJuego> {
  int _modo = 0;
  int _record = 0;

  /// Cambia al volver de una partida para recargar el ranking.
  int _vuelta = 0;

  ModoJuego get _actual => widget.ficha.modos[_modo];

  @override
  void initState() {
    super.initState();
    _cargarRecord();
  }

  Future<void> _cargarRecord() async {
    final juego = _actual.juego;
    final record = await RecordsDiverKoru.leer(juego);
    if (mounted && juego == _actual.juego) setState(() => _record = record);
  }

  Future<void> _jugar() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _actual.crear()));
    if (!mounted) return;
    setState(() => _vuelta++);
    _cargarRecord();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final ficha = widget.ficha;
    final color = widget.color;
    final juego = _actual.juego;

    return Scaffold(
      appBar: AppBar(title: Text(ficha.titulo), actions: const [BotonInicio()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(KoruRadius.l),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(KoruRadius.m),
                  ),
                  child: Icon(ficha.icono, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ficha.descripcion, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: koru.oro,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _record > 0
                                ? 'Tu récord: ${juego.formatear(_record)}'
                                : 'Aún no tienes récord',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (ficha.modos.length > 1) ...[
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: [
                for (final (i, modo) in ficha.modos.indexed)
                  ButtonSegment(value: i, label: Text(modo.nombre)),
              ],
              selected: {_modo},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() {
                  _modo = s.first;
                  _record = 0;
                });
                _cargarRecord();
              },
            ),
            if (_actual.detalle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _actual.detalle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          RankingJuego(key: ValueKey((juego, _vuelta)), juego: juego),
          const SizedBox(height: 16),
          Text('Cómo se juega', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final paso in ficha.comoJugar)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 7, color: color),
                  ),
                  Expanded(
                    child: Text(paso, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Botón fijo: siempre en el mismo sitio, aunque se desplace la página.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: _jugar,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(
              ficha.modos.length > 1 ? 'Jugar · ${_actual.nombre}' : 'Jugar',
            ),
          ),
        ),
      ),
    );
  }
}
