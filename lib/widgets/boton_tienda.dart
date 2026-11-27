import 'package:flutter/material.dart';

import '../paginas/pagina_tienda.dart';
import '../servicios/estadisticas_progreso.dart';
import '../servicios/sesion_actual.dart';
import '../tema/tema_korulab.dart';

/// Botón para la barra superior que abre la tienda y muestra tus
/// ekostrellas. Si no se pasa [username], usa el de la sesión activa.
class BotonTienda extends StatelessWidget {
  const BotonTienda({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    final koru = context.koru;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: 'Ir a la tienda',
        child: Material(
          color: koru.oro.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              final usuario = username ?? SesionActual.instancia.username ?? '';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RewardShopPage(username: usuario),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, size: 20, color: koru.oro),
                  const SizedBox(width: 4),
                  // Se actualiza solo al comprar o ganar ekostrellas.
                  ListenableBuilder(
                    listenable: progressStats,
                    builder: (context, _) => Text(
                      '${progressStats.ekostrellas}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.star_rounded, size: 16, color: koru.oro),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
