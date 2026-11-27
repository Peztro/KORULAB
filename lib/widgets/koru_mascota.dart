import 'package:flutter/material.dart';

/// Emociones de Koru, el caracol de Korulab.
enum EmocionKoru {
  saludando,
  feliz,
  celebrando,
  pensando,
  animando,
  durmiendo,
  jugando,
  leyendo,
  tendero,
}

/// Observa la navegación para saber si una pantalla está visible.
/// Se registra en `MaterialApp.navigatorObservers`.
final RouteObserver<ModalRoute<dynamic>> observadorRutas =
    RouteObserver<ModalRoute<dynamic>>();

/// Dibuja a Koru con una emoción y un movimiento acorde.
///
/// Es el único sitio que sabe qué imagen corresponde a cada emoción: cuando
/// existan poses nuevas, basta con cambiar [_imagenes].
class KoruMascota extends StatefulWidget {
  const KoruMascota({
    super.key,
    this.emocion = EmocionKoru.feliz,
    this.tamano = 120,
    this.animar = true,
  });

  final EmocionKoru emocion;
  final double tamano;

  /// Sin animación propia (por ejemplo, cuando quien lo muestra ya lo anima).
  final bool animar;

  /// Imagen de cada emoción. Las que aún no tienen pose propia reutilizan
  /// la base.
  static const Map<EmocionKoru, String> _imagenes = {
    EmocionKoru.saludando: 'assets/images/koru_base.png',
    EmocionKoru.feliz: 'assets/images/koru_base.png',
    // Sombrero vueltiao y yuca: lección perfecta (100 %).
    EmocionKoru.celebrando: 'assets/images/koru_celebrando.png',
    EmocionKoru.pensando: 'assets/images/koru_base.png',
    EmocionKoru.animando: 'assets/images/koru_base.png',
    EmocionKoru.durmiendo: 'assets/images/koru_base.png',
    // Gorra y mando: sección DiverKoru.
    EmocionKoru.jugando: 'assets/images/koru_mando.png',
    // Gorra y libro: cuando da un consejo.
    EmocionKoru.leyendo: 'assets/images/koru_leyendo.png',
    // Gorra, delantal y manzana: atiende la tienda.
    EmocionKoru.tendero: 'assets/images/koru_tienda.png',
  };

  // Todas las poses traen su propia línea negra de dibujo, así se ven
  // bien sobre fondos claros y oscuros sin contornos agregados.

  static String imagen(EmocionKoru emocion) => _imagenes[emocion]!;

  @override
  State<KoruMascota> createState() => _KoruMascotaState();
}

class _KoruMascotaState extends State<KoruMascota>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bucle = AnimationController(
    vsync: this,
    duration: _duracion(widget.emocion),
  );

  static Duration _duracion(EmocionKoru e) => switch (e) {
    EmocionKoru.celebrando => const Duration(milliseconds: 700),
    EmocionKoru.saludando => const Duration(milliseconds: 900),
    EmocionKoru.durmiendo => const Duration(milliseconds: 2600),
    _ => const Duration(milliseconds: 1500),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizarBucle();
  }

  @override
  void didUpdateWidget(KoruMascota old) {
    super.didUpdateWidget(old);
    if (old.emocion != widget.emocion) {
      _bucle.duration = _duracion(widget.emocion);
    }
    _actualizarBucle();
  }

  void _actualizarBucle() {
    final quieto = !widget.animar || MediaQuery.of(context).disableAnimations;
    if (quieto) {
      _bucle.stop();
    } else {
      _bucle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bucle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ruta = KoruMascota.imagen(widget.emocion);
    final imagen = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Image.asset(
        ruta,
        key: ValueKey(widget.emocion),
        width: widget.tamano,
        height: widget.tamano,
        fit: BoxFit.contain,
        semanticLabel: 'Koru, el caracol de Korulab',
      ),
    );
    if (!widget.animar) return imagen;

    return AnimatedBuilder(
      animation: _bucle,
      child: imagen,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bucle.value);
        final s = widget.tamano;
        final (
          double dy,
          double angulo,
          double escala,
        ) = switch (widget.emocion) {
          // Salta con fuerza.
          EmocionKoru.celebrando => (-s * 0.12 * t, 0.0, 1 + 0.04 * t),
          // Se inclina de lado a lado, como saludando.
          EmocionKoru.saludando => (0.0, (t - 0.5) * 0.18, 1.0),
          // Flota suave.
          EmocionKoru.feliz => (-s * 0.05 * t, 0.0, 1.0),
          // Ladea la cabeza despacio.
          EmocionKoru.pensando => (0.0, -0.06 * t, 1.0),
          // Se balancea dando ánimo.
          EmocionKoru.animando => (-s * 0.03 * t, (t - 0.5) * 0.1, 1.0),
          // Respira.
          EmocionKoru.durmiendo => (0.0, 0.0, 0.97 + 0.03 * t),
          // Se mueve un poco, concentrado en el juego.
          EmocionKoru.jugando => (-s * 0.03 * t, (t - 0.5) * 0.06, 1.0),
          // Lee tranquilo, flotando apenas.
          EmocionKoru.leyendo => (-s * 0.02 * t, -0.03 * t, 1.0),
          // Saluda a los clientes, balanceándose.
          EmocionKoru.tendero => (-s * 0.03 * t, (t - 0.5) * 0.12, 1.0),
        };
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angulo,
            child: Transform.scale(scale: escala, child: child),
          ),
        );
      },
    );
  }
}
