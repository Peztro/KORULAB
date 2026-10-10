import 'package:flutter/material.dart';
import 'db_service.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  runApp(const KoruApp());
}

// ─────────────────────────────────────────────
// Widget raíz de la aplicación - configura el tema, rutas y pantalla inicial
// ─────────────────────────────────────────────
class KoruApp extends StatelessWidget {
  const KoruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korulab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          // Color principal - usado en botones, AppBar y elementos destacados
          primary: Color(0xFF2E7D32),
          // Color del texto/iconos sobre primary
          onPrimary: Color(0xFFFFFFFF),
          // Variante clara del color primario - para fondos de botones, chips, etc.
          primaryContainer: Color(0xFFA5D6A7),
          // Color del texto/iconos sobre primaryContainer
          onPrimaryContainer: Color(0xFF1B5E20),

          // Color secundario - usado en acciones alternativas y énfasis
          secondary: Color(0xFF1976D2),
          // Color del texto/iconos sobre secondary
          onSecondary: Color(0xFFFFFFFF),
          // Variante clara del color secundario
          secondaryContainer: Color(0xFFBBDEFB),
          // Color del texto/iconos sobre secondaryContainer
          onSecondaryContainer: Color(0xFF0D47A1),

          // Color terciario - usado para efectos complementarios y énfasis adicional
          tertiary: Color(0xFF8D6E63),
          // Color del texto/iconos sobre tertiary
          onTertiary: Color(0xFFFFFFFF),
          // Variante clara del color terciario
          tertiaryContainer: Color(0xFFD7CCC8),
          // Color del texto/iconos sobre tertiaryContainer
          onTertiaryContainer: Color(0xFF5D4037),

          // Color para errores y alertas
          error: Color(0xFFD32F2F),
          // Color del texto/iconos sobre error
          onError: Color(0xFFFFFFFF),
          // Variante clara para fondos de errores
          errorContainer: Color(0xFFFFCDD2),
          // Color del texto/iconos sobre errorContainer
          onErrorContainer: Color(0xFFB71C1C),

          // Color de fondo principal - usado en Scaffold y superficies
          surface: Color(0xFF122014),
          // Color del texto/iconos sobre surface
          onSurface: Color(0xFFE8F5E8),
          // Contenedor de superficie - para elementos elevados y destacados
          surfaceContainerHighest: Color(0xFF1B3C22),
          // Color secundario del texto sobre surface
          onSurfaceVariant: Color(0xFFC2E8C4),

          // Color de contorno/borde para separadores y divisores
          outline: Color(0xFF758E77),
          // Variante del contorno - para bordes más suaves
          outlineVariant: Color(0xFF3F5E44),

          // Color de sombra - para sombras y profundidad
          shadow: Color(0xFF000000),
          // Color de oscurecimiento - para overlays y modales
          scrim: Color(0xFF000000),

          // Fondo inverso - para modo claro en apps oscuras
          inverseSurface: Color(0xFFE8F5E8),
          // Texto inverso - para modo claro en apps oscuras
          onInverseSurface: Color(0xFF122014),
          // Color primario inverso - para botones en modo inverso
          inversePrimary: Color(0xFF8DD99F),
          // Tinte de la superficie - aplicado a superficies de fondo
          surfaceTint: Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/home':
            final username = settings.arguments as String?;
            if (username != null) {
              return MaterialPageRoute(
                builder: (_) => HomePage(username: username),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginPage());
          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
    );
  }
}
