import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicio_bd.dart';
import '../servicios/koru_controlador.dart';
import '../tema/tema_korulab.dart';

/// Tarjeta con el aviso general más reciente, en la pantalla de inicio.
/// Se puede cerrar; vuelve a salir cuando se publique uno nuevo.
class AvisoReciente extends StatefulWidget {
  const AvisoReciente({
    super.key,
    required this.username,
    required this.onVerTodos,
  });

  final String username;
  final VoidCallback onVerTodos;

  @override
  State<AvisoReciente> createState() => AvisoRecienteState();
}

class AvisoRecienteState extends State<AvisoReciente> {
  Map<String, dynamic>? _aviso;

  String get _clave =>
      'korulab_aviso_cerrado_${DBService.normalizeUsername(widget.username)}';

  @override
  void initState() {
    super.initState();
    recargar();
  }

  /// Vuelve a consultar el último aviso (p. ej. tras publicar uno).
  Future<void> recargar() async {
    try {
      final mensajes = await DBService.getMessages(widget.username);
      final ultimo = mensajes.where((m) => m['kind'] == 'general').firstOrNull;
      final prefs = await SharedPreferences.getInstance();
      final cerrado = prefs.getInt(_clave);
      if (!mounted) return;
      final nuevo = ultimo == null || ultimo['id'] == cerrado ? null : ultimo;
      if (nuevo != null && nuevo['id'] != _aviso?['id']) {
        unawaited(KoruControlador.instancia.reaccionar(EventoKoru.avisoNuevo));
      }
      setState(() => _aviso = nuevo);
    } catch (e) {
      debugPrint('No se pudo cargar el último aviso: $e');
    }
  }

  Future<void> _cerrar() async {
    final id = _aviso?['id'];
    setState(() => _aviso = null);
    if (id is int) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_clave, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aviso = _aviso;
    final theme = Theme.of(context);
    final koru = context.koru;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: aviso == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: koru.oro.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KoruRadius.l),
                  side: BorderSide(color: koru.oro.withValues(alpha: 0.5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onVerTodos,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.campaign_rounded, color: koru.oro, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVISO',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: koru.oro,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                aviso['title'] as String? ?? 'Aviso',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                aviso['message'] as String? ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ver todos los avisos',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar aviso',
                          onPressed: _cerrar,
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
