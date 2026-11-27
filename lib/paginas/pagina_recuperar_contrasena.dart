import 'package:flutter/material.dart';

import '../servicio_bd.dart';
import '../widgets/auth_layout.dart';
import 'pagina_inicio.dart';

/// "¿Olvidaste tu contraseña?": envía un código al correo de la cuenta y,
/// con ese código, permite crear una contraseña nueva.
///
/// El correo lo envía Supabase con la plantilla "Reset Password", que debe
/// incluir {{ .Token }} para mostrar el código.
class RecuperarContrasenaPage extends StatefulWidget {
  const RecuperarContrasenaPage({super.key, this.usuarioInicial = ''});

  final String usuarioInicial;

  @override
  State<RecuperarContrasenaPage> createState() =>
      _RecuperarContrasenaPageState();
}

class _RecuperarContrasenaPageState extends State<RecuperarContrasenaPage> {
  late final _usuario = TextEditingController(text: widget.usuarioInicial);
  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  /// Correo al que se envió el código; si es null, aún no se envió.
  String? _correo;
  bool _ocupado = false;
  bool _oculta = true;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _codigo.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  /// Muestra el correo a medias: "to***@gmail.com".
  static String _ocultar(String correo) {
    final partes = correo.split('@');
    if (partes.length != 2) return correo;
    final nombre = partes[0];
    final visible = nombre.length <= 2 ? nombre[0] : nombre.substring(0, 2);
    return '$visible***@${partes[1]}';
  }

  Future<void> _enviar() async {
    if (_usuario.text.trim().isEmpty) {
      setState(() => _error = 'Escribe tu @usuario o tu correo.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final correo = await DBService.enviarCodigoRecuperacion(_usuario.text);
      if (!mounted) return;
      setState(() => _correo = correo);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is StateError ? e.message : 'No se pudo enviar.',
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _restablecer() async {
    final codigo = _codigo.text.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(codigo)) {
      setState(() => _error = 'Escribe el código que te llegó al correo.');
      return;
    }
    if (_nueva.text.length < 6) {
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }
    if (_nueva.text != _confirmar.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final username = await DBService.restablecerConCodigo(
        email: _correo!,
        codigo: codigo,
        nueva: _nueva.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage(username: username)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ocupado = false;
        _error = e is StateError ? e.message : 'No se pudo restablecer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correo = _correo;

    if (correo == null) {
      return AuthLayout(
        showBack: true,
        title: '¿Olvidaste tu contraseña?',
        subtitle: 'Te enviaremos un código al correo de tu cuenta.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usuario,
              enabled: !_ocupado,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _ocupado ? null : _enviar(),
              decoration: InputDecoration(
                labelText: '@usuario o correo',
                prefixIcon: const Icon(Icons.person_search_rounded),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Enviar código',
              icon: Icons.send_rounded,
              loading: _ocupado,
              onPressed: _enviar,
            ),
            const SizedBox(height: 16),
            Text(
              '¿No tienes acceso a tu correo? Pídele a tu profesor que '
              'restablezca tu contraseña.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    InputDecoration clave(String etiqueta) => InputDecoration(
      labelText: etiqueta,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: _oculta ? 'Mostrar' : 'Ocultar',
        onPressed: () => setState(() => _oculta = !_oculta),
        icon: Icon(
          _oculta ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );

    return AuthLayout(
      showBack: true,
      title: 'Revisa tu correo',
      subtitle:
          'Enviamos un código a ${_ocultar(correo)}. Si no lo ves, mira en '
          'spam.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codigo,
            enabled: !_ocupado,
            keyboardType: TextInputType.number,
            maxLength: 10,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.next,
            style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 6),
            decoration: const InputDecoration(
              labelText: 'Código',
              counterText: '',
              prefixIcon: Icon(Icons.pin_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nueva,
            enabled: !_ocupado,
            obscureText: _oculta,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: clave(
              'Nueva contraseña',
            ).copyWith(helperText: 'Mínimo 6 caracteres.'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmar,
            enabled: !_ocupado,
            obscureText: _oculta,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _ocupado ? null : _restablecer(),
            decoration: clave(
              'Repite la contraseña',
            ).copyWith(errorText: _error),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Guardar y entrar',
            icon: Icons.arrow_forward_rounded,
            loading: _ocupado,
            onPressed: _restablecer,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _ocupado
                ? null
                : () => setState(() {
                    _correo = null;
                    _codigo.clear();
                    _error = null;
                  }),
            child: const Text('No me llegó: enviar otra vez'),
          ),
        ],
      ),
    );
  }
}
