import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../servicio_bd.dart';
import '../tema/tema_korulab.dart';
import 'ui_koru.dart';

/// Restablece la contraseña de otra cuenta (profesor → estudiante,
/// admin → estudiante o profesor).
///
/// 1. Pregunta si la contraseña será aleatoria o escrita.
/// 2. La aplica con la Edge Function.
/// 3. Muestra el resultado con un botón para copiarla.
///
/// Al entrar con ella, la persona tendrá que crear una contraseña propia.
Future<void> restablecerContrasena(
  BuildContext context, {
  required String solicitante,
  required String username,
  String? nombre,
}) async {
  final persona = (nombre?.trim().isNotEmpty ?? false)
      ? '${nombre!.trim()} (@$username)'
      : '@$username';

  final eleccion = await showDialog<_Eleccion>(
    context: context,
    builder: (_) => _DialogoEleccion(persona: persona),
  );
  if (eleccion == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  String? contrasena;
  Object? error;
  try {
    contrasena = await DBService.resetPassword(
      solicitante,
      username,
      contrasena: eleccion.escrita,
    );
  } catch (e) {
    error = e;
  }
  if (!context.mounted) return;
  Navigator.of(context).pop(); // Cierra el indicador de carga.

  if (contrasena == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error is StateError
              ? error.message
              : 'No se pudo restablecer la contraseña.',
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) =>
        _DialogoResultado(persona: persona, contrasena: contrasena!),
  );
}

class _Eleccion {
  const _Eleccion(this.escrita);

  /// null = aleatoria.
  final String? escrita;
}

class _DialogoEleccion extends StatefulWidget {
  const _DialogoEleccion({required this.persona});

  final String persona;

  @override
  State<_DialogoEleccion> createState() => _DialogoEleccionState();
}

class _DialogoEleccionState extends State<_DialogoEleccion> {
  bool _aleatoria = true;
  bool _oculta = true;
  final _texto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_aleatoria) {
      Navigator.pop(context, const _Eleccion(null));
      return;
    }
    final valor = _texto.text;
    if (valor.length < 6) {
      setState(() => _error = 'Debe tener al menos 6 caracteres.');
      return;
    }
    if (valor.length > 72) {
      setState(() => _error = 'Máximo 72 caracteres.');
      return;
    }
    Navigator.pop(context, _Eleccion(valor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Restablecer contraseña'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La contraseña actual de ${widget.persona} dejará de funcionar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.casino_rounded),
                  label: Text('Aleatoria'),
                ),
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.edit_rounded),
                  label: Text('Escribirla'),
                ),
              ],
              selected: {_aleatoria},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _aleatoria = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 14),
            if (_aleatoria)
              Text(
                'Se generará una de 8 caracteres, fácil de dictar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              TextField(
                controller: _texto,
                autofocus: true,
                obscureText: _oculta,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _confirmar(),
                decoration: InputDecoration(
                  labelText: 'Contraseña temporal',
                  helperText: 'Mínimo 6 caracteres.',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _oculta ? 'Mostrar' : 'Ocultar',
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: Icon(
                      _oculta
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al entrar con ella, tendrá que crear una contraseña propia.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Restablecer')),
      ],
    );
  }
}

class _DialogoResultado extends StatefulWidget {
  const _DialogoResultado({required this.persona, required this.contrasena});

  final String persona;
  final String contrasena;

  @override
  State<_DialogoResultado> createState() => _DialogoResultadoState();
}

class _DialogoResultadoState extends State<_DialogoResultado> {
  bool _copiada = false;

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: widget.contrasena));
    if (mounted) setState(() => _copiada = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return AlertDialog(
      icon: IconTile(icon: Icons.key_rounded, color: koru.hoja, size: 52),
      title: const Text('Contraseña restablecida'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entrégale esta contraseña temporal a ${widget.persona}:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(KoruRadius.m),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SelectableText(
              widget.contrasena,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _copiar,
            icon: Icon(_copiada ? Icons.check_rounded : Icons.copy_rounded),
            label: Text(_copiada ? 'Copiada' : 'Copiar contraseña'),
          ),
          const SizedBox(height: 12),
          Text(
            'Al entrar con ella, tendrá que crear una contraseña propia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}
