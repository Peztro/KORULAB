import 'package:flutter/material.dart';

/// Se incrementa cada vez que alguien pide volver al inicio. La página
/// principal lo escucha para regresar a su primera pestaña.
final pedidoVolverAlInicio = ValueNotifier<int>(0);

/// Cierra todas las pantallas abiertas hasta la principal y la deja en su
/// primera pestaña (Inicio, Panel o Consola, según el rol).
void volverAlInicio(BuildContext context) {
  Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  pedidoVolverAlInicio.value++;
}

/// Botón con una casa para la barra superior de las pantallas.
///
/// [confirmar] se llama antes de salir; si devuelve false, no sale (por
/// ejemplo, en un juego a medias).
class BotonInicio extends StatelessWidget {
  const BotonInicio({super.key, this.confirmar});

  final Future<bool> Function()? confirmar;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ir al inicio',
      icon: const Icon(Icons.home_rounded),
      onPressed: () async {
        final pregunta = confirmar;
        if (pregunta != null && !await pregunta()) return;
        if (context.mounted) volverAlInicio(context);
      },
    );
  }
}

/// Botón "Ir al inicio" para las pantallas finales (lecciones y juegos).
class BotonIrAlInicio extends StatelessWidget {
  const BotonIrAlInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => volverAlInicio(context),
      icon: const Icon(Icons.home_rounded),
      label: const Text('Ir al inicio'),
    );
  }
}

/// Pregunta si de verdad se quiere salir de un juego a medias.
Future<bool> confirmarSalidaDeJuego(BuildContext context) async {
  final salir = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: const Text('¿Seguro que quieres salir?'),
      content: const Text('No se guardará tu puntaje de esta partida.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Seguir jugando'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Salir'),
        ),
      ],
    ),
  );
  return salir ?? false;
}

/// Envuelve la pantalla de un juego: mientras [enJuego] sea true, el botón
/// de atrás (el de la barra y el del teléfono) pregunta antes de salir.
/// [pausar] y [reanudar] detienen el juego mientras se muestra el aviso.
class SalidaDeJuego extends StatelessWidget {
  const SalidaDeJuego({
    super.key,
    required this.enJuego,
    required this.pausar,
    required this.reanudar,
    required this.child,
  });

  final bool enJuego;
  final VoidCallback pausar;
  final VoidCallback reanudar;
  final Widget child;

  /// Pausa, pregunta y reanuda si el jugador decide quedarse.
  static Future<bool> preguntar(
    BuildContext context, {
    required VoidCallback pausar,
    required VoidCallback reanudar,
  }) async {
    pausar();
    final salir = await confirmarSalidaDeJuego(context);
    if (!salir) reanudar();
    return salir;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !enJuego,
      onPopInvokedWithResult: (yaSalio, _) async {
        if (yaSalio) return;
        final navegador = Navigator.of(context);
        if (await preguntar(context, pausar: pausar, reanudar: reanudar)) {
          navegador.pop();
        }
      },
      child: child,
    );
  }
}
