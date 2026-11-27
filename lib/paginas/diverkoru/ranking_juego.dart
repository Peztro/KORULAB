import 'package:flutter/material.dart';

import '../../juegos/datos_juegos.dart';
import '../../juegos/records_diverkoru.dart';
import '../../servicios/servicio_ranking.dart';
import '../../tema/tema_korulab.dart';
import '../../widgets/ui_koru.dart';

/// Ranking global de un juego de DiverKoru: los mejores estudiantes.
///
/// Al aparecer sube tu récord (el de esta partida, [valorPartida], o el
/// guardado en el teléfono) para que cuente aunque lo hicieras antes.
class RankingJuego extends StatefulWidget {
  const RankingJuego({
    super.key,
    required this.juego,
    this.valorPartida = 0,
    this.compacto = false,
  });

  final JuegoDiverKoru juego;
  final int valorPartida;

  /// Versión corta (top 5) para la pantalla final del juego.
  final bool compacto;

  @override
  State<RankingJuego> createState() => _RankingJuegoState();
}

class _RankingJuegoState extends State<RankingJuego> {
  late Future<List<PuestoRanking>> _carga = _cargar();

  @override
  void didUpdateWidget(RankingJuego old) {
    super.didUpdateWidget(old);
    if (old.juego != widget.juego) _carga = _cargar();
  }

  Future<List<PuestoRanking>> _cargar() async {
    final juego = widget.juego;
    final local = await RecordsDiverKoru.leer(juego);
    final mejor = esMejorRecord(juego, widget.valorPartida, local)
        ? widget.valorPartida
        : local;
    await ServicioRanking.registrar(juego, mejor);
    return ServicioRanking.ranking(juego, limite: widget.compacto ? 5 : 20);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return FutureBuilder<List<PuestoRanking>>(
      future: _carga,
      builder: (context, snap) {
        Widget contenido;
        if (snap.connectionState != ConnectionState.done) {
          contenido = const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasError) {
          contenido = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'No se pudo cargar el ranking. Revisa tu conexión.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _carga = _cargar()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        } else if (snap.data!.isEmpty) {
          contenido = Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Aún nadie está en el ranking. ¡Sé el primero!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          );
        } else {
          contenido = Column(
            children: [
              for (final puesto in snap.data!)
                _FilaRanking(puesto: puesto, juego: widget.juego),
            ],
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(KoruRadius.l),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.public_rounded, color: koru.agua),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ranking de Korulab',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    widget.juego.menorEsMejor
                        ? 'menor tiempo'
                        : widget.juego.unidad,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              contenido,
            ],
          ),
        );
      },
    );
  }
}

class _FilaRanking extends StatelessWidget {
  const _FilaRanking({required this.puesto, required this.juego});
  final PuestoRanking puesto;
  final JuegoDiverKoru juego;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    final medalla = switch (puesto.posicion) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: puesto.soyYo ? koru.hoja.withValues(alpha: 0.18) : null,
        borderRadius: BorderRadius.circular(KoruRadius.s),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              medalla ?? '${puesto.posicion}',
              textAlign: TextAlign.center,
              style: medalla != null
                  ? const TextStyle(fontSize: 22)
                  : theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
            ),
          ),
          const SizedBox(width: 6),
          KoruAvatar(
            image: puesto.foto?.provider,
            name: puesto.nombre,
            radius: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              puesto.soyYo ? '${puesto.nombre} (tú)' : puesto.nombre,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: puesto.soyYo ? FontWeight.w900 : null,
              ),
            ),
          ),
          if (juego.menorEsMejor) ...[
            Icon(Icons.timer_rounded, size: 16, color: koru.agua),
            const SizedBox(width: 2),
          ],
          Text(
            juego.formatear(puesto.puntos),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
