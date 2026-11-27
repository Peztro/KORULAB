import 'package:flutter/material.dart';

import '../servicios/servicio_biometrico.dart';
import '../tema/tema_korulab.dart';
import 'ui_koru.dart';

/// Interruptor para entrar con huella o rostro, en Ajustes → Seguridad.
///
/// La preferencia es por usuario y se guarda en el dispositivo. Al activarla
/// se pide verificar la identidad con el propio sensor.
class AjusteBiometria extends StatefulWidget {
  const AjusteBiometria({super.key, required this.username});

  final String username;

  @override
  State<AjusteBiometria> createState() => _AjusteBiometriaState();
}

class _AjusteBiometriaState extends State<AjusteBiometria> {
  bool _cargando = true;
  bool _disponible = false;
  bool _activa = false;
  bool _ocupado = false;
  String _nombre = 'huella o rostro';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final disponible = await BiometricAuthService.isBiometricAvailable();
    final activa = await BiometricAuthService.isBiometricEnabled(
      widget.username,
    );
    final tipos = await BiometricAuthService.getAvailableBiometrics();
    if (!mounted) return;
    setState(() {
      _disponible = disponible;
      _activa = activa;
      _nombre = BiometricAuthService.nombreAmigable(tipos);
      _cargando = false;
    });
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _activar() async {
    setState(() => _ocupado = true);
    try {
      final ok = await BiometricAuthService.authenticate(
        reason: 'Verifica tu identidad para entrar con $_nombre',
      );
      if (!ok) return;
      await BiometricAuthService.saveBiometricPreference(true, widget.username);
      await BiometricAuthService.saveBiometricUser(widget.username);
      await _cargar();
      if (mounted) _aviso('Listo: ya puedes entrar con tu $_nombre.');
    } catch (e) {
      if (mounted) _aviso('No se pudo activar: $e');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _desactivar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Dejar de entrar con $_nombre?'),
        content: const Text(
          'La próxima vez tendrás que entrar con tu usuario y contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() => _ocupado = true);
    await BiometricAuthService.saveBiometricPreference(false, widget.username);
    await BiometricAuthService.clearBiometricData(widget.username);
    await _cargar();
    if (mounted) {
      setState(() => _ocupado = false);
      _aviso('Entrada con $_nombre desactivada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final icono = IconTile(
      icon: _nombre == 'reconocimiento facial'
          ? Icons.face_rounded
          : Icons.fingerprint_rounded,
      color: context.koru.hoja,
      size: 40,
    );
    final titulo = 'Entrar con ${_nombre == 'huella' ? 'huella' : _nombre}';

    if (_cargando) {
      return ListTile(
        leading: icono,
        title: const Text('Entrar con huella o rostro'),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!_disponible) {
      return ListTile(
        enabled: false,
        leading: icono,
        title: const Text('Entrar con huella o rostro'),
        subtitle: const Text(
          'Este dispositivo no tiene huella ni reconocimiento facial '
          'configurados.',
        ),
      );
    }
    return SwitchListTile(
      secondary: icono,
      title: Text(titulo),
      subtitle: Text(
        _activa
            ? 'Activado en este dispositivo.'
            : 'Entra más rápido sin escribir la contraseña.',
      ),
      value: _activa,
      onChanged: _ocupado
          ? null
          : (valor) => valor ? _activar() : _desactivar(),
    );
  }
}
