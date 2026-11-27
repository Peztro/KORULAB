import 'package:flutter/material.dart';
import 'servicio_bd.dart';
import 'servicios/servicio_biometrico.dart';
import 'tema/tema_korulab.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final hasSession = await DBService.hasActiveSession();

    if (hasSession) {
      final username = await DBService.getSessionUsername();

      if (mounted && username != null) {
        // Verificar si biometría está habilitada PARA ESTE USUARIO
        final biometricEnabled = await BiometricAuthService.isBiometricEnabled(
          username,
        );
        final biometricAvailable =
            await BiometricAuthService.isBiometricAvailable();

        // Si biometría está habilitada para este usuario, pedir verificación
        if (biometricEnabled && biometricAvailable) {
          if (mounted) {
            _requestBiometricVerification(username);
          }
        } else {
          // Si no tiene biometría, ir directo a home
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/home', arguments: username);
          }
        }
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _requestBiometricVerification(String username) async {
    try {
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Verifica tu huella para acceder a Korulab',
      );

      if (authenticated && mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/home', arguments: username);
      } else if (mounted) {
        // Si falla la biometría, volver a login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autenticación biométrica fallida. Por favor inicia sesión de nuevo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en autenticación: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: koru.degradadoHero),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              bottom: -40,
              child: Icon(
                Icons.eco_rounded,
                size: 280,
                color: koru.textoHero.withValues(alpha: 0.06),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/korualt.png',
                          width: 220,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aprende a cuidar el planeta',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: koru.textoHero.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildAnimatedDots(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index * 0.15) % 1,
                  ((index * 0.15) % 1) + 0.6,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: context.koru.textoHero,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
