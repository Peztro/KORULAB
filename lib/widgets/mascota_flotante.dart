import 'package:flutter/material.dart';

import '../servicios/koru_controlador.dart';
import '../tema/tema_korulab.dart';
import 'koru_mascota.dart';

/// Koru en una esquina de la pantalla, con su globo de diálogo.
///
/// Se coloca dentro de un [Stack]; solo ocupa (y recibe toques en) su propio
/// espacio, así que no bloquea el resto de la pantalla.
class MascotaFlotante extends StatefulWidget {
  const MascotaFlotante({
    super.key,
    this.tamano = 76,
    this.acciones = const {},
  });

  final double tamano;

  /// Qué hacer al tocar el globo según por qué habló Koru (por ejemplo,
  /// abrir los chats cuando avisa de mensajes nuevos).
  final Map<EventoKoru, VoidCallback> acciones;

  @override
  State<MascotaFlotante> createState() => _MascotaFlotanteState();
}

class _MascotaFlotanteState extends State<MascotaFlotante> with RouteAware {
  final _koru = KoruControlador.instancia;
  ModalRoute<dynamic>? _ruta;

  @override
  void initState() {
    super.initState();
    _koru.addListener(_alCambiar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruta = ModalRoute.of(context);
    if (ruta != null && ruta != _ruta) {
      if (_ruta != null) observadorRutas.unsubscribe(this);
      _ruta = ruta;
      observadorRutas.subscribe(this, ruta);
    }
  }

  @override
  void dispose() {
    observadorRutas.unsubscribe(this);
    _koru.removeListener(_alCambiar);
    _koru.cambiarVisible(false);
    super.dispose();
  }

  void _alCambiar() {
    if (mounted) setState(() {});
  }

  // La pantalla con Koru aparece o vuelve a primer plano.
  @override
  void didPush() => _koru.cambiarVisible(true);

  @override
  void didPopNext() => _koru.cambiarVisible(true);

  // Otra pantalla la tapa.
  @override
  void didPushNext() => _koru.cambiarVisible(false);

  @override
  Widget build(BuildContext context) {
    if (!_koru.activo) return const SizedBox.shrink();
    final mensaje = _koru.mensaje;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
          child: mensaje == null
              ? const SizedBox.shrink()
              : _Globo(
                  key: ValueKey(mensaje),
                  texto: mensaje.texto,
                  onCerrar: _koru.callar,
                  accion: widget.acciones[mensaje.evento],
                ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: 'Koru. Toca para recibir un consejo',
          child: GestureDetector(
            onTap: () => _koru.reaccionar(EventoKoru.consejo, importante: true),
            child: Container(
              width: widget.tamano,
              height: widget.tamano,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: context.koru.hoja.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: KoruMascota(
                emocion: _koru.emocion,
                tamano: widget.tamano - 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Globo extends StatelessWidget {
  const _Globo({
    super.key,
    required this.texto,
    required this.onCerrar,
    this.accion,
  });

  final String texto;
  final VoidCallback onCerrar;

  /// Si hay acción, tocar el globo la hace (y lo cierra) en vez de solo
  /// cerrarlo, y en lugar de la ✕ se ve una flecha.
  final VoidCallback? accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ancho = MediaQuery.sizeOf(context).width * 0.66;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho.clamp(180, 300)),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          side: BorderSide(color: context.koru.hoja.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          onTap: () {
            onCerrar();
            accion?.call();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    texto,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  accion != null
                      ? Icons.arrow_forward_rounded
                      : Icons.close_rounded,
                  size: accion != null ? 18 : 16,
                  color: accion != null
                      ? context.koru.agua
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
