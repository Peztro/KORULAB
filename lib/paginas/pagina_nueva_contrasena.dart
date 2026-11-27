import 'package:flutter/material.dart';

import '../servicio_bd.dart';
import '../widgets/auth_layout.dart';

/// Crear una contraseña propia.
///
/// Se usa cuando la contraseña actual es temporal (la restableció un profesor
/// o admin): no se puede salir de aquí sin cambiarla, salvo cerrando sesión.
class NuevaContrasenaPage extends StatefulWidget {
  const NuevaContrasenaPage({super.key});

  @override
  State<NuevaContrasenaPage> createState() => _NuevaContrasenaPageState();
}

class _NuevaContrasenaPageState extends State<NuevaContrasenaPage> {
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _oculta = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nueva.text.length < 6) {
      setState(() => _error = 'Debe tener al menos 6 caracteres.');
      return;
    }
    if (_nueva.text != _confirmar.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await DBService.establecerNuevaContrasena(_nueva.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! Tu contraseña quedó guardada.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar. Prueba con otra contraseña.';
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final navigator = Navigator.of(context);
    await DBService.logout();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoracion(String etiqueta) => InputDecoration(
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

    return PopScope(
      canPop: false,
      child: AuthLayout(
        title: 'Crea tu contraseña',
        subtitle:
            'Entraste con una contraseña temporal. Elige una nueva que solo '
            'conozcas tú.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nueva,
              obscureText: _oculta,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              decoration: decoracion(
                'Nueva contraseña',
              ).copyWith(helperText: 'Mínimo 6 caracteres.'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmar,
              obscureText: _oculta,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardando ? null : _guardar(),
              decoration: decoracion(
                'Repite la contraseña',
              ).copyWith(errorText: _error),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Guardar y continuar',
              icon: Icons.arrow_forward_rounded,
              loading: _guardando,
              onPressed: _guardar,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _guardando ? null : _cerrarSesion,
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
