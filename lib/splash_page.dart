import 'package:flutter/material.dart';
import 'db_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Esperar un poco para que se vea la pantalla de carga
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Verificar si hay sesión activa
    final hasSession = await DBService.hasActiveSession();
    
    if (hasSession) {
      // Obtener el nombre de usuario
      final username = await DBService.getSessionUsername();
      
      if (mounted && username != null) {
        // Importar HomePage aquí para evitar referencias circulares
        Navigator.of(context).pushReplacementNamed(
          '/home',
          arguments: username,
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/koruicon.png',
                height: 100, fit: BoxFit.contain),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
