import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../servicios/servicio_biometrico.dart';
import '../widgets/advanced_animations.dart';

// ─────────────────────────────────────────────────────────────────
// Widget de autenticación biométrica
// Proporciona interfaz para login con huella/facial
// ─────────────────────────────────────────────────────────────────

class BiometricLoginWidget extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback? onAuthFail;
  final String username;

  const BiometricLoginWidget({
    super.key,
    required this.onAuthSuccess,
    this.onAuthFail,
    required this.username,
  });

  @override
  State<BiometricLoginWidget> createState() => _BiometricLoginWidgetState();
}

class _BiometricLoginWidgetState extends State<BiometricLoginWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAuthenticating = false;
  bool _authSuccess = false;
  bool _authFailed = false;
  String _biometricType = '';
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _initBiometrics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initBiometrics() async {
    final available = await BiometricAuthService.getAvailableBiometrics();
    setState(() {
      _availableBiometrics = available;
      if (available.isNotEmpty) {
        _biometricType = BiometricAuthService.nombreAmigable(available);
      }
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authSuccess = false;
      _authFailed = false;
    });

    try {
      final bool authenticated = await BiometricAuthService.authenticate(
        reason: 'Autentica con tu $_biometricType para acceder a Korulab',
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _authSuccess = true;
          _isAuthenticating = false;
        });
        _controller.forward();

        // Esperar la animación y luego llamar callback
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          widget.onAuthSuccess();
        }
      } else {
        setState(() {
          _authFailed = true;
          _isAuthenticating = false;
        });
        widget.onAuthFail?.call();

        // Limpiar estado después de 2 segundos
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          setState(() {
            _authFailed = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error during authentication: $e');
      setState(() {
        _authFailed = true;
        _isAuthenticating = false;
      });
      widget.onAuthFail?.call();

      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _authFailed = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInScale(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono de biometría
          if (_availableBiometrics.isNotEmpty)
            PulseAnimation(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _availableBiometrics.contains(BiometricType.face)
                      ? Icons.face
                      : Icons.fingerprint_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Título
          Text(
            'Desbloquea con $_biometricType',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Descripción
          Text(
            'Usuario: ${widget.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Estado de autenticación
          if (_authSuccess)
            FadeInScale(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Autenticación exitosa',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (_authFailed)
            FadeInScale(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Autenticación fallida',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_isAuthenticating ? 0.05 : 0),
                  child: Text(
                    _isAuthenticating
                        ? 'Aguardando verificación...'
                        : 'Toca el botón de abajo para autenticar',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          const SizedBox(height: 32),

          // Botón de biometría
          if (_availableBiometrics.isNotEmpty)
            FluidButton(
              label: _isAuthenticating
                  ? 'Verificando...'
                  : 'Autenticar con $_biometricType',
              onPressed: _isAuthenticating ? () {} : _authenticate,
              isLoading: _isAuthenticating,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: _availableBiometrics.contains(BiometricType.face)
                  ? Icons.face
                  : Icons.fingerprint_rounded,
              width: double.infinity,
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Este dispositivo no soporta autenticación biométrica',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget de opciones de autenticación (Biométrica vs Contraseña)
class BiometricAuthOptions extends StatelessWidget {
  final VoidCallback onBiometric;
  final VoidCallback onPassword;
  final bool biometricAvailable;
  final String biometricType;

  const BiometricAuthOptions({
    super.key,
    required this.onBiometric,
    required this.onPassword,
    required this.biometricAvailable,
    required this.biometricType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInScale(
      child: Column(
        children: [
          Text(
            'Elige cómo deseas iniciar sesión',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),

          // Opción biométrica
          if (biometricAvailable)
            Column(
              children: [
                FluidCard(
                  onTap: onBiometric,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.9),
                      theme.colorScheme.primary,
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          biometricType.contains('Facial')
                              ? Icons.face
                              : Icons.fingerprint,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Autenticación Biométrica',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Más rápido y seguro',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Opción contraseña
          FluidCard(
            onTap: onPassword,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contraseña',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Usuario y contraseña',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel de configuración de biometría
class BiometricSettingsPanel extends StatefulWidget {
  final String username;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;

  const BiometricSettingsPanel({
    super.key,
    required this.username,
    this.onEnable,
    this.onDisable,
  });

  @override
  State<BiometricSettingsPanel> createState() => _BiometricSettingsPanelState();
}

class _BiometricSettingsPanelState extends State<BiometricSettingsPanel> {
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _initBiometricSettings();
  }

  Future<void> _initBiometricSettings() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final enabled = await BiometricAuthService.isBiometricEnabled(
      widget.username,
    );
    final biometrics = await BiometricAuthService.getAvailableBiometrics();

    setState(() {
      _isBiometricAvailable = available;
      _biometricEnabled = enabled;
      _availableBiometrics = biometrics;
    });
  }

  Future<void> _toggleBiometric() async {
    if (!_isBiometricAvailable) return;

    if (_biometricEnabled) {
      // Desactivar
      await BiometricAuthService.clearBiometricData(widget.username);
      setState(() {
        _biometricEnabled = false;
      });
      widget.onDisable?.call();
    } else {
      // Activar
      await BiometricAuthService.authenticate(
        reason: 'Verifica tu identidad para habilitar login biométrico',
      ).then((authenticated) {
        if (authenticated) {
          BiometricAuthService.saveBiometricPreference(true, widget.username);
          BiometricAuthService.saveBiometricUser(widget.username);
          setState(() {
            _biometricEnabled = true;
          });
          widget.onEnable?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInScale(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguridad Biométrica',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (_isBiometricAvailable)
            FluidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login Biométrico',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _availableBiometrics.isEmpty
                                ? 'No disponible'
                                : _availableBiometrics
                                      .map((b) {
                                        return BiometricAuthService.getBiometricName(
                                          b,
                                        );
                                      })
                                      .join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _biometricEnabled,
                        onChanged: (_) => _toggleBiometric(),
                        activeThumbColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  if (_biometricEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Login biométrico habilitado para ${widget.username}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            FluidCard(
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este dispositivo no soporta autenticación biométrica',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
